const express = require('express');
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validateRequest = require('../middleware/validateRequest');
const controller = require('../controllers/paymentController');
const { paymentOrderLimiter, paymentVerifyLimiter, paymentWebhookLimiter } = require('../middleware/rateLimiter');
const router = express.Router();
router.post('/webhook', paymentWebhookLimiter, controller.webhook);
router.post('/orders', requireAuth, paymentOrderLimiter, [
  body('productType').optional().equals('subscription').withMessage('Only subscription payments are supported.'),
  body('planId').isString().trim().notEmpty(),
  body('idempotencyKey').optional().isString().isLength({ min: 8, max: 100 }),
], validateRequest, controller.order);
router.post('/verify', requireAuth, paymentVerifyLimiter, [
  body('providerOrderId').isString().trim().notEmpty(), body('providerPaymentId').isString().trim().notEmpty(), body('signature').isString().trim().notEmpty(),
], validateRequest, controller.verify);
module.exports = router;
