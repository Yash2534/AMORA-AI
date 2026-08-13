const { Op } = require('sequelize');
const { getModels } = require('../models');

exports.create = async (req, res, next) => {
  try {
    const reporterUserId = Number(req.user.sub);
    const targetType = req.body.targetType || 'profile';
    const reportedUserId = targetType === 'profile' ? Number(req.body.targetUserId) : null;
    const targetId = targetType === 'profile' ? String(reportedUserId) : String(req.body.targetId);
    const { User, Report, ConversationParticipant } = getModels();
    if (reportedUserId === reporterUserId) {
      return res.status(400).json({ success: false, message: 'You cannot report your own account.', code: 'SELF_REPORT_NOT_ALLOWED', errors: [] });
    }
    if (targetType === 'profile') {
      const target = await User.findOne({ where: { id: reportedUserId, accountStatus: { [Op.ne]: 'deleted' } }, attributes: ['id'] });
      if (!target) return res.status(404).json({ success: false, message: 'The reported profile is not available.', code: 'PROFILE_NOT_AVAILABLE', errors: [] });
      if (req.body.conversationId) {
        const participants = await ConversationParticipant.findAll({
          where: { conversationId: Number(req.body.conversationId) },
          attributes: ['userId'],
        });
        const participantIds = participants.map((participant) => Number(participant.userId));
        if (participantIds.length !== 2
          || !participantIds.includes(reporterUserId)
          || !participantIds.includes(reportedUserId)) {
          return res.status(403).json({ success: false, message: 'The reported profile does not match this conversation.', code: 'REPORT_TARGET_MISMATCH', errors: [] });
        }
      }
    }
    const recent = await Report.findOne({
      where: {
        reporterUserId,
        targetType,
        targetId,
        reason: req.body.reason,
        status: { [Op.in]: ['open', 'reviewing'] },
        createdAt: { [Op.gte]: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      },
      order: [['createdAt', 'DESC']],
    });
    const report = recent || await Report.create({
      reporterUserId,
      reportedUserId,
      targetType,
      targetId,
      reason: req.body.reason,
      notes: req.body.notes || null,
      status: 'open',
    });
    return res.status(recent ? 200 : 201).json({
      success: true,
      message: recent ? 'A matching report is already awaiting review.' : 'Report submitted.',
      data: { report: { id: String(report.id), targetType: report.targetType, reason: report.reason, status: report.status, createdAt: report.createdAt }, created: !recent },
    });
  } catch (error) {
    return next(error);
  }
};
