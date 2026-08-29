require('../src/config/bootstrapEnv');
const fs = require('fs');
const path = require('path');
const { resolveDummySeedConfig } = require('./dummy-seed/config');
const { validateDummyData } = require('./dummy-seed/validate');
const { findSeedUsers } = require('./dummy-seed/store');
const { detectedMimeType, sha256 } = require('./dummy-seed/media');
const { serializePublicProfile } = require('../src/services/publicProfileService');

function fail(message) {
  throw new Error(`Demo profile image verification failed: ${message}`);
}

function publicRequest(host) {
  return { protocol: 'http', get: (header) => header === 'host' ? host : undefined };
}

function fileFor(config, photo) {
  if (typeof photo !== 'string' || !photo.startsWith(`/uploads/onboarding-photos/${config.mediaPrefix}`)) fail(`invalid stored media path: ${photo}`);
  const file = path.resolve(config.uploadsDirectory, path.basename(photo));
  if (!file.startsWith(path.resolve(config.uploadsDirectory))) fail(`unsafe media path: ${photo}`);
  return file;
}

function assertPublicProfileImage(value, profileByUserId, baseUrl, label) {
  const userId = Number(value?.id);
  const profile = profileByUserId.get(userId);
  // These live endpoints can legally also contain development users outside
  // the isolated seed namespace; only assert the seed-owned rows here.
  if (!profile) return;
  const expectedPrimary = `${baseUrl}${profile.photos[0]}`;
  if (value.imageUrl !== expectedPrimary || !Array.isArray(value.gallery) || value.gallery.length !== 2
    || value.gallery[0] !== expectedPrimary) {
    fail(`${label} returned an incorrect image contract for profile ${profile.id}`);
  }
}

async function apiRequest(baseUrl, pathname, token) {
  const response = await fetch(`${baseUrl}${pathname}`, { headers: token ? { authorization: `Bearer ${token}` } : {} });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || body.success !== true) fail(`${pathname} returned ${response.status}: ${body.code || body.message || 'invalid response'}`);
  return body.data;
}

async function login(baseUrl, email, password) {
  const response = await fetch(`${baseUrl}/api/auth/login`, {
    method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password }),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || !body.success || !body.data?.accessToken) fail(`unable to log in as ${email}`);
  return body.data.accessToken;
}

