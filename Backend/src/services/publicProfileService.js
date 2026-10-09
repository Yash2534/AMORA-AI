const { compatibilityFor } = require('./compatibilityService');
const { isRecentlyActive } = require('./discoverEligibilityPolicy');
const { scoreCompatibility } = require('./matchEngineService');
const { protectedPath } = require('../utils/photoStorage');

const list = (value) => (Array.isArray(value) ? value : []);

function ageFor(birthDate) {
  if (!birthDate) return null;
  const now = new Date();
  const birth = new Date(`${birthDate}T00:00:00.000Z`);
  let age = now.getUTCFullYear() - birth.getUTCFullYear();
  if (now.getUTCMonth() < birth.getUTCMonth() || (now.getUTCMonth() === birth.getUTCMonth() && now.getUTCDate() < birth.getUTCDate())) age -= 1;
  return age;
}

function publicUrl(req, value, userId) {
  const secured = protectedPath(userId, value);
  return secured ? `${req.protocol}://${req.get('host')}${secured}` : null;
}

function coarseDistanceKm(value) {
  if (value === null || value === undefined || value === '') return null;
  const precise = Number(value);
  if (!Number.isFinite(precise) || precise < 0) return null;
  return Math.max(5, Math.ceil(precise / 5) * 5);
}

function serializePublicProfile(req, user, profile, options = {}) {
  const photos = list(profile.photos);
  const lifestyle = profile.lifestyle && typeof profile.lifestyle === 'object' ? profile.lifestyle : {};
  const lifestyleLanguages = typeof lifestyle.Languages === 'string'
    ? lifestyle.Languages.split(/\s*(?:,|&|\band\b)\s*/i).filter(Boolean)
    : [];
  const primary = photos[profile.primaryPhotoIndex] || photos[0] || null;
  const queriedScore = profile.getDataValue?.('compatibilityScore');
  const canonicalCompatibility = options.compatibility
    || (options.viewer ? scoreCompatibility(options.viewer, profile) : null);
  const score = options.score ?? (queriedScore === undefined || queriedScore === null
    ? (canonicalCompatibility?.score ?? 0)
    : Number(queriedScore));
  const subscription = user.subscription;
  const premium = Boolean(subscription
    && ['active', 'trialing', 'cancelled'].includes(subscription.status)
    && new Date(subscription.currentPeriodEnd) > new Date());
  const compatibility = compatibilityFor(options.viewer, profile, score, canonicalCompatibility);
  const coverage = canonicalCompatibility?.coverage ?? 0;
  const recentlyActive = isRecentlyActive(user.lastActiveAt, {
    windowMinutes: options.recentActivityWindowMinutes,
  });
  const publicDistanceKm = coarseDistanceKm(options.distanceKm);
  return {
    id: String(user.id),
    gender: profile.gender || '',
    customGender: profile.customGender || '',
    name: user.name,
    age: ageFor(profile.birthDate),
    city: profile.city || '',
    profession: profile.profession || '',
    education: profile.education || '',
    distance: publicDistanceKm,
    distanceKm: publicDistanceKm,
    score,
    compatibilityScore: score,
    compatibilityCoverage: coverage,
    compatibilityReasons: compatibility.reasons.map((reason) => reason.label),
    compatibility,
    intent: list(profile.relationshipGoals)[0] || '',
    recentlyActive,
    status: recentlyActive ? 'Recently active' : null,
    bio: profile.bio || '',
    interests: list(profile.interests),
    imageUrl: publicUrl(req, primary, user.id),
    gallery: photos.map((photo) => publicUrl(req, photo, user.id)).filter(Boolean),
    languages: lifestyleLanguages.length ? lifestyleLanguages : list(profile.languages),
    verification: user.identityVerifiedAt ? 'Verified' : 'Unverified',
    premium,
    lifestyle,
    promptAnswers: profile.prompts || {},
    religion: lifestyle.Religion || profile.religion || '',
    community: profile.community || '',
    height: lifestyle.Height || profile.height || '',
    smoking: lifestyle.Smoking || profile.smoking || '',
    drinking: lifestyle.Drinking || profile.drinking || '',
    weed: lifestyle.Weed || profile.weed || '',
    hometown: profile.hometown || '',
    valuedQualities: list(profile.valuedQualities),
    pronouns: list(profile.pronouns),
    sexuality: profile.sexuality || '',
    preferredTalkingHours: list(profile.preferredTalkingHours),
    loveLanguages: list(profile.loveLanguages),
    iceBreaker: profile.iceBreaker || '',
    communicationStyle: profile.communicationStyle || null,
    ...(options.relationship ? { relationship: options.relationship } : {}),
  };
}

module.exports = { ageFor, publicUrl, coarseDistanceKm, serializePublicProfile };
