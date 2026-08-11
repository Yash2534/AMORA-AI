const { getModels } = require('../models');

const allowedDataFields = ['route', 'targetUserId', 'conversationId', 'eventId', 'imageUrl', 'initials'];

function safeData(value) {
  if (!value || Array.isArray(value) || typeof value !== 'object') return {};
  return Object.fromEntries(allowedDataFields
    .filter((key) => value[key] !== undefined && value[key] !== null)
    .map((key) => [key, value[key]]));
}

function payload(row) {
  return {
    id: String(row.id),
    type: row.type,
    category: row.category,
    title: row.title,
    message: row.message,
    isRead: Boolean(row.isRead),
    readAt: row.readAt,
    createdAt: row.createdAt,
    data: safeData(row.data),
  };
}

const unavailable = (res) => res.status(404).json({
  success: false,
  message: 'Notification is not available.',
  code: 'NOTIFICATION_NOT_FOUND',
  errors: [],
});

exports.list = async (req, res, next) => {
  try {
    const { Notification } = getModels();
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 20);
    const where = { userId: req.user.sub, deletedAt: null };
    if (req.query.unread === 'true') where.isRead = false;
    if (req.query.category) where.category = req.query.category;
    const [rows, unreadCount] = await Promise.all([
      Notification.findAll({
        where,
        order: [['createdAt', 'DESC'], ['id', 'DESC']],
        offset: (page - 1) * limit,
        limit: limit + 1,
      }),
      Notification.count({ where: { userId: req.user.sub, deletedAt: null, isRead: false } }),
    ]);
    const hasMore = rows.length > limit;
    return res.json({
      success: true,
      message: rows.length ? 'Notifications retrieved.' : 'No notifications found.',
      data: {
        notifications: rows.slice(0, limit).map(payload),
        unreadCount,
        pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null },
      },
    });
  } catch (error) { return next(error); }
};

exports.read = async (req, res, next) => {
  try {
    const { Notification } = getModels();
    const row = await Notification.findOne({
      where: { id: req.params.notificationId, userId: req.user.sub, deletedAt: null },
    });
    if (!row) return unavailable(res);
    if (!row.isRead) {
      await row.update({ isRead: true, readAt: new Date() });
      await row.reload();
    }
    const unreadCount = await Notification.count({ where: { userId: req.user.sub, deletedAt: null, isRead: false } });
    return res.json({ success: true, message: 'Notification marked as read.', data: { notification: payload(row), unreadCount } });
  } catch (error) { return next(error); }
};

exports.readAll = async (req, res, next) => {
  try {
    const { Notification } = getModels();
    const [updatedCount] = await Notification.update(
      { isRead: true, readAt: new Date() },
      { where: { userId: req.user.sub, deletedAt: null, isRead: false } },
    );
    return res.json({ success: true, message: 'All notifications marked as read.', data: { updatedCount, unreadCount: 0 } });
  } catch (error) { return next(error); }
};

exports.remove = async (req, res, next) => {
  try {
    const { Notification } = getModels();
    const row = await Notification.findOne({
      where: { id: req.params.notificationId, userId: req.user.sub },
      attributes: ['id', 'deletedAt'],
    });
    if (!row) return unavailable(res);
    if (!row.deletedAt) await row.update({ deletedAt: new Date() });
    const unreadCount = await Notification.count({ where: { userId: req.user.sub, deletedAt: null, isRead: false } });
    return res.json({ success: true, message: 'Notification deleted.', data: { id: String(row.id), deleted: true, unreadCount } });
  } catch (error) { return next(error); }
};

exports._test = { payload, safeData };
