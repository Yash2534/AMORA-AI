const definitions = {
  User: require('./User'), OtpToken: require('./OtpToken'), RefreshToken: require('./RefreshToken'), OnboardingProfile: require('./OnboardingProfile'),
  DiscoverAction: require('./DiscoverAction'), Match: require('./Match'), DiscoverFilterPreference: require('./DiscoverFilterPreference'),
  Block: require('./Block'), Report: require('./Report'), Conversation: require('./Conversation'),
  ConversationParticipant: require('./ConversationParticipant'), Message: require('./Message'), MessageMedia: require('./MessageMedia'), Event: require('./Event'),
  EventRegistration: require('./EventRegistration'),
  SubscriptionPlan: require('./SubscriptionPlan'), Subscription: require('./Subscription'), Payment: require('./Payment'), PaymentEvent: require('./PaymentEvent'),
  RoseTransaction: require('./RoseTransaction'),
  SavedProfile: require('./SavedProfile'), NotificationPreference: require('./NotificationPreference'), Notification: require('./Notification'),
  IdentityVerification: require('./IdentityVerification'),
  UserDevice: require('./UserDevice'), NotificationDelivery: require('./NotificationDelivery'),
};
let models = {};
function initModels(sequelize) {
  if (models.User) return models;
  const created = Object.fromEntries(Object.entries(definitions).map(([name, define]) => [name, define(sequelize)]));
  const { User, RefreshToken, OnboardingProfile, DiscoverAction, Match, DiscoverFilterPreference, Block, Report, Conversation, ConversationParticipant, Message, MessageMedia, Event, EventRegistration, SubscriptionPlan, Subscription, Payment, PaymentEvent, RoseTransaction, SavedProfile, NotificationPreference, Notification, IdentityVerification, UserDevice, NotificationDelivery } = created;
  User.hasMany(RefreshToken, { foreignKey: 'userId', onDelete: 'CASCADE' }); RefreshToken.belongsTo(User, { foreignKey: 'userId' }); User.hasOne(OnboardingProfile, { foreignKey: 'userId', onDelete: 'CASCADE' }); OnboardingProfile.belongsTo(User, { foreignKey: 'userId' });
  User.hasMany(DiscoverAction, { foreignKey: 'actorUserId', onDelete: 'CASCADE', as: 'discoverActions' }); DiscoverAction.belongsTo(User, { foreignKey: 'actorUserId', as: 'actor' }); DiscoverAction.belongsTo(User, { foreignKey: 'targetUserId', as: 'target' });
  User.hasMany(Match, { foreignKey: 'userOneId', onDelete: 'CASCADE', as: 'firstMatches' }); User.hasMany(Match, { foreignKey: 'userTwoId', onDelete: 'CASCADE', as: 'secondMatches' }); Match.belongsTo(User, { foreignKey: 'userOneId', as: 'userOne' }); Match.belongsTo(User, { foreignKey: 'userTwoId', as: 'userTwo' });
  User.hasOne(DiscoverFilterPreference, { foreignKey: 'userId', onDelete: 'CASCADE' }); DiscoverFilterPreference.belongsTo(User, { foreignKey: 'userId' });
  User.hasMany(SavedProfile, { foreignKey: 'userId', as: 'savedProfiles', onDelete: 'CASCADE' }); SavedProfile.belongsTo(User, { foreignKey: 'userId', as: 'owner' }); SavedProfile.belongsTo(User, { foreignKey: 'savedUserId', as: 'savedUser' });
  User.hasOne(NotificationPreference, { foreignKey: 'userId', as: 'notificationPreference', onDelete: 'CASCADE' }); NotificationPreference.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  User.hasMany(Notification, { foreignKey: 'userId', as: 'notifications', onDelete: 'CASCADE' }); Notification.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  User.hasMany(Notification, { foreignKey: 'actorUserId', as: 'triggeredNotifications', onDelete: 'SET NULL' }); Notification.belongsTo(User, { foreignKey: 'actorUserId', as: 'actor' });
  User.hasOne(IdentityVerification, { foreignKey: 'userId', as: 'identityVerification', onDelete: 'CASCADE' }); IdentityVerification.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  User.hasMany(UserDevice, { foreignKey: 'userId', as: 'devices', onDelete: 'CASCADE' }); UserDevice.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  Notification.hasMany(NotificationDelivery, { foreignKey: 'notificationId', as: 'deliveries', onDelete: 'CASCADE' }); NotificationDelivery.belongsTo(Notification, { foreignKey: 'notificationId', as: 'notification' }); UserDevice.hasMany(NotificationDelivery, { foreignKey: 'userDeviceId', as: 'deliveries', onDelete: 'CASCADE' }); NotificationDelivery.belongsTo(UserDevice, { foreignKey: 'userDeviceId', as: 'device' });
  User.hasMany(Block, { foreignKey: 'blockerUserId', as: 'blocksCreated', onDelete: 'CASCADE' }); User.hasMany(Block, { foreignKey: 'blockedUserId', as: 'blocksReceived', onDelete: 'CASCADE' }); Block.belongsTo(User, { foreignKey: 'blockerUserId', as: 'blocker' }); Block.belongsTo(User, { foreignKey: 'blockedUserId', as: 'blockedUser' });
  User.hasMany(Report, { foreignKey: 'reporterUserId', as: 'reportsCreated' }); User.hasMany(Report, { foreignKey: 'reportedUserId', as: 'reportsReceived' }); Report.belongsTo(User, { foreignKey: 'reporterUserId', as: 'reporter' }); Report.belongsTo(User, { foreignKey: 'reportedUserId', as: 'reportedUser' });
  Conversation.hasMany(ConversationParticipant, { foreignKey: 'conversationId', as: 'participants', onDelete: 'CASCADE' }); ConversationParticipant.belongsTo(Conversation, { foreignKey: 'conversationId', as: 'conversation' });
  User.hasMany(ConversationParticipant, { foreignKey: 'userId', as: 'conversationMemberships', onDelete: 'CASCADE' }); ConversationParticipant.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  Conversation.hasMany(Message, { foreignKey: 'conversationId', as: 'messages', onDelete: 'CASCADE' }); Message.belongsTo(Conversation, { foreignKey: 'conversationId', as: 'conversation' });
  User.hasMany(Message, { foreignKey: 'senderId', as: 'sentMessages' }); Message.belongsTo(User, { foreignKey: 'senderId', as: 'sender' });
  Message.hasMany(MessageMedia, { foreignKey: 'messageId', as: 'media', onDelete: 'CASCADE' }); MessageMedia.belongsTo(Message, { foreignKey: 'messageId', as: 'message' });
  Conversation.belongsTo(Message, { foreignKey: 'lastMessageId', as: 'lastMessage', constraints: false }); ConversationParticipant.belongsTo(Message, { foreignKey: 'lastReadMessageId', as: 'lastReadMessage', constraints: false });
  User.hasMany(Event, { foreignKey: 'organizerId', as: 'organizedEvents' }); Event.belongsTo(User, { foreignKey: 'organizerId', as: 'organizer' });
  Event.hasMany(EventRegistration, { foreignKey: 'eventId', as: 'registrations', onDelete: 'CASCADE' }); EventRegistration.belongsTo(Event, { foreignKey: 'eventId', as: 'event' }); User.hasMany(EventRegistration, { foreignKey: 'userId', as: 'eventRegistrations', onDelete: 'CASCADE' }); EventRegistration.belongsTo(User, { foreignKey: 'userId', as: 'user' });
  User.hasOne(Subscription, { foreignKey: 'userId', as: 'subscription' }); Subscription.belongsTo(User, { foreignKey: 'userId', as: 'user' }); SubscriptionPlan.hasMany(Subscription, { foreignKey: 'planId', as: 'subscriptions' }); Subscription.belongsTo(SubscriptionPlan, { foreignKey: 'planId', as: 'plan' });
  User.hasMany(Payment, { foreignKey: 'userId', as: 'payments' }); Payment.belongsTo(User, { foreignKey: 'userId', as: 'user' }); SubscriptionPlan.hasMany(Payment, { foreignKey: 'planId', as: 'payments' }); Payment.belongsTo(SubscriptionPlan, { foreignKey: 'planId', as: 'plan' }); Payment.hasMany(PaymentEvent, { foreignKey: 'paymentId', as: 'events' }); PaymentEvent.belongsTo(Payment, { foreignKey: 'paymentId', as: 'payment' });
  User.hasMany(RoseTransaction, { foreignKey: 'senderId', as: 'rosesSent' });
  User.hasMany(RoseTransaction, { foreignKey: 'recipientId', as: 'rosesReceived' });
  RoseTransaction.belongsTo(User, { foreignKey: 'senderId', as: 'sender' });
  RoseTransaction.belongsTo(User, { foreignKey: 'recipientId', as: 'recipient' });
  RoseTransaction.belongsTo(Conversation, { foreignKey: 'conversationId', as: 'conversation' });
  models = created; return models;
}
function getModels() { if (!models.User) throw new Error('Models are not initialized.'); return models; }
module.exports = { initModels, getModels };
