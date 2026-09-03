const { literal } = require('sequelize');
const { getModels } = require('../models');
const { publicUrl } = require('./publicProfileService');

const ACTIVE_REGISTRATION_STATUSES = ['registered', 'promoted'];

function registrationDeadlineFor(event) {
  return event.registrationDeadline || event.startDateTime;
}

function registrationIsClosed(event, now = new Date()) {
  const deadline = registrationDeadlineFor(event);
  return !deadline || new Date(deadline).getTime() <= now.getTime();
}

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
  const { EventRegistration, EventWaitlist, User, OnboardingProfile } = getModels();
  return [
    {
      model: User,
      as: 'organizer',
      required: true,
      where: { accountStatus: 'active' },
      attributes: ['id', 'name', 'identityVerifiedAt'],
      include: [{ model: OnboardingProfile, required: false, attributes: ['photos', 'primaryPhotoIndex'] }],
    },
    { model: EventRegistration, as: 'registrations', required: false, where: { userId }, attributes: ['status', 'registeredAt', 'cancelledAt'] },
    { model: EventWaitlist, as: 'waitlist', required: false, where: { userId }, attributes: ['status', 'joinedAt', 'endedAt'] },
  ];
}

function countAttributes() {
  return {
    include: [
      [literal(`(SELECT COUNT(*) FROM \`EventRegistrations\` capacityRegistration WHERE capacityRegistration.eventId = \`Event\`.\`id\` AND capacityRegistration.status IN ('registered','promoted'))`), 'registeredCount'],
      [literal(`(SELECT COUNT(*) FROM \`EventWaitlist\` capacityWaitlist WHERE capacityWaitlist.eventId = \`Event\`.\`id\` AND capacityWaitlist.status = 'waiting')`), 'waitlistCount'],
    ],
  };
}

function participationFor(event) {
  const registration = event.registrations?.[0];
  const waitlist = event.waitlist?.[0];
  return {
    registered: Boolean(registration && ACTIVE_REGISTRATION_STATUSES.includes(registration.status)),
    waitlisted: waitlist?.status === 'waiting',
    registrationStatus: registration?.status || null,
    waitlistStatus: waitlist?.status || null,
  };
}

function serializeEvent(req, event) {
  const plain = event.get({ plain: true });
  const registeredCount = Number(plain.registeredCount || 0);
  const waitlistCount = Number(plain.waitlistCount || 0);
  const participation = participationFor(plain);
  const registrationClosed = registrationIsClosed(plain);
  const waitlistAvailable = plain.status === 'published'
    && !registrationClosed
    && new Date(plain.endDateTime) > new Date()
    && plain.waitlistEnabled
    && Number(plain.waitlistCapacity) > 0
    && registeredCount >= Number(plain.capacity)
    && waitlistCount < Number(plain.waitlistCapacity)
    && !participation.registered
    && !participation.waitlisted;
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
    registrationDeadline: registrationDeadlineFor(plain),
    registrationClosed,
    capacity: Number(plain.capacity),
    registeredCount,
    seatsLeft: Math.max(0, Number(plain.capacity) - registeredCount),
    waitlistCapacity: Number(plain.waitlistCapacity || 0),
    waitlistCount,
    available: plain.status === 'published' && plain.registrationOpen && !registrationClosed && registeredCount < Number(plain.capacity),
    waitlistAvailable,
    status: plain.status,
    heroImageUrl: publicUrl(req, plain.heroImageUrl),
    price: Number(plain.price || 0),
    dressCode: plain.dressCode,
    ageRange: plain.minAge == null && plain.maxAge == null ? null : `${plain.minAge || 18}-${plain.maxAge || 'any'}`,
    language: plain.language,
    agenda: Array.isArray(plain.agenda) ? plain.agenda : [],
    facilities: Array.isArray(plain.facilities) ? plain.facilities : [],
    interests: Array.isArray(plain.interests) ? plain.interests : [],
    organizer: plain.organizer ? {
      id: String(plain.organizer.id),
      name: plain.organizer.name,
      verified: Boolean(plain.organizer.identityVerifiedAt),
      imageUrl: (() => {
        const photos = Array.isArray(plain.organizer.OnboardingProfile?.photos)
          ? plain.organizer.OnboardingProfile.photos
          : [];
        const primaryPhotoIndex = Number(plain.organizer.OnboardingProfile?.primaryPhotoIndex || 0);
        return publicUrl(req, photos[primaryPhotoIndex] || photos[0] || null);
      })(),
    } : null,
    participation,
  };
}

module.exports = {
  ACTIVE_REGISTRATION_STATUSES,
  EventServiceError,
  registrationDeadlineFor,
  registrationIsClosed,
  countAttributes,
  eligibilitySql,
  participationIncludes,
  serializeEvent,
  userMeetsEligibility,
};
