const { Op, QueryTypes } = require('sequelize');
const { getModels, sequelize } = require('../models');
const { success, failure } = require('../admin/responses');
const { recordAudit } = require('../services/adminAuditService');

exports.overview = async (req, res, next) => {
  try {
    const models = getModels();
    const User = models.User;
    const OnboardingProfile = models.OnboardingProfile;
    const Subscription = models.Subscription;
    const Payment = models.Payment;
    const SubscriptionPlan = models.SubscriptionPlan;
    const AdminAuditLog = models.AdminAuditLog;

    let totalUsers = 0;
    let totalProfiles = 0;
    let totalSubscriptions = 0;
    let totalPayments = 0;
    let totalPlans = 0;
    let totalAuditLogs = 0;

    try { totalUsers = User ? await User.count() : 0; } catch (_) {}
    try { totalProfiles = OnboardingProfile ? await OnboardingProfile.count() : 0; } catch (_) {}
    try { totalSubscriptions = Subscription ? await Subscription.count() : 0; } catch (_) {}
    try { totalPayments = Payment ? await Payment.count() : 0; } catch (_) {}
    try { totalPlans = SubscriptionPlan ? await SubscriptionPlan.count() : 0; } catch (_) {}
    try { totalAuditLogs = AdminAuditLog ? await AdminAuditLog.count() : 0; } catch (_) {}

    // Anomaly 1: Orphan Profiles
    let orphanProfiles = [];
    try {
      orphanProfiles = await sequelize.query(
        `SELECT p.id, p.userId FROM OnboardingProfiles p LEFT JOIN Users u ON p.userId = u.id WHERE u.id IS NULL`,
        { type: QueryTypes.SELECT }
      );
    } catch (_) {}

    // Anomaly 2: Subscriptions with missing plans or users
    let orphanSubscriptions = [];
    try {
      orphanSubscriptions = await sequelize.query(
        `SELECT s.id, s.userId, s.planId FROM Subscriptions s 
         LEFT JOIN Users u ON s.userId = u.id 
         LEFT JOIN SubscriptionPlans sp ON s.planId = sp.id 
         WHERE u.id IS NULL OR sp.id IS NULL`,
        { type: QueryTypes.SELECT }
      );
    } catch (_) {}

    // Anomaly 3: Payment vs Subscription status mismatches
    let paymentMismatches = [];
    try {
      paymentMismatches = await sequelize.query(
        `SELECT p.id as paymentId, p.status as paymentStatus, s.id as subscriptionId, s.status as subscriptionStatus 
         FROM Payments p 
         JOIN Subscriptions s ON p.productReferenceId = CAST(s.id AS CHAR)
         WHERE (p.status = 'failed' AND s.status = 'active') 
            OR (p.status = 'paid' AND (s.status = 'cancelled' OR s.status = 'expired'))`,
        { type: QueryTypes.SELECT }
      );
    } catch (_) {}

    // Anomaly 4: Inconsistent timestamps
    let timestampAnomalies = [];
    try {
      timestampAnomalies = await sequelize.query(
        `SELECT id, createdAt, updatedAt FROM Payments WHERE updatedAt < createdAt LIMIT 50`,
        { type: QueryTypes.SELECT }
      );
    } catch (_) {}

    const anomaliesList = [
      ...(orphanProfiles || []).map((r) => ({
        id: `orphan_profile_${r.id}`,
        category: 'ORPHAN_RECORD',
        severity: 'HIGH',
        entityType: 'OnboardingProfile',
        entityId: String(r.id),
        description: `Profile ${r.id} belongs to non-existent user ${r.userId}`,
        detectedAt: new Date().toISOString(),
      })),
      ...(orphanSubscriptions || []).map((r) => ({
        id: `orphan_sub_${r.id}`,
        category: 'MISSING_RELATION',
        severity: 'CRITICAL',
        entityType: 'Subscription',
        entityId: String(r.id),
        description: `Subscription ${r.id} references missing User ${r.userId} or Plan ${r.planId}`,
        detectedAt: new Date().toISOString(),
      })),
      ...(paymentMismatches || []).map((r) => ({
        id: `pay_mismatch_${r.paymentId}`,
        category: 'STATUS_MISMATCH',
        severity: 'HIGH',
        entityType: 'Payment',
        entityId: String(r.paymentId),
        description: `Payment ${r.paymentId} status '${r.paymentStatus}' contradicts subscription ${r.subscriptionId} status '${r.subscriptionStatus}'`,
        detectedAt: new Date().toISOString(),
      })),
      ...(timestampAnomalies || []).map((r) => ({
        id: `ts_anomaly_${r.id}`,
        category: 'TIMESTAMP_INCONSISTENCY',
        severity: 'MEDIUM',
        entityType: 'Payment',
        entityId: String(r.id),
        description: `Payment ${r.id} updatedAt (${r.updatedAt}) is earlier than createdAt (${r.createdAt})`,
        detectedAt: new Date().toISOString(),
      })),
    ];

    const healthScore = Math.max(0, 100 - anomaliesList.length * 5);

    return success(req, res, 'Data integrity overview retrieved.', {
      integrity: {
        healthScore,
        totalEntities: totalUsers + totalProfiles + totalSubscriptions + totalPayments,
        totalAnomalies: anomaliesList.length,
        lastScanAt: new Date().toISOString(),
        breakdown: {
          users: totalUsers,
          profiles: totalProfiles,
          subscriptions: totalSubscriptions,
          payments: totalPayments,
          plans: totalPlans,
          auditLogs: totalAuditLogs,
        },
        anomalies: anomaliesList,
      },
    });
  } catch (error) {
    return next(error);
  }
};

exports.runCheck = async (req, res, next) => {
  try {
    await recordAudit({
      request: req,
      administratorId: req.admin.id,
      action: 'admin.data_integrity.scan_executed',
      targetType: 'system',
      targetId: 'data_integrity',
      metadata: { triggeredBy: req.admin.email },
    });

    return exports.overview(req, res, next);
  } catch (error) {
    return next(error);
  }
};
