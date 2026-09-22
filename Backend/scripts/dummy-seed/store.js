const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { plans } = require('../seed-subscription-plans');
const { MESSAGE_LINES, buildSeedBlueprint, dateDaysBefore, pairKey, shortHash, stablePair } = require('./factory');

function setAction(map, actorUserId, targetUserId, action, createdAt) {
  if (actorUserId !== targetUserId) map.set(`${actorUserId}:${targetUserId}`, { actorUserId, targetUserId, action, createdAt, updatedAt: createdAt });
}
async function findSeedUsers(User, config, transaction) { return User.findAll({ where: { email: { [Op.like]: `%${config.emailSuffix}` } }, transaction }); }

async function resetSeedData(models, config, transaction) {
  const { User, ConversationParticipant, Conversation, Message, MessageMedia, RoseTransaction, Notification, NotificationDelivery, UserDevice, DiscoverAction, Match, SavedProfile, Block, DiscoverFilterPreference, NotificationPreference, Subscription, Payment, PaymentEvent, Event, EventRegistration, EventWaitlist, Report, IdentityVerification, IdentityVerificationDecisionEvent, RefreshToken, OnboardingProfile, ConsentEvent } = models;
  const seedUsers = await findSeedUsers(User, config, transaction); const userIds = seedUsers.map((user) => user.id);
  if (!userIds.length) return { users: 0, conversations: 0 };
  const memberships = await ConversationParticipant.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['conversationId'], transaction });
  const conversationIds = [...new Set(memberships.map((row) => row.conversationId))];
  if (conversationIds.length) {
    const members = await ConversationParticipant.findAll({ where: { conversationId: { [Op.in]: conversationIds } }, attributes: ['userId'], transaction }); const seedSet = new Set(userIds);
    if (members.some((row) => !seedSet.has(row.userId))) throw new Error('Refusing to reset: a seed user is in a conversation with a non-seed user.');
    const messages = await Message.findAll({ where: { conversationId: { [Op.in]: conversationIds } }, attributes: ['id'], transaction }); const messageIds = messages.map((row) => row.id);
    await Conversation.update({ lastMessageId: null, lastMessageAt: null }, { where: { id: { [Op.in]: conversationIds } }, transaction });
    await ConversationParticipant.update({ lastReadMessageId: null, lastReadAt: null }, { where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    await RoseTransaction.update({ conversationId: null }, { where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    if (messageIds.length) await MessageMedia.destroy({ where: { messageId: { [Op.in]: messageIds } }, transaction });
    await Message.destroy({ where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    await ConversationParticipant.destroy({ where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    await Conversation.destroy({ where: { id: { [Op.in]: conversationIds } }, transaction });
  }
  const notifications = await Notification.findAll({ where: { [Op.or]: [{ userId: { [Op.in]: userIds } }, { actorUserId: { [Op.in]: userIds } }] }, attributes: ['id'], transaction }); const notificationIds = notifications.map((row) => row.id);
  if (notificationIds.length) await NotificationDelivery.destroy({ where: { notificationId: { [Op.in]: notificationIds } }, transaction });
  await Notification.destroy({ where: { [Op.or]: [{ userId: { [Op.in]: userIds } }, { actorUserId: { [Op.in]: userIds } }] }, transaction });
  const devices = await UserDevice.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['id'], transaction }); const deviceIds = devices.map((row) => row.id);
  if (deviceIds.length) await NotificationDelivery.destroy({ where: { userDeviceId: { [Op.in]: deviceIds } }, transaction });
  await UserDevice.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  const payments = await Payment.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['id'], transaction }); const paymentIds = payments.map((row) => row.id);
  if (paymentIds.length) await PaymentEvent.destroy({ where: { paymentId: { [Op.in]: paymentIds } }, transaction }); await Payment.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  const organizedEvents = await Event.findAll({ where: { organizerId: { [Op.in]: userIds } }, attributes: ['id'], transaction }); const eventIds = organizedEvents.map((row) => row.id);
  if (eventIds.length) { const registrations = await EventRegistration.findAll({ where: { eventId: { [Op.in]: eventIds } }, attributes: ['userId'], transaction }); const seedSet = new Set(userIds); if (registrations.some((row) => !seedSet.has(row.userId))) throw new Error('Refusing to reset a seed event with a non-seed attendee.'); await EventRegistration.destroy({ where: { eventId: { [Op.in]: eventIds } }, transaction }); await EventWaitlist.destroy({ where: { eventId: { [Op.in]: eventIds } }, transaction }); await Event.destroy({ where: { id: { [Op.in]: eventIds } }, transaction }); }
  await EventRegistration.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await EventWaitlist.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  const verifications = await IdentityVerification.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['id'], transaction }); const verificationIds = verifications.map((row) => row.id);
  if (verificationIds.length) await IdentityVerificationDecisionEvent.sequelize.query(
    'DELETE FROM `IdentityVerificationDecisionEvents` WHERE `verificationId` IN (:verificationIds)',
    { replacements: { verificationIds }, transaction },
  );
  await IdentityVerification.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await ConsentEvent.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await Report.destroy({ where: { [Op.or]: [{ reporterUserId: { [Op.in]: userIds } }, { reportedUserId: { [Op.in]: userIds } }] }, transaction });
  await RoseTransaction.destroy({ where: { [Op.or]: [{ senderId: { [Op.in]: userIds } }, { recipientId: { [Op.in]: userIds } }] }, transaction });
  await DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: { [Op.in]: userIds } }, { targetUserId: { [Op.in]: userIds } }] }, transaction });
  await Match.destroy({ where: { [Op.or]: [{ userOneId: { [Op.in]: userIds } }, { userTwoId: { [Op.in]: userIds } }] }, transaction });
  await SavedProfile.destroy({ where: { [Op.or]: [{ userId: { [Op.in]: userIds } }, { savedUserId: { [Op.in]: userIds } }] }, transaction });
  await Block.destroy({ where: { [Op.or]: [{ blockerUserId: { [Op.in]: userIds } }, { blockedUserId: { [Op.in]: userIds } }] }, transaction });
  await DiscoverFilterPreference.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await NotificationPreference.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await Subscription.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await RefreshToken.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await OnboardingProfile.destroy({ where: { userId: { [Op.in]: userIds } }, transaction }); await User.destroy({ where: { id: { [Op.in]: userIds } }, transaction });
  return { users: userIds.length, conversations: conversationIds.length };
}

