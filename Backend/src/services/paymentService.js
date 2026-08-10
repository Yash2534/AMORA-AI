const crypto = require('crypto');
const { getModels } = require('../models');
const { getPaymentProvider } = require('./razorpayProvider');
const { activateSubscription, subscriptionJson, currentSubscription } = require('./entitlementService');
const { postWalletTransaction, reverseWalletCredit } = require('./walletService');

function publicError(message, code, status = 400) { const error = new Error(message); error.code = code; error.status = status; return error; }
function idempotencyKey(req) {
  const value = String(req.get('Idempotency-Key') || req.body?.idempotencyKey || '').trim();
  if (!/^[A-Za-z0-9._:-]{8,100}$/.test(value)) throw publicError('A valid Idempotency-Key is required.', 'IDEMPOTENCY_KEY_REQUIRED');
  return value;
}

async function productFor(type, referenceId, transaction) {
  const { SubscriptionPlan, WalletProduct, BoostProduct } = getModels();
  let product;
  if (type === 'subscription') {
    product = await SubscriptionPlan.findOne({ where: { id: referenceId, active: true }, transaction });
    if (product) return { product, amountMinor: Number(product.priceMinor), currency: product.currency, planId: product.id };
  } else if (type === 'wallet_top_up') {
    product = await WalletProduct.findOne({ where: { id: referenceId, type: 'top_up', active: true }, transaction });
    if (product) return { product, amountMinor: Number(product.priceMinor), currency: product.currency, planId: null };
  } else if (type === 'boost') {
    product = await BoostProduct.findOne({ where: { id: referenceId, active: true }, transaction });
    if (product) return { product, amountMinor: Number(product.priceMinor), currency: product.currency, planId: null };
  }
  throw publicError('The selected product is not available.', 'PRODUCT_NOT_AVAILABLE', 404);
}

async function createPaymentOrder({ userId, productType, productReferenceId, key }) {
  const { Payment } = getModels(); const provider = getPaymentProvider();
  const existing = await Payment.findOne({ where: { userId, idempotencyKey: key } });
  if (existing?.providerOrderId) return orderJson(existing, provider.publicKey());
  const selected = await productFor(productType, productReferenceId);
  let payment = existing;
  if (payment && (payment.productType !== productType || payment.productReferenceId !== productReferenceId)) throw publicError('The idempotency key was already used for another product.', 'IDEMPOTENCY_CONFLICT', 409);
  if (!payment) payment = await Payment.create({ userId, planId: selected.planId, productType, productReferenceId, provider: provider.name, amountMinor: selected.amountMinor, currency: selected.currency, status: 'created', idempotencyKey: key });
  try {
    const order = await provider.createOrder({ amount: selected.amountMinor, currency: selected.currency, receipt: `amoraa_${payment.id}`, notes: { internalPaymentId: String(payment.id), userId: String(userId), productType, productReferenceId } });
    if (!order?.id || Number(order.amount) !== selected.amountMinor || order.currency !== selected.currency) throw publicError('The payment provider returned an invalid order.', 'PROVIDER_ORDER_INVALID', 502);
    await payment.update({ providerOrderId: order.id, status: 'created', failureCode: null, failureMessage: null, metadata: { providerStatus: order.status } });
    return orderJson(payment, provider.publicKey());
  } catch (error) {
    await payment.update({ status: 'failed', failureCode: error.code || 'ORDER_CREATION_FAILED', failureMessage: String(error.message).slice(0, 500) });
    throw error;
  }
}

function orderJson(payment, providerKey) {
  return { paymentId: String(payment.id), provider: payment.provider, providerOrderId: payment.providerOrderId, amountMinor: Number(payment.amountMinor), currency: payment.currency, productType: payment.productType, productReferenceId: payment.productReferenceId, checkout: { key: providerKey, orderId: payment.providerOrderId, amount: Number(payment.amountMinor), currency: payment.currency, name: 'AMORAA' } };
}

