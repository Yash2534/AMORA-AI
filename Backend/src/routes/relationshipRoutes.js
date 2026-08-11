const express = require('express');
const { param, query } = require('express-validator');
const requireAuth = require('../middleware/authMiddleware');
const validate = require('../middleware/validateRequest');
const controller = require('../controllers/relationshipController');

const userId = param('userId').isInt({ min: 1 }).withMessage('userId must be a valid user id.').toInt();
const page = query('page').optional().isInt({ min: 1, max: 100000 }).toInt();
const limit = query('limit').optional().isInt({ min: 1, max: 30 }).toInt();

const saved = express.Router();
saved.use(requireAuth);
saved.get('/', [page, limit], validate, controller.listSaved);
saved.post('/:userId', [userId], validate, controller.save);
saved.delete('/:userId', [userId], validate, controller.unsave);

const reactions = express.Router();
reactions.use(requireAuth);
reactions.get('/', [query('type').isIn(['like', 'superLike']).withMessage('type must be like or superLike.'), page, limit], validate, controller.listReactions);
reactions.delete('/:userId', [userId], validate, controller.removeReaction);

const me = express.Router();
me.use(requireAuth);
me.get('/saved-profiles', [page, limit], validate, controller.listSaved);
me.put('/saved-profiles/:userId', [userId], validate, controller.save);
me.delete('/saved-profiles/:userId', [userId], validate, controller.unsave);
me.get('/likes', [page, limit], validate, controller.listLikes);
me.get('/super-likes', [page, limit], validate, controller.listSuperLikes);
me.get('/received-likes', [page, limit], validate, controller.listReceivedLikes);

module.exports = { saved, reactions, me };
