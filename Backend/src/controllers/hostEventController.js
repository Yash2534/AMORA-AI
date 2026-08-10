const { getModels } = require('../models');
const { countAttributes, participationIncludes, serializeEvent } = require('../services/eventService');

const ok = (res, message, data, status = 200) => res.status(status).json({ success: true, message, data });
const fail = (res, status, message, code) => res.status(status).json({ success: false, message, code, errors: [] });

function requireHost(req, res) {
  if (!['host', 'admin'].includes(req.authUser.role)) {
    fail(res, 403, 'Host access is required.', 'HOST_ACCESS_REQUIRED');
    return false;
  }
  return true;
}

function eventValues(body) {
  return {
    title: body.title,
    description: body.description,
    category: body.category,
    city: body.city,
    venueName: body.venueName,
    address: body.address ?? null,
    latitude: body.latitude ?? null,
    longitude: body.longitude ?? null,
    startDateTime: body.startDateTime,
    endDateTime: body.endDateTime,
    capacity: body.capacity,
    waitlistCapacity: body.waitlistCapacity ?? 0,
    status: body.status ?? 'draft',
    visibility: body.visibility ?? 'public',
    registrationOpen: body.registrationOpen ?? true,
    waitlistEnabled: body.waitlistEnabled ?? true,
    heroImageUrl: body.heroImageUrl ?? null,
    price: body.price ?? 0,
    dressCode: body.dressCode ?? null,
    minAge: body.minAge ?? null,
    maxAge: body.maxAge ?? null,
    language: body.language ?? null,
    agenda: body.agenda ?? [],
    facilities: body.facilities ?? [],
    interests: body.interests ?? [],
    checkInOpensAt: body.checkInOpensAt ?? null,
    checkInClosesAt: body.checkInClosesAt ?? null,
  };
}

exports.dashboard = async (req, res, next) => {
  try {
    if (!requireHost(req, res)) return;
    const { Event } = getModels();
    const where = req.authUser.role === 'admin' ? {} : { hostId: req.authUser.id };
    const events = await Event.findAll({
      where,
      attributes: countAttributes(),
      include: participationIncludes(Number(req.user.sub)),
      order: [['startDateTime', 'DESC'], ['id', 'DESC']],
      limit: 100,
    });
    return ok(res, 'Host dashboard loaded.', { events: events.map((event) => serializeEvent(event, { host: true })) });
  } catch (error) { return next(error); }
};

exports.create = async (req, res, next) => {
  try {
    if (!requireHost(req, res)) return;
    if (new Date(req.body.endDateTime) <= new Date(req.body.startDateTime)) return fail(res, 400, 'Event end time must be after its start time.', 'VALIDATION_ERROR');
    if (req.body.minAge != null && req.body.maxAge != null && req.body.minAge > req.body.maxAge) return fail(res, 400, 'Minimum age cannot exceed maximum age.', 'VALIDATION_ERROR');
    const { Event } = getModels();
    const event = await Event.create({ ...eventValues(req.body), hostId: Number(req.user.sub) });
    const loaded = await Event.findByPk(event.id, { attributes: countAttributes(), include: participationIncludes(Number(req.user.sub)) });
    return ok(res, 'Event created.', { event: serializeEvent(loaded, { host: true }) }, 201);
  } catch (error) { return next(error); }
};

exports.update = async (req, res, next) => {
  try {
    if (!requireHost(req, res)) return;
    const { Event, EventRegistration } = getModels();
    const event = await Event.findByPk(req.params.eventId);
    if (!event || (req.authUser.role !== 'admin' && Number(event.hostId) !== Number(req.user.sub))) return fail(res, 404, 'Event not found.', 'EVENT_NOT_FOUND');
    const next = { ...event.get({ plain: true }), ...req.body };
    if (new Date(next.endDateTime) <= new Date(next.startDateTime)) return fail(res, 400, 'Event end time must be after its start time.', 'VALIDATION_ERROR');
    if (next.minAge != null && next.maxAge != null && Number(next.minAge) > Number(next.maxAge)) return fail(res, 400, 'Minimum age cannot exceed maximum age.', 'VALIDATION_ERROR');
    const allowedTransitions = {
      draft: ['draft', 'published', 'cancelled'],
      published: ['published', 'completed', 'cancelled'],
      cancelled: ['cancelled'],
      completed: ['completed'],
    };
    if (req.body.status && !allowedTransitions[event.status].includes(req.body.status)) return fail(res, 409, 'This event status transition is not allowed.', 'EVENT_STATUS_TRANSITION_NOT_ALLOWED');
    if (req.body.capacity != null || req.body.startDateTime != null || req.body.endDateTime != null) {
      const registeredCount = await EventRegistration.count({ where: { eventId: event.id, status: ['registered', 'promoted'] } });
      if (Number(req.body.capacity) < registeredCount) return fail(res, 409, 'Capacity cannot be lower than current registrations.', 'CAPACITY_BELOW_REGISTRATIONS');
      if (registeredCount > 0 && new Date(next.endDateTime) <= new Date()) return fail(res, 409, 'Dates cannot move a registered event into the past.', 'EVENT_DATE_CHANGE_NOT_ALLOWED');
    }
    const allowed = eventValues(next);
    await event.update(allowed);
    const loaded = await Event.findByPk(event.id, { attributes: countAttributes(), include: participationIncludes(Number(req.user.sub)) });
    return ok(res, 'Event updated.', { event: serializeEvent(loaded, { host: true }) });
  } catch (error) { return next(error); }
};
