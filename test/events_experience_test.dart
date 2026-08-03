import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/data/event_asset_catalog.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/events_browse_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(EventParticipationController.instance.clear);
  tearDown(EventParticipationController.instance.clear);

  testWidgets('all local event assets load and core events map uniquely', (
    tester,
  ) async {
    for (final asset in EventAssetCatalog.all) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
    expect(
      events.take(5).map((event) => event.image.assetPath).toSet(),
      hasLength(5),
    );
    expect(events[0].image.assetPath, EventAssetCatalog.coffee);
    expect(events[1].image.assetPath, EventAssetCatalog.garba);
    expect(events[2].image.assetPath, EventAssetCatalog.liveMusic);
    expect(events[3].image.assetPath, EventAssetCatalog.foundersMixer);
    expect(events[4].image.assetPath, EventAssetCatalog.heritageFoodWalk);
  });

  testWidgets('events render directly without a membership purchase gate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const EventsBrowseScreen(showNavigation: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    expect(find.text('Featured experience'), findsOneWidget);
    expect(find.byKey(const ValueKey('events-filter-button')), findsNothing);
    expect(find.byTooltip('Filter events'), findsNothing);
    expect(find.byKey(const ValueKey('events-search-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('events-my-events-button')),
      findsOneWidget,
    );
    expect(find.text('Unlock Events'), findsNothing);
    expect(find.text('Explore Membership'), findsNothing);
    expect(find.textContaining('Subscribe'), findsNothing);
    expect(find.textContaining('ticket', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remaining Search and My Events actions stay functional', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {MyEventsScreen.routeName: (_) => const MyEventsScreen()},
        home: const EventsBrowseScreen(showNavigation: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('events-search-button')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('events-my-events-button')));
    await tester.pumpAndSettle();
    expect(find.byType(MyEventsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member feed renders discovery and supported RSVP states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const EventsBrowseScreen(showNavigation: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    expect(find.text('Featured experience'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recommended for You'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recommended for You'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('My Events'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('My Events'), findsWidgets);
    expect(find.textContaining('ticket', findRichText: true), findsNothing);
    expect(find.textContaining('Rs ', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category selection updates through the compact selector', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          backgroundColor: Color(0xFFFDF1F7),
          body: SafeArea(child: EventsMemberExperience()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('event-category-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('amoraa-select-option-Coffee')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('event-category-selector')),
        matching: find.text('Coffee'),
      ),
      findsOneWidget,
    );
    expect(find.text('Featured experience'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event detail opens directly without membership access UI', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: EventDetailScreen(event: events.first),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(events.first.title), findsOneWidget);
    expect(find.text('Join Event'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Share event'), findsOneWidget);
    expect(find.byTooltip('Save event'), findsNothing);
    expect(find.byTooltip('Remove saved event'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.text('Events are for AMORAA members'), findsNothing);
    expect(find.text('Explore Membership'), findsNothing);
    expect(find.textContaining('ticket', findRichText: true), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('joining from details updates the shared My Events state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(AmoraSession.logOut);
    AmoraSession.logIn();
    final controller = EventParticipationController();
    final event = events[6];

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: EventDetailScreen(event: event, controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join Event'));
    await tester.pump(const Duration(milliseconds: 700));

    expect(controller.statusFor(event.id), TicketStatus.upcoming);

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AmoraTheme.light(),
        home: MyEventsScreen(controller: controller),
      ),
    );
    await tester.pump();
    expect(find.text(event.title), findsOneWidget);
    expect(find.text('Upcoming (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event detail transitions from skeleton to immersive sections', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: EventDetailScreen(event: events[4]),
      ),
    );
    await tester.pump();
    expect(find.byType(EventDetailSkeleton), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(EventDetailHero), findsOneWidget);
    expect(find.text('About this gathering'), findsOneWidget);
    expect(find.text('Read more'), findsOneWidget);
    final readMore = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Read more'),
    );
    readMore.onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('member feed stays centred and responsive on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const EventsBrowseScreen(showNavigation: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    final experience = find.byType(EventsMemberExperience);
    expect(tester.getSize(experience).width, lessThanOrEqualTo(1120));
    expect(find.text('Featured experience'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event detail is responsive and has no bottom navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: EventDetailScreen(event: events[4]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailHero), findsOneWidget);
    expect(find.byType(EventDetailSection), findsWidgets);
    expect(find.byType(FloatingBottomNav), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('main navigation opens Events directly with one bottom bar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const MainShell()),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('bottom-nav-Events')));
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    expect(find.text('Featured experience'), findsOneWidget);
    expect(find.text('Unlock Events'), findsNothing);
    expect(find.byType(FloatingBottomNav), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
