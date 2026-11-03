const { Op, literal } = require('sequelize');
const { getModels } = require('../models');

const activeAccountWhere = (extra = {}) => ({ ...extra, accountStatus: 'active' });
const matchPairWhere = (firstUserId, secondUserId) => ({
  [Op.or]: [
    { userOneId: firstUserId, userTwoId: secondUserId },
    { userOneId: secondUserId, userTwoId: firstUserId },
  ],
});

async function areUsersBlocked(firstUserId, secondUserId, options = {}) {
  const { Block } = getModels();
  return Boolean(await Block.findOne({
    where: {
      [Op.or]: [
        { blockerUserId: firstUserId, blockedUserId: secondUserId },
        { blockerUserId: secondUserId, blockedUserId: firstUserId },
      ],
    },
    attributes: ['id'],
    transaction: options.transaction,
  }));
}

async function isUserReportedBy(reporterUserId, reportedUserId, options = {}) {
  const { Report } = getModels();
  return Boolean(await Report.findOne({
    where: {
      reporterUserId: Number(reporterUserId),
      [Op.or]: [
        { reportedUserId: Number(reportedUserId) },
        { targetType: 'profile', targetId: String(reportedUserId) },
      ],
    },
    attributes: ['id'],
    transaction: options.transaction,
  }));
}

async function areUsersReported(firstUserId, secondUserId, options = {}) {
  const { Report } = getModels();
  const first = Number(firstUserId);
  const second = Number(secondUserId);
  return Boolean(await Report.findOne({
    where: {
      [Op.or]: [
        {
          reporterUserId: first,
          [Op.or]: [
            { reportedUserId: second },
            { targetType: 'profile', targetId: String(second) },
          ],
          status: { [Op.in]: ['open', 'reviewing', 'resolved', 'dismissed'] },
        },
        {
          reporterUserId: second,
          [Op.or]: [
            { reportedUserId: first },
            { targetType: 'profile', targetId: String(first) },
          ],
          status: { [Op.in]: ['open', 'reviewing', 'resolved'] },
        },
      ],
    },
    attributes: ['id'],
    transaction: options.transaction,
  }));
}

function notBlockedUserSql(sequelize, viewerUserId, candidateAlias = 'User') {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const viewer = sequelize.escape(Number(viewerUserId));
  const candidate = `${quote(candidateAlias)}.${quote('id')}`;
  return literal(`NOT EXISTS (SELECT 1 FROM ${quote(getModels().Block.getTableName())} AS ${quote('visibilityBlock')} WHERE (${quote('visibilityBlock')}.${quote('blockerUserId')} = ${viewer} AND ${quote('visibilityBlock')}.${quote('blockedUserId')} = ${candidate}) OR (${quote('visibilityBlock')}.${quote('blockedUserId')} = ${viewer} AND ${quote('visibilityBlock')}.${quote('blockerUserId')} = ${candidate}))`);
}

function notReportedUserSql(sequelize, viewerUserId, candidateAlias = 'User') {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const viewer = sequelize.escape(Number(viewerUserId));
  const candidate = `${quote(candidateAlias)}.${quote('id')}`;
  const candidateStr = `CAST(${candidate} AS CHAR)`;
  const viewerStr = `CAST(${viewer} AS CHAR)`;
  const reportTable = quote(getModels().Report.getTableName());
  return literal(`NOT EXISTS (SELECT 1 FROM ${reportTable} AS ${quote('visibilityReport')} WHERE (${quote('visibilityReport')}.${quote('reporterUserId')} = ${viewer} AND (${quote('visibilityReport')}.${quote('reportedUserId')} = ${candidate} OR (${quote('visibilityReport')}.${quote('targetType')} = 'profile' AND ${quote('visibilityReport')}.${quote('targetId')} = ${candidateStr})) AND ${quote('visibilityReport')}.${quote('status')} IN ('open', 'reviewing', 'resolved', 'dismissed')) OR (${quote('visibilityReport')}.${quote('reporterUserId')} = ${candidate} AND (${quote('visibilityReport')}.${quote('reportedUserId')} = ${viewer} OR (${quote('visibilityReport')}.${quote('targetType')} = 'profile' AND ${quote('visibilityReport')}.${quote('targetId')} = ${viewerStr})) AND ${quote('visibilityReport')}.${quote('status')} IN ('open', 'reviewing', 'resolved')))`);
}

function visibleMatchSql(sequelize, viewerUserId) {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const viewer = sequelize.escape(Number(viewerUserId));
  const match = quote('Match');
  const otherUser = `IF(${match}.${quote('userOneId')} = ${viewer}, ${match}.${quote('userTwoId')}, ${match}.${quote('userOneId')})`;
  return literal(`NOT EXISTS (SELECT 1 FROM ${quote(getModels().Block.getTableName())} AS ${quote('matchBlock')} WHERE (${quote('matchBlock')}.${quote('blockerUserId')} = ${viewer} AND ${quote('matchBlock')}.${quote('blockedUserId')} = ${otherUser}) OR (${quote('matchBlock')}.${quote('blockedUserId')} = ${viewer} AND ${quote('matchBlock')}.${quote('blockerUserId')} = ${otherUser}))`);
}

module.exports = {
  activeAccountWhere,
  matchPairWhere,
  areUsersBlocked,
  isUserReportedBy,
  areUsersReported,
  notBlockedUserSql,
  notReportedUserSql,
  visibleMatchSql,
};
