require('../src/config/bootstrapEnv');
const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { resolveDummySeedConfig } = require('./dummy-seed/config');
const { scoreCompatibility, compatibilityReasons } = require('../src/services/matchEngineService');
const { localAiMatch } = require('../src/services/aiMatchProvider');

const ageAt = (birthDate, reference) => { const birth = new Date(`${birthDate}T00:00:00.000Z`); let age = reference.getUTCFullYear() - birth.getUTCFullYear(); if (reference.getUTCMonth() < birth.getUTCMonth() || (reference.getUTCMonth() === birth.getUTCMonth() && reference.getUTCDate() < birth.getUTCDate())) age -= 1; return age; };
const lowerList = (value) => (Array.isArray(value) ? value : []).map((item) => String(item).toLowerCase());
const accepts = (profile, gender) => { const values = lowerList(profile.interestedIn); const target = String(gender || '').toLowerCase(); return !values.length || values.some((value) => ['everyone', 'all', 'any', 'both', target, target === 'female' ? 'woman' : 'man'].includes(value)); };
const bucket = (score) => score < 50 ? '<50' : score < 60 ? '50-59' : score < 70 ? '60-69' : score < 80 ? '70-79' : score < 90 ? '80-89' : '90-100';
const median = (values) => { const sorted = [...values].sort((a, b) => a - b); return sorted.length ? (sorted[Math.floor((sorted.length - 1) / 2)] + sorted[Math.floor(sorted.length / 2)]) / 2 : null; };

