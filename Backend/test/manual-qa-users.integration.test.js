const assert = require('node:assert/strict');
const { after, before, test } = require('node:test');
const { Op } = require('sequelize');

require('../src/config/bootstrapEnv');
const applicationDatabase = process.env.DB_NAME;
const testDatabase = process.env.TEST_DB_NAME || `${applicationDatabase}_test`;
if (!testDatabase || !/test/i.test(testDatabase) || testDatabase === applicationDatabase) {
  throw new Error('Manual QA integration tests require a separate test database.');
}
process.env.DB_NAME = testDatabase;
process.env.NODE_ENV = 'test';

const { migrate } = require('../src/migrations/run');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { pairKeyFor } = require('../src/services/conversationAccessService');
const { seedQaUsers, resetQaRelations } = require('../scripts/manual-qa-users-store');
const { validateManualQaUsers } = require('../scripts/manual-qa-users-validate');

const config = {
  passwords: { krupa: 'IntegrationOnlyKrupa1!', yashu: 'IntegrationOnlyYashu1!' },
};
const media = {
  krupa: ['/uploads/test-krupa-one.webp', '/uploads/test-krupa-two.webp'],
  yashu: ['/uploads/test-yashu-one.webp', '/uploads/test-yashu-two.webp'],
};
let models;
let users;
let unrelated;

async function cleanup() {
  if (!models) return;
  const rows = await models.User.findAll({
    where: { email: ['krupa@gmail.com', 'yashu@gmail.com', 'manual-qa-unrelated@test.invalid'] },
  });
  const ids = rows.map((row) => Number(row.id));
  if (!ids.length) return;
  await models.DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: ids }, { targetUserId: ids }] } });
  await models.Block.destroy({ where: { [Op.or]: [{ blockerUserId: ids }, { blockedUserId: ids }] } });
  await models.SavedProfile.destroy({ where: { [Op.or]: [{ userId: ids }, { savedUserId: ids }] } });
  await models.RoseTransaction.destroy({ where: { [Op.or]: [{ senderId: ids }, { recipientId: ids }] } });
  await models.Report.destroy({ where: { [Op.or]: [{ reporterUserId: ids }, { reportedUserId: ids }] } });
  await models.Match.destroy({ where: { [Op.or]: [{ userOneId: ids }, { userTwoId: ids }] } });
  await models.DiscoverFilterPreference.destroy({ where: { userId: ids } });
  await models.OnboardingProfile.destroy({ where: { userId: ids } });
  await models.User.destroy({ where: { id: ids } });
}

before(async () => {
  await migrate({ databaseName: testDatabase, quiet: true });
  await initializeDatabase();
  models = getModels();
  await cleanup();
});

after(async () => {
  await cleanup();
  try { await getSequelize().close(); } catch (_) { /* initialization may have failed */ }
});

test('rerunning the seed updates the exact accounts without duplicates', async () => {
  users = await getSequelize().transaction((transaction) => seedQaUsers(
    models, config, media, transaction, new Date('2026-09-30T12:00:00.000Z'),
  ));
  const firstIds = [Number(users.krupa.id), Number(users.yashu.id)];
  users = await getSequelize().transaction((transaction) => seedQaUsers(
    models, config, media, transaction, new Date('2026-09-30T12:00:00.000Z'),
  ));
  assert.deepEqual([Number(users.krupa.id), Number(users.yashu.id)], firstIds);
  assert.equal(await models.User.count({ where: { email: ['krupa@gmail.com', 'yashu@gmail.com'] } }), 2);
  const result = await validateManualQaUsers(models, config);
  assert.deepEqual(result.completion, { krupa: 100, yashu: 100 });
  assert.equal(result.compatibility.score, 93);
  assert.equal(result.compatibility.coverage, 100);
});

test('reset removes only A/B relations and preserves an unrelated relation', async () => {
  const krupaId = Number(users.krupa.id);
  const yashuId = Number(users.yashu.id);
  unrelated = await models.User.create({
    name: 'Manual QA unrelated',
    email: 'manual-qa-unrelated@test.invalid',
    phoneNumber: '',
    authProvider: 'local',
    isVerified: true,
    accountStatus: 'active',
  });
  const unrelatedAction = await models.DiscoverAction.create({
    actorUserId: krupaId, targetUserId: unrelated.id, action: 'pass',
  });
  await models.DiscoverAction.bulkCreate([
    { actorUserId: krupaId, targetUserId: yashuId, action: 'like' },
    { actorUserId: yashuId, targetUserId: krupaId, action: 'like' },
  ]);
  await models.Match.create({ userOneId: Math.min(krupaId, yashuId), userTwoId: Math.max(krupaId, yashuId) });
  await models.Block.create({ blockerUserId: krupaId, blockedUserId: yashuId });
  await models.SavedProfile.create({ userId: yashuId, savedUserId: krupaId });
  await models.RoseTransaction.create({ senderId: krupaId, recipientId: yashuId, idempotencyKey: 'manual-qa-integration-rose' });
  await models.Report.create({ reporterUserId: yashuId, reportedUserId: krupaId, targetType: 'profile', targetId: String(krupaId), reason: 'other' });
  const conversation = await models.Conversation.create({ pairKey: pairKeyFor(krupaId, yashuId), type: 'direct' });
  await models.ConversationParticipant.bulkCreate([
    { conversationId: conversation.id, userId: krupaId },
    { conversationId: conversation.id, userId: yashuId },
  ]);

  await getSequelize().transaction((transaction) => resetQaRelations(models, users, transaction));
  const result = await validateManualQaUsers(models, config);
  assert.ok(Object.values(result.relationshipCounts).every((count) => count === 0));
  assert.equal(await models.DiscoverAction.count({ where: { id: unrelatedAction.id } }), 1);
});
