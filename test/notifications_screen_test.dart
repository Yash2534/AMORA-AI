import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/features/notifications/data/notification_inbox_repository.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _NotificationRemote implements NotificationInboxRemoteDataSource {
  _NotificationRemote({this.failure, bool empty = false})
    : rows = empty ? <Map<String, dynamic>>[] : _seed();

  Object? failure;
  final List<Map<String, dynamic>> rows;

  static List<Map<String, dynamic>> _seed() {
    final now = DateTime.now();
    Map<String, dynamic> item(
      String id,
      String category,
      String title, {
      String? type,
      bool read = false,
      int minutes = 1,
      Map<String, dynamic> data = const <String, dynamic>{},
      Map<String, dynamic>? actor,
    }) => <String, dynamic>{
      'id': id,
      'type': type ?? category.toLowerCase().replaceAll(' ', '_'),
      'category': category,
      'title': title,
      'message': '$title details',
      'isRead': read,
      'readAt': read ? now.toIso8601String() : null,
      'createdAt': now.subtract(Duration(minutes: minutes)).toIso8601String(),
      'data': data,
      'actor': actor,
    };
    return <Map<String, dynamic>>[
      item(
        'like-kavya',
        'Likes',
        'You received a like',
        type: 'new_like',
        data: const <String, dynamic>{},
        actor: {
          'userId': '7',
          'name': 'Kavya',
          'photoUrl': 'https://cdn.example.test/kavya.jpg',
        },
      ),
      item(
        'message-riya',
        'Messages',
        'Riya sent you a new message',
        minutes: 2,
        data: {'conversationId': '5', 'targetUserId': '8'},
      ),
      item(
        'match-aadhya',
        'Matches',
        'You have a new match',
        minutes: 3,
        data: {'targetUserId': '9'},
      ),
      item(
        'super-like-meera',
        'Super Likes',
        'Meera Super Liked you',
        minutes: 4,
        data: {'targetUserId': '10'},
      ),
      item(
        'event-reminder',
        'Events',
        'Coffee Match Meetup is tomorrow',
        minutes: 5,
      ),
      item(
        'view-nisha',
        'Profile Views',
        'Nisha viewed your profile',
        read: true,
        minutes: 6,
      ),
      item(
        'verification',
        'Verification',
        'Identity verification approved',
        minutes: 7,
      ),
      item(
        'security',
        'Security',
        'New security login detected',
        read: true,
        minutes: 8,
      ),
      item(
        'payment',
        'Payments',
        'Subscription renewed',
        read: true,
        minutes: 9,
      ),
      item('offer', 'Offers', 'A premium offer is available', minutes: 10),
    ];
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    if (failure case final error?) throw error;
    final uri = Uri.parse(path);
    if (method == 'GET') {
      var filtered = rows.toList(growable: false);
      if (uri.queryParameters['unread'] == 'true') {
        filtered = filtered.where((item) => item['isRead'] != true).toList();
      }
      final category = uri.queryParameters['category'];
      if (category != null) {
        filtered = filtered
            .where((item) => item['category'] == category)
            .toList();
      }
      return _response(<String, dynamic>{
        'notifications': filtered,
        'unreadCount': rows.where((item) => item['isRead'] != true).length,
        'pagination': <String, dynamic>{'hasMore': false, 'nextPage': null},
      });
    }
    if (method == 'PUT' && path.endsWith('/read-all')) {
      for (final row in rows) {
        row['isRead'] = true;
      }
      return _response(<String, dynamic>{
        'updatedCount': rows.length,
        'unreadCount': 0,
      });
    }
    if (method == 'PUT') {
      final id = uri.pathSegments[2];
      final row = rows.firstWhere((item) => item['id'] == id);
      row['isRead'] = true;
      row['readAt'] = DateTime.now().toIso8601String();
      return _response(<String, dynamic>{
        'notification': row,
        'unreadCount': rows.where((item) => item['isRead'] != true).length,
      });
    }
    if (method == 'DELETE') {
      final id = uri.pathSegments.last;
      rows.removeWhere((item) => item['id'] == id);
      return _response(<String, dynamic>{
        'id': id,
        'deleted': true,
        'unreadCount': rows.where((item) => item['isRead'] != true).length,
      });
    }
    throw StateError('$method $path is unsupported');
  }

  Map<String, dynamic> _response(Map<String, dynamic> data) =>
      <String, dynamic>{'success': true, 'data': data};
}

