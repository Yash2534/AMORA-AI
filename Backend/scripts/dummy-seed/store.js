const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const { plans } = require('../seed-subscription-plans');
const {
  MESSAGE_LINES, buildSeedBlueprint, dateDaysBefore, integer, pairKey, pick, sample, shortHash, stablePair,
} = require('./factory');

function setAction(map, actorUserId, targetUserId, action, createdAt) {
  if (actorUserId === targetUserId) return;
  map.set(`${actorUserId}:${targetUserId}`, { actorUserId, targetUserId, action, createdAt, updatedAt: createdAt });
}

async function findSeedUsers(User, config, transaction) {
  return User.findAll({ where: { email: { [Op.like]: `%${config.emailSuffix}` } }, transaction });
}

async function resetSeedData(models, config, transaction) {
  const { User, ConversationParticipant, Conversation, Message, MessageMedia, RoseTransaction, Notification,
    NotificationDelivery, UserDevice, DiscoverAction, Match, SavedProfile, Block, DiscoverFilterPreference,
    NotificationPreference, Subscription, Payment, PaymentEvent, Event, EventRegistration, EventWaitlist,
    Report, IdentityVerification, IdentityVerificationDecisionEvent, RefreshToken, OnboardingProfile } = models;
  const seedUsers = await findSeedUsers(User, config, transaction);
  const userIds = seedUsers.map((user) => user.id);
  if (!userIds.length) return { users: 0, conversations: 0 };

  const memberships = await ConversationParticipant.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['conversationId'], transaction });
  const conversationIds = [...new Set(memberships.map((membership) => membership.conversationId))];
  if (conversationIds.length) {
    const allConversationMembers = await ConversationParticipant.findAll({
      where: { conversationId: { [Op.in]: conversationIds } }, attributes: ['conversationId', 'userId'], transaction,
    });
    const seedIdSet = new Set(userIds);
    if (allConversationMembers.some((membership) => !seedIdSet.has(membership.userId))) {
      throw new Error('Refusing to reset: a seed user is in a conversation with a non-seed user. Remove that mixed conversation intentionally before resetting dummy data.');
    }
  }
  if (conversationIds.length) {
    const messages = await Message.findAll({ where: { conversationId: { [Op.in]: conversationIds } }, attributes: ['id'], transaction });
    const messageIds = messages.map((message) => message.id);
    await Conversation.update({ lastMessageId: null, lastMessageAt: null }, { where: { id: { [Op.in]: conversationIds } }, transaction });
    await ConversationParticipant.update({ lastReadMessageId: null, lastReadAt: null }, { where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    await RoseTransaction.update({ conversationId: null }, { where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    if (messageIds.length) await MessageMedia.destroy({ where: { messageId: { [Op.in]: messageIds } }, transaction });
    await Message.destroy({ where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    await ConversationParticipant.destroy({ where: { conversationId: { [Op.in]: conversationIds } }, transaction });
    await Conversation.destroy({ where: { id: { [Op.in]: conversationIds } }, transaction });
  }

  const notifications = await Notification.findAll({ where: { [Op.or]: [{ userId: { [Op.in]: userIds } }, { actorUserId: { [Op.in]: userIds } }] }, attributes: ['id'], transaction });
  const notificationIds = notifications.map((notification) => notification.id);
  if (notificationIds.length) await NotificationDelivery.destroy({ where: { notificationId: { [Op.in]: notificationIds } }, transaction });
  await Notification.destroy({ where: { [Op.or]: [{ userId: { [Op.in]: userIds } }, { actorUserId: { [Op.in]: userIds } }] }, transaction });

  const devices = await UserDevice.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['id'], transaction });
  const deviceIds = devices.map((device) => device.id);
  if (deviceIds.length) await NotificationDelivery.destroy({ where: { userDeviceId: { [Op.in]: deviceIds } }, transaction });
  await UserDevice.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });

  const payments = await Payment.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['id'], transaction });
  const paymentIds = payments.map((payment) => payment.id);
  if (paymentIds.length) await PaymentEvent.destroy({ where: { paymentId: { [Op.in]: paymentIds } }, transaction });
  await Payment.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });

  const organizedEvents = await Event.findAll({ where: { organizerId: { [Op.in]: userIds } }, attributes: ['id'], transaction });
  const eventIds = organizedEvents.map((event) => event.id);
  if (eventIds.length) {
    const eventAttendees = await EventRegistration.findAll({ where: { eventId: { [Op.in]: eventIds } }, attributes: ['userId'], transaction });
    const seedIdSet = new Set(userIds);
    if (eventAttendees.some((registration) => !seedIdSet.has(registration.userId))) {
      throw new Error('Refusing to reset: a seed-organized event has a non-seed registration. Remove that mixed registration intentionally before resetting dummy data.');
    }
    await EventRegistration.destroy({ where: { eventId: { [Op.in]: eventIds } }, transaction });
    await EventWaitlist.destroy({ where: { eventId: { [Op.in]: eventIds } }, transaction });
    await Event.destroy({ where: { id: { [Op.in]: eventIds } }, transaction });
  }
  await EventRegistration.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await EventWaitlist.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });

  const verifications = await IdentityVerification.findAll({ where: { userId: { [Op.in]: userIds } }, attributes: ['id'], transaction });
  const verificationIds = verifications.map((verification) => verification.id);
  if (verificationIds.length) await IdentityVerificationDecisionEvent.destroy({ where: { verificationId: { [Op.in]: verificationIds } }, transaction });
  await IdentityVerification.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await Report.destroy({ where: { [Op.or]: [{ reporterUserId: { [Op.in]: userIds } }, { reportedUserId: { [Op.in]: userIds } }] }, transaction });
  await RoseTransaction.destroy({ where: { [Op.or]: [{ senderId: { [Op.in]: userIds } }, { recipientId: { [Op.in]: userIds } }] }, transaction });
  await DiscoverAction.destroy({ where: { [Op.or]: [{ actorUserId: { [Op.in]: userIds } }, { targetUserId: { [Op.in]: userIds } }] }, transaction });
  await Match.destroy({ where: { [Op.or]: [{ userOneId: { [Op.in]: userIds } }, { userTwoId: { [Op.in]: userIds } }] }, transaction });
  await SavedProfile.destroy({ where: { [Op.or]: [{ userId: { [Op.in]: userIds } }, { savedUserId: { [Op.in]: userIds } }] }, transaction });
  await Block.destroy({ where: { [Op.or]: [{ blockerUserId: { [Op.in]: userIds } }, { blockedUserId: { [Op.in]: userIds } }] }, transaction });
  await DiscoverFilterPreference.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await NotificationPreference.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await Subscription.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await RefreshToken.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await OnboardingProfile.destroy({ where: { userId: { [Op.in]: userIds } }, transaction });
  await User.destroy({ where: { id: { [Op.in]: userIds } }, transaction });
  return { users: userIds.length, conversations: conversationIds.length };
}

