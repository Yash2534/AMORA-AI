const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const fs = require('node:fs');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (testDatabase === applicationDatabase || !/test/i.test(testDatabase)) {
  throw new Error('Admin user integration tests require an isolated TEST_DB_NAME containing "test".');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';
require('../src/config/env');
const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');
const { absolutePathFor } = require('../src/utils/identityVerificationStorage');
const adminMfaService = require('../src/services/adminMfaService');

let server;
let baseUrl;
let administrator;
let role;
let consumer;
let consumerProfile;
let matchingPeer;
let matchingPeerProfile;
let matchingConversation;
let verification;
let verificationStoragePath;
let password;
let consumerPassword;

async function request(path, options = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    method: options.method || 'GET',
    headers: {
      ...(options.accessToken ? { authorization: `Bearer ${options.accessToken}` } : {}),
      ...(options.cookie ? { cookie: options.cookie } : {}),
      ...(options.body ? { 'content-type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
    ...(options.body ? { body: JSON.stringify(options.body) } : {}),
  });
  return { status: response.status, body: await response.json() };
}

function taxonomyOptionId(category, label) {
  const normalized = String(label).trim().replace(/\s+/g, ' ').toLocaleLowerCase('en-US');
  return `taxonomy_${category}_${crypto.createHash('sha256').update(`${category}\0${normalized}`).digest('hex').slice(0, 32)}`;
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  const { Administrator, AdminRole, AdminPermission, User, OnboardingProfile, ProfileTaxonomyOption } = getModels();
  const suffix = crypto.randomUUID().replaceAll('-', '');
  password = `AdminUsers!${suffix}Aa1`;
  role = await AdminRole.create({
    key: `admin_users_${suffix}`,
    name: 'Admin Users Integration Role',
    isActive: true,
  });
  const keys = [
    'users.view', 'users.details.view', 'users.profile.view', 'users.sessions.view',
    'users.loginHistory.view', 'users.notes.view', 'users.notes.manage', 'users.timeline.view',
    'users.manage', 'users.activate', 'users.forceLogout', 'users.delete', 'users.resetPassword',
    'profiles.view', 'profiles.details.view', 'profiles.preview', 'profiles.edit',
    'profiles.photos.view', 'profiles.photos.manage', 'profiles.audit.view',
    'profiles.sensitiveFields.view',
    'verifications.view', 'verifications.pending.view', 'verifications.details.view',
    'verifications.aadhaar.view', 'verifications.selfie.view', 'verifications.history.view',
    'verifications.approve',
    'matching.likes.view', 'matching.superLikes.view', 'matching.roses.view',
    'matching.matches.view', 'matching.actions.details.view', 'matching.actions.failed.view',
    'matching.aiScore.view', 'matching.aiScore.explanation.view', 'matching.audit.view',
    'discover.settings.view', 'discover.settings.manage', 'discover.filters.view', 'discover.filters.manage',
    'matching.sensitiveFields.view',
  ];
  const permissions = await AdminPermission.findAll({ where: { key: keys } });
  assert.equal(permissions.length, keys.length);
  await role.addPermissions(permissions);
  administrator = await Administrator.create({
    name: 'Admin Users Integration',
    email: `admin.users.${suffix}@example.test`,
    passwordHash: await bcrypt.hash(password, 12),
  });
  await administrator.addRole(role);
  consumerPassword = `Client!${suffix}Aa1`;
  consumer = await User.create({
    name: `Real Client ${suffix}`,
    email: `real.client.${suffix}@example.test`,
    phoneNumber: `+9199${suffix.slice(0, 8).replace(/[^0-9]/g, '7')}`,
    passwordHash: await bcrypt.hash(consumerPassword, 12),
    isVerified: true,
    accountStatus: 'active',
  });
  consumerProfile = await OnboardingProfile.create({
    userId: consumer.id,
    birthDate: '1995-04-20',
    gender: 'Woman',
    city: 'Pune',
    bio: 'A real integration profile persisted in the isolated test database.',
    interests: ['music', 'travel'],
    languages: ['English', 'Hindi'],
    photos: ['/uploads/integration-profile.jpg'],
    primaryPhotoIndex: 0,
    onboardingCompleted: true,
    stage: 'complete',
  });
  const taxonomyOptions = [
    ['education', 'Bachelor of Technology'],
    ['languages', 'English'],
    ['languages', 'Hindi'],
    ['interests', 'music'],
    ['interests', 'travel'],
  ].map(([categoryKey, label], index) => ({
    id: taxonomyOptionId(categoryKey, label),
    categoryKey,
    label,
    normalizedLabel: label.toLocaleLowerCase('en-US'),
    allowsCustomValue: false,
    isActive: true,
    sortOrder: index + 1,
  }));
  await ProfileTaxonomyOption.bulkCreate(taxonomyOptions, { ignoreDuplicates: true });
  matchingPeer = await User.create({
    name: `Matching Peer ${suffix}`,
    email: `matching.peer.${suffix}@example.test`,
    phoneNumber: `+9188${suffix.slice(0, 8).replace(/[^0-9]/g, '6')}`,
    passwordHash: await bcrypt.hash(consumerPassword, 12),
    isVerified: true,
    accountStatus: 'active',
  });
  matchingPeerProfile = await OnboardingProfile.create({
    userId: matchingPeer.id,
    birthDate: '1994-03-19', gender: 'Woman', city: 'Pune',
    bio: 'Authoritative matching integration peer.',
    interests: ['music'], languages: ['English'], relationshipGoals: ['long_term'],
    photos: ['/uploads/matching-peer.jpg'], primaryPhotoIndex: 0,
    onboardingCompleted: true, stage: 'complete',
  });
  const { DiscoverAction, Match, RoseTransaction } = getModels();
  await DiscoverAction.create({ actorUserId: consumer.id, targetUserId: matchingPeer.id, action: 'like' });
  await DiscoverAction.create({ actorUserId: matchingPeer.id, targetUserId: consumer.id, action: 'superLike' });
  await Match.create({ userOneId: Math.min(consumer.id, matchingPeer.id), userTwoId: Math.max(consumer.id, matchingPeer.id), matchedAt: new Date() });
  matchingConversation = (await require('../src/services/conversationAccessService').ensureDirectConversation(consumer.id, matchingPeer.id)).conversation;
  await RoseTransaction.create({ senderId: consumer.id, recipientId: matchingPeer.id, conversationId: matchingConversation.id, idempotencyKey: `admin-matching-${suffix}`, status: 'sent', note: 'Integration rose' });
  const { IdentityVerification } = getModels();
  const evidenceBytes = Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex');
  verificationStoragePath = `identity-verification/${consumer.id}-admin-integration.png`;
  const evidencePath = absolutePathFor(verificationStoragePath);
  await fs.promises.writeFile(evidencePath, evidenceBytes, { flag: 'w', mode: 0o600 });
  verification = await IdentityVerification.create({
    userId: consumer.id,
    status: 'pending',
    aadhaarStoragePath: verificationStoragePath,
    aadhaarMimeType: 'image/png',
    aadhaarSizeBytes: evidenceBytes.length,
    selfieStoragePath: verificationStoragePath,
    selfieMimeType: 'image/png',
    selfieSizeBytes: evidenceBytes.length,
    submittedAt: new Date(),
  });
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

after(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  const { AdminAuditLog, AdminRefreshToken, Administrator, AdminRole, RefreshToken, OnboardingProfile, IdentityVerification, User, Conversation, ConversationParticipant } = getModels();
  if (consumer) {
    await IdentityVerification.destroy({ where: { userId: consumer.id } });
    await RefreshToken.destroy({ where: { userId: consumer.id } });
    await OnboardingProfile.destroy({ where: { userId: consumer.id } });
    await User.destroy({ where: { id: consumer.id } });
  }
  if (matchingPeer) {
    await OnboardingProfile.destroy({ where: { userId: matchingPeer.id } });
    await User.destroy({ where: { id: matchingPeer.id } });
  }
  if (matchingConversation) {
    await ConversationParticipant.destroy({ where: { conversationId: matchingConversation.id } });
    await Conversation.destroy({ where: { id: matchingConversation.id } });
  }
  if (administrator) {
    await AdminAuditLog.destroy({ where: { administratorId: administrator.id } });
    await AdminRefreshToken.destroy({ where: { administratorId: administrator.id }, force: true });
    await administrator.setRoles([]);
    await Administrator.destroy({ where: { id: administrator.id } });
  }
  if (role) {
    await role.setPermissions([]);
    await AdminRole.destroy({ where: { id: role.id } });
  }
  if (verificationStoragePath) await fs.promises.unlink(absolutePathFor(verificationStoragePath)).catch(() => {});
  await getSequelize().close();
});

test('admin user reads and lifecycle mutations commit to the client-authoritative database', async () => {
  const login = await request('/api/admin/v1/auth/login', {
    method: 'POST',
    body: { email: administrator.email, password, rememberMe: false },
  });
  assert.equal(login.status, 200);
  const adminToken = login.body.data.accessToken;

  const users = await request(`/api/admin/v1/users?search=${consumer.id}&page=1&pageSize=20`, {
    accessToken: adminToken,
  });
  assert.equal(users.status, 200);
  const listed = users.body.data.items.find((item) => item.id === String(consumer.id));
  assert.ok(listed);
  assert.equal(listed.displayName, consumer.name);
  assert.notEqual(listed.email, consumer.email);
  assert.equal(listed.verificationStatus, 'pending');

  const supportedListContract = await request(
    `/api/admin/v1/users?status=active&onlineStatus=offline&sortBy=displayName&sortDirection=asc&page=1&pageSize=20`,
    { accessToken: adminToken },
  );
  assert.equal(supportedListContract.status, 200);
  const unsupportedListQuery = await request(
    '/api/admin/v1/users?verificationStatus=pending&page=1&pageSize=20',
    { accessToken: adminToken },
  );
  assert.equal(unsupportedListQuery.status, 422);
  assert.equal(unsupportedListQuery.body.code, 'UNSUPPORTED_QUERY_PARAMETER');

  const details = await request(`/api/admin/v1/users/${consumer.id}`, { accessToken: adminToken });
  assert.equal(details.status, 200);
  assert.equal(details.body.data.user.id, String(consumer.id));

  const consumerLogin = await request('/api/auth/login', {
    method: 'POST',
    body: { email: consumer.email, password: consumerPassword },
  });
  assert.equal(consumerLogin.status, 200);
  const loginHistory = await request(`/api/admin/v1/users/${consumer.id}/login-history?page=1&pageSize=20`, {
    accessToken: adminToken,
  });
  assert.equal(loginHistory.status, 200);
  assert.ok(loginHistory.body.data.items.some((item) => item.result === 'successful'));
  assert.equal(loginHistory.body.data.items[0].ipAddress, '127.0.***.***');

  const invalidNote = await request(`/api/admin/v1/users/${consumer.id}/notes`, {
    method: 'POST', accessToken: adminToken, body: { text: '' },
  });
  assert.equal(invalidNote.status, 400);
  const createdNote = await request(`/api/admin/v1/users/${consumer.id}/notes`, {
    method: 'POST', accessToken: adminToken, body: { text: 'Persisted internal investigation note.' },
  });
  assert.equal(createdNote.status, 200);
  assert.equal(createdNote.body.data.note.text, 'Persisted internal investigation note.');
  assert.equal(createdNote.body.data.note.canEdit, true);
  const noteId = createdNote.body.data.note.id;
  const listedNotes = await request(`/api/admin/v1/users/${consumer.id}/notes?page=1&pageSize=20`, { accessToken: adminToken });
  assert.equal(listedNotes.status, 200);
  assert.equal(listedNotes.body.data.items[0].id, noteId);
  const updatedNote = await request(`/api/admin/v1/users/${consumer.id}/notes/${noteId}`, {
    method: 'PUT', accessToken: adminToken, body: { text: 'Updated internal investigation note.' },
  });
  assert.equal(updatedNote.status, 200);
  assert.equal(updatedNote.body.data.note.version, 2);
  const { AdminUserNoteVersion } = getModels();
  assert.equal(await AdminUserNoteVersion.count({ where: { noteId } }), 2);
  const timeline = await request(`/api/admin/v1/users/${consumer.id}/timeline?page=1&pageSize=20`, { accessToken: adminToken });
  assert.equal(timeline.status, 200);
  assert.ok(timeline.body.data.items.some((item) => item.category === 'login_successful'));
  assert.ok(timeline.body.data.items.some((item) => item.category === 'admin_note_updated'));
  const deletedNote = await request(`/api/admin/v1/users/${consumer.id}/notes/${noteId}`, {
    method: 'DELETE', accessToken: adminToken,
  });
  assert.equal(deletedNote.status, 200);
  const notesAfterDelete = await request(`/api/admin/v1/users/${consumer.id}/notes?page=1&pageSize=20`, { accessToken: adminToken });
  assert.equal(notesAfterDelete.status, 200);
  assert.equal(notesAfterDelete.body.data.items.some((item) => item.id === noteId), false);
  assert.equal(await AdminUserNoteVersion.count({ where: { noteId } }), 3);
  const profile = await request(`/api/admin/v1/users/${consumer.id}/profile`, { accessToken: adminToken });
  assert.equal(profile.status, 200);
  assert.equal(profile.body.data.city, 'Pune');
  assert.equal(profile.body.data.about, 'A real integration profile persisted in the isolated test database.');

  const originalClientToken = jwt.sign({ sub: String(consumer.id), ver: 0 }, process.env.JWT_SECRET, { expiresIn: '5m' });
  const before = await request('/api/auth/me', { accessToken: originalClientToken });
  assert.equal(before.status, 200);
  assert.equal(before.body.data.user.accountStatus, 'active');

  const profiles = await request(`/api/admin/v1/profiles?search=${encodeURIComponent(consumer.name)}&page=1&pageSize=20`, {
    accessToken: adminToken,
  });
  assert.equal(profiles.status, 200);
  const listedProfile = profiles.body.data.items.find((item) => item.profileId === String(consumerProfile.id));
  assert.ok(listedProfile);
  assert.equal(listedProfile.city, 'Pune');

  const filteredProfiles = await request(
    `/api/admin/v1/profiles?search=${encodeURIComponent(consumer.name)}&profileStatus=complete&verificationStatus=pending&hasPhotos=true&registeredFrom=2020-01-01&registeredTo=2099-01-01&updatedFrom=2020-01-01&updatedTo=2099-01-01&sortBy=displayName&sortDirection=asc&page=1&pageSize=20`,
    { accessToken: adminToken },
  );
  assert.equal(filteredProfiles.status, 200);
  assert.ok(filteredProfiles.body.data.items.some((item) => item.profileId === String(consumerProfile.id)));
  const unsupportedProfileFilter = await request('/api/admin/v1/profiles?completionFrom=50&page=1&pageSize=20', {
    accessToken: adminToken,
  });
  assert.equal(unsupportedProfileFilter.status, 422);
  assert.equal(unsupportedProfileFilter.body.code, 'UNSUPPORTED_QUERY_PARAMETER');
  const unsupportedProfileSort = await request('/api/admin/v1/profiles?sortBy=photoCount&page=1&pageSize=20', {
    accessToken: adminToken,
  });
  assert.equal(unsupportedProfileSort.status, 400);
  const notSubmittedProfiles = await request('/api/admin/v1/profiles?verificationStatus=not_submitted&page=1&pageSize=20', {
    accessToken: adminToken,
  });
  assert.equal(notSubmittedProfiles.status, 200);
  assert.equal(
    notSubmittedProfiles.body.data.items.some((item) => item.profileId === String(consumerProfile.id)),
    false,
  );

  const profileDetails = await request(`/api/admin/v1/profiles/${consumerProfile.id}`, { accessToken: adminToken });
  assert.equal(profileDetails.status, 200);
  assert.equal(profileDetails.body.data.about, 'A real integration profile persisted in the isolated test database.');
  assert.equal(profileDetails.body.data.photos.length, 1);

  const educationTaxonomy = await request('/api/admin/v1/profiles/options/education', { accessToken: adminToken });
  assert.equal(educationTaxonomy.status, 200);
  assert.equal(educationTaxonomy.body.data.category, 'education');
  assert.ok(educationTaxonomy.body.data.items.some((item) => item.label === 'Bachelor of Technology'));
  const otherEducation = educationTaxonomy.body.data.items.find((item) => item.allowsCustomValue);
  assert.ok(otherEducation);
  const languageTaxonomy = await request('/api/admin/v1/profiles/options/languages', { accessToken: adminToken });
  const interestTaxonomy = await request('/api/admin/v1/profiles/options/interests', { accessToken: adminToken });
  assert.equal(languageTaxonomy.status, 200);
  assert.equal(languageTaxonomy.body.data.maximumSelections, 10);
  const englishId = languageTaxonomy.body.data.items.find((item) => item.label === 'English').id;
  const hindiId = languageTaxonomy.body.data.items.find((item) => item.label === 'Hindi').id;
  const musicId = interestTaxonomy.body.data.items.find((item) => item.label === 'music').id;

  const crossCategoryTaxonomyUpdate = await request(`/api/admin/v1/profiles/${consumerProfile.id}`, {
    method: 'PATCH', accessToken: adminToken, body: { education: { optionId: englishId } },
  });
  assert.equal(crossCategoryTaxonomyUpdate.status, 422);

  const updatedBio = 'This profile bio was committed by an authorized administrator integration test.';
  const profileUpdate = await request(`/api/admin/v1/profiles/${consumerProfile.id}`, {
    method: 'PATCH',
    accessToken: adminToken,
    headers: { 'if-match': profileDetails.body.data.version },
    body: {
      about: updatedBio,
      city: 'Bengaluru',
      education: { optionId: otherEducation.id, customValue: 'Doctorate' },
      languageIds: [englishId, hindiId],
      interestIds: [musicId],
    },
  });
  assert.equal(profileUpdate.status, 200);
  assert.equal(profileUpdate.body.data.about, updatedBio);
  assert.equal(profileUpdate.body.data.education.label, 'Doctorate');
  assert.deepEqual(profileUpdate.body.data.languages.map((item) => item.label), ['English', 'Hindi']);
  await consumerProfile.reload();
  assert.equal(consumerProfile.education, 'Doctorate');
  assert.deepEqual(consumerProfile.languages, ['English', 'Hindi']);
  assert.deepEqual(consumerProfile.interests, ['music']);
  const refreshedEducationTaxonomy = await request('/api/admin/v1/profiles/options/education', { accessToken: adminToken });
  assert.ok(refreshedEducationTaxonomy.body.data.items.some((item) => item.label === 'Doctorate'));
  const clientProfile = await request('/api/me/profile', { accessToken: originalClientToken });
  assert.equal(clientProfile.status, 200);
  assert.equal(clientProfile.body.data.profile.bio, updatedBio);
  assert.equal(clientProfile.body.data.profile.location, 'Bengaluru');

  const photoId = profileUpdate.body.data.photos[0].photoId;
  const primary = await request(`/api/admin/v1/profiles/${consumerProfile.id}/photos/${photoId}`, {
    method: 'PATCH',
    accessToken: adminToken,
    body: { isPrimary: true },
  });
  assert.equal(primary.status, 200);
  const reordered = await request(`/api/admin/v1/profiles/${consumerProfile.id}/photos/reorder`, {
    method: 'PATCH',
    accessToken: adminToken,
    body: { photoIds: [photoId] },
  });
  assert.equal(reordered.status, 200);
  const profileAudit = await request(`/api/admin/v1/profiles/${consumerProfile.id}/audit-history`, {
    accessToken: adminToken,
  });
  assert.equal(profileAudit.status, 200);
  assert.ok(profileAudit.body.data.items.some((item) => item.actionType === 'admin.profiles.update'));

  const likes = await request(`/api/admin/v1/matching/actions?type=like&search=${encodeURIComponent(matchingPeer.name)}&page=1&pageSize=20&sortBy=createdAt&sortDirection=desc&includeFailureDetails=false`, { accessToken: adminToken });
  assert.equal(likes.status, 200);
  assert.equal(likes.body.data.items.length, 1);
  assert.equal(likes.body.data.items[0].actionType, 'like');
  assert.equal(likes.body.data.items[0].result, 'matched');
  const likeDetails = await request(`/api/admin/v1/matching/actions/${likes.body.data.items[0].actionId}`, { accessToken: adminToken });
  assert.equal(likeDetails.status, 200);
  assert.equal(likeDetails.body.data.sender.userId, String(consumer.id));
  const superLikes = await request('/api/admin/v1/matching/actions?type=super_like&page=1&pageSize=20&sortBy=createdAt&sortDirection=desc&includeFailureDetails=true', { accessToken: adminToken });
  assert.equal(superLikes.status, 200);
  assert.ok(superLikes.body.data.items.some((item) => item.sender.userId === String(matchingPeer.id)));
  const roses = await request('/api/admin/v1/matching/actions?type=rose&status=sent&page=1&pageSize=20&sortBy=createdAt&sortDirection=desc&includeFailureDetails=false', { accessToken: adminToken });
  assert.equal(roses.status, 200);
  assert.ok(roses.body.data.items.some((item) => item.target.userId === String(matchingPeer.id)));
  const retiredGiftActions = await request('/api/admin/v1/matching/actions?type=gift&page=1&pageSize=20', { accessToken: adminToken });
  assert.equal(retiredGiftActions.status, 400);
  const matches = await request(`/api/admin/v1/matches?search=${encodeURIComponent(matchingPeer.name)}&conversationCreated=true&sortBy=aiScore&sortDirection=desc&page=1&pageSize=20`, { accessToken: adminToken });
  assert.equal(matches.status, 200);
  const matchingRow = matches.body.data.items.find((item) => item.userB.userId === String(matchingPeer.id) || item.userA.userId === String(matchingPeer.id));
  assert.ok(matchingRow);
  assert.equal(matchingRow.conversationExists, true);
  const matchDetails = await request(`/api/admin/v1/matches/${matchingRow.matchId}`, { accessToken: adminToken });
  assert.equal(matchDetails.status, 200);
  assert.equal(matchDetails.body.data.mutualActionIds.length, 2);
  const score = await request(`/api/admin/v1/matches/${matchingRow.matchId}/ai-score?includeExplanation=true`, { accessToken: adminToken });
  assert.equal(score.status, 200);
  assert.equal(score.body.data.scaleMinimum, 0);
  assert.equal(score.body.data.scaleMaximum, 100);
  assert.ok(score.body.data.factors.length > 0);
  const matchHistory = await request(`/api/admin/v1/matches/${matchingRow.matchId}/history`, { accessToken: adminToken });
  assert.equal(matchHistory.status, 200);
  assert.ok(matchHistory.body.data.items.some((item) => item.action === 'admin.matching.ai_score_viewed'));
  const failedLike = await request('/api/discover/swipe', {
    method: 'POST', accessToken: originalClientToken, body: { targetUserId: consumer.id, action: 'like' },
  });
  assert.equal(failedLike.status, 400);
  const failedActions = await request('/api/admin/v1/matching/actions?type=like&status=failed&failureCode=self_action_not_allowed&page=1&pageSize=20&sortBy=createdAt&sortDirection=desc&includeFailureDetails=true', { accessToken: adminToken });
  assert.equal(failedActions.status, 200);
  assert.ok(failedActions.body.data.items.some((item) => item.failure.safeCode === 'SELF_ACTION_NOT_ALLOWED'));
  const failedActionDetails = await request(`/api/admin/v1/matching/actions/${failedActions.body.data.items[0].actionId}?includeFailureDetails=true`, { accessToken: adminToken });
  assert.equal(failedActionDetails.status, 200);
  assert.equal(failedActionDetails.body.data.status, 'failed');

  const discoverSettings = await request('/api/admin/v1/discover/settings', { accessToken: adminToken });
  assert.equal(discoverSettings.status, 200);
  const originalMinimumScore = discoverSettings.body.data.settings.find((item) => item.key === 'default_minimum_score').value;
  const updatedDiscoverSettings = await request('/api/admin/v1/discover/settings', {
    method: 'PATCH', accessToken: adminToken,
    headers: { 'if-match': discoverSettings.body.data.version },
    body: { expectedVersion: discoverSettings.body.data.version, values: { default_minimum_score: 7 } },
  });
  assert.equal(updatedDiscoverSettings.status, 200);
  assert.equal(updatedDiscoverSettings.body.data.settings.find((item) => item.key === 'default_minimum_score').value, 7);
  const staleDiscoverSettings = await request('/api/admin/v1/discover/settings', {
    method: 'PATCH', accessToken: adminToken,
    headers: { 'if-match': discoverSettings.body.data.version },
    body: { expectedVersion: discoverSettings.body.data.version, values: { default_minimum_score: 8 } },
  });
  assert.equal(staleDiscoverSettings.status, 409);
  const peerToken = jwt.sign({ sub: String(matchingPeer.id), ver: matchingPeer.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '5m' });
  const peerDefaults = await request('/api/discover/filters', { accessToken: peerToken });
  assert.equal(peerDefaults.status, 200);
  assert.equal(peerDefaults.body.data.filters.minScore, 7);

  const discoverFilters = await request('/api/admin/v1/discover/filter-configuration?includeSensitive=true', { accessToken: adminToken });
  assert.equal(discoverFilters.status, 200);
  const cityFilter = discoverFilters.body.data.filters.find((item) => item.id === 'city');
  assert.ok(cityFilter);
  const disabledCity = await request('/api/admin/v1/discover/filter-configuration/city', {
    method: 'PATCH', accessToken: adminToken,
    headers: { 'if-match': discoverFilters.body.data.version, 'x-field-version': cityFilter.version },
    body: { enabled: false },
  });
  assert.equal(disabledCity.status, 200);
  const ignoredDisabledFilter = await request('/api/discover/filters', { method: 'PUT', accessToken: peerToken, body: { city: 'Not-a-real-city' } });
  assert.equal(ignoredDisabledFilter.status, 200);
  assert.equal(ignoredDisabledFilter.body.data.filters.city, '');
  const disabledCityRow = disabledCity.body.data.filters.find((item) => item.id === 'city');
  const restoredCity = await request('/api/admin/v1/discover/filter-configuration/city', {
    method: 'PATCH', accessToken: adminToken,
    headers: { 'if-match': disabledCity.body.data.version, 'x-field-version': disabledCityRow.version },
    body: { enabled: true },
  });
  assert.equal(restoredCity.status, 200);
  const restoredSettings = await request('/api/admin/v1/discover/settings', {
    method: 'PATCH', accessToken: adminToken,
    headers: { 'if-match': updatedDiscoverSettings.body.data.version },
    body: { expectedVersion: updatedDiscoverSettings.body.data.version, values: { default_minimum_score: originalMinimumScore } },
  });
  assert.equal(restoredSettings.status, 200);

  const verificationList = await request('/api/admin/v1/verifications?status=pending&page=1&pageSize=20', {
    accessToken: adminToken,
  });
  assert.equal(verificationList.status, 200);
  assert.ok(verificationList.body.data.items.some((item) => item.verificationId === String(verification.id)));
  const verificationDetails = await request(`/api/admin/v1/verifications/${verification.id}`, {
    accessToken: adminToken,
  });
  assert.equal(verificationDetails.status, 200);
  assert.deepEqual(verificationDetails.body.data.summary.allowedActions, ['approve']);
  assert.equal(verificationDetails.body.data.evidenceReadyForDecision, true);
  assert.equal(verificationDetails.body.data.aadhaarStoragePath, undefined);
  assert.equal(verificationDetails.body.data.evidence.length, 2);
  const mediaResponse = await fetch(`${baseUrl}/api/admin/v1/media/${verificationDetails.body.data.evidence[0].mediaId}`, {
    headers: { authorization: `Bearer ${adminToken}` },
  });
  assert.equal(mediaResponse.status, 200);
  assert.equal(mediaResponse.headers.get('cache-control'), 'no-store, private, max-age=0');
  assert.deepEqual(Buffer.from(await mediaResponse.arrayBuffer()), Buffer.from('89504e470d0a1a0a0000000d49484452', 'hex'));
  const decisionKey = crypto.randomUUID();
  const approved = await request(`/api/admin/v1/verifications/${verification.id}/approve`, {
    method: 'POST',
    accessToken: adminToken,
    headers: {
      'idempotency-key': decisionKey,
      'if-match': verificationDetails.body.data.summary.reviewVersion,
    },
    body: { expectedVersion: verificationDetails.body.data.summary.reviewVersion, idempotencyKey: decisionKey },
  });
  assert.equal(approved.status, 200);
  assert.equal(approved.body.data.summary.status, 'approved');
  await verification.reload();
  await consumer.reload();
  assert.equal(verification.status, 'verified');
  assert.equal(String(verification.reviewerAdministratorId), String(administrator.id));
  assert.ok(consumer.identityVerifiedAt);
  const clientVerification = await request('/api/identity-verification/me', { accessToken: originalClientToken });
  assert.equal(clientVerification.status, 200);
  assert.equal(clientVerification.body.data.verification.status, 'verified');
  const verificationHistory = await request(`/api/admin/v1/verifications/${verification.id}/history`, {
    accessToken: adminToken,
  });
  assert.equal(verificationHistory.status, 200);
  assert.equal(verificationHistory.body.data.items[0].action, 'approve');
  assert.equal(verificationHistory.body.data.items[0].actorName, administrator.name);

  const deactivated = await request(`/api/admin/v1/users/${consumer.id}/deactivate`, {
    method: 'POST',
    accessToken: adminToken,
    body: { reason: 'Integration lifecycle verification' },
  });
  assert.equal(deactivated.status, 200);
  assert.equal(deactivated.body.data.user.status, 'deactivated');
  await consumer.reload();
  assert.equal(consumer.accountStatus, 'deactivated');
  const revokedClient = await request('/api/auth/me', { accessToken: originalClientToken });
  assert.equal(revokedClient.status, 401);

  const activated = await request(`/api/admin/v1/users/${consumer.id}/activate`, {
    method: 'POST',
    accessToken: adminToken,
  });
  assert.equal(activated.status, 200);
  assert.equal(activated.body.data.user.status, 'active');
  await consumer.reload();
  const currentClientToken = jwt.sign({ sub: String(consumer.id), ver: consumer.tokenVersion }, process.env.JWT_SECRET, { expiresIn: '5m' });
  const clientAfter = await request('/api/auth/me', { accessToken: currentClientToken });
  assert.equal(clientAfter.status, 200);
  assert.equal(clientAfter.body.data.user.accountStatus, 'active');

  const { RefreshToken } = getModels();
  await RefreshToken.create({
    userId: consumer.id,
    tokenSelector: crypto.randomBytes(16).toString('hex'),
    tokenHash: await bcrypt.hash('integration-refresh-token', 4),
    expiresAt: new Date(Date.now() + 60_000),
    createdByIp: '127.0.0.1',
  });
  const forced = await request(`/api/admin/v1/users/${consumer.id}/force-logout`, {
    method: 'POST',
    accessToken: adminToken,
  });
  assert.equal(forced.status, 200);
  assert.equal(forced.body.data.revokedSessions, 1);
  assert.equal(await RefreshToken.count({ where: { userId: consumer.id } }), 0);
  const afterForceLogout = await request('/api/auth/me', { accessToken: currentClientToken });
  assert.equal(afterForceLogout.status, 401);

  const enrollment = await request('/api/admin/v1/auth/mfa/enroll', {
    method: 'POST', accessToken: adminToken,
  });
  assert.equal(enrollment.status, 201);
  const confirmed = await request('/api/admin/v1/auth/mfa/confirm', {
    method: 'POST',
    accessToken: adminToken,
    body: { code: adminMfaService.totpFor(enrollment.body.data.secret, Math.floor(Date.now() / 30000)) },
  });
  assert.equal(confirmed.status, 200);
  const stepUp = await request('/api/admin/v1/auth/mfa/step-up', {
    method: 'POST',
    accessToken: adminToken,
    body: { recoveryCode: confirmed.body.data.recoveryCodes[0] },
  });
  assert.equal(stepUp.status, 200);

  const reset = await request(`/api/admin/v1/users/${consumer.id}/reset-password`, {
    method: 'POST', accessToken: adminToken,
  });
  assert.equal(reset.status, 200);
  const deleted = await request(`/api/admin/v1/users/${consumer.id}`, {
    method: 'DELETE',
    accessToken: adminToken,
    body: { reason: 'privacy_concerns' },
  });
  assert.equal(deleted.status, 200);
  await consumer.reload();
  assert.equal(consumer.accountStatus, 'deleted');
  assert.equal(consumer.passwordHash, null);
  assert.match(consumer.email, /@deleted\.amora\.invalid$/);
});
