const { Op, literal } = require('sequelize');
const { getModels } = require('../models');
const {
  ACTIVE_REGISTRATION_STATUSES,
  EventServiceError,
  countAttributes,
  eligibilitySql,
  participationIncludes,
  serializeEvent,
  userMeetsEligibility,
} = require('../services/eventService');

const ok = (res, message, data, status = 200) => res.status(status).json({ success: true, message, data });
const fail = (res, status, message, code) => res.status(status).json({ success: false, message, code, errors: [] });
const activeRegistrationWhere = { status: ACTIVE_REGISTRATION_STATUSES };

function handleError(error, res, next) {
  if (error instanceof EventServiceError) return fail(res, error.status, error.message, error.code);
  return next(error);
}

function eventWhere(query, userId) {
  const now = new Date();
  const where = {
    visibility: 'public',
    status: { [Op.in]: ['published', 'completed'] },
    [Op.and]: [eligibilitySql(userId)],
  };
  if (query.search) {
    const pattern = `%${query.search.trim()}%`;
    where[Op.or] = ['title', 'description', 'category', 'city', 'venueName'].map((field) => ({ [field]: { [Op.like]: pattern } }));
  }
  if (query.category) where.category = query.category;
  if (query.city) where.city = query.city;
  if (query.dateFrom || query.dateTo) {
    where.startDateTime = {};
    if (query.dateFrom) where.startDateTime[Op.gte] = new Date(query.dateFrom);
    if (query.dateTo) where.startDateTime[Op.lte] = new Date(query.dateTo);
  }
  if (query.timing === 'past' || query.past === true) where.endDateTime = { [Op.lt]: now };
  else if (query.timing !== 'all') where.endDateTime = { [Op.gte]: now };
  if (query.available === true) {
    where.registrationOpen = true;
    where[Op.and].push(literal(`(SELECT COUNT(*) FROM \`EventRegistrations\` availabilityRegistration WHERE availabilityRegistration.eventId = \`Event\`.\`id\` AND availabilityRegistration.status IN ('registered','promoted')) < \`Event\`.\`capacity\``));
  }
  return where;
}

exports.list = async (req, res, next) => {
  try {
    const { Event } = getModels();
    const userId = Number(req.user.sub);
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const result = await Event.findAndCountAll({
      where: eventWhere(req.query, userId),
      attributes: countAttributes(),
      include: participationIncludes(userId),
      order: [['startDateTime', 'ASC'], ['id', 'ASC']],
      limit,
      offset: (page - 1) * limit,
      distinct: true,
    });
    const total = Number(result.count);
    return ok(res, 'Events loaded.', { events: result.rows.map(serializeEvent), pagination: { page, limit, total, hasMore: page * limit < total, nextPage: page * limit < total ? page + 1 : null } });
  } catch (error) { return next(error); }
};

exports.detail = async (req, res, next) => {
  try {
    const { Event } = getModels();
    const userId = Number(req.user.sub);
    const event = await Event.findOne({
      where: { id: req.params.eventId, visibility: 'public', status: { [Op.in]: ['published', 'completed', 'cancelled'] }, [Op.and]: [eligibilitySql(userId)] },
      attributes: countAttributes(),
      include: participationIncludes(userId),
    });
    if (!event) return fail(res, 404, 'Event not found.', 'EVENT_NOT_FOUND');
    return ok(res, 'Event loaded.', { event: serializeEvent(event) });
  } catch (error) { return next(error); }
};

async function participationState(eventId, userId) {
  const { EventRegistration, EventWaitlist } = getModels();
  const [registration, waitlist] = await Promise.all([
    EventRegistration.findOne({ where: { eventId, userId } }),
    EventWaitlist.findOne({ where: { eventId, userId } }),
  ]);
  return {
    registered: Boolean(registration && ACTIVE_REGISTRATION_STATUSES.includes(registration.status)),
    waitlisted: waitlist?.status === 'waiting',
    registrationStatus: registration?.status || null,
    waitlistStatus: waitlist?.status || null,
  };
}

