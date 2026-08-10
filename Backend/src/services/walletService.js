const { getModels } = require('../models');

async function walletForUpdate(userId, transaction) {
  const { Wallet } = getModels();
  let wallet = await Wallet.findOne({ where: { userId }, transaction, lock: transaction.LOCK.UPDATE });
  if (!wallet) {
    try { wallet = await Wallet.create({ userId, status: 'active', creditUnit: 'AMORAA_CREDITS', balance: 0 }, { transaction }); }
    catch (error) {
      if (error.name !== 'SequelizeUniqueConstraintError') throw error;
      wallet = await Wallet.findOne({ where: { userId }, transaction, lock: transaction.LOCK.UPDATE });
    }
  }
  return wallet;
}

async function postWalletTransaction({ userId, direction, amount, type, referenceType, referenceId, idempotencyKey, description }, transaction) {
  const { WalletTransaction } = getModels();
  const wallet = await walletForUpdate(userId, transaction);
  if (wallet.status !== 'active') { const error = new Error('Wallet is not active.'); error.code = 'WALLET_UNAVAILABLE'; throw error; }
  const existing = await WalletTransaction.findOne({ where: { walletId: wallet.id, idempotencyKey }, transaction, lock: transaction.LOCK.UPDATE });
  if (existing) return { wallet, walletTransaction: existing, duplicate: true };
  const before = Number(wallet.balance); const value = Number(amount);
  if (!Number.isSafeInteger(value) || value <= 0) { const error = new Error('Wallet amount is invalid.'); error.code = 'INVALID_WALLET_AMOUNT'; throw error; }
  const after = direction === 'debit' ? before - value : before + value;
  if (after < 0) { const error = new Error('Wallet balance is insufficient.'); error.code = 'INSUFFICIENT_BALANCE'; throw error; }
  await wallet.update({ balance: after }, { transaction });
  const walletTransaction = await WalletTransaction.create({ walletId: wallet.id, userId, direction, amount: value, type, referenceType, referenceId: String(referenceId), idempotencyKey, balanceBefore: before, balanceAfter: after, status: 'posted', description }, { transaction });
  return { wallet, walletTransaction, duplicate: false };
}

async function reverseWalletCredit({ userId, amount, referenceId, idempotencyKey, description }, transaction) {
  const { WalletTransaction } = getModels();
  const wallet = await walletForUpdate(userId, transaction);
  const existing = await WalletTransaction.findOne({ where: { walletId: wallet.id, idempotencyKey }, transaction, lock: transaction.LOCK.UPDATE });
  if (existing) return { wallet, walletTransaction: existing, duplicate: true };
  const before = Number(wallet.balance); const after = before - Number(amount);
  await wallet.update({ balance: after, status: after < 0 ? 'frozen' : wallet.status }, { transaction });
  const walletTransaction = await WalletTransaction.create({ walletId: wallet.id, userId, direction: 'debit', amount, type: 'refund', referenceType: 'payment_reversal', referenceId: String(referenceId), idempotencyKey, balanceBefore: before, balanceAfter: after, status: 'posted', description }, { transaction });
  return { wallet, walletTransaction, duplicate: false };
}

module.exports = { walletForUpdate, postWalletTransaction, reverseWalletCredit };
