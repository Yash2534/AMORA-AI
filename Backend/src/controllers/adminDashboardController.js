const { Op, QueryTypes } = require('sequelize');
const { getModels } = require('../models');
const { dashboardRange } = require('../admin/timeRange');

const metric = (value, now, extra = {}) => ({ value: Number(value || 0), updatedAt: now, ...extra });
const maskEmail = (value) => {
  const [local, domain] = String(value || '').split('@');
  return local && domain ? `${local.slice(0, 1)}***@${domain}` : null;
};

exports.overview = async (req, res, next) => {
  try {
    const {
      User, IdentityVerification, Subscription, Report, Event, Payment,
      OnboardingProfile, SubscriptionPlan, EventRegistration,
      Match, DiscoverAction, Message, Notification,
    } = getModels();
    const granted = req.adminPermissions || new Set();
    const can = (permission) => granted.has(permission);
    const canUsers = can('users.view');
    const canPresence = canUsers && can('presence.view');
    const canVerification = can('verifications.view') || can('verifications.pending.view');
    const canMembership = can('membership.view');
    const canReports = can('reports.view');
    const canEvents = can('events.view');
    const canRevenue = can('revenue.view');
    const canRegistrationAnalytics = can('analytics.users.view');
    const canMatches = can('matching.matches.view');
    const canLikes = can('matching.likes.view');
    const canMessages = can('chatModeration.messages.view');
    const canNotifications = can('notifications.view');
    const now = new Date();
    const { from, to, timezone } = dashboardRange(req.query, now);
    const [
      totalUsers, activeUsers, onlineUsers, pendingVerification,
      activeMemberships, openReports, events, revenue, recentUsers,
      latestReports, latestEvents, registrationRows,
      newUsers, verifiedUsers, matches, likes, messages, notifications,
      databaseHealth,
    ] = await Promise.all([
      canUsers ? User.count() : null,
      canUsers ? User.count({ where: { accountStatus: 'active' } }) : null,
      canPresence ? User.count({ where: { accountStatus: 'active', lastActiveAt: { [Op.gte]: new Date(now.getTime() - 5 * 60 * 1000) } } }) : null,
      canVerification ? IdentityVerification.count({ where: { status: { [Op.in]: ['pending', 'under_review'] } } }) : null,
      canMembership ? Subscription.count({ where: { status: { [Op.in]: ['active', 'trialing'] }, currentPeriodEnd: { [Op.gt]: now } } }) : null,
      canReports ? Report.count({ where: { status: { [Op.in]: ['open', 'reviewing'] } } }) : null,
      canEvents ? Event.count() : null,
      canRevenue ? Payment.sum('amountMinor', { where: { status: 'paid', currency: 'INR', createdAt: { [Op.between]: [from, to] } } }) : null,
      canUsers ? User.findAll({
        limit: 8,
        order: [['createdAt', 'DESC']],
        include: [
          { model: OnboardingProfile, required: false },
          ...(canVerification ? [{ model: IdentityVerification, as: 'identityVerification', required: false }] : []),
          ...(canMembership ? [{ model: Subscription, as: 'subscription', required: false, include: [{ model: SubscriptionPlan, as: 'plan', required: false }] }] : []),
        ],
      }) : [],
      canReports ? Report.findAll({ limit: 8, order: [['createdAt', 'DESC']] }) : [],
      canEvents ? Event.findAll({
        limit: 8,
        order: [['startDateTime', 'DESC']],
        attributes: { include: [[Event.sequelize.fn('COUNT', Event.sequelize.col('registrations.id')), 'registrationCount']] },
        include: [{ model: EventRegistration, as: 'registrations', attributes: [], required: false }],
        group: ['Event.id'],
        subQuery: false,
      }) : [],
      canRegistrationAnalytics ? User.sequelize.query(
        'SELECT DATE(`createdAt`) AS `date`, COUNT(*) AS `count` FROM `Users` WHERE `createdAt` BETWEEN :from AND :to GROUP BY DATE(`createdAt`) ORDER BY `date`',
        { replacements: { from, to }, type: QueryTypes.SELECT },
      ) : [],
      canUsers ? User.count({ where: { createdAt: { [Op.between]: [from, to] } } }) : null,
      canVerification ? User.count({ where: { identityVerifiedAt: { [Op.ne]: null } } }) : null,
      canMatches ? Match.count({ where: { matchedAt: { [Op.between]: [from, to] } } }) : null,
      canLikes ? DiscoverAction.count({ where: { action: { [Op.in]: ['like', 'superLike'] }, createdAt: { [Op.between]: [from, to] } } }) : null,
      canMessages ? Message.count({ where: { deletedAt: null, createdAt: { [Op.between]: [from, to] } } }) : null,
      canNotifications ? Notification.count({ where: { deletedAt: null, createdAt: { [Op.between]: [from, to] } } }) : null,
      User.sequelize.query('SELECT 1 AS healthy', { type: QueryTypes.SELECT }),
    ]);

    const userRows = recentUsers.map((user) => {
      const photos = Array.isArray(user.OnboardingProfile?.photos) ? user.OnboardingProfile.photos : [];
      const primaryIndex = Number(user.OnboardingProfile?.primaryPhotoIndex || 0);
      return {
        id: String(user.id),
        name: user.name,
        email: maskEmail(user.email),
        status: user.accountStatus,
        registeredAt: user.createdAt,
        profileImageUrl: photos[primaryIndex] || photos[0] || null,
        ...(canVerification ? { verificationStatus: user.identityVerification?.status || 'not_submitted' } : {}),
        ...(canMembership ? { membership: user.subscription?.plan?.displayName || null } : {}),
      };
    });
    const reportRows = latestReports.map((report) => ({
      id: String(report.id),
      reference: `RPT-${report.id}`,
      type: report.targetType,
      status: report.status,
      createdAt: report.createdAt,
      reportedEntity: report.targetId,
    }));
    const eventRows = latestEvents.map((event) => ({
      id: String(event.id),
      title: event.title,
      startsAt: event.startDateTime,
      status: event.status,
      locationSummary: [event.venueName, event.city].filter(Boolean).join(', '),
      imageUrl: event.heroImageUrl,
      registrationCount: Number(event.get('registrationCount') || 0),
    }));

    return res.json({
      success: true,
      data: {
        period: { from, to, timezone, granularity: 'day' },
        metrics: {
          ...(canUsers ? { totalUsers: metric(totalUsers, now), activeUsers: metric(activeUsers, now), newUsers: metric(newUsers, now) } : {}),
          ...(canPresence ? { onlineUsers: metric(onlineUsers, now) } : {}),
          ...(canVerification ? { pendingVerification: metric(pendingVerification, now) } : {}),
          ...(canVerification ? { verifiedUsers: metric(verifiedUsers, now) } : {}),
          ...(canMembership ? { activeMemberships: metric(activeMemberships, now) } : {}),
          ...(canReports ? { reports: metric(openReports, now) } : {}),
          ...(canEvents ? { events: metric(events, now) } : {}),
          ...(canRevenue ? { revenue: metric(revenue, now, { amountMinor: Number(revenue || 0), currency: 'INR' }) } : {}),
          ...(canMatches ? { matches: metric(matches, now) } : {}),
          ...(canLikes ? { likes: metric(likes, now) } : {}),
          ...(canMessages ? { messages: metric(messages, now) } : {}),
          ...(canNotifications ? { notifications: metric(notifications, now) } : {}),
          systemHealth: metric(databaseHealth[0]?.healthy === 1 ? 1 : 0, now, { description: 'Authoritative database health check.' }),
        },
        charts: canRegistrationAnalytics ? {
          registrations: {
            series: [{ label: 'Registrations', points: registrationRows.map((row) => ({ label: row.date, date: row.date, value: Number(row.count) })) }],
            updatedAt: now,
          },
        } : {},
        recentUsers: userRows,
        latestReports: reportRows,
        latestEvents: eventRows,
        liveNotifications: [],
        errors: {},
      },
      meta: { generatedAt: now, requestId: req.adminCorrelationId },
    });
  } catch (error) {
    return next(error);
  }
};

exports.notifications = async (req, res) => res.status(501).json({
  success: false,
  message: 'Administrator dashboard notifications require an approved authoritative database schema.',
  code: 'SCHEMA_NOT_AVAILABLE',
  errors: [],
  meta: { requestId: req.adminCorrelationId || null },
});