async function seedDummyData(models, config, mediaUrls, transaction, suppliedBlueprint) {
  const { User, OnboardingProfile, DiscoverAction, Match, Conversation, ConversationParticipant, Message, MessageMedia, RoseTransaction, SavedProfile, Block, DiscoverFilterPreference, NotificationPreference, Notification, SubscriptionPlan, Subscription, LegalDocumentVersion, ConsentEvent, IdentityVerification, Report } = models;
  const blueprint = suppliedBlueprint || buildSeedBlueprint(config); const passwordHash = await bcrypt.hash(config.password, 10);
  await User.bulkCreate(blueprint.users.map((entry) => ({ name: entry.name, email: entry.email, phoneNumber: entry.phoneNumber, passwordHash, authProvider: 'local', isVerified: true, termsAcceptedAt: entry.createdAt, accountStatus: entry.accountStatus, deactivatedAt: entry.accountStatus === 'deactivated' ? entry.updatedAt : null, lastActiveAt: entry.lastActiveAt, identityVerifiedAt: entry.identityVerified ? entry.updatedAt : null, createdAt: entry.createdAt, updatedAt: entry.updatedAt })), { transaction, validate: true });
  const createdUsers = await findSeedUsers(User, config, transaction); const byEmail = new Map(createdUsers.map((row) => [row.email, row]));
  const entries = blueprint.users.map((entry) => ({ ...entry, id: byEmail.get(entry.email).id })); const byKey = new Map(entries.map((entry) => [entry.key, entry])); const master = byKey.get('master');

  const legalDocuments = await LegalDocumentVersion.findAll({ where: { status: 'ACTIVE' }, transaction }); const legalByKey = new Map(legalDocuments.map((row) => [row.documentKey, row]));
  if (!legalByKey.has('TERMS_OF_SERVICE') || !legalByKey.has('PRIVACY_POLICY')) throw new Error('Active Terms and Privacy document versions are required before dummy seeding.');
  await ConsentEvent.bulkCreate(entries.flatMap((entry) => [
    { userId: entry.id, documentVersionId: legalByKey.get('TERMS_OF_SERVICE').id, purpose: 'TERMS_OF_SERVICE_ACCEPTANCE', action: 'ACCEPTED', source: 'SIGNUP_EMAIL', platform: 'ANDROID', occurredAt: entry.createdAt, metadata: { appVersion: 'development-seed', flowVersion: 'v2' } },
    { userId: entry.id, documentVersionId: legalByKey.get('PRIVACY_POLICY').id, purpose: 'PRIVACY_POLICY_ACKNOWLEDGEMENT', action: 'ACKNOWLEDGED', source: 'SIGNUP_EMAIL', platform: 'ANDROID', occurredAt: entry.createdAt, metadata: { appVersion: 'development-seed', flowVersion: 'v2' } },
  ]), { transaction, validate: true });
  await OnboardingProfile.bulkCreate(entries.map((entry, index) => ({ userId: entry.id, birthDate: entry.birthDate, gender: entry.gender, customGender: entry.gender === 'Other' ? 'Non-binary' : '', interestedIn: entry.interestedIn, relationshipGoals: entry.relationshipGoals, city: entry.city, preferredDistance: entry.preferredDistance, profession: entry.profession, company: entry.company, education: entry.education, bio: entry.bio, iceBreaker: entry.iceBreaker, hometown: entry.hometown, interests: entry.interests, lifestyle: entry.lifestyle, prompts: entry.prompts, pronouns: entry.pronouns, sexuality: entry.sexuality, valuedQualities: entry.valuedQualities, loveLanguages: entry.loveLanguages, preferredTalkingHours: entry.preferredTalkingHours, communicationStyle: entry.communicationStyle, photos: mediaUrls[index], primaryPhotoIndex: 0, height: `${entry.heightCm} cm`, smoking: entry.smoking, drinking: entry.drinking, weed: entry.weed, community: entry.community, religion: entry.religion, languages: entry.languages, stage: entry.completed ? 'complete' : 'photos', onboardingCompleted: entry.completed, createdAt: entry.createdAt, updatedAt: entry.updatedAt })), { transaction, validate: true });
  await DiscoverFilterPreference.bulkCreate(entries.map((entry) => ({ userId: entry.id, minAge: entry.key === 'master' ? 21 : 21, maxAge: entry.key === 'master' ? 38 : 40, maxDistanceKm: entry.key === 'master' ? 500 : 200, minScore: 0, city: null, minHeight: null, hometown: [], datingIntentions: [], lifestyleTags: [], education: null, profession: null, community: null, religion: null, languages: [], pronouns: [], sexuality: null, qualities: [], preferredTalkingHours: [], loveLanguages: [], communicationStyles: [], smoking: null, drinking: null, weed: null, verifiedOnly: false, onlineNow: false, hasPrompts: false, hasEventInterest: false, createdAt: entry.createdAt, updatedAt: entry.updatedAt })), { transaction, validate: true });
  await NotificationPreference.bulkCreate(entries.map((entry, index) => ({ userId: entry.id, newMatches: true, messages: true, eventReminders: true, paymentsAndMembership: true, offers: index % 3 === 0, safetyUpdates: true, pushEnabled: false, emailEnabled: true, smsEnabled: false, quietHoursEnabled: true, quietStart: '22:00', quietEnd: '07:00', createdAt: entry.createdAt, updatedAt: entry.updatedAt })), { transaction, validate: true });
  for (const plan of plans) await SubscriptionPlan.upsert(plan, { transaction });
  const premiumEntries = entries.filter((entry) => entry.premium && entry.accountStatus === 'active');
  await Subscription.bulkCreate(premiumEntries.map((entry) => ({ userId: entry.id, planId: plans[plans.length - 1].id, status: 'active', provider: 'seed', providerCustomerId: `seed-customer-${entry.id}`, providerSubscriptionId: `seed-subscription-${entry.id}`, startedAt: dateDaysBefore(config.referenceDate, 20), currentPeriodStart: dateDaysBefore(config.referenceDate, 10), currentPeriodEnd: new Date(config.referenceDate.getTime() + 20 * 86400000), autoRenew: true, cancelAtPeriodEnd: false, createdAt: entry.createdAt, updatedAt: entry.updatedAt })), { transaction, validate: true });
  const verifiedEntries = entries.filter((entry) => entry.identityVerified);
  await IdentityVerification.bulkCreate(verifiedEntries.map((entry) => ({ userId: entry.id, status: 'verified', aadhaarStoragePath: `dummy-seed/${entry.key}/aadhaar.webp`, aadhaarMimeType: 'image/webp', aadhaarSizeBytes: 1, selfieStoragePath: `dummy-seed/${entry.key}/selfie.webp`, selfieMimeType: 'image/webp', selfieSizeBytes: 1, submittedAt: entry.createdAt, reviewedAt: entry.updatedAt, reviewVersion: 1, submissionVersion: 1, createdAt: entry.createdAt, updatedAt: entry.updatedAt })), { transaction, validate: true });

  const actions = new Map(); const now = config.referenceDate;
  setAction(actions, master.id, byKey.get('candidate-e').id, 'like', dateDaysBefore(now, 2));
  setAction(actions, byKey.get('candidate-f').id, master.id, 'like', dateDaysBefore(now, 1));
  setAction(actions, byKey.get('candidate-g').id, master.id, 'superLike', dateDaysBefore(now, 1, 30));
  const matchKeys = ['candidate-i', 'candidate-j', 'candidate-k', 'candidate-l', 'candidate-u', 'candidate-v', 'candidate-w'];
  for (const [index, key] of matchKeys.entries()) { const other = byKey.get(key); setAction(actions, master.id, other.id, index === 3 ? 'superLike' : 'like', dateDaysBefore(now, 30 - index)); setAction(actions, other.id, master.id, 'like', dateDaysBefore(now, 30 - index, 5)); }
  entries.filter((entry) => entry.role === 'PAGINATION_POOL').slice(0, 8).forEach((entry, index) => setAction(actions, entry.id, master.id, index === 0 ? 'superLike' : 'like', dateDaysBefore(now, 1 + index)));
  await DiscoverAction.bulkCreate([...actions.values()], { transaction, validate: true });
  const matchRows = matchKeys.map((key, index) => { const [userOneId, userTwoId] = stablePair(master.id, byKey.get(key).id); return { userOneId, userTwoId, matchedAt: dateDaysBefore(now, 30 - index) }; });
  await Match.bulkCreate(matchRows, { transaction, validate: true }); await Conversation.bulkCreate(matchRows.map((row) => ({ pairKey: pairKey(row.userOneId, row.userTwoId), type: 'direct', lastMessageAt: row.matchedAt, createdAt: row.matchedAt, updatedAt: row.matchedAt })), { transaction, validate: true });
  const conversations = await Conversation.findAll({ where: { pairKey: { [Op.in]: matchRows.map((row) => pairKey(row.userOneId, row.userTwoId)) } }, transaction }); const conversationByPair = new Map(conversations.map((row) => [row.pairKey, row]));
  await ConversationParticipant.bulkCreate(matchRows.flatMap((row) => { const conversation = conversationByPair.get(pairKey(row.userOneId, row.userTwoId)); return [row.userOneId, row.userTwoId].map((userId) => ({ conversationId: conversation.id, userId, joinedAt: row.matchedAt, createdAt: row.matchedAt, updatedAt: row.matchedAt })); }), { transaction, validate: true });

  const roseConversation = conversationByPair.get(pairKey(master.id, byKey.get('candidate-l').id));
  const roseRows = await RoseTransaction.bulkCreate([
    { senderId: byKey.get('candidate-l').id, recipientId: master.id, conversationId: roseConversation.id, idempotencyKey: `amoraa-v2-${config.randomSeed}-incoming-chat-rose`, status: 'sent', note: 'A thoughtful hello for our conversation.', createdAt: dateDaysBefore(now, 3), updatedAt: dateDaysBefore(now, 3) },
    { senderId: byKey.get('candidate-g').id, recipientId: master.id, conversationId: null, idempotencyKey: `amoraa-v2-${config.randomSeed}-incoming-profile-rose`, status: 'sent', note: 'Your profile stood out to me.', createdAt: dateDaysBefore(now, 1), updatedAt: dateDaysBefore(now, 1) },
  ], { transaction, validate: true, returning: true });
  const chatRose = roseRows[0]; const messageRows = [];
  const messageCounts = { 'candidate-i': 0, 'candidate-j': 4, 'candidate-k': 8, 'candidate-l': 5, 'candidate-u': 55, 'candidate-v': 12, 'candidate-w': 3 };
  for (const [key, count] of Object.entries(messageCounts)) { const other = byKey.get(key); const conversation = conversationByPair.get(pairKey(master.id, other.id)); for (let i = 0; i < count; i += 1) { const incoming = i % 2 === 0; messageRows.push({ conversationId: conversation.id, senderId: incoming ? other.id : master.id, type: 'text', text: MESSAGE_LINES[(i + other.sequence) % MESSAGE_LINES.length], context: null, status: key === 'candidate-k' && incoming && i >= count - 3 ? 'delivered' : 'read', deliveredAt: dateDaysBefore(now, Math.max(1, 20 - i)), readAt: key === 'candidate-k' && incoming && i >= count - 3 ? null : dateDaysBefore(now, Math.max(1, 20 - i), -5), createdAt: dateDaysBefore(now, Math.max(1, 20 - i)), updatedAt: dateDaysBefore(now, Math.max(1, 20 - i)) }); } }
  if (messageRows.length) await Message.bulkCreate(messageRows, { transaction, validate: true });
  const roseMessage = await Message.create({ conversationId: roseConversation.id, senderId: byKey.get('candidate-l').id, type: 'rose', roseTransactionId: chatRose.id, text: chatRose.note, context: { type: 'rose', title: 'Rose', detail: 'A special AMORAA Rose' }, status: 'delivered', deliveredAt: dateDaysBefore(now, 3), createdAt: dateDaysBefore(now, 3), updatedAt: dateDaysBefore(now, 3) }, { transaction });
  const imageConversation = conversationByPair.get(pairKey(master.id, byKey.get('candidate-w').id)); const imageMessage = await Message.create({ conversationId: imageConversation.id, senderId: byKey.get('candidate-w').id, type: 'image', text: 'The view from my walk today.', status: 'delivered', deliveredAt: dateDaysBefore(now, 1), createdAt: dateDaysBefore(now, 1), updatedAt: dateDaysBefore(now, 1) }, { transaction });
  const chatFile = path.join(config.chatMediaDirectory, 'amoraa-v2-seed-chat-image.webp'); const chatSize = fs.statSync(chatFile).size;
  await MessageMedia.create({ messageId: imageMessage.id, mediaType: 'image', originalName: 'development-walk.webp', storagePath: 'chat-media/amoraa-v2-seed-chat-image.webp', mimeType: 'image/webp', sizeBytes: chatSize, createdAt: imageMessage.createdAt }, { transaction });
  const allMessages = await Message.findAll({ where: { conversationId: { [Op.in]: conversations.map((row) => row.id) } }, order: [['id', 'ASC']], transaction });
  for (const conversation of conversations) { const values = allMessages.filter((row) => row.conversationId === conversation.id); if (!values.length) continue; const last = values[values.length - 1]; await conversation.update({ lastMessageId: last.id, lastMessageAt: last.createdAt }, { transaction }); const participants = await ConversationParticipant.findAll({ where: { conversationId: conversation.id }, transaction }); for (const participant of participants) { const unreadScenario = conversation.id === conversationByPair.get(pairKey(master.id, byKey.get('candidate-k').id)).id && participant.userId === master.id; const readTo = unreadScenario ? values[Math.max(0, values.length - 4)] : last; await participant.update({ lastReadMessageId: readTo?.id || null, lastReadAt: readTo?.createdAt || null, mutedAt: conversation.id === imageConversation.id && participant.userId === master.id ? dateDaysBefore(now, 1) : null }, { transaction }); } }

  await SavedProfile.create({ userId: master.id, savedUserId: byKey.get('candidate-m').id, createdAt: dateDaysBefore(now, 2), updatedAt: now }, { transaction });
  await Block.create({ blockerUserId: master.id, blockedUserId: byKey.get('candidate-n').id, createdAt: dateDaysBefore(now, 2), updatedAt: now }, { transaction });
  await Report.bulkCreate([{ reporterUserId: byKey.get('candidate-r').id, reportedUserId: byKey.get('candidate-q').id, targetType: 'profile', targetId: String(byKey.get('candidate-q').id), reason: 'fake_profile', notes: 'Controlled development-only moderation fixture.', status: 'open', createdAt: dateDaysBefore(now, 4), updatedAt: dateDaysBefore(now, 4) }], { transaction, validate: true });
  const notifications = [
    { userId: master.id, actorUserId: byKey.get('candidate-f').id, type: 'new_like', category: 'Likes', dedupeKey: 'amoraa-v2-master-like', title: 'You received a like', message: 'Someone new liked your profile.', isRead: false, readAt: null, data: { actorUserId: byKey.get('candidate-f').id }, createdAt: dateDaysBefore(now, 1), updatedAt: dateDaysBefore(now, 1) },
    { userId: master.id, actorUserId: byKey.get('candidate-g').id, type: 'new_super_like', category: 'Super Likes', dedupeKey: 'amoraa-v2-master-super-like', title: 'You received a Super Like', message: 'Someone sent you a Super Like.', isRead: false, readAt: null, data: { actorUserId: byKey.get('candidate-g').id }, createdAt: dateDaysBefore(now, 1, 10), updatedAt: dateDaysBefore(now, 1, 10) },
    { userId: master.id, actorUserId: byKey.get('candidate-l').id, type: 'rose_received', category: 'message', dedupeKey: 'amoraa-v2-master-rose', title: 'You received a Rose', message: chatRose.note, isRead: false, readAt: null, data: { conversationId: String(roseConversation.id), roseTransactionId: String(chatRose.id) }, createdAt: dateDaysBefore(now, 3), updatedAt: dateDaysBefore(now, 3) },
  ];
  await Notification.bulkCreate(notifications, { transaction, validate: true });
  return { entries, master, counts: { users: entries.length, profiles: entries.length, actions: actions.size, likes: [...actions.values()].filter((row) => row.action === 'like').length, superLikes: [...actions.values()].filter((row) => row.action === 'superLike').length, roses: roseRows.length, matches: matchRows.length, conversations: conversations.length, messages: allMessages.length, savedProfiles: 1, blocks: 1, reports: 1, notifications: notifications.length, subscriptions: premiumEntries.length }, fingerprint: shortHash(JSON.stringify(entries.map(({ email, role, birthDate, interests }) => ({ email, role, birthDate, interests })))) };
}

module.exports = { findSeedUsers, resetSeedData, seedDummyData };
