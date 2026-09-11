const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');
const { getModels } = require('../models');
const { conversationAccess } = require('../services/conversationAccessService');
const { areUsersBlocked } = require('../services/accessControlService');
const { activeMatch } = require('../services/conversationAccessService');
const { corsOrigin } = require('../config/originPolicy');

let io;
const connections = new Map();

const userRoom = (userId) => `user:${Number(userId)}`;
const conversationRoom = (conversationId) => `conversation:${Number(conversationId)}`;
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

function emitAdminEvent(eventName, payload = {}, requiredPermission = null) {
  if (!io) return;
  const eventId = `evt_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  const enrichedPayload = {
    eventId,
    timestamp: new Date().toISOString(),
    event: eventName,
    data: payload,
  };
  if (requiredPermission) {
    io.to(`admin:perm:${requiredPermission}`).emit(eventName, enrichedPayload);
  } else {
    io.to('admin:all').emit(eventName, enrichedPayload);
  }
}

function attachRealtimeServer(httpServer) {
  if (io) return io;
  io = new Server(httpServer, {
    cors: { origin: corsOrigin, credentials: true },
    transports: ['websocket', 'polling'],
  });
  io.use(async (socket, next) => {
    try {
      const rawToken = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace(/^Bearer\s+/i, '');
      if (!rawToken) throw new Error('Token missing.');

      // 1. Check if token is Admin access token
      if (process.env.ADMIN_JWT_SECRET) {
        try {
          const adminPayload = jwt.verify(rawToken, process.env.ADMIN_JWT_SECRET);
          if (adminPayload.typ === 'admin_access') {
            const { Administrator, AdminRole, AdminPermission } = getModels();
            const admin = await Administrator.findByPk(adminPayload.sub, {
              include: [{
                model: AdminRole,
                as: 'roles',
                where: { isActive: true },
                required: false,
                include: [{ model: AdminPermission, as: 'permissions' }],
              }],
            });
            if (admin && admin.status === 'active') {
              socket.data.isAdmin = true;
              socket.data.adminId = Number(admin.id);
              const perms = new Set((admin.roles || []).flatMap((r) => (r.permissions || []).map((p) => p.key)));
              socket.data.permissions = perms;
              return next();
            }
          }
        } catch (_) {
          // Not an admin token, fall through to user token verification
        }
      }

      // 2. User token verification
      const payload = jwt.verify(rawToken, process.env.JWT_SECRET);
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
    if (socket.data.isAdmin) {
      socket.join('admin:all');
      if (socket.data.permissions) {
        for (const perm of socket.data.permissions) {
          socket.join(`admin:perm:${perm}`);
        }
      }
      return;
    }

    const userId = socket.data.userId;
    await getModels().User.update({ lastActiveAt: new Date() }, { where: { id: userId } });
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
    socket.on('disconnect', async () => {
      if (socket.data.isAdmin) return;
      const remaining = Math.max(0, (connections.get(userId) || 1) - 1);
      if (remaining) connections.set(userId, remaining); else connections.delete(userId);
      if (remaining === 0) await emitPresence(userId, false);
      await getModels().User.update({ lastActiveAt: new Date() }, { where: { id: userId } });
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

module.exports = { attachRealtimeServer, closeRealtimeServer, emitConversationEvent, emitAdminEvent, isUserOnline };
