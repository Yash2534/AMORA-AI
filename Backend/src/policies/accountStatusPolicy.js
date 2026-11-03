const ACTIVE_ACCOUNT_STATUS = 'active';

function isActiveAccount(user) {
  return Boolean(user) && user.accountStatus === ACTIVE_ACCOUNT_STATUS;
}

function isSessionCurrent(user, tokenPayload) {
  return isActiveAccount(user)
    && Number(tokenPayload?.ver || 0) === Number(user.tokenVersion || 0);
}

module.exports = { ACTIVE_ACCOUNT_STATUS, isActiveAccount, isSessionCurrent };
