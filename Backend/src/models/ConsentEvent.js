const { DataTypes } = require('sequelize');

const ACTIONS = Object.freeze({ ACCEPTED: 'ACCEPTED', ACKNOWLEDGED: 'ACKNOWLEDGED', WITHDRAWN: 'WITHDRAWN', RECONSENTED: 'RECONSENTED' });
const SOURCES = Object.freeze({ SIGNUP_EMAIL: 'SIGNUP_EMAIL', SIGNUP_GOOGLE: 'SIGNUP_GOOGLE', SETTINGS: 'SETTINGS', RECONSENT_FLOW: 'RECONSENT_FLOW', ONBOARDING: 'ONBOARDING' });
const PLATFORMS = Object.freeze({ ANDROID: 'ANDROID', IOS: 'IOS', WEB: 'WEB' });
const PURPOSES = Object.freeze({ TERMS_OF_SERVICE_ACCEPTANCE: 'TERMS_OF_SERVICE_ACCEPTANCE', PRIVACY_POLICY_ACKNOWLEDGEMENT: 'PRIVACY_POLICY_ACKNOWLEDGEMENT' });
const values = (object) => Object.values(object);

const defineConsentEvent = (sequelize) => sequelize.define('ConsentEvent', {
  id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
  userId: { type: DataTypes.INTEGER, allowNull: true },
  documentVersionId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
  purpose: { type: DataTypes.ENUM(...values(PURPOSES)), allowNull: false, validate: { isIn: [values(PURPOSES)] } },
  action: { type: DataTypes.ENUM(...values(ACTIONS)), allowNull: false, validate: { isIn: [values(ACTIONS)] } },
  source: { type: DataTypes.ENUM(...values(SOURCES)), allowNull: false, validate: { isIn: [values(SOURCES)] } },
  platform: { type: DataTypes.ENUM(...values(PLATFORMS)), allowNull: false, validate: { isIn: [values(PLATFORMS)] } },
  occurredAt: { type: DataTypes.DATE, allowNull: false },
  metadata: { type: DataTypes.JSON, allowNull: true },
}, { tableName: 'ConsentEvents', indexes: [{ fields: ['userId', 'occurredAt'] }, { fields: ['documentVersionId', 'occurredAt'] }] });

defineConsentEvent.ACTIONS = ACTIONS;
defineConsentEvent.SOURCES = SOURCES;
defineConsentEvent.PLATFORMS = PLATFORMS;
defineConsentEvent.PURPOSES = PURPOSES;
module.exports = defineConsentEvent;