void main() {
  test('notification model derives like copy from relational actor data', () {
    final record = InboxNotification.fromJson({
      'id': '1',
      'type': 'new_like',
      'category': 'Likes',
      'title': 'You received a like',
      'message': 'Someone is interested in your profile.',
      'isRead': false,
      'createdAt': '2026-08-12T00:00:00.000Z',
      'data': <String, dynamic>{},
      'actor': {
        'userId': '42',
        'name': 'Priya',
        'photoUrl': 'https://cdn.example.test/priya.jpg',
      },
    });

    expect(record.actor?.userId, '42');
    expect(record.actor?.photoUrl, 'https://cdn.example.test/priya.jpg');
    expect(record.displayTitle, 'Priya liked your profile');
  });

  test('historical like without actor keeps safe stored title', () {
    final record = InboxNotification.fromJson({
      'id': '2',
      'type': 'new_like',
      'category': 'Likes',
      'title': 'You received a like',
      'message': 'Someone is interested in your profile.',
      'isRead': false,
      'createdAt': '2026-08-12T00:00:00.000Z',
      'data': <String, dynamic>{},
    });

    expect(record.actor, isNull);
    expect(record.displayTitle, 'You received a like');
  });

  Future<void> pumpNotifications(
    WidgetTester tester, {
    ValueChanged<RouteSettings>? onRoute,
    _NotificationRemote? remote,
    double textScale = 1,
  }) async {
    final repository = NotificationInboxRepository(
      remote: remote ?? _NotificationRemote(),
    );
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: NotificationsHubScreen(repository: repository),
        onGenerateRoute: (settings) {
          onRoute?.call(settings);
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(
              body: Center(child: Text('${settings.name} destination')),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('load failure shows retry without seeded fallback', (
    tester,
  ) async {
    final remote = _NotificationRemote(
      failure: const AuthException('Notification service unavailable.'),
    );
    await pumpNotifications(tester, remote: remote);
    expect(find.text('Notification service unavailable.'), findsOneWidget);
    expect(find.text('Kavya liked your profile'), findsNothing);
    remote.failure = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Kavya liked your profile'), findsOneWidget);
  });

  testWidgets('empty backend inbox renders the real empty state', (
    tester,
  ) async {
    await pumpNotifications(tester, remote: _NotificationRemote(empty: true));
    expect(find.text("You're all caught up"), findsOneWidget);
    expect(find.text('Kavya liked your profile'), findsNothing);
  });

  testWidgets('renders the premium notification timeline at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpNotifications(tester);

    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('notifications-back-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notifications-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification-filter-rail')),
      findsOneWidget,
    );
    final header = find.byKey(const ValueKey('notifications-header'));
    expect(header, findsOneWidget);
    expect(
      find.descendant(of: header, matching: find.text('Notifications')),
      findsOneWidget,
    );
    expect(find.descendant(of: header, matching: find.text('7')), findsNothing);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Kavya liked your profile'), findsOneWidget);
    expect(find.text('Priority Hub'), findsNothing);
    expect(find.text('Your most meaningful update comes first'), findsNothing);
    expect(find.text('Mark all as read'), findsNothing);
    expect(find.textContaining('Push token'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('header and feed remain overflow-free at 1.3x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpNotifications(
      tester,
      remote: _NotificationRemote(empty: true),
      textScale: 1.3,
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings opens existing notification preferences route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpNotifications(
      tester,
      onRoute: (settings) => openedRoute = settings,
    );
    await tester.tap(
      find.byKey(const ValueKey('notifications-settings-button')),
    );
    await tester.pumpAndSettle();

    expect(openedRoute?.name, '/notification-preferences');
    expect(find.text('/notification-preferences destination'), findsOneWidget);
  });

  testWidgets('horizontal filter bar loads Unread notifications remotely', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpNotifications(tester);
    final rail = find.byKey(const ValueKey('notification-filter-rail'));
    expect(
      find.descendant(
        of: rail,
        matching: find.byType(AmoraaHorizontalFilterBar<String>),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: rail,
        matching: find.byType(AmoraaCompactSelect<String>),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: rail, matching: find.byIcon(Icons.arrow_drop_down)),
      findsNothing,
    );

    const filters = <String>[
      'All',
      'Unread',
      'Matches',
      'Messages',
      'Likes',
      'Super Likes',
      'Events',
      'Profile Views',
      'Verification',
      'Security',
      'Payments',
      'Offers',
    ];
    final bar = tester.widget<AmoraaHorizontalFilterBar<String>>(
      find.byType(AmoraaHorizontalFilterBar<String>),
    );
    expect(bar.options, filters);
    expect(bar.multiSelect, isFalse);
    expect(bar.showCheckmark, isFalse);
    final allChip = find.byKey(const ValueKey('notification-filter-All'));
    final unreadChip = find.byKey(const ValueKey('notification-filter-Unread'));
    expect(tester.getCenter(allChip).dy, tester.getCenter(unreadChip).dy);
    final scroller = find.byKey(const ValueKey('notification-filter-scroll'));
    expect(scroller, findsOneWidget);
    expect(tester.widget<ListView>(scroller).scrollDirection, Axis.horizontal);

    await tester.tap(unreadChip);
    await tester.pumpAndSettle();
    expect(tester.widget<AmoraFilterChip>(allChip).selected, isFalse);
    expect(tester.widget<AmoraFilterChip>(unreadChip).selected, isTrue);
    expect(tester.widget<AmoraFilterChip>(unreadChip).showCheckmark, isFalse);
    final selectedMaterialChip = tester.widget<FilterChip>(
      find.descendant(of: unreadChip, matching: find.byType(FilterChip)),
    );
    expect(selectedMaterialChip.showCheckmark, isFalse);
    expect(
      selectedMaterialChip.selectedColor,
      isNot(selectedMaterialChip.backgroundColor),
    );
    final unreadLabel = find.descendant(
      of: unreadChip,
      matching: find.text('Unread'),
    );
    expect(tester.getCenter(unreadLabel).dy, tester.getCenter(unreadChip).dy);
    expect(tester.getSize(unreadChip).height, 48);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('notification-filter-Offers')),
      320,
      scrollable: find.descendant(
        of: scroller,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('notification-filter-Offers')),
      findsOneWidget,
    );
    expect(find.text('Kavya liked your profile'), findsOneWidget);
    expect(find.text('Nisha viewed your profile'), findsNothing);

    final unreadTile = find.byKey(
      const ValueKey('notification-tile-like-kavya'),
    );
    await tester.drag(unreadTile, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(unreadTile, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe right marks read and swipe left deletes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpNotifications(tester);
    final firstTile = find.byKey(
      const ValueKey('notification-tile-like-kavya'),
    );
    final firstUnreadBadge = find.byKey(
      const ValueKey('notification-unread-like-kavya'),
    );
    expect(firstUnreadBadge, findsOneWidget);

    await tester.drag(firstTile, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(firstUnreadBadge, findsNothing);
    expect(firstTile, findsOneWidget);

    await tester.drag(firstTile, const Offset(-340, 0));
    await tester.pumpAndSettle();
    expect(firstTile, findsNothing);
    expect(find.text('Notification deleted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press enters multi-select mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpNotifications(tester);
    await tester.longPress(
      find.byKey(const ValueKey('notification-tile-like-kavya')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('notification-selection-toolbar')),
      findsOneWidget,
    );
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byTooltip('Mark selected as read'), findsOneWidget);
    expect(find.byTooltip('Delete selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification tap opens its existing related route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpNotifications(
      tester,
      onRoute: (settings) => openedRoute = settings,
    );
    await tester.tap(
      find.byKey(const ValueKey('notification-tile-like-kavya')),
    );
    await tester.pumpAndSettle();

    expect(openedRoute?.name, '/profile-detail');
    expect(openedRoute?.arguments, isNotNull);
    expect(find.text('/profile-detail destination'), findsOneWidget);
  });

  testWidgets('desktop notification center remains centred and constrained', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpNotifications(tester);
    final feed = find.byKey(const ValueKey('notification-feed'));
    expect(tester.getSize(feed).width, lessThanOrEqualTo(680));
    expect(tester.getCenter(feed).dx, moreOrLessEquals(600, epsilon: 1));
    expect(tester.takeException(), isNull);
  });
}