async function fulfillPayment(payment, providerPayment, transaction) {
  const { Payment, WalletProduct, BoostProduct, BoostEntitlement } = getModels();
  const locked = await Payment.findByPk(payment.id, { transaction, lock: transaction.LOCK.UPDATE });
  if (locked.status === 'paid') return locked;
  if (String(providerPayment.order_id) !== String(locked.providerOrderId) || String(providerPayment.id) === '') throw publicError('Provider payment does not match this order.', 'PAYMENT_MISMATCH');
  if (Number(providerPayment.amount) !== Number(locked.amountMinor) || String(providerPayment.currency).toUpperCase() !== locked.currency.toUpperCase()) throw publicError('Provider amount or currency does not match the order.', 'PAYMENT_MISMATCH');
  if (providerPayment.status !== 'captured') throw publicError('Payment has not been captured by the provider.', 'PAYMENT_NOT_CAPTURED', 409);
  await locked.update({ providerPaymentId: providerPayment.id, status: 'paid', verifiedAt: new Date(), failureCode: null, failureMessage: null }, { transaction });
  if (locked.productType === 'subscription') {
    await activateSubscription(locked, transaction);
  } else if (locked.productType === 'wallet_top_up') {
    const product = await WalletProduct.findByPk(locked.productReferenceId, { transaction });
    if (!product || product.type !== 'top_up') throw new Error('Wallet top-up product is unavailable during fulfilment.');
    await postWalletTransaction({ userId: locked.userId, direction: 'credit', amount: Number(product.credits), type: 'top_up', referenceType: 'payment', referenceId: locked.id, idempotencyKey: `payment:${locked.id}`, description: product.name }, transaction);
  } else if (locked.productType === 'boost') {
    const product = await BoostProduct.findByPk(locked.productReferenceId, { transaction });
    if (!product) throw new Error('Boost product is unavailable during fulfilment.');
    await BoostEntitlement.findOrCreate({ where: { userId: locked.userId, idempotencyKey: `payment:${locked.id}` }, defaults: { userId: locked.userId, productId: product.id, paymentId: locked.id, source: 'payment', quantity: product.quantity, remainingQuantity: product.quantity, durationMinutes: product.durationMinutes, status: 'active', idempotencyKey: `payment:${locked.id}` }, transaction });
  }
  return locked;
}

async function verifyPayment({ userId, providerOrderId, providerPaymentId, signature }) {
  const { Payment } = getModels(); const provider = getPaymentProvider();
  const payment = await Payment.findOne({ where: { provider: provider.name, providerOrderId } });
  if (!payment || Number(payment.userId) !== Number(userId)) throw publicError('Payment order was not found.', 'PAYMENT_NOT_FOUND', 404);
  if (payment.status === 'paid') return paymentResult(payment);
  if (!provider.verifyCheckoutSignature({ orderId: payment.providerOrderId, paymentId: providerPaymentId, signature })) throw publicError('Payment signature is invalid.', 'PAYMENT_SIGNATURE_INVALID', 400);
  const providerPayment = await provider.fetchPayment(providerPaymentId);
  await Payment.sequelize.transaction((transaction) => fulfillPayment(payment, providerPayment, transaction));
  await payment.reload(); return paymentResult(payment);
}

async function paymentResult(payment) {
  const membership = payment.productType === 'subscription' ? subscriptionJson(await currentSubscription(payment.userId)) : null;
  return { payment: { id: String(payment.id), status: payment.status, provider: payment.provider, providerOrderId: payment.providerOrderId, providerPaymentId: payment.providerPaymentId, amountMinor: Number(payment.amountMinor), currency: payment.currency, productType: payment.productType }, membership };
}

