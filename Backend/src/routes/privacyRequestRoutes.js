const router = require('express').Router();
const { body, param } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/privacyRequestController');

const types = ['ACCESS', 'EXPORT', 'CORRECTION', 'WITHDRAWAL'];
router.use(requireAuth);
router.post('/', [body('requestType').isString().trim().isIn(types).withMessage('requestType is invalid.'),body('purposes').optional().isArray({min:1})], validate, controller.create);
router.post('/:id/step-up/confirmations',[param('id').isInt({min:1}),body('password').isString().notEmpty()],validate,controller.issueStepUp);
router.post('/:id/step-up/verify',[param('id').isInt({min:1}),body('confirmation').isString().matches(/^[a-f0-9]{32}\.[a-f0-9]{64}$/)],validate,controller.verifyStepUp);
router.post('/:id/access',[param('id').isInt({min:1})],validate,controller.processAccess);
router.post('/:id/withdrawal',[param('id').isInt({min:1})],validate,controller.processWithdrawal);
router.post('/:id/export',[param('id').isInt({min:1})],validate,controller.generateExport);
router.get('/:id/export/download',[param('id').isInt({min:1})],validate,controller.downloadExport);
router.get('/:id/access-result',[param('id').isInt({min:1})],validate,controller.getAccessResult);
router.post('/:id/correction',[param('id').isInt({min:1}),body('category').equals('DATE_OF_BIRTH'),body('requestedBirthDate').isISO8601().toDate().custom((value)=>{if(new Date(value)>new Date(Date.now()-18*365.25*24*60*60*1000))throw new Error('requestedBirthDate must be for an adult.');return true;})],validate,controller.submitCorrection);
router.get('/:id/correction',[param('id').isInt({min:1})],validate,controller.getCorrection);
router.get('/withdrawable-consents', controller.getWithdrawableConsents);
router.get('/', controller.listMine);
router.get('/:id', [param('id').isInt({ min: 1 }).withMessage('Privacy request id is invalid.')], validate, controller.getMine);

module.exports = router;
