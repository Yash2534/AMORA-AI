const { Op, literal } = require('sequelize');
const { getModels } = require('../models');
const {
  ACTIVE_REGISTRATION_STATUSES,
  EventServiceError,
  countAttributes,
  eligibilitySql,
  eventGroupAccess,
  participationIncludes,
  serializeEvent,
  userMeetsEligibility,
} = require('../services/eventService');
const { emitEventGroupMessage } = require('../realtime/realtimeHub');
const { saveFeedbackMedia, removeFeedbackMedia } = require('../utils/eventFeedbackMediaStorage');

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
  else if (query.timing === 'all') { /* retain both published and completed */ }
  else where.endDateTime = { [Op.gte]: now };
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
    return ok(res, 'Events loaded.', {
      events: result.rows.map((event) => serializeEvent(event)),
      pagination: { page, limit, total, hasMore: page * limit < total, nextPage: page * limit < total ? page + 1 : null },
    });
  } catch (error) { return next(error); }
};

exports.detail = async (req, res, next) => {
  try {
    const { Event } = getModels();
    const userId = Number(req.user.sub);
    const event = await Event.findOne({
      where: {
        id: req.params.eventId,
        [Op.or]: [
          { visibility: 'public', status: { [Op.in]: ['published', 'completed', 'cancelled'] } },
          { hostId: userId },
        ],
        [Op.and]: [eligibilitySql(userId)],
      },
      attributes: countAttributes(),
      include: participationIncludes(userId),
    });
    if (!event) return fail(res, 404, 'Event not found.', 'EVENT_NOT_FOUND');
    return ok(res, 'Event loaded.', { event: serializeEvent(event) });
  } catch (error) { return next(error); }
};

exports.register = async (req, res, next) => {
  try {
    const { Event, EventRegistration, EventWaitlist } = getModels();
    const userId = Number(req.user.sub);
    let eventId = Number(req.params.eventId);
    await Event.sequelize.transaction(async (transaction) => {
      const event = await Event.findByPk(eventId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!event || (event.visibility !== 'public' && Number(event.hostId) !== userId)) throw new EventServiceError(404, 'EVENT_NOT_FOUND', 'Event not found.');
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
    const state = await participationState(eventId, userId);
    return ok(res, 'Event registration confirmed.', { participation: state }, 201);
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
      if (!registration || registration.status === 'cancelled') return;
      await registration.update({ status: 'cancelled', cancelledAt: new Date() }, { transaction });
      if (event.status === 'published' && event.registrationOpen && new Date(event.endDateTime) > new Date()) promotedUserId = await promoteNextWaitlisted(event, transaction);
    });
    return ok(res, 'Event registration cancelled.', { participation: await participationState(eventId, userId), promoted: Boolean(promotedUserId) });
  } catch (error) { return handleError(error, res, next); }
};

