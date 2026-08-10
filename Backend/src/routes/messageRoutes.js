const router = require('express').Router();
const { param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/messageController');

router.use(requireAuth);
router.get('/:messageId/media/:mediaId', [
  param('messageId').isInt({ min: 1 }).withMessage('messageId must be valid.').toInt(),
  param('mediaId').isInt({ min: 1 }).withMessage('mediaId must be valid.').toInt(),
], validate, controller.downloadMedia);
router.delete('/:messageId', [
  param('messageId').isInt({ min: 1 }).withMessage('messageId must be valid.').toInt(),
], validate, controller.remove);

module.exports = router;
