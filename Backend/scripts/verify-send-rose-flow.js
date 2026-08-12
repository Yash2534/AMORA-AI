require('../src/config/bootstrapEnv');
const assert = require('node:assert/strict');
const jwt = require('jsonwebtoken');
const { Op } = require('sequelize');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { app } = require('../src/server');

if (!process.argv.includes('--confirm-development-db') || process.env.NODE_ENV === 'production') {
  throw new Error('Pass --confirm-development-db and run only against the development schema.');
}

let server;
let models;
const ids = [];

async function main() {
  await initializeDatabase();
  models = getModels();
  for (const name of ['Rose Verification Sender', 'Rose Verification Recipient']) {
    const user = await models.User.create({ name, email: `${Date.now()}_${ids.length}@rose-verification.test`, phoneNumber: '', authProvider: 'local', isVerified: true, termsAcceptedAt: new Date() });
    ids.push(user.id);
  }
  server = app.listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  const sender = await models.User.findByPk(ids[0]);
  const response = await fetch(`http://127.0.0.1:${server.address().port}/api/roses/send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${jwt.sign({ sub: sender.id, ver: Number(sender.tokenVersion || 0) }, process.env.JWT_SECRET, { expiresIn: '15m' })}`, 'content-type': 'application/json' },
    body: JSON.stringify({ recipientId: ids[1], note: 'Verification Rose', idempotencyKey: `rose-verification:${Date.now()}` }),
  });
  const body = await response.json();
  assert.equal(response.status, 201, JSON.stringify(body));
  assert.ok(await models.RoseTransaction.findByPk(body.data.roseTransaction.id));
  assert.equal(await models.Notification.count({ where: { userId: ids[1], type: 'rose_received' } }), 1);
  console.log(`[Verify] Standalone Rose persisted as transaction ${body.data.roseTransaction.id}.`);
}

main().catch((error) => { console.error(error); process.exitCode = 1; }).finally(async () => {
  if (server) await new Promise((resolve) => server.close(resolve));
  if (models && ids.length) {
    await models.Notification.destroy({ where: { [Op.or]: [{ userId: ids }, { actorUserId: ids }] }, force: true });
    await models.RoseTransaction.destroy({ where: { [Op.or]: [{ senderId: ids }, { recipientId: ids }] } });
    await models.User.destroy({ where: { id: ids } });
  }
  try { await getSequelize().close(); } catch (_) {}
});
