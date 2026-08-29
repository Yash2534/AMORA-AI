const fs = require('fs');
const path = require('path');
const { Op, QueryTypes } = require('sequelize');
const { findSeedUsers } = require('./store');
const { pairKey } = require('./factory');
const { calculateProfileCompletion } = require('../../src/services/profileCompletionService');
const { detectedMimeType, sha256 } = require('./media');

function invariant(condition, message) {
  if (!condition) throw new Error(`Dummy seed validation failed: ${message}`);
}

async function validateDummyData(sequelize, models, config) {
  const { User, OnboardingProfile, DiscoverAction, Match, Conversation, ConversationParticipant, Message,
    RoseTransaction, SavedProfile, Block, DiscoverFilterPreference, NotificationPreference } = models;
  const users = await findSeedUsers(User, config);
  invariant(users.length === config.userCount, `expected ${config.userCount} seed users, found ${users.length}`);
  const userIds = users.map((user) => user.id);
  const profiles = await OnboardingProfile.findAll({ where: { userId: { [Op.in]: userIds } } });
  invariant(profiles.length === users.length, 'every seed user must have one profile');
  const completed = profiles.filter((profile) => profile.onboardingCompleted);
  invariant(completed.length >= users.length - 2, 'only the deliberate edge profile may be incomplete');
  const imageOwners = new Map();
  const imageHashes = new Map();
  for (const profile of profiles) {
    invariant(Array.isArray(profile.photos) && profile.photos.length === 2, `profile ${profile.id} must have exactly two demo photos`);
    invariant(Number(profile.primaryPhotoIndex) === 0, `profile ${profile.id} must have primaryPhotoIndex 0`);
    for (const [photoIndex, photo] of profile.photos.entries()) {
      invariant(photo.startsWith(`/uploads/onboarding-photos/${config.mediaPrefix}`), `profile ${profile.id} has an unexpected demo media URL`);
      const file = path.join(path.resolve(config.uploadsDirectory, '..', '..'), photo.replace(/^\//, ''));
      invariant(fs.existsSync(file), `missing media file ${photo}`);
      const bytes = fs.readFileSync(file);
      invariant(Boolean(detectedMimeType(bytes)), `unsupported or unreadable media file ${photo}`);
      const previousOwner = imageOwners.get(photo);
      invariant(!previousOwner, `photo ${photo} is assigned to profiles ${previousOwner?.profileId} and ${profile.id}`);
      imageOwners.set(photo, { profileId: profile.id, userId: profile.userId, photoIndex });
      const hash = sha256(bytes);
      const previousHash = imageHashes.get(hash);
      invariant(!previousHash, `duplicate image hash ${hash}: ${previousHash?.photo} and ${photo}`);
      imageHashes.set(hash, { photo, profileId: profile.id, userId: profile.userId, photoIndex });
    }
  }
  invariant(imageOwners.size === users.length * 2, 'each seed user must own two unique image files');
  invariant(imageHashes.size === imageOwners.size, 'every seeded image must have a unique SHA-256 hash');
  for (const profile of completed) {
    invariant(profile.birthDate && profile.gender && profile.city && profile.profession && profile.education, `profile ${profile.id} is missing onboarding data`);
    invariant(Array.isArray(profile.interestedIn) && profile.interestedIn.length > 0, `profile ${profile.id} has no dating preference`);
    invariant(Array.isArray(profile.relationshipGoals) && profile.relationshipGoals.length > 0, `profile ${profile.id} has no relationship goal`);
    invariant(Array.isArray(profile.interests) && profile.interests.length >= 5 && profile.interests.length <= 10, `profile ${profile.id} has an invalid interest count`);
  }

  const [actions, matches, conversations, participants, messages, roses, savedProfiles, blocks, filters, notificationPreferences] = await Promise.all([
    DiscoverAction.findAll({ where: { actorUserId: { [Op.in]: userIds }, targetUserId: { [Op.in]: userIds } } }),
    Match.findAll({ where: { userOneId: { [Op.in]: userIds }, userTwoId: { [Op.in]: userIds } } }),
    Conversation.findAll(), ConversationParticipant.findAll({ where: { userId: { [Op.in]: userIds } } }),
    Message.findAll({ where: { senderId: { [Op.in]: userIds } } }),
    RoseTransaction.findAll({ where: { senderId: { [Op.in]: userIds } } }), SavedProfile.findAll({ where: { userId: { [Op.in]: userIds } } }),
    Block.findAll({ where: { blockerUserId: { [Op.in]: userIds } } }), DiscoverFilterPreference.findAll({ where: { userId: { [Op.in]: userIds } } }),
    NotificationPreference.findAll({ where: { userId: { [Op.in]: userIds } } }),
  ]);
  invariant(filters.length === users.length, 'every seed user must have discover preferences');
  invariant(notificationPreferences.length === users.length, 'every seed user must have notification preferences');
  invariant(actions.every((value) => value.actorUserId !== value.targetUserId), 'self discover action found');
  invariant(savedProfiles.every((value) => value.userId !== value.savedUserId), 'self-saved profile found');
  invariant(blocks.every((value) => value.blockerUserId !== value.blockedUserId), 'self block found');
  const actionKeys = new Set(actions.map((value) => `${value.actorUserId}:${value.targetUserId}`));
  invariant(actionKeys.size === actions.length, 'duplicate discover action found');
  const positiveKeys = new Set(actions.filter((value) => value.action !== 'pass').map((value) => `${value.actorUserId}:${value.targetUserId}`));
  for (const match of matches) {
    invariant(match.userOneId < match.userTwoId, `match ${match.id} is not in canonical order`);
    invariant(positiveKeys.has(`${match.userOneId}:${match.userTwoId}`) && positiveKeys.has(`${match.userTwoId}:${match.userOneId}`), `match ${match.id} is not backed by reciprocal positive actions`);
  }
  const conversationPairs = new Map(conversations.map((value) => [value.pairKey, value]));
  for (const match of matches) invariant(conversationPairs.has(pairKey(match.userOneId, match.userTwoId)), `match ${match.id} has no conversation`);
  const participantCounts = new Map();
  for (const participant of participants) participantCounts.set(participant.conversationId, (participantCounts.get(participant.conversationId) || 0) + 1);
  for (const match of matches) {
    const conversation = conversationPairs.get(pairKey(match.userOneId, match.userTwoId));
    invariant(participantCounts.get(conversation.id) === 2, `conversation ${conversation.id} does not have two participants`);
  }
  const participantKeys = new Set(participants.map((value) => `${value.conversationId}:${value.userId}`));
  for (const message of messages) invariant(participantKeys.has(`${message.conversationId}:${message.senderId}`), `message ${message.id} sender is not a participant`);

  const invalidForeignKeys = await sequelize.query(`
    SELECT COUNT(*) AS count FROM DiscoverActions da
      LEFT JOIN Users actor ON actor.id = da.actorUserId LEFT JOIN Users target ON target.id = da.targetUserId
      WHERE actor.id IS NULL OR target.id IS NULL
    UNION ALL SELECT COUNT(*) FROM Matches m LEFT JOIN Users a ON a.id=m.userOneId LEFT JOIN Users b ON b.id=m.userTwoId WHERE a.id IS NULL OR b.id IS NULL
    UNION ALL SELECT COUNT(*) FROM Messages m LEFT JOIN Conversations c ON c.id=m.conversationId LEFT JOIN Users u ON u.id=m.senderId WHERE c.id IS NULL OR u.id IS NULL
    UNION ALL SELECT COUNT(*) FROM RoseTransactions r LEFT JOIN Users a ON a.id=r.senderId LEFT JOIN Users b ON b.id=r.recipientId WHERE a.id IS NULL OR b.id IS NULL
  `, { type: QueryTypes.SELECT });
  invariant(invalidForeignKeys.every((row) => Number(row.count) === 0), 'orphaned foreign key found');

  const byEmail = new Map(users.map((user) => [user.email, user]));
  const demoA = byEmail.get('demo.aisha@seed.amoraa.example.test');
  const demoB = byEmail.get('demo.rohan@seed.amoraa.example.test');
  const demoC = byEmail.get('demo.kavya@seed.amoraa.example.test');
  invariant(demoA && demoB && demoC, 'three demo accounts are required');
  invariant(positiveKeys.has(`${demoB.id}:${demoA.id}`), 'Demo B must like Demo A');
  invariant(!actionKeys.has(`${demoA.id}:${demoB.id}`), 'Demo A must be free to like Demo B during the video');
  invariant(matches.some((match) => pairKey(match.userOneId, match.userTwoId) === pairKey(demoA.id, demoC.id)), 'Demo A and Demo C must have an existing match');
  const demoConversation = conversationPairs.get(pairKey(demoA.id, demoC.id));
  invariant(messages.filter((message) => message.conversationId === demoConversation.id).length >= 50, 'demo conversation must exercise message pagination');
  const profilesByUserId = new Map(profiles.map((profile) => [profile.userId, profile]));
  for (const demo of [demoA, demoB, demoC]) {
    invariant(calculateProfileCompletion(demo, profilesByUserId.get(demo.id)).percentage === 100, `demo profile ${demo.email} must be 100% complete`);
  }
  invariant(roses.some((rose) => rose.senderId === demoC.id && rose.recipientId === demoA.id && rose.conversationId === demoConversation.id), 'Demo C must have sent Demo A a Rose on their existing match');
  invariant(actions.filter((action) => action.targetUserId === demoA.id && action.action !== 'pass').length >= Math.min(40, Math.max(10, users.length - 5)), 'Demo A must have a substantial likes inbox');
  invariant(completed.length > 20 && savedProfiles.length > 40 && messages.length > 40, 'seed volume is insufficient for pagination testing');

  return {
    users: users.length, profiles: profiles.length, completedProfiles: completed.length,
    actions: actions.length, likes: actions.filter((value) => value.action === 'like').length,
    superLikes: actions.filter((value) => value.action === 'superLike').length,
    roses: roses.length, matches: matches.length, conversations: matches.length,
    messages: messages.length, savedProfiles: savedProfiles.length, blocks: blocks.length,
    profileImages: imageOwners.size, uniqueImageHashes: imageHashes.size,
  };
}

module.exports = { validateDummyData };
