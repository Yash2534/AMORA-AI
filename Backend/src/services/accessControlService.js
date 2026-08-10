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

function notBlockedUserSql(sequelize, viewerUserId, candidateAlias = 'User') {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const viewer = sequelize.escape(Number(viewerUserId));
  const candidate = `${quote(candidateAlias)}.${quote('id')}`;
  return literal(`NOT EXISTS (SELECT 1 FROM ${quote(getModels().Block.getTableName())} AS ${quote('visibilityBlock')} WHERE (${quote('visibilityBlock')}.${quote('blockerUserId')} = ${viewer} AND ${quote('visibilityBlock')}.${quote('blockedUserId')} = ${candidate}) OR (${quote('visibilityBlock')}.${quote('blockedUserId')} = ${viewer} AND ${quote('visibilityBlock')}.${quote('blockerUserId')} = ${candidate}))`);
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
  notBlockedUserSql,
  visibleMatchSql,
};
