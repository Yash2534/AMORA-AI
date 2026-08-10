const computeCompatibilityScore = require('../utils/computeCompatibilityScore');

const list = (value) => (Array.isArray(value) ? value : []);

function ageFor(birthDate) {
  if (!birthDate) return null;
  const now = new Date();
  const birth = new Date(`${birthDate}T00:00:00.000Z`);
  let age = now.getUTCFullYear() - birth.getUTCFullYear();
  if (now.getUTCMonth() < birth.getUTCMonth() || (now.getUTCMonth() === birth.getUTCMonth() && now.getUTCDate() < birth.getUTCDate())) age -= 1;
  return age;
}

function publicUrl(req, value) {
  if (value && /^https?:\/\//i.test(value)) return value;
  return value ? `${req.protocol}://${req.get('host')}${value}` : null;
}

function serializePublicProfile(req, user, profile, options = {}) {
  const photos = list(profile.photos);
  const primary = photos[profile.primaryPhotoIndex] || photos[0] || null;
  const queriedScore = profile.getDataValue?.('compatibilityScore');
  const score = options.score ?? (queriedScore === undefined || queriedScore === null
    ? (options.viewer ? computeCompatibilityScore(options.viewer, profile) : 0)
    : Number(queriedScore));
  const subscription = user.subscription;
  const premium = Boolean(subscription
    && ['active', 'trialing', 'cancelled'].includes(subscription.status)
    && new Date(subscription.currentPeriodEnd) > new Date());
  return {
    id: String(user.id),
    gender: profile.gender || '',
    name: user.name,
    age: ageFor(profile.birthDate),
    city: profile.city || '',
    profession: profile.profession || '',
    education: profile.education || '',
    distance: null,
    score,
    intent: list(profile.relationshipGoals)[0] || '',
    personality: profile.personality || '',
    status: null,
    bio: profile.bio || '',
    interests: list(profile.interests),
    imageUrl: publicUrl(req, primary),
    gallery: photos.map((photo) => publicUrl(req, photo)).filter(Boolean),
    languages: list(profile.languages),
    verification: user.isVerified ? 'Verified' : 'Unverified',
    premium,
    lifestyle: profile.lifestyle || {},
    promptAnswers: profile.prompts || {},
    travelPreference: profile.travelPreference || '',
    musicTaste: profile.musicTaste || '',
    foodPreference: profile.foodPreference || '',
    weekendPlan: profile.weekendPlan || '',
    petPreference: profile.petPreference || '',
    coffeePreference: profile.coffeePreference || '',
    religion: profile.religion || '',
    community: profile.community || '',
    height: profile.height || '',
    fitnessLevel: profile.fitnessLevel || '',
    smoking: profile.smoking || '',
    drinking: profile.drinking || '',
    weed: profile.weed || '',
    children: profile.children || '',
    loveLanguage: profile.loveLanguage || '',
    greenFlags: list(profile.greenFlags),
    redFlags: list(profile.redFlags),
    familyValues: profile.familyValues || '',
    dateIdeas: list(profile.dateIdeas),
    hometown: profile.hometown || '',
    valuedQualities: list(profile.valuedQualities),
    pronouns: list(profile.pronouns),
    sexuality: profile.sexuality || '',
    preferredTalkingHours: list(profile.preferredTalkingHours),
    loveLanguages: list(profile.loveLanguages),
    communicationStyle: profile.communicationStyle || null,
    ...(options.relationship ? { relationship: options.relationship } : {}),
  };
}

module.exports = { ageFor, serializePublicProfile };
