const assert = require('node:assert/strict');
const { test } = require('node:test');
const express = require('express');
const {
  databasePoolConfig,
  migrationStartupMode,
  aiCandidateWindow,
  requireDistributedRateLimit,
} = require('../src/config/scalability');
const { pagination } = require('../src/utils/pagination');
const { LocalConnectionRegistry } = require('../src/realtime/realtimeHub');
const { createGracefulShutdown } = require('../src/services/gracefulShutdown');
const readiness = require('../src/services/serviceReadiness');
const { app } = require('../src/server');
const chatMediaStorage = require('../src/utils/chatMediaStorage');
const { buildRateLimiters } = require('../src/middleware/rateLimiter');

test('database pool settings have bounded defaults and reject unsafe configuration', () => {
  assert.deepEqual(databasePoolConfig({}), { max: 10, min: 0, acquire: 30000, idle: 10000 });
  assert.deepEqual(databasePoolConfig({ DB_POOL_MAX: '25', DB_POOL_MIN: '5', DB_POOL_ACQUIRE_MS: '45000', DB_POOL_IDLE_MS: '15000' }), { max: 25, min: 5, acquire: 45000, idle: 15000 });
  assert.throws(() => databasePoolConfig({ DB_POOL_MAX: '0' }), /DB_POOL_MAX/);
  assert.throws(() => databasePoolConfig({ DB_POOL_MAX: '2', DB_POOL_MIN: '3' }), /cannot exceed/);
});

test('production migration mode verifies by default and migration application is explicit', () => {
  assert.equal(migrationStartupMode({ NODE_ENV: 'production' }), 'verify');
  assert.equal(migrationStartupMode({ NODE_ENV: 'development' }), 'apply');
  assert.equal(migrationStartupMode({ NODE_ENV: 'production', DB_MIGRATION_STARTUP_MODE: 'apply' }), 'apply');
  assert.throws(() => migrationStartupMode({ DB_MIGRATION_STARTUP_MODE: 'sometimes' }), /verify or apply/);
});

test('AI window and collection pagination enforce hard maximums', () => {
  assert.equal(aiCandidateWindow({}), 500);
  assert.equal(aiCandidateWindow({ AI_DISCOVERY_CANDIDATE_WINDOW: '2000' }), 2000);
  assert.throws(() => aiCandidateWindow({ AI_DISCOVERY_CANDIDATE_WINDOW: '2001' }), /AI_DISCOVERY_CANDIDATE_WINDOW/);
  assert.deepEqual(pagination({ page: '2', limit: '100000' }), { page: 2, limit: 50, offset: 50 });
});

test('distributed-rate-limit requirement is strictly parsed', () => {
  assert.equal(requireDistributedRateLimit({}), false);
  assert.equal(requireDistributedRateLimit({ REQUIRE_DISTRIBUTED_RATE_LIMIT: 'true' }), true);
  assert.throws(() => requireDistributedRateLimit({ REQUIRE_DISTRIBUTED_RATE_LIMIT: 'yes' }), /true or false/);
});

test('rate limiters accept a replaceable per-policy store factory', () => {
  const policies = [];
  class TestStore {
    constructor() { this.localKeys = false; this.prefix = 'test:'; }
    init() {}
    async get() { return undefined; }
    async increment() { return { totalHits: 1, resetTime: new Date(Date.now() + 1000) }; }
    async decrement() {}
    async resetKey() {}
    async resetAll() {}
  }
  const limiters = buildRateLimiters({ storeFactory: (name) => { policies.push(name); return new TestStore(); } });
  assert.equal(typeof limiters.loginLimiter, 'function');
  assert.ok(policies.includes('otp-request'));
  assert.ok(policies.includes('privacy-request'));
  assert.equal(new Set(policies).size, policies.length);
});

test('local realtime registry is encapsulated and tracks multi-socket users idempotently', () => {
  const registry = new LocalConnectionRegistry();
  assert.equal(registry.connect(7), 0);
  assert.equal(registry.connect(7), 1);
  assert.equal(registry.size(), 2);
  assert.equal(registry.disconnect(7), 1);
  assert.equal(registry.disconnect(7), 0);
  assert.equal(registry.count(7), 0);
});

test('graceful shutdown is ordered and idempotent', async () => {
  const calls = [];
  const shutdown = createGracefulShutdown({
    server: {},
    timeoutMs: 1000,
    logger: { info() {}, error() {} },
    closeHttp: async () => calls.push('http'),
    closeRealtime: async () => calls.push('realtime'),
    closeDb: async () => calls.push('database'),
    exit: (code) => calls.push(`exit:${code}`),
  });
  const first = shutdown('SIGTERM');
  const second = shutdown('SIGINT');
  assert.equal(first, second);
  assert.deepEqual(await first, { timedOut: false });
  assert.deepEqual(calls, ['http', 'realtime', 'database', 'exit:0']);
});

test('liveness stays available while readiness fails before initialization', async (context) => {
  readiness.reset();
  const server = app.listen(0);
  context.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${base}/health/live`)).status, 200);
  const response = await fetch(`${base}/health/ready`);
  assert.equal(response.status, 503);
  assert.equal((await response.json()).data.initialized, false);
});

test('chat upload rejects a payload above its strict byte limit', async (context) => {
  const uploadApp = express();
  uploadApp.post('/upload', chatMediaStorage.upload.single('media'), (_req, res) => res.sendStatus(204));
  uploadApp.use((error, _req, res, _next) => res.status(413).json({ code: error.code }));
  const server = uploadApp.listen(0);
  context.after(() => new Promise((resolve) => server.close(resolve)));
  await new Promise((resolve) => server.once('listening', resolve));
  const form = new FormData();
  form.append('media', new Blob([Buffer.alloc(chatMediaStorage.maximumMediaBytes + 1)], { type: 'image/jpeg' }), 'large.jpg');
  const response = await fetch(`http://127.0.0.1:${server.address().port}/upload`, { method: 'POST', body: form });
  assert.equal(response.status, 413);
  assert.equal((await response.json()).code, 'LIMIT_FILE_SIZE');
});