async function run() {
  const config = resolveDummySeedConfig(process.env, [...process.argv.slice(2), '--validate-only']); require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db'); const { getModels } = require('../src/models');
  await initializeDatabase(); const sequelize = getSequelize();
  try {
    const m = getModels();
    const users = await m.User.findAll({ where: { email: { [Op.like]: `%${config.emailSuffix}` } }, include: [{ model: m.OnboardingProfile, required: true }, { model: m.Subscription, as: 'subscription', required: false, include: [{ model: m.SubscriptionPlan, as: 'plan', required: false }] }] });
    const master = users.find((user) => user.email === 'master@seed.amoraa.example.test'); const viewer = master.OnboardingProfile;
    const seedIds = users.map((user) => user.id);
    const [filters, allActions, allMatches, allBlocks, saved, allRoses, conversations, allMessages, notifications, reports, consents, verifications, allSaved, allNotifications] = await Promise.all([
      m.DiscoverFilterPreference.findOne({ where: { userId: master.id } }), m.DiscoverAction.findAll({ where: { actorUserId: { [Op.in]: seedIds }, targetUserId: { [Op.in]: seedIds } } }),
      m.Match.findAll({ where: { userOneId: { [Op.in]: seedIds }, userTwoId: { [Op.in]: seedIds } } }), m.Block.findAll({ where: { blockerUserId: { [Op.in]: seedIds }, blockedUserId: { [Op.in]: seedIds } } }),
      m.SavedProfile.findAll({ where: { userId: master.id } }), m.RoseTransaction.findAll({ where: { senderId: { [Op.in]: seedIds }, recipientId: { [Op.in]: seedIds } } }),
      m.ConversationParticipant.findAll({ where: { userId: master.id } }), m.Message.findAll(), m.Notification.findAll({ where: { userId: master.id } }),
      m.Report.findAll({ where: { [Op.or]: [{ reporterUserId: { [Op.in]: users.map((u) => u.id) } }, { reportedUserId: { [Op.in]: users.map((u) => u.id) } }] } }),
      m.ConsentEvent.findAll({ where: { userId: { [Op.in]: users.map((u) => u.id) } } }), m.IdentityVerification.findAll({ where: { userId: { [Op.in]: users.map((u) => u.id) } } }),
      m.SavedProfile.findAll({ where: { userId: { [Op.in]: seedIds }, savedUserId: { [Op.in]: seedIds } } }), m.Notification.findAll({ where: { userId: { [Op.in]: seedIds } } }),
    ]);
    const actions = allActions.filter((row) => row.actorUserId === master.id || row.targetUserId === master.id);
    const matches = allMatches.filter((row) => row.userOneId === master.id || row.userTwoId === master.id);
    const blocks = allBlocks.filter((row) => row.blockerUserId === master.id || row.blockedUserId === master.id);
    const roses = allRoses.filter((row) => row.senderId === master.id || row.recipientId === master.id);
    const actedIds = new Set(actions.filter((row) => row.actorUserId === master.id).map((row) => row.targetUserId));
    const matchedIds = new Set(matches.map((row) => row.userOneId === master.id ? row.userTwoId : row.userOneId));
    const blockedIds = new Set(blocks.map((row) => row.blockerUserId === master.id ? row.blockedUserId : row.blockerUserId));
    const exclusions = {}; const eligible = [];
    for (const user of users) {
      if (user.id === master.id) continue; const profile = user.OnboardingProfile; let reason = null; const age = ageAt(profile.birthDate, config.referenceDate);
      if (user.accountStatus !== 'active') reason = 'inactive_account';
      else if (!profile.onboardingCompleted || profile.stage !== 'complete') reason = 'incomplete_profile';
      else if (age < filters.minAge || age > filters.maxAge) reason = 'age_range_mismatch';
      else if (!accepts(viewer, profile.gender)) reason = 'viewer_gender_preference';
      else if (!accepts(profile, viewer.gender)) reason = 'reciprocal_preference_mismatch';
      else if (blockedIds.has(user.id)) reason = 'block';
      else if (actedIds.has(user.id)) reason = 'previous_action';
      else if (matchedIds.has(user.id)) reason = 'existing_match';
      if (reason) exclusions[reason] = (exclusions[reason] || 0) + 1;
      else {
        const compatibility = scoreCompatibility(viewer, profile);
        const ai = localAiMatch(viewer, profile, compatibility);
        eligible.push({ userId: user.id, name: user.name, age, compatibility: compatibility.score, coverage: compatibility.coverage, reasons: compatibilityReasons(viewer, profile), aiConfidence: ai.aiConfidence, aiMatchScore: ai.aiMatchScore, aiReasons: ai.aiReasons });
      }
    }
    eligible.sort((a, b) => b.compatibility - a.compatibility || a.userId - b.userId); const scores = eligible.map((row) => row.compatibility); const distribution = { '<50': 0, '50-59': 0, '60-69': 0, '70-79': 0, '80-89': 0, '90-100': 0 }; for (const score of scores) distribution[bucket(score)] += 1;
    const aiRanking = [...eligible].sort((a, b) => b.aiMatchScore - a.aiMatchScore || b.aiConfidence - a.aiConfidence || a.userId - b.userId);
    const profiles = users.map((user) => ({ user: user.name, age: ageAt(user.OnboardingProfile.birthDate, config.referenceDate), genderPresentation: user.OnboardingProfile.gender, primaryImage: user.OnboardingProfile.photos[0], additionalImages: user.OnboardingProfile.photos.slice(1), imageSourceType: 'synthetic/generated/local development asset', localPaths: user.OnboardingProfile.photos.map((photo) => path.resolve(config.uploadsDirectory, path.basename(photo))), ageAppearanceAppropriate: true }));
    const conversationIds = new Set(conversations.map((row) => row.conversationId));
    const masterMessages = allMessages.filter((row) => conversationIds.has(row.conversationId));
    const unreadConversations = conversations.filter((participant) => masterMessages.some((message) => message.conversationId === participant.conversationId && message.senderId !== master.id && message.id > Number(participant.lastReadMessageId || 0) && !message.deletedAt)).length;
    const datasetMessages = allMessages.filter((message) => seedIds.includes(message.senderId));
    const report = { generatedAt: new Date().toISOString(), provider: 'LOCAL', master: { email: master.email, name: master.name, age: ageAt(viewer.birthDate, config.referenceDate), completion: 100, accountStatus: master.accountStatus, onboarding: viewer.onboardingCompleted, premium: master.subscription?.status === 'active', premiumPlan: master.subscription?.plan?.displayName || master.subscription?.plan?.name || null, verified: Boolean(master.identityVerifiedAt), existingMatches: matches.length, conversations: conversations.length, unreadConversations, notifications: notifications.length }, dataset: { users: users.length, completeProfiles: users.filter((u) => u.OnboardingProfile.onboardingCompleted).length, incompleteProfiles: users.filter((u) => !u.OnboardingProfile.onboardingCompleted).length, profileImages: users.reduce((n, u) => n + u.OnboardingProfile.photos.length, 0), verified: verifications.filter((v) => v.status === 'verified').length, premium: users.filter((u) => u.subscription?.status === 'active').length, legalConsentEvents: consents.length }, discover: { eligible: eligible.length, excluded: users.length - 1 - eligible.length, exclusionReasons: exclusions, paginationPagesAt10: Math.ceil(eligible.length / 10) }, matchEngine: { distribution, minimum: Math.min(...scores), average: Number((scores.reduce((a, b) => a + b, 0) / scores.length).toFixed(2)), median: median(scores), maximum: Math.max(...scores), candidates: eligible }, aiMatches: { provider: 'LOCAL', candidates: aiRanking.length, returned: aiRanking.length, paginationPagesAt10: Math.ceil(aiRanking.length / 10), ranking: aiRanking }, masterData: { likes: actions.filter((row) => row.action === 'like').length, superLikes: actions.filter((row) => row.action === 'superLike').length, saved: saved.length, roses: roses.length, matches: matches.length, conversations: conversations.length, messages: masterMessages.length, notifications: notifications.length, blocks: blocks.length }, otherData: { likes: allActions.filter((row) => row.action === 'like').length, superLikes: allActions.filter((row) => row.action === 'superLike').length, saved: allSaved.length, roses: allRoses.length, matches: allMatches.length, conversations: allMatches.length, messages: datasetMessages.length, notifications: allNotifications.length, blocks: allBlocks.length, reports: reports.length }, images: profiles };
    const jsonPath = path.resolve(__dirname, '../tmp/amoraa-v2-seed-report.json'); fs.mkdirSync(path.dirname(jsonPath), { recursive: true }); fs.writeFileSync(jsonPath, `${JSON.stringify(report, null, 2)}\n`);
    console.log(`[DummySeedReport] ${JSON.stringify({ eligible: report.discover.eligible, excluded: report.discover.excluded, distribution, min: report.matchEngine.minimum, median: report.matchEngine.median, average: report.matchEngine.average, max: report.matchEngine.maximum, aiCandidates: report.aiMatches.candidates, jsonPath })}`);
    return report;
  } finally { await sequelize.close(); }
}

if (require.main === module) run().catch((error) => { console.error(`[DummySeedReport] ${error.stack || error.message}`); process.exitCode = 1; });
module.exports = { run };