exports.register = async (req, res, next) => {
  try {
    const { Event, EventRegistration, EventWaitlist } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    await Event.sequelize.transaction(async (transaction) => {
      const event = await Event.findOne({ where: { id: eventId, visibility: 'public' }, transaction, lock: transaction.LOCK.UPDATE });
      if (!event) throw new EventServiceError(404, 'EVENT_NOT_FOUND', 'Event not found.');
      if (!(await userMeetsEligibility(userId, event, { transaction }))) throw new EventServiceError(403, 'EVENT_NOT_ELIGIBLE', 'This event is not available for your profile.');
      if (event.status !== 'published' || !event.registrationOpen || new Date(event.endDateTime) <= new Date()) throw new EventServiceError(409, 'EVENT_REGISTRATION_CLOSED', 'Registration is closed for this event.');
      const existing = await EventRegistration.findOne({ where: { eventId, userId }, transaction, lock: transaction.LOCK.UPDATE });
      if (existing && ACTIVE_REGISTRATION_STATUSES.includes(existing.status)) return;
      const waiting = await EventWaitlist.findOne({ where: { eventId, userId, status: 'waiting' }, transaction, lock: transaction.LOCK.UPDATE });
      if (waiting) throw new EventServiceError(409, 'ALREADY_WAITLISTED', 'Leave the waitlist before registering.');
      const registeredCount = await EventRegistration.count({ where: { eventId, ...activeRegistrationWhere }, transaction });
      if (registeredCount >= Number(event.capacity)) throw new EventServiceError(409, 'EVENT_FULL', 'This event is full. You may join its waitlist.');
      const values = { status: 'registered', registeredAt: new Date(), cancelledAt: null };
      if (existing) await existing.update(values, { transaction });
      else await EventRegistration.create({ eventId, userId, ...values }, { transaction });
    });
    return ok(res, 'Event registration confirmed.', { participation: await participationState(eventId, userId) }, 201);
  } catch (error) { return handleError(error, res, next); }
};

exports.cancelRegistration = async (req, res, next) => {
  try {
    const { Event, EventRegistration } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    let promotedUserId = null;
    await Event.sequelize.transaction(async (transaction) => {
      const event = await Event.findByPk(eventId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!event) throw new EventServiceError(404, 'EVENT_NOT_FOUND', 'Event not found.');
      const registration = await EventRegistration.findOne({ where: { eventId, userId }, transaction, lock: transaction.LOCK.UPDATE });
      if (!registration || !ACTIVE_REGISTRATION_STATUSES.includes(registration.status)) return;
      await registration.update({ status: 'cancelled', cancelledAt: new Date() }, { transaction });
      if (event.status === 'published' && event.registrationOpen && new Date(event.endDateTime) > new Date()) {
        promotedUserId = await promoteNextWaitlisted(event, transaction);
      }
    });
    return ok(res, 'Event registration cancelled.', { participation: await participationState(eventId, userId), promoted: Boolean(promotedUserId) });
  } catch (error) { return handleError(error, res, next); }
};

