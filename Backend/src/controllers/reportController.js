const { Op } = require('sequelize');
const { getModels } = require('../models');
const { storeEvidence, removeStoredEvidence, maximumEvidenceCount } = require('../utils/reportEvidenceStorage');

exports.create = async (req, res, next) => {
  try {
    const reporterUserId = Number(req.user.sub);
    const targetType = req.body.targetType || 'profile';
    const reportedUserId = targetType === 'profile' ? Number(req.body.targetUserId) : null;
    const targetId = targetType === 'profile' ? String(reportedUserId) : String(req.body.targetId);
    const { User, Report } = getModels();
    if (reportedUserId === reporterUserId) {
      return res.status(400).json({ success: false, message: 'You cannot report your own account.', code: 'SELF_REPORT_NOT_ALLOWED', errors: [] });
    }
    if (targetType === 'profile') {
      const target = await User.findOne({ where: { id: reportedUserId, accountStatus: { [Op.ne]: 'deleted' } }, attributes: ['id'] });
      if (!target) return res.status(404).json({ success: false, message: 'The reported profile is not available.', code: 'PROFILE_NOT_AVAILABLE', errors: [] });
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

exports.addEvidence = async (req, res, next) => {
  let stored;
  try {
    const { Report, ReportEvidence } = getModels();
    const report = await Report.findOne({ where: { id: req.params.reportId, reporterUserId: req.user.sub } });
    if (!report) return res.status(404).json({ success: false, message: 'Report is not available.', code: 'REPORT_NOT_AVAILABLE', errors: [] });
    if (!['open', 'reviewing'].includes(report.status)) {
      return res.status(409).json({ success: false, message: 'Evidence can no longer be added to this report.', code: 'REPORT_CLOSED', errors: [] });
    }
    if (!req.file) return res.status(400).json({ success: false, message: 'An evidence image is required.', code: 'VALIDATION_ERROR', errors: [{ field: 'evidence', message: 'An evidence image is required.' }] });
    if (await ReportEvidence.count({ where: { reportId: report.id } }) >= maximumEvidenceCount) {
      return res.status(409).json({ success: false, message: `A maximum of ${maximumEvidenceCount} evidence files is allowed.`, code: 'EVIDENCE_LIMIT_REACHED', errors: [] });
    }
    stored = await storeEvidence(report.id, req.file);
    const evidence = await ReportEvidence.create({
      reportId: report.id,
      originalName: stored.originalName,
      storagePath: stored.storagePath,
      mimeType: stored.mimeType,
      sizeBytes: stored.sizeBytes,
    });
    return res.status(201).json({
      success: true,
      message: 'Report evidence uploaded.',
      data: { evidence: { id: String(evidence.id), reportId: String(report.id), originalName: evidence.originalName, mimeType: evidence.mimeType, sizeBytes: evidence.sizeBytes, createdAt: evidence.createdAt } },
    });
  } catch (error) {
    if (stored?.absolutePath) await removeStoredEvidence(stored.absolutePath);
    if (error.code === 'INVALID_EVIDENCE_TYPE') {
      return res.status(400).json({ success: false, message: error.message, code: error.code, errors: [] });
    }
    return next(error);
  }
};
