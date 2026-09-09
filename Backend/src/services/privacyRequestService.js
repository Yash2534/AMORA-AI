const crypto = require('crypto');
const { getModels } = require('../models');

const ACTIVE_STATUSES = Object.freeze(['IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'PROCESSING']);
const TRANSITIONS = Object.freeze({
  IDENTITY_VERIFICATION_REQUIRED: ['VERIFIED', 'FAILED'],
  VERIFIED: ['PROCESSING', 'FAILED'],
  PROCESSING: ['COMPLETED', 'FAILED'],
  COMPLETED: [],
  FAILED: [],
});

const nullable = (row, field) => row.get(field) ?? null;
const safeRequest = (row) => ({
  id: String(row.id), requestType: row.requestType, status: row.status,
  requestedAt: row.requestedAt, identityVerifiedAt: nullable(row, 'identityVerifiedAt'),
  processingStartedAt: nullable(row, 'processingStartedAt'), completedAt: nullable(row, 'completedAt'),
  failedAt: nullable(row, 'failedAt'), failureCode: nullable(row, 'failureCode'), correlationId: row.correlationId,
  createdAt: row.createdAt, updatedAt: row.updatedAt,
});

class PrivacyRequestService {
  async create({ userId, requestType }) {
    const { User, PrivacyRequest } = getModels();
    return User.sequelize.transaction(async (transaction) => {
      // Locking the owner serializes retries for the same person across request types.
      const user = await User.findByPk(userId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!user) {
        const error = new Error('User not found.'); error.status = 404; error.code = 'NOT_FOUND'; throw error;
      }
      const existing = await PrivacyRequest.findOne({
        where: { userId, requestType, status: ACTIVE_STATUSES },
        order: [['requestedAt', 'DESC'], ['id', 'DESC']], transaction, lock: transaction.LOCK.UPDATE,
      });
      if (existing) return { request: existing, duplicate: true };
      const request = await PrivacyRequest.create({
        userId, requestType, status: 'IDENTITY_VERIFICATION_REQUIRED', requestedAt: new Date(),
        correlationId: crypto.randomUUID(), metadata: null,
      }, { transaction });
      return { request, duplicate: false };
    });
  }

  // Reserved for a future authenticated staff workflow; no client route may call this.
  async transition({ requestId, nextStatus, failureCode = null, assignedAdminId = null }) {
    const { PrivacyRequest } = getModels();
    return PrivacyRequest.sequelize.transaction(async (transaction) => {
      const request = await PrivacyRequest.findByPk(requestId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!request) { const error = new Error('Privacy request not found.'); error.status = 404; error.code = 'NOT_FOUND'; throw error; }
      if (!TRANSITIONS[request.status].includes(nextStatus)) { const error = new Error('Privacy request transition is invalid.'); error.status = 409; error.code = 'PRIVACY_REQUEST_TRANSITION_INVALID'; throw error; }
      const now = new Date();
      const values = { status: nextStatus };
      if (nextStatus === 'VERIFIED') values.identityVerifiedAt = now;
      if (nextStatus === 'PROCESSING') values.processingStartedAt = now;
      if (nextStatus === 'COMPLETED') values.completedAt = now;
      if (nextStatus === 'FAILED') { values.failedAt = now; values.failureCode = failureCode || 'PRIVACY_REQUEST_FAILED'; }
      if (assignedAdminId !== null) values.assignedAdminId = assignedAdminId;
      await request.update(values, { transaction });
      return request;
    });
  }
}

module.exports = { PrivacyRequestService, ACTIVE_STATUSES, TRANSITIONS, safeRequest };