function webhookEntities(body) {
  const payment = body?.payload?.payment?.entity || null;
  const refund = body?.payload?.refund?.entity || null;
  const dispute = body?.payload?.dispute?.entity || null;
  return { payment, refund, dispute, providerPaymentId: payment?.id || refund?.payment_id || dispute?.payment_id || null };
}
async function processWebhook({ rawBody, signature, eventId }) {
  const provider = getPaymentProvider();
  if (!provider.verifyWebhookSignature(rawBody, signature)) throw publicError('Webhook signature is invalid.', 'WEBHOOK_SIGNATURE_INVALID', 400);
  let body; try { body = JSON.parse(rawBody.toString('utf8')); } catch (_) { throw publicError('Webhook body is invalid.', 'WEBHOOK_INVALID'); }
  const stableEventId = String(eventId || body.id || crypto.createHash('sha256').update(rawBody).digest('hex'));
  const { Payment, PaymentEvent, Subscription, WalletProduct, BoostEntitlement, Boost } = getModels();
  const duplicate = await PaymentEvent.findOne({ where: { provider: provider.name, providerEventId: stableEventId } });
  if (duplicate) return { duplicate: true, status: duplicate.status };
  const entities = webhookEntities(body); const orderId = entities.payment?.order_id;
  const payment = orderId
    ? await Payment.findOne({ where: { provider: provider.name, providerOrderId: orderId } })
    : entities.providerPaymentId
      ? await Payment.findOne({ where: { provider: provider.name, providerPaymentId: entities.providerPaymentId } })
      : null;
  await Payment.sequelize.transaction(async (transaction) => {
    const record = await PaymentEvent.create({ paymentId: payment?.id || null, provider: provider.name, providerEventId: stableEventId, eventType: String(body.event || 'unknown'), payloadHash: crypto.createHash('sha256').update(rawBody).digest('hex'), payload: body, status: 'received' }, { transaction });
    const event = String(body.event || '');
    if (payment && ['payment.captured', 'order.paid'].includes(event) && entities.payment) {
      await fulfillPayment(payment, entities.payment, transaction); await record.update({ status: 'processed', processedAt: new Date() }, { transaction });
    } else if (payment && event === 'payment.failed') {
      await Payment.update({ status: 'failed', failureCode: entities.payment?.error_code || 'PAYMENT_FAILED', failureMessage: String(entities.payment?.error_description || 'Provider reported payment failure').slice(0, 500) }, { where: { id: payment.id, status: { [require('sequelize').Op.ne]: 'paid' } }, transaction });
      await record.update({ status: 'processed', processedAt: new Date() }, { transaction });
    } else if (payment && ['refund.processed', 'dispute.created'].includes(event)) {
      const reversed = event === 'refund.processed' ? 'refunded' : 'chargeback';
      await Payment.update({ status: reversed }, { where: { id: payment.id }, transaction });
      if (payment.productType === 'subscription') {
        await Subscription.update({ status: 'cancelled', autoRenew: false, cancelAtPeriodEnd: false, currentPeriodEnd: new Date(), endedAt: new Date() }, { where: { userId: payment.userId }, transaction });
      } else if (payment.productType === 'wallet_top_up') {
        const product = await WalletProduct.findByPk(payment.productReferenceId, { transaction });
        if (product) await reverseWalletCredit({ userId: payment.userId, amount: Number(product.credits), referenceId: payment.id, idempotencyKey: `reversal:${payment.id}`, description: `Provider reversal: ${product.name}` }, transaction);
      } else if (payment.productType === 'boost') {
        await BoostEntitlement.update({ status: 'revoked', remainingQuantity: 0 }, { where: { paymentId: payment.id }, transaction });
        await Boost.update({ active: false }, { where: { userId: payment.userId, boostEntitlementId: { [require('sequelize').Op.in]: (await BoostEntitlement.findAll({ where: { paymentId: payment.id }, attributes: ['id'], transaction })).map((row) => row.id) } }, transaction });
      }
      await record.update({ status: 'processed', processedAt: new Date() }, { transaction });
    } else await record.update({ status: 'ignored', processedAt: new Date() }, { transaction });
  });
  return { duplicate: false, status: 'processed' };
}

module.exports = { publicError, idempotencyKey, productFor, createPaymentOrder, verifyPayment, processWebhook, fulfillPayment, paymentResult };
