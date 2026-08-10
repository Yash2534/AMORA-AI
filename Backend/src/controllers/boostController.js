const { Op } = require('sequelize');
const { getModels } = require('../models');
const { idempotencyKey, createPaymentOrder, publicError } = require('../services/paymentService');
const { postWalletTransaction } = require('../services/walletService');

const productJson = (item) => ({ id: item.id, name: item.name, description: item.description, quantity: Number(item.quantity), durationMinutes: Number(item.durationMinutes), priceMinor: Number(item.priceMinor), walletCost: Number(item.walletCost), currency: item.currency });
async function inventory(userId) {
  const { BoostEntitlement, Boost } = getModels(); const now = new Date();
  const entitlements = await BoostEntitlement.findAll({ where: { userId, status: 'active', remainingQuantity: { [Op.gt]: 0, }, [Op.or]: [{ expiresAt: null }, { expiresAt: { [Op.gt]: now } }] }, order: [['expiresAt', 'ASC'], ['id', 'ASC']] });
  const active = await Boost.findOne({ where: { userId, active: true, expiresAt: { [Op.gt]: now } }, order: [['expiresAt', 'DESC']] });
  return { available: entitlements.reduce((sum, item) => sum + Number(item.remainingQuantity), 0), active: active ? { startedAt: active.startedAt, expiresAt: active.expiresAt, remainingSeconds: Math.max(0, Math.ceil((new Date(active.expiresAt) - now) / 1000)) } : null };
}

exports.products = async (_req, res, next) => { try { const products = await getModels().BoostProduct.findAll({ where: { active: true }, order: [['sortOrder', 'ASC'], ['id', 'ASC']] }); return res.json({ success: true, message: 'Boost products retrieved.', data: { products: products.map(productJson) } }); } catch (error) { return next(error); } };
exports.me = async (req, res, next) => { try { return res.json({ success: true, message: 'Boost inventory retrieved.', data: { boost: await inventory(req.user.sub) } }); } catch (error) { return next(error); } };
exports.purchase = async (req, res, next) => {
  try {
    const key = idempotencyKey(req); const source = req.body.source || 'wallet'; const { BoostProduct, BoostEntitlement, Wallet } = getModels(); const product = await BoostProduct.findOne({ where: { id: req.body.productId, active: true } });
    if (!product) throw publicError('Boost product is not available.', 'PRODUCT_NOT_AVAILABLE', 404);
    if (source === 'provider') {
      const order = await createPaymentOrder({ userId: req.user.sub, productType: 'boost', productReferenceId: product.id, key });
      return res.status(201).json({ success: true, message: 'Boost payment order created.', data: { order, boost: await inventory(req.user.sub) } });
    }
    if (source !== 'wallet') throw publicError('Boost purchase source is invalid.', 'VALIDATION_ERROR');
    await Wallet.sequelize.transaction(async (transaction) => {
      const result = await postWalletTransaction({ userId: req.user.sub, direction: 'debit', amount: Number(product.walletCost), type: 'boost_spend', referenceType: 'boost_product', referenceId: product.id, idempotencyKey: key, description: product.name }, transaction);
      await BoostEntitlement.findOrCreate({ where: { userId: req.user.sub, idempotencyKey: `wallet:${key}` }, defaults: { userId: req.user.sub, productId: product.id, walletTransactionId: result.walletTransaction.id, source: 'wallet', quantity: product.quantity, remainingQuantity: product.quantity, durationMinutes: product.durationMinutes, status: 'active', idempotencyKey: `wallet:${key}` }, transaction });
    });
    return res.status(201).json({ success: true, message: 'Boost entitlement purchased.', data: { boost: await inventory(req.user.sub) } });
  } catch (error) { if (error.code === 'INSUFFICIENT_BALANCE') error.status = 409; return next(error); }
};

exports._inventory = inventory;
