const { literal } = require('sequelize');
const { getModels } = require('../models');

const ACTIVE_REGISTRATION_STATUSES = ['registered'];

class EventServiceError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function ageFromBirthDate(value, now = new Date()) {
  if (!value) return null;
  const birth = new Date(`${value}T00:00:00Z`);
  if (Number.isNaN(birth.getTime())) return null;
  let age = now.getUTCFullYear() - birth.getUTCFullYear();
  const beforeBirthday = now.getUTCMonth() < birth.getUTCMonth()
    || (now.getUTCMonth() === birth.getUTCMonth() && now.getUTCDate() < birth.getUTCDate());
  if (beforeBirthday) age -= 1;
  return age;
}

async function userMeetsEligibility(userId, event, options = {}) {
  if (event.minAge == null && event.maxAge == null) return true;
  const { OnboardingProfile } = getModels();
  const profile = await OnboardingProfile.findOne({
    where: { userId, onboardingCompleted: true },
    attributes: ['birthDate'],
    transaction: options.transaction,
  });
  const age = ageFromBirthDate(profile?.birthDate);
  return age != null
    && (event.minAge == null || age >= Number(event.minAge))
    && (event.maxAge == null || age <= Number(event.maxAge));
}

function eligibilitySql(userId) {
  const id = Number(userId);
  return literal(`(
    (\`Event\`.\`minAge\` IS NULL AND \`Event\`.\`maxAge\` IS NULL)
    OR EXISTS (
      SELECT 1 FROM \`OnboardingProfiles\` eligibilityProfile
      WHERE eligibilityProfile.userId = ${id}
        AND eligibilityProfile.onboardingCompleted = 1
        AND (\`Event\`.\`minAge\` IS NULL OR TIMESTAMPDIFF(YEAR, eligibilityProfile.birthDate, UTC_DATE()) >= \`Event\`.\`minAge\`)
        AND (\`Event\`.\`maxAge\` IS NULL OR TIMESTAMPDIFF(YEAR, eligibilityProfile.birthDate, UTC_DATE()) <= \`Event\`.\`maxAge\`)
    )
  )`);
}

function participationIncludes(userId) {
  const { EventRegistration, User } = getModels();
  return [
    { model: User, as: 'organizer', required: true, where: { accountStatus: 'active' }, attributes: ['id', 'name', 'identityVerifiedAt'] },
    { model: EventRegistration, as: 'registrations', required: false, where: { userId }, attributes: ['status', 'registeredAt', 'cancelledAt'] },
  ];
}

function countAttributes() {
  return {
    include: [[literal(`(SELECT COUNT(*) FROM \`EventRegistrations\` capacityRegistration WHERE capacityRegistration.eventId = \`Event\`.\`id\` AND capacityRegistration.status = 'registered')`), 'registeredCount']],
  };
}

function participationFor(event) {
  const registration = event.registrations?.[0];
  return {
    registered: registration?.status === 'registered',
    registrationStatus: registration?.status || null,
  };
}

function serializeEvent(event) {
  const plain = event.get({ plain: true });
  const registeredCount = Number(plain.registeredCount || 0);
  return {
    id: String(plain.id),
    title: plain.title,
    description: plain.description,
    category: plain.category,
    city: plain.city,
    venueName: plain.venueName,
    address: plain.address,
    latitude: plain.latitude == null ? null : Number(plain.latitude),
    longitude: plain.longitude == null ? null : Number(plain.longitude),
    startDateTime: plain.startDateTime,
    endDateTime: plain.endDateTime,
    capacity: Number(plain.capacity),
    registeredCount,
    seatsLeft: Math.max(0, Number(plain.capacity) - registeredCount),
    available: plain.status === 'published' && plain.registrationOpen && registeredCount < Number(plain.capacity),
    status: plain.status,
    heroImageUrl: plain.heroImageUrl,
    price: Number(plain.price || 0),
    dressCode: plain.dressCode,
    ageRange: plain.minAge == null && plain.maxAge == null ? null : `${plain.minAge || 18}-${plain.maxAge || 'any'}`,
    language: plain.language,
    agenda: Array.isArray(plain.agenda) ? plain.agenda : [],
    facilities: Array.isArray(plain.facilities) ? plain.facilities : [],
    interests: Array.isArray(plain.interests) ? plain.interests : [],
    organizer: plain.organizer ? { id: String(plain.organizer.id), name: plain.organizer.name, verified: Boolean(plain.organizer.identityVerifiedAt) } : null,
    participation: participationFor(plain),
  };
}

module.exports = {
  ACTIVE_REGISTRATION_STATUSES,
  EventServiceError,
  countAttributes,
  eligibilitySql,
  participationIncludes,
  serializeEvent,
  userMeetsEligibility,
};
