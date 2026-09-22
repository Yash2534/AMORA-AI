require('../src/config/bootstrapEnv');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { resolveDummySeedConfig } = require('./dummy-seed/config');

async function run() {
  const config = resolveDummySeedConfig(process.env, [...process.argv.slice(2), '--validate-only']); require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db'); const { getModels } = require('../src/models'); const { createHttpServer } = require('../src/server');
  await initializeDatabase(); const sequelize = getSequelize(); let server;
  const api = async (baseUrl, pathname, { method = 'GET', token, body, form } = {}) => { const response = await fetch(`${baseUrl}${pathname}`, { method, headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), ...(body ? { 'content-type': 'application/json' } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}), ...(form ? { body: form } : {}) }); const json = await response.json().catch(() => ({})); if (!response.ok || !json.success) throw new Error(`${method} ${pathname}: ${response.status} ${json.code || json.message}`); return { status: response.status, data: json.data }; };
  try {
    server = createHttpServer(); await new Promise((resolve, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', resolve); }); const baseUrl = `http://127.0.0.1:${server.address().port}`;
    const login = await api(baseUrl, '/api/auth/login', { method: 'POST', body: { email: 'master@seed.amoraa.example.test', password: config.password } }); let token = login.data.accessToken; const refreshToken = login.data.refreshToken; const masterId = Number(login.data.user.id);
    const models = getModels(); const byName = async (name) => models.User.findOne({ where: { name } });
    const [candidateA, candidateB, reciprocal, roseTarget, unreadUser, roseMatchUser] = await Promise.all(['Arjun Desai', 'Rohan Shah', 'Neel Vyas', 'Mihir Joshi', 'Aarav Singh', 'Yash Trivedi'].map(byName));
    const profile = await api(baseUrl, '/api/me/profile', { token }); assert.equal(profile.data.profile.profileCompletion.percentage, 100);
    const feed1 = await api(baseUrl, '/api/discover/feed?page=1&limit=10', { token }); const feed2 = await api(baseUrl, '/api/discover/feed?page=2&limit=10', { token }); assert.ok(feed1.data.profiles.length && feed2.data.profiles.length);
    const ai1 = await api(baseUrl, '/api/discover/ai-matches?page=1&limit=10', { token }); const ai2 = await api(baseUrl, '/api/discover/ai-matches?page=2&limit=10', { token }); assert.equal(ai1.data.provider, 'LOCAL'); assert.ok(ai2.data.recommendations.length);
    await api(baseUrl, '/api/discover/filters', { token }); await api(baseUrl, `/api/profiles/${candidateA.id}`, { token });
    await api(baseUrl, `/api/me/saved-profiles/${candidateA.id}`, { method: 'PUT', token }); await api(baseUrl, `/api/me/saved-profiles/${candidateA.id}`, { method: 'DELETE', token });
    await api(baseUrl, '/api/discover/swipe', { method: 'POST', token, body: { targetUserId: candidateA.id, action: 'superLike' } });
    await api(baseUrl, '/api/roses/send', { method: 'POST', token, body: { recipientId: roseTarget.id, note: 'Development verification Rose.', idempotencyKey: `master-profile-rose-${Date.now()}` } });
    const reciprocalResult = await api(baseUrl, '/api/discover/swipe', { method: 'POST', token, body: { targetUserId: reciprocal.id, action: 'like' } }); assert.equal(reciprocalResult.data.matched, true);
    const reciprocalConversation = await models.Conversation.findOne({ where: { pairKey: [masterId, reciprocal.id].sort((a, b) => a - b).join(':') } }); assert.ok(reciprocalConversation);
    await api(baseUrl, `/api/conversations/${reciprocalConversation.id}/messages`, { method: 'POST', token, body: { text: 'Automated MASTER flow verification message.' } });
    const form = new FormData(); const image = fs.readFileSync(path.resolve(config.portraitAssetsDirectory, 'amoraa-v2-profile-001-02.webp')); form.append('media', new Blob([image], { type: 'image/webp' }), 'master-verification.webp'); form.append('caption', 'Automated image-message verification.');
    await api(baseUrl, `/api/conversations/${reciprocalConversation.id}/media`, { method: 'POST', token, form });
    await api(baseUrl, '/api/roses/send', { method: 'POST', token, body: { recipientId: reciprocal.id, conversationId: reciprocalConversation.id, note: 'Automated matched-chat Rose.', idempotencyKey: `master-chat-rose-${Date.now()}` } });
    const unreadConversation = await models.Conversation.findOne({ where: { pairKey: [masterId, unreadUser.id].sort((a, b) => a - b).join(':') } }); await api(baseUrl, `/api/conversations/${unreadConversation.id}/messages`, { token }); await api(baseUrl, `/api/conversations/${unreadConversation.id}/read`, { method: 'PUT', token, body: {} });
    const roseConversation = await models.Conversation.findOne({ where: { pairKey: [masterId, roseMatchUser.id].sort((a, b) => a - b).join(':') } }); await api(baseUrl, `/api/conversations/${roseConversation.id}/mute`, { method: 'PUT', token, body: {} }); await api(baseUrl, `/api/conversations/${roseConversation.id}/mute`, { method: 'DELETE', token });
    await api(baseUrl, '/api/notifications?page=1&limit=30', { token });
    await api(baseUrl, `/api/blocks/${candidateB.id}`, { method: 'POST', token }); await api(baseUrl, `/api/blocks/${candidateB.id}`, { method: 'DELETE', token });
    await api(baseUrl, '/api/reports', { method: 'POST', token, body: { targetType: 'profile', targetUserId: candidateB.id, reason: 'other', notes: 'Automated development-only report-flow verification.' } });
    await api(baseUrl, '/api/me/profile', { method: 'PUT', token, body: { bio: 'MASTER profile edit verified through the normal API. This text is removed by the final deterministic reseed.' } });
    await api(baseUrl, '/api/auth/logout', { method: 'POST', token, body: { refreshToken } });
    const relogin = await api(baseUrl, '/api/auth/login', { method: 'POST', body: { email: 'master@seed.amoraa.example.test', password: config.password } }); token = relogin.data.accessToken; await api(baseUrl, '/api/auth/me', { token });
    console.log('[MasterFlow] PASS login, profile/edit, discover pagination, filters, LOCAL AI pagination, profile detail, save/unsave, Super Like, profile Rose, reciprocal Match, text/image/Rose chat, unread/read, mute/unmute, notifications, block/unblock, report, logout/login.');
  } finally { if (server) await new Promise((resolve) => server.close(resolve)); await sequelize.close(); }
}

if (require.main === module) run().catch((error) => { console.error(`[MasterFlow] ${error.stack || error.message}`); process.exitCode = 1; });
module.exports = { run };
