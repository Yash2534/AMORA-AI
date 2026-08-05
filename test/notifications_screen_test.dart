import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpNotifications(
    WidgetTester tester, {
    ValueChanged<RouteSettings>? onRoute,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const NotificationsHubScreen(),
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

  testWidgets('horizontal filter bar filters Unread notifications locally', (
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