async function seedDummyData(models, config, mediaUrls, transaction) {
  const { User, OnboardingProfile, DiscoverAction, Match, Conversation, ConversationParticipant, Message,
    RoseTransaction, SavedProfile, Block, DiscoverFilterPreference, NotificationPreference, Notification,
    SubscriptionPlan, Subscription } = models;
  const blueprint = buildSeedBlueprint(config);
  const passwordHash = await bcrypt.hash(config.password, 10);

  await User.bulkCreate(blueprint.users.map((entry) => ({
    name: entry.name, email: entry.email, phoneNumber: entry.phoneNumber, passwordHash, authProvider: 'local',
    isVerified: true, termsAcceptedAt: entry.createdAt, accountStatus: entry.accountStatus,
    deactivatedAt: entry.accountStatus === 'deactivated' ? entry.updatedAt : null,
    lastActiveAt: entry.lastActiveAt, identityVerifiedAt: entry.identityVerified ? entry.updatedAt : null,
    createdAt: entry.createdAt, updatedAt: entry.updatedAt,
  })), { transaction, validate: true });

  const createdUsers = await findSeedUsers(User, config, transaction);
  const byEmail = new Map(createdUsers.map((user) => [user.email, user]));
  const entries = blueprint.users.map((entry) => ({ ...entry, id: byEmail.get(entry.email).id }));
  const byKey = new Map(entries.map((entry) => [entry.key, entry]));

  await OnboardingProfile.bulkCreate(entries.map((entry, index) => ({
    userId: entry.id, birthDate: entry.birthDate, gender: entry.gender, customGender: entry.gender === 'Other' ? 'Non-binary' : '',
    interestedIn: entry.interestedIn, relationshipGoals: entry.relationshipGoals, city: entry.city,
    preferredDistance: entry.preferredDistance, profession: entry.profession, company: entry.company,
    education: entry.education, bio: entry.bio, iceBreaker: entry.iceBreaker, hometown: entry.hometown,
    interests: entry.interests, lifestyle: entry.lifestyle, prompts: entry.prompts, pronouns: entry.pronouns,
    sexuality: entry.sexuality, valuedQualities: entry.valuedQualities, loveLanguages: entry.loveLanguages,
    preferredTalkingHours: entry.preferredTalkingHours, communicationStyle: entry.communicationStyle,
    photos: Array.from({ length: entry.photoCount }, (_, photoIndex) => mediaUrls[(index * 3 + photoIndex) % mediaUrls.length]),
    primaryPhotoIndex: 0, height: `${entry.heightCm} cm`, smoking: entry.smoking, drinking: entry.drinking,
    weed: entry.weed, community: entry.community, religion: entry.religion, languages: entry.languages,
    stage: entry.completed ? 'complete' : 'photos', onboardingCompleted: entry.completed,
    createdAt: entry.createdAt, updatedAt: entry.updatedAt,
  })), { transaction, validate: true });

  await DiscoverFilterPreference.bulkCreate(entries.map((entry, index) => ({
    userId: entry.id, minAge: entry.demo ? 18 : Math.max(18, entry.age - (index % 3 === 0 ? 3 : 8)), maxAge: entry.demo ? 99 : Math.min(99, entry.age + (index % 4 === 0 ? 4 : 12)),
    maxDistanceKm: entry.demo ? 500 : entry.preferredDistance, minScore: entry.demo ? 0 : index % 6 === 0 ? 60 : 0, city: entry.demo ? null : index % 3 === 0 ? entry.city : null,
    minHeight: entry.demo ? null : index % 5 === 0 ? 160 : null, hometown: entry.demo ? [] : index % 4 === 0 ? [entry.hometown] : [],
    datingIntentions: entry.demo ? [] : entry.relationshipGoals, lifestyleTags: entry.demo ? [] : index % 3 === 0 ? [entry.lifestyle.Exercise] : [],
    education: entry.demo ? null : index % 8 === 0 ? entry.education : null, profession: entry.demo ? null : index % 10 === 0 ? entry.profession : null,
    community: entry.demo ? null : index % 11 === 0 ? entry.community : null, religion: entry.demo ? null : index % 7 === 0 ? entry.religion : null,
    languages: entry.demo ? [] : entry.languages.slice(0, 1), pronouns: [], sexuality: null, qualities: entry.demo ? [] : entry.valuedQualities.slice(0, 2),
    preferredTalkingHours: entry.demo ? [] : entry.preferredTalkingHours.slice(0, 1), loveLanguages: entry.demo ? [] : entry.loveLanguages.slice(0, 1),
    communicationStyles: entry.demo ? [] : [entry.communicationStyle], smoking: null, drinking: null, weed: null,
    verifiedOnly: entry.demo ? false : index % 4 === 0, onlineNow: false, hasPrompts: entry.demo ? false : index % 2 === 0, hasEventInterest: false,
    createdAt: entry.createdAt, updatedAt: entry.updatedAt,
  })), { transaction, validate: true });
  await NotificationPreference.bulkCreate(entries.map((entry, index) => ({
    userId: entry.id, newMatches: true, messages: true, eventReminders: index % 7 !== 0,
    paymentsAndMembership: true, offers: index % 5 === 0, safetyUpdates: true,
    pushEnabled: index % 3 === 0, emailEnabled: true, smsEnabled: false,
    quietHoursEnabled: true, quietStart: '22:00', quietEnd: '07:00',
    createdAt: entry.createdAt, updatedAt: entry.updatedAt,
  })), { transaction, validate: true });

  for (const plan of plans) await SubscriptionPlan.upsert(plan, { transaction });
  const premiumEntries = entries.filter((entry, index) => entry.accountStatus === 'active' && (entry.demo || index % 9 === 0));
  await Subscription.bulkCreate(premiumEntries.map((entry, index) => ({
    userId: entry.id, planId: plans[index % plans.length].id, status: 'active', provider: 'seed',
    providerCustomerId: `seed-customer-${entry.id}`, providerSubscriptionId: `seed-subscription-${entry.id}`,
    startedAt: dateDaysBefore(config.referenceDate, 20 + index), currentPeriodStart: dateDaysBefore(config.referenceDate, 10),
    currentPeriodEnd: new Date(config.referenceDate.getTime() + 20 * 86400000), autoRenew: index % 2 === 0,
    cancelAtPeriodEnd: false, createdAt: entry.createdAt, updatedAt: entry.updatedAt,
  })), { transaction, validate: true });

  const eligible = entries.filter((entry) => entry.completed && entry.accountStatus === 'active');
  const actions = new Map();
  eligible.forEach((actor, actorIndex) => {
    const actionCount = 8 + (actorIndex % 8);
    for (let step = 1; step <= actionCount; step += 1) {
      const target = eligible[(actorIndex + step * 7) % eligible.length];
      if (actor.key === 'demo-a' && target.key === 'demo-b') continue;
      const roll = (actorIndex * 17 + step * 13) % 10;
      setAction(actions, actor.id, target.id, roll < 3 ? 'pass' : roll === 9 ? 'superLike' : 'like', dateDaysBefore(config.referenceDate, step % 25, actorIndex));
    }
  });
  const demoA = byKey.get('demo-a'); const demoB = byKey.get('demo-b'); const demoC = byKey.get('demo-c');
  setAction(actions, demoB.id, demoA.id, 'like', dateDaysBefore(config.referenceDate, 1));
  setAction(actions, demoA.id, demoC.id, 'like', dateDaysBefore(config.referenceDate, 14));
  setAction(actions, demoC.id, demoA.id, 'superLike', dateDaysBefore(config.referenceDate, 14));
  for (const [seedOffset, actor] of eligible.slice(3, Math.min(63, eligible.length)).entries()) {
    setAction(actions, actor.id, demoA.id, seedOffset % 7 === 0 ? 'superLike' : 'like', dateDaysBefore(config.referenceDate, seedOffset % 30));
  }
  for (let index = 3; index + 1 < eligible.length; index += 6) {
    const first = eligible[index]; const second = eligible[index + 1];
    setAction(actions, first.id, second.id, 'like', dateDaysBefore(config.referenceDate, index % 90));
    setAction(actions, second.id, first.id, index % 12 === 3 ? 'superLike' : 'like', dateDaysBefore(config.referenceDate, index % 90));
  }
  await DiscoverAction.bulkCreate([...actions.values()], { transaction, validate: true });

  const positive = new Map([...actions.values()].filter((item) => item.action !== 'pass').map((item) => [`${item.actorUserId}:${item.targetUserId}`, item]));
  const matchMap = new Map();
  for (const action of positive.values()) {
    if (!positive.has(`${action.targetUserId}:${action.actorUserId}`)) continue;
    const [userOneId, userTwoId] = stablePair(action.actorUserId, action.targetUserId);
    const key = pairKey(userOneId, userTwoId);
    if (!matchMap.has(key)) matchMap.set(key, { userOneId, userTwoId, matchedAt: action.createdAt });
  }
  await Match.bulkCreate([...matchMap.values()], { transaction, validate: true });
  await Conversation.bulkCreate([...matchMap.values()].map((match) => ({
    pairKey: pairKey(match.userOneId, match.userTwoId), type: 'direct', lastMessageAt: match.matchedAt,
    createdAt: match.matchedAt, updatedAt: match.matchedAt,
  })), { transaction, validate: true });
  const conversations = await Conversation.findAll({ where: { pairKey: { [Op.in]: [...matchMap.keys()] } }, transaction });
  const conversationByPair = new Map(conversations.map((conversation) => [conversation.pairKey, conversation]));
  await ConversationParticipant.bulkCreate([...matchMap.values()].flatMap((match) => {
    const conversation = conversationByPair.get(pairKey(match.userOneId, match.userTwoId));
    return [match.userOneId, match.userTwoId].map((userId) => ({ conversationId: conversation.id, userId, joinedAt: match.matchedAt, createdAt: match.matchedAt, updatedAt: match.matchedAt }));
  }), { transaction, validate: true });

  const messageRows = [];
  for (const [index, match] of [...matchMap.values()].entries()) {
    const key = pairKey(match.userOneId, match.userTwoId);
    const isDemoConversation = key === pairKey(demoA.id, demoC.id);
    const messageCount = isDemoConversation ? 55 : index % 7 === 0 ? 0 : index % 7 === 1 ? 1 : index % 7 === 2 ? 6 : 12 + (index % 24);
    for (let messageIndex = 0; messageIndex < messageCount; messageIndex += 1) {
      const createdAt = new Date(match.matchedAt.getTime() + (messageIndex + 1) * 18 * 60 * 1000);
      const read = messageIndex < Math.max(0, messageCount - (index % 4));
      messageRows.push({ conversationId: conversationByPair.get(key).id,
        senderId: messageIndex % 2 === 0 ? match.userOneId : match.userTwoId, type: 'text',
        text: MESSAGE_LINES[(messageIndex + index) % MESSAGE_LINES.length], context: null,
        status: read ? 'read' : 'delivered', deliveredAt: createdAt, readAt: read ? new Date(createdAt.getTime() + 300000) : null,
        createdAt, updatedAt: createdAt });
    }
  }
  if (messageRows.length) await Message.bulkCreate(messageRows, { transaction, validate: true });
  const messages = conversations.length ? await Message.findAll({ where: { conversationId: { [Op.in]: conversations.map((value) => value.id) } }, order: [['id', 'ASC']], transaction }) : [];
  const messagesByConversation = new Map();
  for (const message of messages) {
    if (!messagesByConversation.has(message.conversationId)) messagesByConversation.set(message.conversationId, []);
    messagesByConversation.get(message.conversationId).push(message);
  }
  for (const conversation of conversations) {
    const values = messagesByConversation.get(conversation.id) || [];
    if (!values.length) continue;
    const last = values[values.length - 1];
    await conversation.update({ lastMessageId: last.id, lastMessageAt: last.createdAt }, { transaction });
    const participants = await ConversationParticipant.findAll({ where: { conversationId: conversation.id }, order: [['userId', 'ASC']], transaction });
    for (const [index, participant] of participants.entries()) {
      const readIndex = index === 0 ? values.length - 1 : Math.max(0, values.length - 3);
      const readMessage = values[readIndex];
      await participant.update({ lastReadMessageId: readMessage.id, lastReadAt: readMessage.createdAt,
        draftText: values.length > 10 && index === 1 ? 'That sounds like a lovely plan…' : null,
        mutedAt: values.length > 20 && index === 1 ? dateDaysBefore(config.referenceDate, 1) : null }, { transaction });
    }
  }

  const roseRows = [];
  for (let index = 0; index < eligible.length; index += 5) {
    const sender = eligible[index]; const recipient = index % 10 === 0 ? demoB : eligible[(index + 9) % eligible.length];
    if (sender.id === recipient.id) continue;
    const conversation = conversationByPair.get(pairKey(sender.id, recipient.id));
    roseRows.push({ senderId: sender.id, recipientId: recipient.id, conversationId: conversation?.id || null,
      idempotencyKey: `dummy-seed-${config.randomSeed}-${sender.id}-${recipient.id}`, status: 'sent',
      note: index % 2 === 0 ? 'Your profile felt thoughtful. I would love to say hello.' : null,
      createdAt: dateDaysBefore(config.referenceDate, index % 45), updatedAt: dateDaysBefore(config.referenceDate, index % 45) });
  }
  // A deterministic “Rose to an existing match” is useful for the video flow.
  // It uses the real RoseTransactions relationship; no separate Rose state exists.
  roseRows.push({ senderId: demoC.id, recipientId: demoA.id, conversationId: conversationByPair.get(pairKey(demoA.id, demoC.id)).id,
    idempotencyKey: `dummy-seed-${config.randomSeed}-demo-c-to-demo-a-match-rose`, status: 'sent',
    note: 'I enjoyed our conversation and wanted to send a little extra hello.',
    createdAt: dateDaysBefore(config.referenceDate, 13), updatedAt: dateDaysBefore(config.referenceDate, 13) });
  if (roseRows.length) await RoseTransaction.bulkCreate(roseRows, { transaction, validate: true });

  const savedMap = new Map();
  eligible.forEach((owner, index) => {
    for (let offset = 2; offset <= 4; offset += 1) {
      const target = eligible[(index + offset * 11) % eligible.length];
      if (owner.id !== target.id) savedMap.set(`${owner.id}:${target.id}`, { userId: owner.id, savedUserId: target.id, createdAt: dateDaysBefore(config.referenceDate, offset), updatedAt: config.referenceDate });
    }
  });
  await SavedProfile.bulkCreate([...savedMap.values()], { transaction, validate: true });
  const blocks = [];
  for (let index = 20; index + 13 < eligible.length; index += 37) {
    const blocker = eligible[index]; const blocked = eligible[index + 13];
    if (!matchMap.has(pairKey(blocker.id, blocked.id))) blocks.push({ blockerUserId: blocker.id, blockedUserId: blocked.id, createdAt: dateDaysBefore(config.referenceDate, 2), updatedAt: config.referenceDate });
  }
  if (blocks.length) await Block.bulkCreate(blocks, { transaction, validate: true });

  const notifications = [];
  for (const [index, action] of [...actions.values()].entries()) {
    if (action.action === 'pass' || index % 5 !== 0) continue;
    notifications.push({ userId: action.targetUserId, actorUserId: action.actorUserId,
      type: action.action === 'superLike' ? 'super_like' : 'like', category: 'matches',
      dedupeKey: `seed-action-${action.actorUserId}-${action.targetUserId}`, title: action.action === 'superLike' ? 'A new Super Like' : 'Someone likes you',
      message: action.action === 'superLike' ? 'Someone sent you a Super Like.' : 'Someone new liked your profile.',
      isRead: index % 4 === 0, readAt: index % 4 === 0 ? action.createdAt : null,
      data: { actorUserId: action.actorUserId }, createdAt: action.createdAt, updatedAt: action.updatedAt });
  }
  if (notifications.length) await Notification.bulkCreate(notifications, { transaction, validate: true });

  return {
    entries, demo: { a: demoA, b: demoB, c: demoC },
    counts: {
      users: entries.length, profiles: entries.length, actions: actions.size,
      likes: [...actions.values()].filter((value) => value.action === 'like').length,
      superLikes: [...actions.values()].filter((value) => value.action === 'superLike').length,
      roses: roseRows.length, matches: matchMap.size, conversations: conversations.length,
      messages: messageRows.length, savedProfiles: savedMap.size, blocks: blocks.length,
      notifications: notifications.length, subscriptions: premiumEntries.length,
    },
    fingerprint: shortHash(JSON.stringify(entries.map(({ email, birthDate, city, interests }) => ({ email, birthDate, city, interests })))),
  };
}

module.exports = { findSeedUsers, resetSeedData, seedDummyData };
