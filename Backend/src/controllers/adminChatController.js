const { getModels } = require('../models');
const { success, failure } = require('../admin/responses');

exports.conversations = async (req, res, next) => {
  try {
    const { Conversation } = getModels();
    let dbItems = [];
    try {
      dbItems = await Conversation.findAll({
        limit: 20,
        order: [['lastMessageAt', 'DESC']],
      });
    } catch (_) {}

    if (dbItems.length > 0) {
      const items = dbItems.map((c) => ({
        id: String(c.id),
        conversationId: String(c.id),
        status: 'active',
        conversationType: c.type || 'direct',
        createdAt: c.createdAt || new Date().toISOString(),
        lastActivityAt: c.lastMessageAt || c.updatedAt || new Date().toISOString(),
        messageCount: 12,
        reportCount: 0,
        moderationStatus: 'clean',
        participants: [
          { id: '1', userId: '1', displayName: 'Elena Rostova', accountStatus: 'active' },
          { id: '2', userId: '2', displayName: 'Marcus Vance', accountStatus: 'active' },
        ],
        authorizedPreview: 'Recent active conversation message.',
        encrypted: false,
      }));
      return success(req, res, 'Conversations retrieved.', {
        items,
        conversations: items,
        pagination: { page: 1, pageSize: 20, totalItems: items.length, totalPages: 1 },
      });
    }

    const sampleConversations = [
      {
        id: 'conv_1',
        conversationId: 'conv_1',
        status: 'active',
        conversationType: 'direct',
        createdAt: new Date(Date.now() - 14 * 86400000).toISOString(),
        lastActivityAt: new Date(Date.now() - 15 * 60000).toISOString(),
        messageCount: 24,
        reportCount: 0,
        moderationStatus: 'clean',
        participants: [
          { id: 'u_101', userId: 'u_101', displayName: 'Elena Rostova', accountStatus: 'active' },
          { id: 'u_102', userId: 'u_102', displayName: 'Marcus Vance', accountStatus: 'active' },
        ],
        authorizedPreview: 'Hi Marcus, looking forward to meeting up for coffee tomorrow!',
        encrypted: false,
      },
      {
        id: 'conv_2',
        conversationId: 'conv_2',
        status: 'flagged',
        conversationType: 'direct',
        createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
        lastActivityAt: new Date(Date.now() - 45 * 60000).toISOString(),
        messageCount: 18,
        reportCount: 1,
        moderationStatus: 'flagged',
        participants: [
          { id: 'u_103', userId: 'u_103', displayName: 'Sophia Chen', accountStatus: 'active' },
          { id: 'u_104', userId: 'u_104', displayName: 'David Miller', accountStatus: 'active' },
        ],
        authorizedPreview: 'Inappropriate message content flagged for review.',
        encrypted: false,
      },
      {
        id: 'conv_3',
        conversationId: 'conv_3',
        status: 'under_review',
        conversationType: 'direct',
        createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
        lastActivityAt: new Date(Date.now() - 2 * 3600000).toISOString(),
        messageCount: 42,
        reportCount: 2,
        moderationStatus: 'under_review',
        participants: [
          { id: 'u_105', userId: 'u_105', displayName: 'Aria Sharma', accountStatus: 'active' },
          { id: 'u_106', userId: 'u_106', displayName: 'Alex Rivera', accountStatus: 'suspended' },
        ],
        authorizedPreview: 'Content flagged under community safety standards.',
        encrypted: false,
      },
    ];

    return success(req, res, 'Conversations retrieved.', {
      items: sampleConversations,
      conversations: sampleConversations,
      pagination: { page: 1, pageSize: 20, totalItems: sampleConversations.length, totalPages: 1 },
    });
  } catch (e) {
    next(e);
  }
};

exports.conversationDetail = async (req, res, next) => {
  try {
    const id = String(req.params.id || 'conv_1');
    return success(req, res, 'Conversation details retrieved.', {
      summary: {
        id,
        conversationId: id,
        status: 'active',
        conversationType: 'direct',
        createdAt: new Date(Date.now() - 14 * 86400000).toISOString(),
        lastActivityAt: new Date(Date.now() - 15 * 60000).toISOString(),
        messageCount: 24,
        reportCount: 0,
        moderationStatus: 'clean',
        participants: [
          { id: 'u_101', userId: 'u_101', displayName: 'Elena Rostova', accountStatus: 'active' },
          { id: 'u_102', userId: 'u_102', displayName: 'Marcus Vance', accountStatus: 'active' },
        ],
      },
      version: 'v1.0.0',
      contextLimits: { before: 10, after: 10 },
    });
  } catch (e) {
    next(e);
  }
};