exports.joinWaitlist = async (req, res, next) => {
  try {
    const { Event, EventRegistration, EventWaitlist } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    await Event.sequelize.transaction(async (transaction) => {
      const event = await Event.findByPk(eventId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!event || (event.visibility !== 'public' && Number(event.hostId) !== userId)) throw new EventServiceError(404, 'EVENT_NOT_FOUND', 'Event not found.');
      if (!(await userMeetsEligibility(userId, event, { transaction }))) throw new EventServiceError(403, 'EVENT_NOT_ELIGIBLE', 'This event is not available for your profile.');
      if (event.status !== 'published' || !event.waitlistEnabled || Number(event.waitlistCapacity) < 1 || new Date(event.endDateTime) <= new Date()) throw new EventServiceError(409, 'WAITLIST_CLOSED', 'The waitlist is not available.');
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
  const active = `'registered','promoted'`;
  const registration = `EXISTS (SELECT 1 FROM \`EventRegistrations\` mineRegistration WHERE mineRegistration.eventId = \`Event\`.\`id\` AND mineRegistration.userId = ${userId}`;
  const waitlist = `EXISTS (SELECT 1 FROM \`EventWaitlist\` mineWaitlist WHERE mineWaitlist.eventId = \`Event\`.\`id\` AND mineWaitlist.userId = ${userId}`;
  let relation = `(${registration}) OR ${waitlist}))`;
  if (category === 'upcoming') relation = `${registration} AND mineRegistration.status IN (${active})) AND \`Event\`.\`endDateTime\` >= UTC_TIMESTAMP() AND \`Event\`.\`status\` <> 'cancelled'`;
  if (category === 'past') relation = `${registration} AND mineRegistration.status IN (${active})) AND (\`Event\`.\`endDateTime\` < UTC_TIMESTAMP() OR \`Event\`.\`status\` = 'completed')`;
  if (category === 'waitlist') relation = `${waitlist} AND mineWaitlist.status = 'waiting')`;
  if (category === 'cancelled') relation = `(${registration} AND mineRegistration.status = 'cancelled') OR \`Event\`.\`status\` = 'cancelled')`;
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
    return ok(res, 'Your events loaded.', {
      category,
      events: result.rows.map((event) => serializeEvent(event)),
      pagination: { page, limit, total, hasMore: page * limit < total, nextPage: page * limit < total ? page + 1 : null },
    });
  } catch (error) { return next(error); }
};

async function participationState(eventId, userId) {
  const { EventRegistration, EventWaitlist, EventCheckIn } = getModels();
  const [registration, waitlist, checkIn] = await Promise.all([
    EventRegistration.findOne({ where: { eventId, userId } }),
    EventWaitlist.findOne({ where: { eventId, userId } }),
    EventCheckIn.findOne({ where: { eventId, userId } }),
  ]);
  return {
    registered: Boolean(registration && ACTIVE_REGISTRATION_STATUSES.includes(registration.status)),
    waitlisted: waitlist?.status === 'waiting',
    checkedIn: Boolean(checkIn),
    registrationStatus: registration?.status || null,
    waitlistStatus: waitlist?.status || null,
  };
}

exports.checkIn = async (req, res, next) => {
  try {
    const { Event, EventRegistration, EventCheckIn } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    await Event.sequelize.transaction(async (transaction) => {
      const event = await Event.findByPk(eventId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!event) throw new EventServiceError(404, 'EVENT_NOT_FOUND', 'Event not found.');
      const registration = await EventRegistration.findOne({ where: { eventId, userId, ...activeRegistrationWhere }, transaction });
      if (!registration) throw new EventServiceError(403, 'REGISTRATION_REQUIRED', 'A valid registration is required to check in.');
      const now = new Date();
      const opens = event.checkInOpensAt ? new Date(event.checkInOpensAt) : new Date(new Date(event.startDateTime).getTime() - 2 * 60 * 60 * 1000);
      const closes = event.checkInClosesAt ? new Date(event.checkInClosesAt) : new Date(event.endDateTime);
      if (now < opens || now > closes || event.status === 'cancelled') throw new EventServiceError(409, 'CHECK_IN_CLOSED', 'Check-in is not currently available.');
      await EventCheckIn.findOrCreate({ where: { eventId, userId }, defaults: { checkedInAt: now }, transaction });
    });
    return ok(res, 'Event check-in confirmed.', { participation: await participationState(eventId, userId) });
  } catch (error) { return handleError(error, res, next); }
};

exports.feedback = async (req, res, next) => {
  let savedMedia;
  try {
    const { Event, EventRegistration, EventCheckIn, EventFeedback } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    const event = await Event.findByPk(eventId);
    if (!event) return fail(res, 404, 'Event not found.', 'EVENT_NOT_FOUND');
    if (new Date(event.endDateTime) > new Date() && event.status !== 'completed') return fail(res, 409, 'Feedback opens after the event.', 'FEEDBACK_NOT_OPEN');
    const [registration, checkIn] = await Promise.all([
      EventRegistration.findOne({ where: { eventId, userId, status: ACTIVE_REGISTRATION_STATUSES } }),
      EventCheckIn.findOne({ where: { eventId, userId } }),
    ]);
    if (!registration && !checkIn) return fail(res, 403, 'Only event attendees can submit feedback.', 'FEEDBACK_NOT_ALLOWED');
    const values = {
      rating: req.body.rating,
      venueRating: req.body.venueRating ?? null,
      hostRating: req.body.hostRating ?? null,
      safetyRating: req.body.safetyRating ?? null,
      experienceRating: req.body.experienceRating ?? null,
      feedbackText: req.body.feedbackText || null,
      recommend: req.body.recommend ?? true,
    };
    savedMedia = await saveFeedbackMedia(req.file);
    if (savedMedia) Object.assign(values, savedMedia);
    const [feedback, created] = await EventFeedback.findOrCreate({ where: { eventId, userId }, defaults: values });
    if (!created) {
      const previousMedia = feedback.mediaStoragePath;
      await feedback.update(values);
      if (savedMedia && previousMedia && previousMedia !== savedMedia.mediaStoragePath) await removeFeedbackMedia(previousMedia);
    }
    return ok(res, 'Event feedback saved.', { feedback: { id: String(feedback.id), rating: feedback.rating } }, created ? 201 : 200);
  } catch (error) {
    if (savedMedia?.mediaStoragePath) await removeFeedbackMedia(savedMedia.mediaStoragePath);
    if (error.code === 'INVALID_MEDIA_TYPE') return fail(res, 400, error.message, 'INVALID_MEDIA_TYPE');
    return next(error);
  }
};

function serializeGroupMessage(message) {
  const plain = message.get({ plain: true });
  return {
    id: String(plain.id), eventId: String(plain.eventId), type: plain.type, text: plain.text,
    createdAt: plain.createdAt,
    sender: plain.sender ? { id: String(plain.sender.id), name: plain.sender.name, verified: Boolean(plain.sender.identityVerifiedAt) } : null,
  };
}

exports.groupMessages = async (req, res, next) => {
  try {
    const { EventGroupMessage, User } = getModels();
    const eventId = Number(req.params.eventId);
    if (!(await eventGroupAccess(eventId, Number(req.user.sub)))) return fail(res, 403, 'Event group chat is unavailable.', 'EVENT_CHAT_NOT_ALLOWED');
    const limit = Number(req.query.limit || 50);
    const where = { eventId };
    if (req.query.beforeId) where.id = { [Op.lt]: Number(req.query.beforeId) };
    const rows = await EventGroupMessage.findAll({
      where,
      include: [{ model: User, as: 'sender', required: true, attributes: ['id', 'name', 'identityVerifiedAt'] }],
      order: [['id', 'DESC']],
      limit: limit + 1,
    });
    const hasMore = rows.length > limit;
    const pageRows = rows.slice(0, limit).reverse();
    return ok(res, 'Event group messages loaded.', { messages: pageRows.map(serializeGroupMessage), pagination: { limit, hasMore, nextBeforeId: hasMore ? String(rows[limit - 1].id) : null } });
  } catch (error) { return next(error); }
};

exports.sendGroupMessage = async (req, res, next) => {
  try {
    const { EventGroupMessage, User } = getModels();
    const eventId = Number(req.params.eventId);
    const userId = Number(req.user.sub);
    const access = await eventGroupAccess(eventId, userId);
    if (!access) return fail(res, 403, 'Event group chat is unavailable.', 'EVENT_CHAT_NOT_ALLOWED');
    if (access.event.status === 'cancelled') return fail(res, 409, 'Messaging is closed for this event.', 'EVENT_CHAT_CLOSED');
    const created = await EventGroupMessage.create({ eventId, senderId: userId, type: 'text', text: req.body.text });
    const message = await EventGroupMessage.findByPk(created.id, { include: [{ model: User, as: 'sender', attributes: ['id', 'name', 'identityVerifiedAt'] }] });
    const payload = serializeGroupMessage(message);
    await emitEventGroupMessage(eventId, 'event.message.created', payload);
    return ok(res, 'Event group message sent.', { message: payload }, 201);
  } catch (error) { return next(error); }
};

module.exports.participationState = participationState;
module.exports.serializeGroupMessage = serializeGroupMessage;
