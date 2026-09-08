const { DataTypes } = require('sequelize');

const ACCOUNT_DELETION_STATUSES = Object.freeze({
  PENDING: 'PENDING',
  VERIFIED: 'VERIFIED',
  PROCESSING: 'PROCESSING',
  COMPLETED: 'COMPLETED',
  FAILED: 'FAILED',
  BLOCKED_BY_RETENTION_DECISION: 'BLOCKED_BY_RETENTION_DECISION',
});

const statusValues = Object.values(ACCOUNT_DELETION_STATUSES);

const defineAccountDeletionRequest = (sequelize) => sequelize.define('AccountDeletionRequest', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  // Nullable only after a future physical User deletion; non-null values retain FK integrity.
  userId: { type: DataTypes.INTEGER, allowNull: true },
  status: {
    type: DataTypes.ENUM(...statusValues),
    allowNull: false,
    defaultValue: ACCOUNT_DELETION_STATUSES.PENDING,
    validate: { isIn: { args: [statusValues], msg: 'status is invalid.' } },
  },
  requestedAt: { type: DataTypes.DATE, allowNull: false },
  verifiedAt: { type: DataTypes.DATE, allowNull: true },
  processingStartedAt: { type: DataTypes.DATE, allowNull: true },
  completedAt: { type: DataTypes.DATE, allowNull: true },
  failedAt: { type: DataTypes.DATE, allowNull: true },
  failureCode: { type: DataTypes.STRING(80), allowNull: true },
  legalHold: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
  legalHoldReason: { type: DataTypes.STRING(120), allowNull: true },
  correlationId: { type: DataTypes.STRING(36), allowNull: false, unique: true, defaultValue: DataTypes.UUIDV4 },
}, {
  tableName: 'AccountDeletionRequests',
  indexes: [
    { fields: ['userId', 'requestedAt'] },
    { fields: ['status', 'requestedAt'] },
  ],
});

defineAccountDeletionRequest.STATUSES = ACCOUNT_DELETION_STATUSES;
module.exports = defineAccountDeletionRequest;
