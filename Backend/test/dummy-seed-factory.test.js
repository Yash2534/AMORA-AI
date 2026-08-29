const test = require('node:test');
const assert = require('node:assert/strict');
const { buildSeedBlueprint, pairKey } = require('../scripts/dummy-seed/factory');
const { detectedMimeType, sha256 } = require('../scripts/dummy-seed/media');

const config = { userCount: 60, randomSeed: 789, referenceDate: new Date('2026-08-29T12:00:00.000Z') };

test('dummy profile generation is deterministic, unique, varied, and onboarding-compatible', () => {
  const first = buildSeedBlueprint(config).users;
  const second = buildSeedBlueprint(config).users;
  assert.deepEqual(first, second);
  assert.equal(first.length, 60);
  assert.equal(new Set(first.map((value) => value.email)).size, 60);
  assert.equal(new Set(first.map((value) => value.phoneNumber)).size, 60);
  assert.ok(new Set(first.map((value) => value.bio)).size > 15);
  assert.ok(new Set(first.map((value) => value.city)).size >= 4);
  for (const profile of first.filter((value) => value.completed)) {
    assert.match(profile.email, /@seed\.amoraa\.example\.test$/);
    assert.ok(profile.age >= 18);
    assert.ok(profile.interests.length >= 5 && profile.interests.length <= 10);
    assert.ok(profile.photoCount >= 2 && profile.photoCount <= 6);
  }
});

test('demo accounts and video relationships have stable identities', () => {
  const values = buildSeedBlueprint(config).users;
  assert.deepEqual(values.slice(0, 3).map((value) => value.email), [
    'demo.aisha@seed.amoraa.example.test', 'demo.rohan@seed.amoraa.example.test', 'demo.kavya@seed.amoraa.example.test',
  ]);
  assert.equal(pairKey(9, 2), '2:9');
});

test('seed media helpers only accept supported image signatures and hash content', () => {
  const png = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  assert.equal(detectedMimeType(png), 'image/png');
  assert.equal(detectedMimeType(Buffer.from('not-an-image')), null);
  assert.notEqual(sha256(Buffer.from('portrait-a')), sha256(Buffer.from('portrait-b')));
});
