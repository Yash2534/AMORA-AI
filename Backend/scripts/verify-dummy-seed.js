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
      method: 'POST', body: JSON.stringify({ email: 'demo.aisha@seed.amoraa.example.test', password: config.password }),
    });
    const token = login.accessToken;
    if (!token) throw new Error('Demo login did not return an access token.');
    const pageOne = await request(baseUrl, '/api/discover/feed?page=1&limit=20&verifiedOnly=false', token);
    const pageTwo = await request(baseUrl, '/api/discover/feed?page=2&limit=20&verifiedOnly=false', token);
    const receivedOne = await request(baseUrl, '/api/me/received-likes?page=1&limit=20', token);
    const receivedTwo = await request(baseUrl, '/api/me/received-likes?page=2&limit=20', token);
    const filters = await request(baseUrl, '/api/discover/filters', token);
    const matches = await request(baseUrl, '/api/matches', token);
    const conversations = await request(baseUrl, '/api/conversations?page=1&limit=20', token);
    const demoB = await getModels().User.findOne({ where: { email: 'demo.rohan@seed.amoraa.example.test' } });
    await request(baseUrl, `/api/profiles/${demoB.id}`, token);
    const demoC = await getModels().User.findOne({ where: { email: 'demo.kavya@seed.amoraa.example.test' } });
    const demoConversation = await getModels().Conversation.findOne({ where: { pairKey: [login.user.id, demoC.id].sort((a, b) => a - b).join(':') } });
    const history = await request(baseUrl, `/api/conversations/${demoConversation.id}/messages?limit=20`, token);
    const listLength = (value) => Array.isArray(value) ? value.length : Array.isArray(value?.items) ? value.items.length : Array.isArray(value?.profiles) ? value.profiles.length : Array.isArray(value?.matches) ? value.matches.length : Array.isArray(value?.conversations) ? value.conversations.length : Array.isArray(value?.messages) ? value.messages.length : 0;
    if (listLength(pageOne) < 1 || listLength(pageTwo) < 1) throw new Error('Discovery did not return two populated pages.');
    if (listLength(receivedOne) < 1 || listLength(receivedTwo) < 1) throw new Error('Received likes did not return two populated pages.');
    if (listLength(matches) < 1 || listLength(conversations) < 1 || listLength(history) < 1) throw new Error('Demo match/conversation/message APIs were empty.');
    if (!filters) throw new Error('Discover filters did not load.');
    console.log(`[DummySeed] API verification passed: login, discovery pages 1-2, profile, filters, likes pages 1-2, matches, conversations, and message history.`);
    console.log(`[DummySeed] Validated counts: ${JSON.stringify(counts)}`);
    return counts;
  } finally {
    if (server) await new Promise((resolve) => server.close(resolve));
    await sequelize.close();
  }
}

if (require.main === module) run().catch((error) => { console.error(`[DummySeed] ${error.message}`); process.exitCode = 1; });
module.exports = { request, run };
