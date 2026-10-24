const jwt = require('jsonwebtoken');
const { Server } = require('socket.io');
const { getModels } = require('../models');
const { conversationAccess } = require('../services/conversationAccessService');
const { areUsersBlocked } = require('../services/accessControlService');
const { isSessionCurrent } = require('../policies/accountStatusPolicy');
const { activeMatch } = require('../services/conversationAccessService');
const { corsOrigin } = require('../config/originPolicy');
const { authenticateAccessToken } = require('../services/adminAuthService');
const logger = require('../utils/logger');

let io;
class LocalConnectionRegistry {
  constructor() { this.counts = new Map(); }
  count(userId) { return this.counts.get(Number(userId)) || 0; }
  connect(userId) { const before = this.count(userId); this.counts.set(Number(userId), before + 1); return before; }
  disconnect(userId) { const remaining = Math.max(0, this.count(userId) - 1); if (remaining) this.counts.set(Number(userId), remaining); else this.counts.delete(Number(userId)); return remaining; }
  clear() { this.counts.clear(); }
  size() { return [...this.counts.values()].reduce((sum, count) => sum + count, 0); }
}
const connections = new LocalConnectionRegistry();

const userRoom = (userId) => `user:${Number(userId)}`;
const conversationRoom = (conversationId) => `conversation:${Number(conversationId)}`;
const isUserOnline = (userId) => connections.count(userId) > 0;

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

async function emitAdminEvent(eventName, payload = {}, requiredPermission = null) {
  if (!io || !requiredPermission) return;
  const eventId = `evt_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  const enrichedPayload = {
    eventId,
    timestamp: new Date().toISOString(),
    event: eventName,
    data: payload,
  };
  for (const socket of io.sockets.sockets.values()) {
    if (!socket.data.isAdmin) continue;
    try {
      const access = await authenticateAccessToken(socket.data.adminAccessToken);
      socket.data.permissions = access.permissions;
      if (access.permissions.has(requiredPermission)) socket.emit(eventName, enrichedPayload);
    } catch (error) {
      socket.disconnect(true);
      logger.warn('Revoked or invalid administrator realtime session disconnected.', {
        adminId: socket.data.adminId,
        code: error.code || 'AUTHENTICATION_FAILED',
      });
    }
  }
}

function attachRealtimeServer(httpServer, { adapter } = {}) {
  if (io) return io;
  io = new Server(httpServer, {
    cors: { origin: corsOrigin, credentials: true },
    transports: ['websocket', 'polling'],
  });
  if (adapter) io.adapter(adapter);
  io.use(async (socket, next) => {
    try {
      const rawToken = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace(/^Bearer\s+/i, '');
      if (!rawToken) throw new Error('Token missing.');

      const decoded = jwt.decode(rawToken);
      if (decoded?.typ === 'admin_access') {
        const access = await authenticateAccessToken(rawToken);
        socket.data.isAdmin = true;
        socket.data.adminId = Number(access.administrator.id);
        socket.data.adminAccessToken = rawToken;
        socket.data.permissions = access.permissions;
        return next();
      }

      // 2. User token verification
      const payload = jwt.verify(rawToken, process.env.JWT_SECRET);
      const { User } = getModels();
      const user = await User.findByPk(payload.sub, { attributes: ['id', 'accountStatus', 'tokenVersion'] });
      if (!isSessionCurrent(user, payload)) throw new Error('Realtime session is unavailable.');
      socket.data.userId = Number(user.id);
      next();
    } catch (_) {
      next(new Error('AUTHENTICATION_FAILED'));
    }
  });
  io.on('connection', async (socket) => {
    if (socket.data.isAdmin) {
      if (socket.data.permissions) {
        for (const perm of socket.data.permissions) {
          socket.join(`admin:perm:${perm}`);
        }
      }
      socket.use(async (_packet, next) => {
        try {
          const access = await authenticateAccessToken(socket.data.adminAccessToken);
          socket.data.permissions = access.permissions;
          return next();
        } catch (_) {
          socket.disconnect(true);
          return next(new Error('AUTHENTICATION_FAILED'));
        }
      });
      return;
    }

    const userId = socket.data.userId;
    await getModels().User.update({ lastActiveAt: new Date() }, { where: { id: userId } });
    socket.join(userRoom(userId));
    const previous = connections.connect(userId);
    if (previous === 0) await emitPresence(userId, true);
    socket.on('conversation.subscribe', async (value, acknowledge) => {
      try {
        const conversationId = Number(value?.conversationId);
        if (!conversationId || !(await conversationAccess(conversationId, userId))) throw new Error('Conversation unavailable.');
        const room = conversationRoom(conversationId);
        if (!socket.rooms.has(room)) await socket.join(room);
        if (typeof acknowledge === 'function') acknowledge({ success: true });
      } catch (_) {
        if (typeof acknowledge === 'function') acknowledge({ success: false, code: 'CONVERSATION_NOT_AVAILABLE' });
      }
    });
    socket.on('disconnect', async () => {
      if (socket.data.isAdmin) return;
      const remaining = connections.disconnect(userId);
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

function realtimeMetrics() { return { localSocketConnections: connections.size() }; }
module.exports = { attachRealtimeServer, closeRealtimeServer, emitConversationEvent, emitAdminEvent, isUserOnline, realtimeMetrics, LocalConnectionRegistry };
