const { getModels } = require('../models');
const { areUsersBlocked } = require('../services/accessControlService');
const { postWalletTransaction } = require('../services/walletService');
const { idempotencyKey, publicError } = require('../services/paymentService');
const { createNotification } = require('../services/notificationService');

exports.catalog = async (_req, res, next) => {
  try { const gifts = await getModels().Gift.findAll({ where: { active: true }, order: [['sortOrder', 'ASC'], ['id', 'ASC']] }); return res.json({ success: true, message: 'Gift catalog retrieved.', data: { gifts: gifts.map((gift) => ({ id: gift.id, name: gift.name, type: gift.type, description: gift.description, priceCredits: Number(gift.priceCredits), creditUnit: gift.creditUnit, assetUrl: gift.assetUrl })) } }); }
  catch (error) { return next(error); }
};

exports.send = async (req, res, next) => {
  try {
    const senderId = Number(req.user.sub); const recipientId = Number(req.body.recipientId); const key = idempotencyKey(req);
    if (senderId === recipientId) throw publicError('You cannot send a gift to yourself.', 'SELF_GIFT_NOT_ALLOWED');
    const { Gift, GiftTransaction, User, Wallet, ConversationParticipant } = getModels();
    const [recipient, gift] = await Promise.all([User.findOne({ where: { id: recipientId, accountStatus: 'active' } }), Gift.findOne({ where: { id: req.body.giftId, active: true } })]);
    if (!recipient) throw publicError('The recipient is not available.', 'RECIPIENT_NOT_AVAILABLE', 404);
    if (!gift) throw publicError('The selected gift is not available.', 'PRODUCT_NOT_AVAILABLE', 404);
    if (await areUsersBlocked(senderId, recipientId)) throw publicError('Gift sending is not available for this relationship.', 'GIFT_NOT_ALLOWED', 403);
    const conversationId = req.body.conversationId ? Number(req.body.conversationId) : null;
    if (conversationId) {
      const memberships = await ConversationParticipant.count({ where: { conversationId, userId: [senderId, recipientId] } });
      if (memberships !== 2) throw publicError('The conversation is not available for this gift.', 'CONVERSATION_NOT_ALLOWED', 403);
    }
    let transactionRow; let wallet;
    await Wallet.sequelize.transaction(async (transaction) => {
      const result = await postWalletTransaction({ userId: senderId, direction: 'debit', amount: Number(gift.priceCredits), type: 'gift_spend', referenceType: 'gift', referenceId: gift.id, idempotencyKey: key, description: `Gift: ${gift.name}` }, transaction);
      wallet = result.wallet;
      if (result.duplicate) {
        transactionRow = await GiftTransaction.findOne({ where: { senderId, idempotencyKey: key }, transaction, lock: transaction.LOCK.UPDATE });
        if (transactionRow) return;
      }
      transactionRow = await GiftTransaction.create({ senderId, recipientId, giftId: gift.id, walletTransactionId: result.walletTransaction.id, conversationId, priceAtPurchase: gift.priceCredits, creditUnit: gift.creditUnit, idempotencyKey: key, status: 'sent', note: req.body.note?.trim() || null }, { transaction });
    });
    await createNotification({ userId: recipientId, type: 'gift_received', category: 'gift', title: 'You received a gift', message: `Someone sent you ${gift.name}.`, data: { giftTransactionId: String(transactionRow.id), conversationId: conversationId ? String(conversationId) : '' }, conversationId, dedupeKey: `gift:${transactionRow.id}` });
    return res.status(201).json({ success: true, message: 'Gift sent.', data: { giftTransaction: { id: String(transactionRow.id), recipientId: String(transactionRow.recipientId), giftId: transactionRow.giftId, priceAtPurchase: Number(transactionRow.priceAtPurchase), creditUnit: transactionRow.creditUnit, status: transactionRow.status, createdAt: transactionRow.createdAt }, wallet: { balance: Number(wallet.balance), creditUnit: wallet.creditUnit } } });
  } catch (error) { if (error.code === 'INSUFFICIENT_BALANCE') error.status = 409; return next(error); }
};
