const { createPaymentOrder, verifyPayment, processWebhook, idempotencyKey } = require('../services/paymentService');

exports.order = async (req, res, next) => {
  try {
    const productType = req.body.productType || 'subscription';
    const productReferenceId = String(req.body.planId || req.body.productId || '');
    const order = await createPaymentOrder({ userId: req.user.sub, productType, productReferenceId, key: idempotencyKey(req) });
    return res.status(201).json({ success: true, message: 'Payment order created.', data: { order } });
  } catch (error) { return next(error); }
};

exports.verify = async (req, res, next) => {
  try {
    const result = await verifyPayment({ userId: req.user.sub, providerOrderId: req.body.providerOrderId, providerPaymentId: req.body.providerPaymentId, signature: req.body.signature });
    return res.json({ success: true, message: 'Payment verified.', data: result });
  } catch (error) { return next(error); }
};

exports.webhook = async (req, res, next) => {
  try {
    const rawBody = req.rawBody || Buffer.from(JSON.stringify(req.body || {}));
    const result = await processWebhook({ rawBody, signature: req.get('X-Razorpay-Signature'), eventId: req.get('X-Razorpay-Event-Id') });
    return res.json({ success: true, message: result.duplicate ? 'Webhook already processed.' : 'Webhook accepted.', data: result });
  } catch (error) { return next(error); }
};
