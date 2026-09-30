require('../src/config/bootstrapEnv');
const { resolveDummySeedConfig } = require('./dummy-seed/config');

async function request(baseUrl, pathname, token, options = {}) {
  const response = await fetch(`${baseUrl}${pathname}`, {
    ...options,
    headers: { 'content-type': 'application/json', ...(token ? { authorization: `Bearer ${token}` } : {}), ...(options.headers || {}) },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || body.success !== true) throw new Error(`${options.method || 'GET'} ${pathname} failed (${response.status}): ${body.code || body.message || 'unknown error'}`);
  return body.data;
}

async function run() {
  const config = resolveDummySeedConfig(process.env, [...process.argv.slice(2), '--validate-only']);
  require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db');
  const { getModels } = require('../src/models');
  const { validateDummyData } = require('./dummy-seed/validate');
  const { createHttpServer } = require('../src/server');
  await initializeDatabase();
  const sequelize = getSequelize();
  let server;
  try {
    const counts = await validateDummyData(sequelize, getModels(), config);
    server = createHttpServer();
    await new Promise((resolve, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', resolve); });
    const baseUrl = `http://127.0.0.1:${server.address().port}`;
    const health = await request(baseUrl, '/health');
    if (!health) throw new Error('Health response was empty.');
    const login = await request(baseUrl, '/api/auth/login', null, {
      method: 'POST', body: JSON.stringify({ email: config.demoEmail, password: config.password }),
    });
    const token = login.accessToken;
    if (!token) throw new Error('Demo login did not return an access token.');
    const pageOne = await request(baseUrl, '/api/discover/feed?page=1&limit=10&verifiedOnly=false', token);
    const aiOne = await request(baseUrl, '/api/discover/ai-matches?page=1&limit=10', token);
    const receivedOne = await request(baseUrl, '/api/me/received-likes?page=1&limit=30', token);
    const filters = await request(baseUrl, '/api/discover/filters', token);
    const matches = await request(baseUrl, '/api/matches', token);
    const conversations = await request(baseUrl, '/api/conversations?page=1&limit=20', token);
    const candidate = await getModels().User.findOne({ where: { name: 'Aarohi Desai' } });
    await request(baseUrl, `/api/profiles/${candidate.id}`, token);
    const demoConversation = conversations.conversations[0];
    const history = await request(baseUrl, `/api/conversations/${demoConversation.id}/messages?limit=20`, token);
    const listLength = (value) => Array.isArray(value) ? value.length : Array.isArray(value?.items) ? value.items.length : Array.isArray(value?.profiles) ? value.profiles.length : Array.isArray(value?.matches) ? value.matches.length : Array.isArray(value?.conversations) ? value.conversations.length : Array.isArray(value?.messages) ? value.messages.length : 0;
    if (listLength(pageOne) < 5) throw new Error('Discovery did not return a populated walkthrough page.');
    if (listLength(aiOne?.recommendations) < 5) throw new Error('AI Matches did not return a populated walkthrough page.');
    if (listLength(receivedOne) < 1) throw new Error('Received likes did not return a populated page.');
    if (listLength(matches) < 1 || listLength(conversations) < 1 || listLength(history) < 1) throw new Error('Demo match/conversation/message APIs were empty.');
    if (!filters) throw new Error('Discover filters did not load.');
    if (aiOne.provider !== 'LOCAL') throw new Error(`Expected LOCAL AI provider, received ${aiOne.provider}.`);
    console.log('[DummySeed] API verification passed: walkthrough login, Discover, LOCAL AI, profile, filters, likes, matches, conversations, and message history.');
    console.log(`[DummySeed] Validated counts: ${JSON.stringify(counts)}`);
    return counts;
  } finally {
    if (server) await new Promise((resolve) => server.close(resolve));
    await sequelize.close();
  }
}

if (require.main === module) run().catch((error) => { console.error(`[DummySeed] ${error.stack || error.message}`); process.exitCode = 1; });
module.exports = { request, run };
