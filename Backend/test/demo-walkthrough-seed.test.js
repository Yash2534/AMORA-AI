const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');
const bcrypt = require('bcrypt');
const { buildSeedBlueprint } = require('../scripts/dummy-seed/factory');
const { assignSourceImages } = require('../scripts/dummy-seed/media');
const { calculateProfileCompletion } = require('../src/services/profileCompletionService');
const { isDiscoverComplete, viewerAcceptsCandidate, candidateAcceptsViewer, ageFor } = require('../src/services/discoverEligibilityPolicy');
const { scoreCompatibility } = require('../src/services/compatibilityScoringService');
const { rankCandidates } = require('../src/services/aiMatchProvider');

const root = path.resolve(__dirname, '..');
const config = {
  userCount: 25,
  randomSeed: 12345,
  referenceDate: new Date('2026-08-29T12:00:00.000Z'),
  portraitAssetsDirectory: path.join(root, 'demo-assets', 'amoraa-v2-generated', 'profiles'),
  mediaPrefix: 'amoraa-v2-profile-',
};

function profile(entry, photos = ['/uploads/a.webp', '/uploads/b.webp']) {
  return {
    ...entry,
    photos,
    height: `${entry.heightCm} cm`,
    stage: entry.completed ? 'complete' : 'photos',
    onboardingCompleted: entry.completed,
  };
}

test('walkthrough account authenticates with a real bcrypt hash and reaches canonical 100% completion', async () => {
  const master = buildSeedBlueprint(config).users[0];
  const runtimePassword = 'integration-only-password';
  const passwordHash = await bcrypt.hash(runtimePassword, 4);
  assert.equal(await bcrypt.compare(runtimePassword, passwordHash), true);
  assert.equal(await bcrypt.compare('incorrect', passwordHash), false);
  assert.equal(ageFor(master.birthDate, new Date('2026-09-30T12:00:00.000Z')), 28);
  const value = profile(master, Array.from({ length: 5 }, (_, index) => `/uploads/demo-${index}.webp`));
  assert.equal(isDiscoverComplete(value, { now: new Date('2026-09-30T12:00:00.000Z') }), true);
  assert.deepEqual(calculateProfileCompletion({ name: master.name }, value), { percentage: 100, complete: true });
});

test('walkthrough cohorts provide fresh eligible women with varied canonical and LOCAL AI scores', () => {
  const users = buildSeedBlueprint(config).users;
  const master = profile(users[0]);
  const freshKeys = new Set(['candidate-a', 'candidate-b', 'candidate-c', 'candidate-d', 'candidate-f', 'candidate-g', 'candidate-h', 'candidate-r', 'candidate-s', 'candidate-t']);
  const fresh = users.filter((entry) => freshKeys.has(entry.key)).map((entry) => profile(entry));
  assert.ok(fresh.length >= 6);
  for (const candidate of fresh) {
    assert.equal(viewerAcceptsCandidate(master.interestedIn, candidate.gender), true);
    assert.equal(candidateAcceptsViewer(candidate.interestedIn, master.gender), true);
    assert.ok(candidate.age >= 23 && candidate.age <= 35);
  }
  const compatibility = fresh.map((candidate) => scoreCompatibility(master, candidate));
  assert.ok(new Set(compatibility.map((value) => value.score)).size >= 3);
  const ranked = rankCandidates({}, fresh.map((candidate, index) => ({ userId: index + 1, compatibility: compatibility[index] })));
  assert.ok(ranked.length >= 5);
  assert.ok(ranked.every((value) => value.aiReasons.length > 0 && value.aiConfidence > 0));
  assert.deepEqual(ranked, rankCandidates({}, fresh.map((candidate, index) => ({ userId: index + 1, compatibility: compatibility[index] }))));
});

test('walkthrough portrait manifest contains five demo photos and two unique photos per other profile', () => {
  const blueprint = buildSeedBlueprint(config);
  const assigned = assignSourceImages(config, blueprint.users);
  assert.equal(assigned[0].length, 5);
  assert.ok(assigned.slice(1).every((photos) => photos.length === 2));
  const hashes = assigned.flat().map((item) => item.hash);
  assert.equal(new Set(hashes).size, hashes.length);
  assert.ok(assigned.flat().every((item) => fs.existsSync(item.file)));
});

test('walkthrough relationship cohorts are mutually exclusive by design', () => {
  const roles = new Map(buildSeedBlueprint(config).users.map((entry) => [entry.key, entry.role]));
  const matched = new Set(['candidate-i', 'candidate-j', 'candidate-k', 'candidate-l']);
  const passed = new Set(['candidate-u', 'candidate-v', 'candidate-w']);
  const fresh = new Set(['candidate-a', 'candidate-b', 'candidate-c', 'candidate-d', 'candidate-f', 'candidate-g', 'candidate-h', 'candidate-r', 'candidate-s', 'candidate-t']);
  assert.equal([...matched].some((key) => fresh.has(key) || passed.has(key)), false);
  assert.equal([...passed].some((key) => fresh.has(key)), false);
  assert.ok([...matched, ...passed, ...fresh].every((key) => roles.has(key)));
});
