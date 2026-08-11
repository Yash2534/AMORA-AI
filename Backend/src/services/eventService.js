const { Op, literal } = require('sequelize');
const { getModels } = require('../models');

const ACTIVE_REGISTRATION_STATUSES = ['registered', 'promoted'];

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
  if (Number(event.hostId) === Number(userId)) return true;
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
    OR \`Event\`.\`hostId\` = ${id}
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
  const { EventRegistration, EventWaitlist, EventCheckIn, User } = getModels();
  return [
    { model: User, as: 'host', required: true, where: { accountStatus: 'active' }, attributes: ['id', 'name', 'identityVerifiedAt'] },
    { model: EventRegistration, as: 'registrations', required: false, where: { userId }, attributes: ['status', 'registeredAt', 'cancelledAt'] },
    { model: EventWaitlist, as: 'waitlist', required: false, where: { userId }, attributes: ['status', 'joinedAt', 'endedAt'] },
    { model: EventCheckIn, as: 'checkIns', required: false, where: { userId }, attributes: ['checkedInAt'] },
  ];
}

function countAttributes() {
  return {
    include: [
      [literal(`(SELECT COUNT(*) FROM \`EventRegistrations\` capacityRegistration WHERE capacityRegistration.eventId = \`Event\`.\`id\` AND capacityRegistration.status IN ('registered','promoted'))`), 'registeredCount'],
      [literal(`(SELECT COUNT(*) FROM \`EventWaitlist\` capacityWaitlist WHERE capacityWaitlist.eventId = \`Event\`.\`id\` AND capacityWaitlist.status = 'waiting')`), 'waitlistCount'],
      [literal(`(SELECT COUNT(*) FROM \`EventCheckIns\` capacityCheckIn WHERE capacityCheckIn.eventId = \`Event\`.\`id\`)`), 'checkInCount'],
    ],
  };
}

function participationFor(event) {
  const registration = event.registrations?.[0];
  const waitlist = event.waitlist?.[0];
  return {
    registered: Boolean(registration && ACTIVE_REGISTRATION_STATUSES.includes(registration.status)),
    waitlisted: waitlist?.status === 'waiting',
    checkedIn: Boolean(event.checkIns?.[0]),
    registrationStatus: registration?.status || null,
    waitlistStatus: waitlist?.status || null,
  };
}

function serializeEvent(event, options = {}) {
  const plain = event.get({ plain: true });
  const registeredCount = Number(plain.registeredCount || 0);
  const waitlistCount = Number(plain.waitlistCount || 0);
  const participation = participationFor(plain);
  const data = {
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
    waitlistCapacity: Number(plain.waitlistCapacity),
    waitlistCount,
    available: plain.status === 'published' && plain.registrationOpen && registeredCount < Number(plain.capacity),
    waitlistAvailable: plain.waitlistEnabled && waitlistCount < Number(plain.waitlistCapacity),
    status: plain.status,
    heroImageUrl: plain.heroImageUrl,
    price: Number(plain.price || 0),
    dressCode: plain.dressCode,
    ageRange: plain.minAge == null && plain.maxAge == null ? null : `${plain.minAge || 18}-${plain.maxAge || 'any'}`,
    language: plain.language,
    agenda: Array.isArray(plain.agenda) ? plain.agenda : [],
    facilities: Array.isArray(plain.facilities) ? plain.facilities : [],
    interests: Array.isArray(plain.interests) ? plain.interests : [],
    host: plain.host ? { id: String(plain.host.id), name: plain.host.name, verified: Boolean(plain.host.identityVerifiedAt) } : null,
    participation,
  };
  if (options.host) data.hostMetrics = { checkInCount: Number(plain.checkInCount || 0) };
  return data;
}

async function visibleEvent(eventId, userId, options = {}) {
  const { Event } = getModels();
  const event = await Event.findOne({
    where: {
      id: eventId,
      [Op.or]: [
        { visibility: 'public', status: { [Op.in]: ['published', 'completed', 'cancelled'] } },
        { hostId: userId },
      ],
      [Op.and]: [eligibilitySql(userId)],
    },
    transaction: options.transaction,
    lock: options.lock,
  });
  return event;
}

async function eventGroupAccess(eventId, userId, options = {}) {
  const { Event, EventRegistration, User } = getModels();
  const user = await User.findOne({ where: { id: userId, accountStatus: 'active' }, transaction: options.transaction });
  if (!user) return null;
  const event = await Event.findByPk(eventId, { transaction: options.transaction });
  if (!event) return null;
  if (Number(event.hostId) === Number(userId)) return { event, role: 'host' };
  const registration = await EventRegistration.findOne({
    where: { eventId, userId, status: ACTIVE_REGISTRATION_STATUSES },
    transaction: options.transaction,
  });
  return registration ? { event, role: 'attendee' } : null;
}

module.exports = {
  ACTIVE_REGISTRATION_STATUSES,
  EventServiceError,
  countAttributes,
  eligibilitySql,
  eventGroupAccess,
  participationFor,
  participationIncludes,
  serializeEvent,
  userMeetsEligibility,
  visibleEvent,
};
