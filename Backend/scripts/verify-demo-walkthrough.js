require('../src/config/bootstrapEnv');

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const { resolveDummySeedConfig } = require('./dummy-seed/config');
const { calculateProfileCompletion } = require('../src/services/profileCompletionService');

async function run() {
  const config = resolveDummySeedConfig();
  require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db');
  const { getModels } = require('../src/models');
  const { app } = require('../src/server');
  await initializeDatabase();
  const models = getModels();
  const server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const baseUrl = `http://127.0.0.1:${server.address().port}`;
  const request = async (url, { token, method = 'GET', body } = {}) => {
    const response = await fetch(`${baseUrl}${url}`, {
      method,
      headers: {
        ...(token ? { authorization: `Bearer ${token}` } : {}),
        ...(body ? { 'content-type': 'application/json' } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    const payload = await response.json();
    if (!response.ok) throw new Error(`${method} ${url} returned ${response.status}: ${JSON.stringify(payload)}`);
    return payload;
  };

  try {
    const login = await request('/api/auth/login', {
      method: 'POST',
      body: { email: config.demoEmail, password: config.password },
    });
    const token = login.data.accessToken;
    const [profileResponse, discover, ai, matchesResponse, conversationsResponse, incomingResponse,
      outgoingResponse, superResponse, savedResponse, notificationsResponse] = await Promise.all([
      request('/api/me/profile', { token }),
      request('/api/discover/feed?limit=10', { token }),
      request('/api/discover/ai-matches?limit=10', { token }),
      request('/api/matches', { token }),
      request('/api/conversations?limit=20', { token }),
      request('/api/me/received-likes?limit=30', { token }),
      request('/api/me/likes?limit=30', { token }),
      request('/api/me/super-likes?limit=30', { token }),
      request('/api/me/saved-profiles?limit=30', { token }),
      request('/api/notifications?limit=50', { token }),
    ]);
    const demo = await models.User.findOne({ where: { email: config.demoEmail } });
    const storedProfile = await models.OnboardingProfile.findOne({ where: { userId: demo.id } });
    const conversations = conversationsResponse.data.conversations || [];
    const messagePages = await Promise.all(conversations.map((conversation) => request(`/api/conversations/${conversation.id}/messages?limit=100`, { token })));
    const userIds = (await models.User.findAll({ where: { [Op.or]: [{ email: config.demoEmail }, { email: { [Op.like]: `%${config.emailSuffix}` } }] }, attributes: ['id'] })).map((row) => row.id);
    const [passes, roses, dbMatches, dbConversations, dbMessages, unreadParticipants] = await Promise.all([
      models.DiscoverAction.count({ where: { actorUserId: demo.id, action: 'pass' } }),
      models.RoseTransaction.count({ where: { [Op.or]: [{ senderId: demo.id }, { recipientId: demo.id }], status: 'sent' } }),
      models.Match.count({ where: { [Op.or]: [{ userOneId: demo.id }, { userTwoId: demo.id }] } }),
      models.ConversationParticipant.count({ where: { userId: demo.id } }),
      models.Message.count({ where: { conversationId: { [Op.in]: conversations.map((row) => Number(row.id)) } } }),
      models.ConversationParticipant.count({ where: { userId: demo.id, lastReadMessageId: { [Op.ne]: null } } }),
    ]);
    const media = [];
    for (const userId of userIds) {
      const value = await models.OnboardingProfile.findOne({ where: { userId }, attributes: ['photos'] });
      for (const photo of value?.photos || []) {
        const response = await fetch(`${baseUrl}${photo}`);
        media.push({ photo, ok: response.ok, contentType: response.headers.get('content-type') || '' });
      }
    }
    const discoverProfiles = discover.data.profiles || [];
    const aiRecommendations = ai.data.recommendations || [];
    const scoreValues = discoverProfiles.map((item) => Number(item.compatibilityScore)).filter(Number.isFinite);
    const aiScores = aiRecommendations.map((item) => Number(item.aiMatchScore)).filter(Number.isFinite);
    const aiConfidence = aiRecommendations.map((item) => Number(item.aiConfidence)).filter(Number.isFinite);
    const notificationRows = notificationsResponse.data.notifications || [];
    const report = {
      userId: String(demo.id),
      accountStatus: demo.accountStatus,
      login: await bcrypt.compare(config.password, demo.passwordHash || ''),
      profileCompletion: profileResponse.data.profile.profileCompletion.percentage,
      canonicalProfileCompletion: calculateProfileCompletion(demo, storedProfile).percentage,
      photos: storedProfile.photos.length,
      interests: storedProfile.interests.length,
      prompts: Object.keys(storedProfile.prompts).length,
      discover: {
        count: discoverProfiles.length,
        profiles: discoverProfiles.map((item) => ({ id: item.id, name: item.name, compatibilityScore: item.compatibilityScore, distanceKm: item.distanceKm })),
        scoreRange: scoreValues.length ? [Math.min(...scoreValues), Math.max(...scoreValues)] : [],
        coordinatesLeaked: /matchLatitude|matchLongitude/.test(JSON.stringify(discoverProfiles)),
      },
      aiMatches: {
        count: aiRecommendations.length,
        scoreRange: aiScores.length ? [Math.min(...aiScores), Math.max(...aiScores)] : [],
        confidenceRange: aiConfidence.length ? [Math.min(...aiConfidence), Math.max(...aiConfidence)] : [],
        reasonsValid: aiRecommendations.every((item) => Array.isArray(item.aiReasons) && item.aiReasons.length > 0),
        provider: ai.data.provider,
        pagination: ai.data.pagination,
      },
      relationships: {
        incomingLikes: incomingResponse.data.profiles.length,
        outgoingLikes: outgoingResponse.data.profiles.length,
        outgoingSuperLikes: superResponse.data.profiles.length,
        passes,
        saved: savedResponse.data.profiles.length,
        roses,
      },
      matches: { api: matchesResponse.data.matches.length, database: dbMatches },
      chats: {
        conversations: conversations.length,
        databaseParticipants: dbConversations,
        messages: dbMessages,
        apiMessageCounts: messagePages.map((page) => page.data.messages.length),
        participantsWithReadState: unreadParticipants,
      },
      notifications: {
        count: notificationRows.length,
        categories: [...new Set(notificationRows.map((row) => row.category))].sort(),
      },
      media: {
        profilesWithPhotos: userIds.length,
        files: media.length,
        broken: media.filter((item) => !item.ok || !item.contentType.startsWith('image/')).length,
        diskFilesExist: media.every((item) => fs.existsSync(path.join(path.resolve(config.uploadsDirectory, '..', '..'), item.photo.replace(/^\//, '')))),
      },
    };
    console.log(`[DemoWalkthroughVerify] ${JSON.stringify(report)}`);
    return report;
  } finally {
    await new Promise((resolve) => server.close(resolve));
    await getSequelize().close();
  }
}

if (require.main === module) run().catch((error) => {
  console.error(`[DemoWalkthroughVerify] ${error.stack || error.message}`);
  process.exitCode = 1;
});

module.exports = { run };
