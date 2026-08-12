import 'package:amora_ai/core/data/image_repository.dart';

class AmoraDummyData {
  const AmoraDummyData._();

  static final users = ImageRepository.profiles;
  static final events = ImageRepository.events;
  static final dateSpots = ImageRepository.venues;

  static final notifications = <DummyNotification>[
    for (var i = 0; i < 15; i++)
      DummyNotification(
        id: 'notification-$i',
        category: _notificationCategories[i % _notificationCategories.length],
        title: _notificationTitles[i % _notificationTitles.length],
        subtitle: _notificationSubtitles[i % _notificationSubtitles.length],
        time: i == 0 ? 'Now' : '${i + 1}h',
        ctaLabel: _notificationCtas[i % _notificationCtas.length],
        imageUrl: i % 3 == 0
            ? events[i % events.length].imageUrl
            : users[(i + 5) % users.length].imageUrl,
        fallbackAsset: i % 3 == 0
            ? events[i % events.length].fallbackAsset
            : users[(i + 5) % users.length].fallbackAsset,
      ),
  ];

  static final chats = <DummyConversation>[
    for (var i = 0; i < 10; i++)
      DummyConversation(
        id: 'chat-$i',
        user: users[(i + 8) % users.length],
        lastMessage: _chatMessages[i % _chatMessages.length],
        time: i == 0 ? 'Now' : '${i * 8 + 12}m',
        unread: i % 4,
        online: i.isEven,
      ),
  ];

  static const subscriptionPlans = [
    DummySubscriptionPlan(
      id: 'gold-monthly',
      name: 'AMORAA Gold',
      price: 'Rs 699',
      period: 'monthly',
      benefits: ['See intent first', 'Priority profiles', 'AI openers'],
    ),
    DummySubscriptionPlan(
      id: 'platinum-quarterly',
      name: 'AMORAA Platinum',
      price: 'Rs 1,799',
      period: 'quarterly',
      benefits: ['Advanced filters', 'Priority profiles', 'Read receipts'],
    ),
    DummySubscriptionPlan(
      id: 'concierge',
      name: 'AMORAA Concierge',
      price: 'Rs 4,999',
      period: 'monthly',
      benefits: ['Curated matches', 'Date planning', 'Profile review'],
    ),
  ];
}

class DummyNotification {
  const DummyNotification({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.ctaLabel,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String time;
  final String ctaLabel;
  final String imageUrl;
  final String fallbackAsset;
}

class DummyConversation {
  const DummyConversation({
    required this.id,
    required this.user,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.online,
  });

  final String id;
  final DummyProfile user;
  final String lastMessage;
  final String time;
  final int unread;
  final bool online;
}

class DummySubscriptionPlan {
  const DummySubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.benefits,
  });

  final String id;
  final String name;
  final String price;
  final String period;
  final List<String> benefits;
}

const _notificationCategories = [
  'Matches',
  'Messages',
  'Events',
  'AI Tips',
  'Payments',
  'Offers',
  'Safety',
];

const _notificationTitles = [
  'New high-intent match',
  'Message waiting',
  'Weekend event update',
  'AI opener ready',
  'Payment reminder',
  'Gold benefit unlocked',
  'Verification update',
];

const _notificationSubtitles = [
  'A verified profile shares your relationship intention.',
  'Your conversation has a warm reply and an AI nudge.',
  'A curated venue has confirmed your attendance window.',
  'Try a thoughtful prompt based on shared interests.',
  'Review your plan before renewal.',
  'Priority picks are refreshed for tonight.',
  'Your trust profile is almost complete.',
];

const _notificationCtas = ['View', 'Open', 'Review', 'Reply', 'Manage'];

const _chatMessages = [
  'That coffee place looks perfect for Saturday.',
  'Your AI opener was actually thoughtful.',
  'I liked your answer about communication.',
  'Want to compare favorite interests?',
  'This event looks calmer than most mixers.',
];