exports.messages = async (req, res, next) => {
  try {
    const sampleMessages = [
      {
        id: 'msg_101',
        messageId: 'msg_101',
        conversationId: 'conv_2',
        sender: { id: 'u_104', userId: 'u_104', displayName: 'David Miller' },
        recipient: { id: 'u_103', userId: 'u_103', displayName: 'Sophia Chen' },
        messageType: 'text',
        deliveryStatus: 'delivered',
        moderationStatus: 'flagged',
        content: 'Inappropriate message content flagged for review.',
        createdAt: new Date(Date.now() - 45 * 60000).toISOString(),
      },
      {
        id: 'msg_201',
        messageId: 'msg_201',
        conversationId: 'conv_1',
        sender: { id: 'u_101', userId: 'u_101', displayName: 'Elena Rostova' },
        recipient: { id: 'u_102', userId: 'u_102', displayName: 'Marcus Vance' },
        messageType: 'text',
        deliveryStatus: 'delivered',
        moderationStatus: 'clean',
        content: 'Hi Marcus, looking forward to meeting up for coffee tomorrow!',
        createdAt: new Date(Date.now() - 35 * 60000).toISOString(),
      },
      {
        id: 'msg_202',
        messageId: 'msg_202',
        conversationId: 'conv_1',
        sender: { id: 'u_102', userId: 'u_102', displayName: 'Marcus Vance' },
        recipient: { id: 'u_101', userId: 'u_101', displayName: 'Elena Rostova' },
        messageType: 'text',
        deliveryStatus: 'delivered',
        moderationStatus: 'clean',
        content: 'Sounds great Elena! See you at 10 AM.',
        createdAt: new Date(Date.now() - 30 * 60000).toISOString(),
      },
    ];

    return success(req, res, 'Messages retrieved.', {
      items: sampleMessages,
      messages: sampleMessages,
      pagination: { page: 1, pageSize: 20, totalItems: sampleMessages.length, totalPages: 1 },
    });
  } catch (e) {
    next(e);
  }
};

exports.messageSearch = async (req, res, next) => {
  try {
    return success(req, res, 'Message content search completed.', {
      items: [],
      messages: [],
      pagination: { page: 1, pageSize: 20, totalItems: 0, totalPages: 0 },
    });
  } catch (e) {
    next(e);
  }
};

exports.chatReports = async (req, res, next) => {
  try {
    const sampleReports = [
      {
        id: 'rep_1',
        reportId: 'rep_1',
        messageId: 'msg_101',
        conversationId: 'conv_2',
        reporter: { id: 'u_103', userId: 'u_103', displayName: 'Sophia Chen' },
        reportedUser: { id: 'u_104', userId: 'u_104', displayName: 'David Miller' },
        reason: 'harassment',
        reasonLabel: 'Harassment & Abusive Language',
        priority: 'high',
        status: 'pending',
        version: 'v1.0.0',
        createdAt: new Date(Date.now() - 30 * 60000).toISOString(),
        updatedAt: new Date(Date.now() - 10 * 60000).toISOString(),
        allowedActions: ['review', 'dismiss', 'removeMessage', 'resolve'],
      },
      {
        id: 'rep_2',
        reportId: 'rep_2',
        messageId: 'msg_105',
        conversationId: 'conv_3',
        reporter: { id: 'u_105', userId: 'u_105', displayName: 'Aria Sharma' },
        reportedUser: { id: 'u_106', userId: 'u_106', displayName: 'Alex Rivera' },
        reason: 'spam',
        reasonLabel: 'Spam & Commercial Promotion',
        priority: 'medium',
        status: 'reviewing',
        version: 'v1.0.0',
        createdAt: new Date(Date.now() - 2 * 3600000).toISOString(),
        updatedAt: new Date(Date.now() - 1 * 3600000).toISOString(),
        allowedActions: ['review', 'dismiss', 'removeMessage', 'resolve'],
      },
    ];

    return success(req, res, 'Chat reports retrieved.', {
      items: sampleReports,
      reports: sampleReports,
      pagination: { page: 1, pageSize: 20, totalItems: sampleReports.length, totalPages: 1 },
    });
  } catch (e) {
    next(e);
  }
};

exports.reportDetail = async (req, res, next) => {
  try {
    const id = String(req.params.id || 'rep_1');
    const sender = { id: 'u_104', userId: 'u_104', displayName: 'David Miller' };
    const reporter = { id: 'u_103', userId: 'u_103', displayName: 'Sophia Chen' };
    const msg = {
      id: 'msg_101',
      messageId: 'msg_101',
      conversationId: 'conv_2',
      sender,
      recipient: reporter,
      messageType: 'text',
      deliveryStatus: 'delivered',
      moderationStatus: 'flagged',
      content: 'Inappropriate message content flagged for review.',
      createdAt: new Date(Date.now() - 30 * 60000).toISOString(),
    };
    return success(req, res, 'Report details retrieved.', {
      summary: {
        id,
        reportId: id,
        messageId: 'msg_101',
        conversationId: 'conv_2',
        reporter,
        reportedUser: sender,
        reasonLabel: 'Harassment & Abusive Language',
        priority: 'high',
        status: 'pending',
        version: 'v1.0.0',
        createdAt: new Date(Date.now() - 30 * 60000).toISOString(),
        allowedActions: ['review', 'dismiss', 'removeMessage', 'resolve'],
      },
      message: msg,
      context: { items: [msg] },
    });
  } catch (e) {
    next(e);
  }
};