async function run() {
  const config = resolveDummySeedConfig();
  require('../src/config/env');
  const { initializeDatabase, getSequelize } = require('../src/config/db');
  const { getModels } = require('../src/models');
  const { createHttpServer } = require('../src/server');
  await initializeDatabase();
  const sequelize = getSequelize();
  let server;
  try {
    const seedCounts = await validateDummyData(sequelize, getModels(), config);
    const { User, OnboardingProfile, Block } = getModels();
    const users = (await findSeedUsers(User, config)).sort((left, right) => left.email.localeCompare(right.email));
    if (users.length !== 150) fail(`expected 150 seed users, found ${users.length}`);
    const profiles = await OnboardingProfile.findAll({ where: { userId: users.map((user) => user.id) } });
    const profileByUserId = new Map(profiles.map((profile) => [Number(profile.userId), profile]));
    const paths = new Map();
    const hashes = new Map();
    const reportRows = [];
    for (const [seedIndex, user] of users.entries()) {
      const profile = profileByUserId.get(Number(user.id));
      if (!profile) fail(`user ${user.id} has no profile`);
      const photos = Array.isArray(profile.photos) ? profile.photos : [];
      if (photos.length !== 2 || Number(profile.primaryPhotoIndex) !== 0) fail(`profile ${profile.id} has invalid gallery ordering`);
      const row = { seed: seedIndex + 1, userId: String(user.id), profileId: String(profile.id), primaryImage: photos[0], galleryImages: photos, hashes: [] };
      for (const [photoIndex, photo] of photos.entries()) {
        const file = fileFor(config, photo);
        if (!fs.existsSync(file)) fail(`missing file ${photo}`);
        const bytes = fs.readFileSync(file);
        const mimeType = detectedMimeType(bytes);
        if (!mimeType) fail(`unsupported image ${photo}`);
        const hash = sha256(bytes);
        if (paths.has(photo)) fail(`image path ${photo} is owned by both profile ${paths.get(photo).profileId} and ${profile.id}`);
        if (hashes.has(hash)) fail(`duplicate SHA-256 ${hash}: ${hashes.get(hash).photo} and ${photo}`);
        paths.set(photo, { userId: user.id, profileId: profile.id, photoIndex });
        hashes.set(hash, { userId: user.id, profileId: profile.id, photo, photoIndex });
        row.hashes.push(hash);
      }
      reportRows.push(row);
    }
    if (paths.size !== 300 || hashes.size !== 300) fail(`expected 300 unique image files and hashes, found ${paths.size} paths and ${hashes.size} hashes`);

    server = createHttpServer();
    await new Promise((resolve, reject) => { server.once('error', reject); server.listen(0, '127.0.0.1', resolve); });
    const baseUrl = `http://127.0.0.1:${server.address().port}`;
    const serializerRequest = publicRequest(`127.0.0.1:${server.address().port}`);
    for (const user of users) {
      const profile = profileByUserId.get(Number(user.id));
      const serialized = serializePublicProfile(serializerRequest, user, profile);
      if (!serialized.imageUrl || serialized.imageUrl !== `${baseUrl}${profile.photos[0]}`) fail(`profile ${profile.id} generated an invalid primary URL`);
      if (serialized.gallery.length !== 2 || serialized.gallery[0] !== serialized.imageUrl) fail(`profile ${profile.id} generated an invalid gallery response`);
    }
    let successfulResponses = 0;
    for (const photo of paths.keys()) {
      const response = await fetch(`${baseUrl}${photo}`);
      const bytes = Buffer.from(await response.arrayBuffer());
      if (response.status !== 200 || !String(response.headers.get('content-type') || '').startsWith('image/') || !bytes.length || !detectedMimeType(bytes)) {
        fail(`media request failed for ${photo}: status=${response.status}, content-type=${response.headers.get('content-type')}`);
      }
      successfulResponses += 1;
    }

    const tokenA = await login(baseUrl, 'demo.aisha@seed.amoraa.example.test', config.password);
    const tokenB = await login(baseUrl, 'demo.rohan@seed.amoraa.example.test', config.password);
    const tokenC = await login(baseUrl, 'demo.kavya@seed.amoraa.example.test', config.password);
    const aisha = users.find((user) => user.email === 'demo.aisha@seed.amoraa.example.test');
    const rohan = users.find((user) => user.email === 'demo.rohan@seed.amoraa.example.test');
    const kavya = users.find((user) => user.email === 'demo.kavya@seed.amoraa.example.test');
    const viewers = [{ id: aisha.id, token: tokenA }, { id: rohan.id, token: tokenB }, { id: kavya.id, token: tokenC }];
    const blockedPairs = new Set((await Block.findAll({ attributes: ['blockerUserId', 'blockedUserId'] }))
      .map((row) => `${row.blockerUserId}:${row.blockedUserId}`));
    for (const user of users) {
      const viewer = viewers.find((candidate) => candidate.id !== user.id
        && !blockedPairs.has(`${candidate.id}:${user.id}`)
        && !blockedPairs.has(`${user.id}:${candidate.id}`));
      if (!viewer) fail(`no unblocked API viewer is available for seeded user ${user.id}`);
      const data = await apiRequest(baseUrl, `/api/profiles/${user.id}`, viewer.token);
      const profile = profileByUserId.get(Number(user.id));
      if (data.profile?.imageUrl !== `${baseUrl}${profile.photos[0]}` || data.profile?.gallery?.length !== 2) fail(`public profile API image mapping failed for profile ${profile.id}`);
    }
    const [feed, likes, superLikes, receivedLikes, matches, conversations, notifications] = await Promise.all([
      apiRequest(baseUrl, '/api/discover/feed?page=1&limit=30&verifiedOnly=false', tokenA),
      apiRequest(baseUrl, '/api/me/likes?page=1&limit=30', tokenA),
      apiRequest(baseUrl, '/api/me/super-likes?page=1&limit=30', tokenA),
      apiRequest(baseUrl, '/api/me/received-likes?page=1&limit=30', tokenA),
      apiRequest(baseUrl, '/api/matches', tokenA),
      apiRequest(baseUrl, '/api/conversations?page=1&limit=50', tokenA),
      apiRequest(baseUrl, '/api/notifications?page=1&limit=50', tokenA),
    ]);
    for (const profile of feed.profiles || []) assertPublicProfileImage(profile, profileByUserId, baseUrl, 'Discovery');
    for (const profile of likes.profiles || []) assertPublicProfileImage(profile, profileByUserId, baseUrl, 'Likes');
    for (const profile of superLikes.profiles || []) assertPublicProfileImage(profile, profileByUserId, baseUrl, 'Super Likes');
    for (const profile of receivedLikes.profiles || []) assertPublicProfileImage(profile, profileByUserId, baseUrl, 'Received Likes');
    for (const match of matches.matches || []) assertPublicProfileImage(match.profile, profileByUserId, baseUrl, 'Matches');
    for (const conversation of conversations.conversations || []) assertPublicProfileImage(conversation.participant, profileByUserId, baseUrl, 'Conversation list');
    for (const notification of notifications.notifications || []) {
      if (!notification.actor) continue;
      const actorProfile = profileByUserId.get(Number(notification.actor.userId));
      if (!actorProfile) continue;
      if (!actorProfile || notification.actor.photoUrl !== `${baseUrl}${actorProfile.photos[0]}`) {
        fail(`Notifications returned an incorrect actor image for user ${notification.actor.userId}`);
      }
    }

    const reportPath = path.resolve(__dirname, '../tmp/demo-profile-image-verification.json');
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, `${JSON.stringify({
      generatedAt: new Date().toISOString(),
      expectedProfiles: 150,
      profilesFound: users.length,
      profilesWithPrimaryImages: users.length,
      totalImageRecords: paths.size,
      uniqueSha256Hashes: hashes.size,
      imageUrlsTested: successfulResponses,
      rows: reportRows,
    }, null, 2)}\n`);
    console.log(`[DemoProfileImages] PASS profiles=150 primary=150 imageRecords=${paths.size} uniqueSha256=${hashes.size} http200=${successfulResponses} duplicates=0`);
    console.log(`[DemoProfileImages] Mapping report: ${reportPath}`);
    return { ...seedCounts, profileImages: paths.size, uniqueImageHashes: hashes.size, http200: successfulResponses, reportPath };
  } finally {
    if (server) await new Promise((resolve) => server.close(resolve));
    await sequelize.close();
  }
}

if (require.main === module) run().catch((error) => { console.error(`[DemoProfileImages] ${error.message}`); process.exitCode = 1; });
module.exports = { run };
