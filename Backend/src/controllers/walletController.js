const { Op } = require('sequelize');
const { getModels } = require('../models');
const { idempotencyKey, createPaymentOrder, publicError } = require('../services/paymentService');
const { walletForUpdate, postWalletTransaction } = require('../services/walletService');

function walletJson(wallet) { return { id: String(wallet.id), status: wallet.status, balance: Number(wallet.balance), creditUnit: wallet.creditUnit, updatedAt: wallet.updatedAt }; }
function transactionJson(row) { return { id: String(row.id), type: row.type, direction: row.direction, amount: Number(row.amount), balanceBefore: Number(row.balanceBefore), balanceAfter: Number(row.balanceAfter), status: row.status, description: row.description, createdAt: row.createdAt }; }

exports.get = async (req, res, next) => {
  try {
    const { Wallet } = getModels(); let wallet = await Wallet.findOne({ where: { userId: req.user.sub } });
    if (!wallet) await Wallet.sequelize.transaction(async (transaction) => { wallet = await walletForUpdate(req.user.sub, transaction); });
    return res.json({ success: true, message: 'Wallet retrieved.', data: { wallet: walletJson(wallet) } });
  } catch (error) { return next(error); }
};

exports.transactions = async (req, res, next) => {
  try {
    const { WalletTransaction } = getModels(); const page = Number(req.query.page || 1); const limit = Number(req.query.limit || 20);
    const where = { userId: req.user.sub }; if (req.query.type) where.type = req.query.type;
    const rows = await WalletTransaction.findAll({ where, order: [['createdAt', 'DESC'], ['id', 'DESC']], offset: (page - 1) * limit, limit: limit + 1 });
    const hasMore = rows.length > limit; const selected = hasMore ? rows.slice(0, limit) : rows;
    return res.json({ success: true, message: 'Wallet transactions retrieved.', data: { transactions: selected.map(transactionJson), pagination: { page, limit, hasMore, nextPage: hasMore ? page + 1 : null } } });
  } catch (error) { return next(error); }
};

exports.products = async (req, res, next) => {
  try {
    const { WalletProduct } = getModels(); const where = { active: true }; if (req.query.type) where.type = req.query.type;
    const products = await WalletProduct.findAll({ where, order: [['sortOrder', 'ASC'], ['id', 'ASC']] });
    return res.json({ success: true, message: 'Wallet products retrieved.', data: { products: products.map((item) => ({ id: item.id, type: item.type, name: item.name, description: item.description, credits: Number(item.credits), priceMinor: item.priceMinor == null ? null : Number(item.priceMinor), currency: item.currency, redemptionKind: item.redemptionKind, grantQuantity: Number(item.grantQuantity), durationMinutes: item.durationMinutes == null ? null : Number(item.durationMinutes) })) } });
  } catch (error) { return next(error); }
};

exports.topUpOrder = async (req, res, next) => {
  try {
    const order = await createPaymentOrder({ userId: req.user.sub, productType: 'wallet_top_up', productReferenceId: String(req.body.productId), key: idempotencyKey(req) });
    return res.status(201).json({ success: true, message: 'Wallet top-up order created.', data: { order } });
  } catch (error) { return next(error); }
};

exports.redeem = async (req, res, next) => {
  try {
    const key = idempotencyKey(req); const { WalletProduct, BoostEntitlement, Wallet } = getModels();
    const product = await WalletProduct.findOne({ where: { id: req.body.productId, type: 'redemption', active: true } });
    if (!product) throw publicError('Redemption product is not available.', 'PRODUCT_NOT_AVAILABLE', 404);
    let wallet; let entitlement;
    await Wallet.sequelize.transaction(async (transaction) => {
      const result = await postWalletTransaction({ userId: req.user.sub, direction: 'debit', amount: Number(product.credits), type: 'redemption', referenceType: 'wallet_product', referenceId: product.id, idempotencyKey: key, description: product.name }, transaction);
      wallet = result.wallet;
      if (product.redemptionKind === 'boost') [entitlement] = await BoostEntitlement.findOrCreate({ where: { userId: req.user.sub, idempotencyKey: `redemption:${key}` }, defaults: { userId: req.user.sub, source: 'redemption', quantity: product.grantQuantity, remainingQuantity: product.grantQuantity, durationMinutes: product.durationMinutes, status: 'active', idempotencyKey: `redemption:${key}`, walletTransactionId: result.walletTransaction.id }, transaction });
    });
    return res.json({ success: true, message: 'Wallet redemption completed.', data: { wallet: walletJson(wallet), entitlement: entitlement ? { id: String(entitlement.id), remainingQuantity: Number(entitlement.remainingQuantity), durationMinutes: Number(entitlement.durationMinutes) } : null } });
  } catch (error) { if (error.code === 'INSUFFICIENT_BALANCE') error.status = 409; return next(error); }
};

exports._json = { walletJson, transactionJson };