async function promoteNextWaitlisted(event, transaction) {
  const { EventRegistration, EventWaitlist, User } = getModels();
  while (true) {
    const entry = await EventWaitlist.findOne({
      where: { eventId: event.id, status: 'waiting' },
      order: [['joinedAt', 'ASC'], ['id', 'ASC']],
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!entry) return null;
    const user = await User.findOne({ where: { id: entry.userId, accountStatus: 'active' }, transaction });
    if (!user || !(await userMeetsEligibility(entry.userId, event, { transaction }))) {
      await entry.update({ status: 'left', endedAt: new Date() }, { transaction });
      continue;
    }
    const existing = await EventRegistration.findOne({ where: { eventId: event.id, userId: entry.userId }, transaction, lock: transaction.LOCK.UPDATE });
    const values = { status: 'promoted', registeredAt: new Date(), cancelledAt: null };
    if (existing) await existing.update(values, { transaction });
    else await EventRegistration.create({ eventId: event.id, userId: entry.userId, ...values }, { transaction });
    await entry.update({ status: 'promoted', endedAt: new Date() }, { transaction });
    return entry.userId;
  }
}

exports.joinWaitlist = async (req, res, next) => {
  try {
    const { Event, EventRegistration, EventWaitlist } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    await Event.sequelize.transaction(async (transaction) => {
      const event = await Event.findOne({ where: { id: eventId, visibility: 'public' }, transaction, lock: transaction.LOCK.UPDATE });
      if (!event) throw new EventServiceError(404, 'EVENT_NOT_FOUND', 'Event not found.');
      if (!(await userMeetsEligibility(userId, event, { transaction }))) throw new EventServiceError(403, 'EVENT_NOT_ELIGIBLE', 'This event is not available for your profile.');
      if (event.status !== 'published' || !event.waitlistEnabled || Number(event.waitlistCapacity) < 1 || new Date(event.endDateTime) <= new Date()) {
        throw new EventServiceError(409, 'WAITLIST_CLOSED', 'The waitlist is not available.');
      }
      const registration = await EventRegistration.findOne({ where: { eventId, userId, ...activeRegistrationWhere }, transaction });
      if (registration) throw new EventServiceError(409, 'ALREADY_REGISTERED', 'Registered attendees cannot join the waitlist.');
      const registeredCount = await EventRegistration.count({ where: { eventId, ...activeRegistrationWhere }, transaction });
      if (registeredCount < Number(event.capacity)) throw new EventServiceError(409, 'EVENT_HAS_CAPACITY', 'Registration is still available for this event.');
      const existing = await EventWaitlist.findOne({ where: { eventId, userId }, transaction, lock: transaction.LOCK.UPDATE });
      if (existing?.status === 'waiting') return;
      const waitingCount = await EventWaitlist.count({ where: { eventId, status: 'waiting' }, transaction });
      if (waitingCount >= Number(event.waitlistCapacity)) throw new EventServiceError(409, 'WAITLIST_FULL', 'The waitlist is full.');
      const values = { status: 'waiting', joinedAt: new Date(), endedAt: null };
      if (existing) await existing.update(values, { transaction });
      else await EventWaitlist.create({ eventId, userId, ...values }, { transaction });
    });
    return ok(res, 'You joined the event waitlist.', { participation: await participationState(eventId, userId) }, 201);
  } catch (error) { return handleError(error, res, next); }
};

exports.leaveWaitlist = async (req, res, next) => {
  try {
    const { EventWaitlist } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    const entry = await EventWaitlist.findOne({ where: { eventId, userId } });
    if (entry?.status === 'waiting') await entry.update({ status: 'left', endedAt: new Date() });
    return ok(res, 'You left the event waitlist.', { participation: await participationState(eventId, userId) });
  } catch (error) { return next(error); }
};

function myEventsWhere(userId, category) {
  const id = Number(userId);
  const registration = `EXISTS (SELECT 1 FROM \`EventRegistrations\` mineRegistration WHERE mineRegistration.eventId = \`Event\`.\`id\` AND mineRegistration.userId = ${id})`;
  const waitlist = `EXISTS (SELECT 1 FROM \`EventWaitlist\` mineWaitlist WHERE mineWaitlist.eventId = \`Event\`.\`id\` AND mineWaitlist.userId = ${id})`;
  let relation = `${registration} OR ${waitlist}`;
  if (category === 'upcoming') relation = `EXISTS (SELECT 1 FROM \`EventRegistrations\` mineRegistration WHERE mineRegistration.eventId = \`Event\`.\`id\` AND mineRegistration.userId = ${id} AND mineRegistration.status IN ('registered','promoted')) AND \`Event\`.\`endDateTime\` >= UTC_TIMESTAMP() AND \`Event\`.\`status\` <> 'cancelled'`;
  if (category === 'past') relation = `EXISTS (SELECT 1 FROM \`EventRegistrations\` mineRegistration WHERE mineRegistration.eventId = \`Event\`.\`id\` AND mineRegistration.userId = ${id} AND mineRegistration.status IN ('registered','promoted')) AND (\`Event\`.\`endDateTime\` < UTC_TIMESTAMP() OR \`Event\`.\`status\` = 'completed')`;
  if (category === 'waitlist') relation = `EXISTS (SELECT 1 FROM \`EventWaitlist\` mineWaitlist WHERE mineWaitlist.eventId = \`Event\`.\`id\` AND mineWaitlist.userId = ${id} AND mineWaitlist.status = 'waiting')`;
  if (category === 'cancelled') relation = `EXISTS (SELECT 1 FROM \`EventRegistrations\` mineRegistration WHERE mineRegistration.eventId = \`Event\`.\`id\` AND mineRegistration.userId = ${id} AND mineRegistration.status = 'cancelled')`;
  return literal(`(${relation})`);
}

exports.myEvents = async (req, res, next) => {
  try {
    const { Event } = getModels();
    const userId = Number(req.user.sub);
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const category = req.query.category || 'all';
    const result = await Event.findAndCountAll({
      where: { [Op.and]: [myEventsWhere(userId, category)] },
      attributes: countAttributes(),
      include: participationIncludes(userId),
      order: [['startDateTime', category === 'past' ? 'DESC' : 'ASC'], ['id', 'ASC']],
      limit,
      offset: (page - 1) * limit,
      distinct: true,
    });
    const total = Number(result.count);
    return ok(res, 'Your events loaded.', { category, events: result.rows.map(serializeEvent), pagination: { page, limit, total, hasMore: page * limit < total, nextPage: page * limit < total ? page + 1 : null } });
  } catch (error) { return next(error); }
};
