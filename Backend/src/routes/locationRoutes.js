const router = require('express').Router();
const { body } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/locationController');

const coordinate = (field, minimum, maximum) => body(field).custom((value) => {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < minimum || value > maximum) {
    throw new Error(`${field} must be a finite number between ${minimum} and ${maximum}.`);
  }
  return true;
});

router.use(requireAuth);
router.get('/', controller.get);
router.put('/', [
  body().custom((value) => {
    const keys = Object.keys(value || {});
    if (keys.some((key) => !['latitude', 'longitude'].includes(key))) {
      throw new Error('Request contains an unsupported location field.');
    }
    return true;
  }),
  coordinate('latitude', -90, 90),
  coordinate('longitude', -180, 180),
], validate, controller.update);
router.delete('/', controller.clear);

module.exports = router;
