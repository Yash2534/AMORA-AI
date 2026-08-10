const express = require('express');
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validateRequest = require('../middleware/validateRequest');
const controller = require('../controllers/paymentController');
const { paymentOrderLimiter, paymentVerifyLimiter, paymentWebhookLimiter } = require('../middleware/rateLimiter');
const router = express.Router();
router.post('/webhook', paymentWebhookLimiter, controller.webhook);
router.post('/orders', requireAuth, paymentOrderLimiter, [
  body('productType').optional().isIn(['subscription', 'wallet_top_up', 'boost']),
  body('planId').optional().isString().trim().notEmpty(),
  body('productId').optional().isString().trim().notEmpty(),
  body().custom((value) => {
    const type = value.productType || 'subscription';
    if (type === 'subscription' ? !value.planId : !value.productId) throw new Error(type === 'subscription' ? 'planId is required.' : 'productId is required.');
    return true;
  }),
  body('idempotencyKey').optional().isString().isLength({ min: 8, max: 100 }),
], validateRequest, controller.order);
router.post('/verify', requireAuth, paymentVerifyLimiter, [
  body('providerOrderId').isString().trim().notEmpty(), body('providerPaymentId').isString().trim().notEmpty(), body('signature').isString().trim().notEmpty(),
], validateRequest, controller.verify);
module.exports = router;
