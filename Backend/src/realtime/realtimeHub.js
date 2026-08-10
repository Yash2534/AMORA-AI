const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');
const { getModels } = require('../models');
const { conversationAccess } = require('../services/conversationAccessService');
const { areUsersBlocked } = require('../services/accessControlService');
const { activeMatch } = require('../services/conversationAccessService');
const { eventGroupAccess } = require('../services/eventService');

let io;
const connections = new Map();

const userRoom = (userId) => `user:${Number(userId)}`;
const conversationRoom = (conversationId) => `conversation:${Number(conversationId)}`;
const eventRoom = (eventId) => `event:${Number(eventId)}`;
const isUserOnline = (userId) => (connections.get(Number(userId)) || 0) > 0;

async function conversationUserIds(conversationId) {
  const { ConversationParticipant, User, OnboardingProfile } = getModels();
  const rows = await ConversationParticipant.findAll({
    where: { conversationId },
    attributes: ['userId'],
    include: [{
      model: User,
      as: 'user',
      required: true,
      where: { accountStatus: 'active' },
      attributes: [],
      include: [{
        model: OnboardingProfile,
        required: true,
        where: { onboardingCompleted: true },
        attributes: [],
      }],
    }],
  });
  if (
    rows.length !== 2
    || await areUsersBlocked(rows[0].userId, rows[1].userId)
    || !(await activeMatch(rows[0].userId, rows[1].userId))
  ) return [];
  return rows.map((row) => Number(row.userId));
}

async function emitConversationEvent(conversationId, event, payload) {
  if (!io) return;
  const userIds = await conversationUserIds(conversationId);
  for (const userId of userIds) io.to(userRoom(userId)).emit(event, payload);
}

async function emitEventGroupMessage(eventId, event, payload) {
  if (!io) return;
  io.to(eventRoom(eventId)).emit(event, payload);
}

async function emitPresence(userId, online) {
  if (!io) return;
  const { ConversationParticipant } = getModels();
  const memberships = await ConversationParticipant.findAll({ where: { userId }, attributes: ['conversationId'] });
  const recipients = new Set();
  for (const membership of memberships) {
    for (const id of await conversationUserIds(membership.conversationId)) if (id !== Number(userId)) recipients.add(id);
  }
  for (const recipient of recipients) io.to(userRoom(recipient)).emit('presence.updated', { userId: String(userId), online });
}

function attachRealtimeServer(httpServer) {
  if (io) return io;
  io = new Server(httpServer, {
    cors: { origin: process.env.CORS_ORIGIN === '*' || !process.env.CORS_ORIGIN ? '*' : process.env.CORS_ORIGIN.split(',').map((item) => item.trim()) },
    transports: ['websocket', 'polling'],
  });
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      if (payload.purpose !== 'realtime') throw new Error('Invalid realtime purpose.');
      const { User } = getModels();
      const user = await User.findByPk(payload.sub, { attributes: ['id', 'accountStatus', 'tokenVersion'] });
      if (!user || user.accountStatus !== 'active' || Number(payload.ver || 0) !== Number(user.tokenVersion || 0)) throw new Error('Realtime session is unavailable.');
      socket.data.userId = Number(user.id);
      next();
    } catch (_) {
      next(new Error('AUTHENTICATION_FAILED'));
    }
  });
  io.on('connection', async (socket) => {
    const userId = socket.data.userId;
    socket.join(userRoom(userId));
    const previous = connections.get(userId) || 0;
    connections.set(userId, previous + 1);
    if (previous === 0) await emitPresence(userId, true);
    socket.on('conversation.subscribe', async (value, acknowledge) => {
      try {
        const conversationId = Number(value?.conversationId);
        if (!conversationId || !(await conversationAccess(conversationId, userId))) throw new Error('Conversation unavailable.');
        socket.join(conversationRoom(conversationId));
        if (typeof acknowledge === 'function') acknowledge({ success: true });
      } catch (_) {
        if (typeof acknowledge === 'function') acknowledge({ success: false, code: 'CONVERSATION_NOT_AVAILABLE' });
      }
    });
    socket.on('event.subscribe', async (value, acknowledge) => {
      try {
        const eventId = Number(value?.eventId);
        if (!eventId || !(await eventGroupAccess(eventId, userId))) throw new Error('Event chat unavailable.');
        socket.join(eventRoom(eventId));
        if (typeof acknowledge === 'function') acknowledge({ success: true });
      } catch (_) {
        if (typeof acknowledge === 'function') acknowledge({ success: false, code: 'EVENT_CHAT_NOT_ALLOWED' });
      }
    });
    socket.on('disconnect', async () => {
      const remaining = Math.max(0, (connections.get(userId) || 1) - 1);
      if (remaining) connections.set(userId, remaining); else connections.delete(userId);
      if (remaining === 0) await emitPresence(userId, false);
    });
  });
  return io;
}

function closeRealtimeServer() {
  if (!io) return Promise.resolve();
  const current = io;
  io = undefined;
  connections.clear();
  return new Promise((resolve) => current.close(resolve));
}

module.exports = { attachRealtimeServer, closeRealtimeServer, emitConversationEvent, emitEventGroupMessage, isUserOnline };
