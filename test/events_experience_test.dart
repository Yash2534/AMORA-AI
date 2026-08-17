import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
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
import 'support/fixture_event_repository.dart';

void main() {
  setUp(() {
    EventParticipationController.instance.clear();
    EventRepository.debugOverride = FixtureEventRepository(events);
  });
  tearDown(() {
    EventParticipationController.instance.clear();
    EventRepository.debugOverride = null;
  });

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
    expect(find.byKey(const ValueKey('events-search-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('events-my-events-button')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    expect(find.text('Featured experience'), findsOneWidget);
    expect(
      tester.getRect(find.byType(EventsContextBar)).left,
      AmoraaMainPageHeader.contentHorizontalInset,
    );
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

  testWidgets('event categories use one-line multi-select filters', (
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

    final categoryBar = tester.widget<EventCategoryBar>(
      find.byType(EventCategoryBar),
    );
    expect(categoryBar.categories, hasLength(11));
    expect(categoryBar.categories.toSet(), hasLength(11));
    expect(find.byType(AmoraaCompactSelect<String>), findsNothing);
    expect(
      tester
          .widget<ListView>(find.byKey(const ValueKey('event-category-scroll')))
          .scrollDirection,
      Axis.horizontal,
    );

    final categoryScroll = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('event-category-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    categoryScroll.position.jumpTo(180);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('event-category-Coffee')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EventCategoryBar>(find.byType(EventCategoryBar))
          .selectedValues,
      {'Coffee'},
    );

    categoryScroll.position.jumpTo(440);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('event-category-Music')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EventCategoryBar>(find.byType(EventCategoryBar))
          .selectedValues,
      {'Coffee', 'Music'},
    );
    expect(
      tester
          .widget<AmoraFilterChip>(
            find.byKey(const ValueKey('event-category-Music')),
          )
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<AmoraFilterChip>(
            find.byKey(const ValueKey('event-category-Music')),
          )
          .showCheckmark,
      isTrue,
    );

    categoryScroll.position.jumpTo(180);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('event-category-Coffee')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EventCategoryBar>(find.byType(EventCategoryBar))
          .selectedValues,
      {'Music'},
    );
    expect(find.text('Featured experience'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('event filter rail remains horizontal at supported widths', (
    tester,
  ) async {
    for (final width in const [
      320.0,
      360.0,
      390.0,
      412.0,
      430.0,
      600.0,
      768.0,
      1024.0,
    ]) {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: const EventsBrowseScreen(showNavigation: false),
        ),
      );
      await tester.pump(const Duration(milliseconds: 520));
      await tester.pump();

      final rail = find.byKey(const ValueKey('event-category-scroll'));
      expect(tester.widget<ListView>(rail).scrollDirection, Axis.horizontal);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: rail, matching: find.byType(Scrollable)).first,
      );
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-category-AMORAA Circles')),
        findsOneWidget,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Event filters overflowed at ${width.toInt()} px',
      );
    }
  });

  testWidgets('recommended Garba card uses one aligned content column', (
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
    await tester.scrollUntilVisible(
      find.text('Recommended for You'),
      320,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    final garba = events.firstWhere(
      (event) => event.title == 'Garba Night for Singles',
    );
    final card = find.byKey(ValueKey('event-card-${garba.id}'));
    expect(card, findsOneWidget);
    final title = find.byKey(ValueKey('event-title-${garba.id}'));
    final date = find.byKey(ValueKey('event-date-${garba.id}'));
    final image = find.byKey(ValueKey('recommended-event-image-${garba.id}'));
    final time = find.byKey(ValueKey('event-time-${garba.id}'));
    final venue = find.byKey(ValueKey('event-venue-${garba.id}'));
    final category = find.byKey(ValueKey('event-category-${garba.id}'));
    final titleLeft = tester.getTopLeft(title).dx;

    expect(find.byType(AmoraaRecommendedEventCard), findsWidgets);
    expect(find.text('Garba Night for Singles'), findsOneWidget);
    expect(tester.getSize(card).width, inInclusiveRange(260, 330));
    expect(
      tester.getSize(image).height,
      AmoraaRecommendedEventCard.imageHeight,
    );
    expect(
      tester.getSize(date),
      const Size(
        AmoraaRecommendedEventCard.dateBadgeWidth,
        AmoraaRecommendedEventCard.dateBadgeHeight,
      ),
    );
    expect(tester.getTopLeft(date).dy, closeTo(tester.getTopLeft(title).dy, 1));
    expect(tester.getTopLeft(time).dx, closeTo(titleLeft, 1));
    expect(tester.getTopLeft(venue).dx, closeTo(titleLeft, 1));
    expect(tester.getTopLeft(category).dx, closeTo(titleLeft, 1));
    final recommendedRail = find.byKey(
      const ValueKey('recommended-event-rail'),
    );
    expect(
      tester
          .widget<ListView>(
            find.descendant(
              of: recommendedRail,
              matching: find.byType(ListView),
            ),
          )
          .scrollDirection,
      Axis.horizontal,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('recommended long titles wrap without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final longTitleEvent = events.firstWhere(
      (event) => event.title == 'Startup Networking Mixer',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => SizedBox(
              width: 260,
              height: AmoraaRecommendedEventCard.requiredHeight(
                context,
                longTitleEvent,
                260,
              ),
              child: AmoraaRecommendedEventCard(
                event: longTitleEvent,
                status: null,
                onOpen: () {},
                onJoin: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.byKey(ValueKey('event-title-${longTitleEvent.id}'));
    expect(tester.getSize(title).height, greaterThan(19));
    expect(tester.takeException(), isNull);
  });

  testWidgets('important horizontal event text wraps without ellipsis', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final event = _eventWithText(
      events.first,
      title: 'AMORAA QA Coffee and Conversation for Intentional Connections',
      venue: 'The Courtyard, Ahmedabad Heritage District',
      category: 'Culture and Meaningful Conversation',
    );
    var joined = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 340,
              child: CompactEventCard(
                event: event,
                status: null,
                onOpen: () {},
                onJoin: () => joined = true,
                showDistance: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(
      find.byKey(ValueKey('event-title-${event.id}')),
    );
    final venue = tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('event-venue-${event.id}')),
        matching: find.text(event.venue),
      ),
    );
    final category = tester.widget<Text>(
      find.byKey(ValueKey('event-category-${event.id}')),
    );
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
    expect(venue.maxLines, isNull);
    expect(venue.overflow, isNull);
    expect(category.maxLines, isNull);
    expect(category.overflow, isNull);
    expect(
      tester.getSize(find.byKey(ValueKey('event-title-${event.id}'))).width,
      greaterThan(130),
    );
    expect(
      tester.getSize(find.byKey(ValueKey('event-action-${event.id}'))),
      const Size(48, 48),
    );

    await tester.tap(find.byKey(ValueKey('event-action-${event.id}')));
    await tester.pump();
    expect(joined, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nearby card stays compact at small medium and large widths', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final event = _eventWithText(
      events.first,
      title: 'AMORAA QA Live Music Social',
      venue: 'The Courtyard, Ahmedabad Heritage District',
      category: 'Live Music',
    );

    for (final width in const [280.0, 360.0, 420.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: CompactEventCard(
                    event: event,
                    status: null,
                    onOpen: () {},
                    onJoin: () {},
                    showDistance: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.byKey(ValueKey('event-card-${event.id}'));
      final title = find.byKey(ValueKey('event-title-${event.id}'));
      final venue = find.byKey(ValueKey('event-venue-${event.id}'));
      final action = find.byKey(ValueKey('event-action-${event.id}'));
      expect(tester.getSize(card).width, width);
      expect(tester.getSize(title).width, greaterThan(130));
      expect(tester.getSize(venue).width, greaterThan(130));
      expect(tester.getSize(action), const Size(48, 48));
      expect(
        tester.getRect(action).bottom - tester.getRect(card).top,
        lessThan(420),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Nearby card overflowed at ${width.toInt()} px',
      );
    }

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const EventsBrowseScreen(showNavigation: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();
    final nearbyRail = find.byKey(const ValueKey('nearby-event-rail'));
    for (
      var attempt = 0;
      attempt < 8 && nearbyRail.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(
        find.byKey(const PageStorageKey('events-member-feed')),
        const Offset(0, -500),
      );
      await tester.pump();
    }
    final nearbyCard = find
        .descendant(of: nearbyRail, matching: find.byType(CompactEventCard))
        .first;
    expect(nearbyRail, findsOneWidget);
    expect(tester.getSize(nearbyCard).height, lessThan(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('event detail hero grows for complete long text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final event = _eventWithText(
      events.first,
      title:
          'AMORAA QA Coffee and Conversation for Intentional Connections Across Ahmedabad',
      category: 'Culture and Meaningful Conversation',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: EventDetailHero(
            event: event,
            status: null,
            height: 260,
            onBack: () {},
            onShare: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text(event.title));
    final category = tester.widget<Text>(find.text(event.category));
    expect(title.maxLines, isNull);
    expect(title.overflow, isNull);
    expect(category.maxLines, isNull);
    expect(category.overflow, isNull);
    expect(
      tester.getSize(find.byType(EventDetailHero)).height,
      greaterThan(260),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('all recommended cards share dimensions and alignment rules', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final recommended = events.sublist(1, 4);
    String? joinedId;
    const itemWidth = 260.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(1024, 700),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Builder(
              builder: (context) => SizedBox(
                height: recommended
                    .map(
                      (event) => AmoraaRecommendedEventCard.requiredHeight(
                        context,
                        event,
                        itemWidth,
                      ),
                    )
                    .reduce(math.max),
                child: ListView.separated(
                  key: const ValueKey('recommended-alignment-test-rail'),
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, index) => SizedBox(
                    width: itemWidth,
                    child: AmoraaRecommendedEventCard(
                      event: recommended[index],
                      status: null,
                      onOpen: () {},
                      onJoin: () => joinedId = recommended[index].id,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AmoraaRecommendedEventCard), findsNWidgets(3));
    expect(find.text('Garba Night for Singles'), findsOneWidget);
    expect(find.text('Live Music Social'), findsOneWidget);
    expect(find.text('Startup Networking Mixer'), findsOneWidget);

    double? expectedTitleInset;
    double? expectedButtonTop;
    Size? expectedButtonSize;
    for (final event in recommended) {
      final card = find.byKey(ValueKey('event-card-${event.id}'));
      final image = find.byKey(ValueKey('recommended-event-image-${event.id}'));
      final date = find.byKey(ValueKey('event-date-${event.id}'));
      final title = find.byKey(ValueKey('event-title-${event.id}'));
      final time = find.byKey(ValueKey('event-time-${event.id}'));
      final venue = find.byKey(ValueKey('event-venue-${event.id}'));
      final category = find.byKey(ValueKey('event-category-${event.id}'));
      final action = find.byKey(
        ValueKey('recommended-event-action-${event.id}'),
      );
      final cardRect = tester.getRect(card);
      final titleRect = tester.getRect(title);

      expect(cardRect.width, itemWidth);
      expect(
        tester.getSize(image).height,
        AmoraaRecommendedEventCard.imageHeight,
      );
      expect(
        tester.getSize(date),
        const Size(
          AmoraaRecommendedEventCard.dateBadgeWidth,
          AmoraaRecommendedEventCard.dateBadgeHeight,
        ),
      );
      expect(tester.getTopLeft(date).dy, closeTo(titleRect.top, 1));
      expect(tester.getTopLeft(time).dx, closeTo(titleRect.left, 1));
      expect(tester.getTopLeft(venue).dx, closeTo(titleRect.left, 1));
      expect(tester.getTopLeft(category).dx, closeTo(titleRect.left, 1));

      final titleInset = titleRect.left - cardRect.left;
      expectedTitleInset ??= titleInset;
      expect(titleInset, closeTo(expectedTitleInset, 1));
      expectedButtonTop ??= tester.getTopLeft(action).dy;
      expectedButtonSize ??= tester.getSize(action);
      expect(tester.getTopLeft(action).dy, closeTo(expectedButtonTop, 1));
      expect(tester.getSize(action), expectedButtonSize);
    }

    final startup = recommended.last;
    expect(
      tester.getSize(find.byKey(ValueKey('event-title-${startup.id}'))).height,
      greaterThan(24),
    );
    final garbaCard = find.byKey(
      ValueKey('event-card-${recommended.first.id}'),
    );
    await tester.tap(
      find.descendant(of: garbaCard, matching: find.text('Join Event')),
    );
    await tester.pump();
    expect(joinedId, recommended.first.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recommended long venue wraps without card overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final event = events[4];
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => SizedBox(
              width: 260,
              height: AmoraaRecommendedEventCard.requiredHeight(
                context,
                event,
                260,
              ),
              child: AmoraaRecommendedEventCard(
                event: event,
                status: null,
                onOpen: () {},
                onJoin: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final venue = find.byKey(ValueKey('event-venue-${event.id}'));
    expect(tester.getSize(venue).height, greaterThan(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('recommended cards remain responsive at every target size', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final event = events.firstWhere(
      (candidate) => candidate.title == 'Startup Networking Mixer',
    );

    for (final width in const <double>[
      320,
      360,
      390,
      412,
      430,
      600,
      768,
      1024,
    ]) {
      await tester.binding.setSurfaceSize(Size(width, 1200));
      for (final textScale in const [1.0, 1.15, 1.3]) {
        final itemWidth = width >= 700
            ? 330.0
            : (width - 64).clamp(260.0, 328.0).toDouble();
        await tester.pumpWidget(
          MaterialApp(
            theme: AmoraTheme.light(),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1200),
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Builder(
                  builder: (context) => SizedBox(
                    height: AmoraaRecommendedEventCard.requiredHeight(
                      context,
                      event,
                      itemWidth,
                    ),
                    child: ListView(
                      key: const ValueKey('responsive-recommended-rail'),
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: AmoraaRecommendedEventCard(
                            event: event,
                            status: null,
                            onOpen: () {},
                            onJoin: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.getSize(find.byType(AmoraaRecommendedEventCard)).width,
          itemWidth,
        );
        expect(
          tester
              .widget<ListView>(
                find.byKey(const ValueKey('responsive-recommended-rail')),
              )
              .scrollDirection,
          Axis.horizontal,
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow at $width px and ${textScale}x text scale',
        );
      }
    }
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

  testWidgets('event detail supports compact 1.3 text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: EventDetailScreen(event: events.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(events.first.title), findsOneWidget);
    expect(find.text('Join Event'), findsOneWidget);
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

  testWidgets('event action failures never expose raw exception text', (
    tester,
  ) async {
    addTearDown(AmoraSession.logOut);
    AmoraSession.logIn();
    EventRepository.debugOverride = _FailingEventRepository(events);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: EventDetailScreen(
          event: events.first,
          controller: EventParticipationController(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Join Event'));
    await tester.pump();

    expect(
      find.text('Could not update this event. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('internal event failure'), findsNothing);
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
    expect(find.text('Read more'), findsNothing);
    expect(find.text(events[4].description), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendee preview uses the persisted registration count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EventAttendeePreview(attendees: [], totalCount: 3),
        ),
      ),
    );

    expect(find.text('3 members attending'), findsOneWidget);
    expect(find.text('0 members attending'), findsNothing);
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

class _FailingEventRepository extends FixtureEventRepository {
  _FailingEventRepository(super.fixtures);

  @override
  Future<TicketStatus?> register(String eventId) =>
      throw StateError('internal event failure');
}

EventModel _eventWithText(
  EventModel source, {
  String? title,
  String? venue,
  String? category,
}) {
  return EventModel(
    id: '${source.id}-long-text',
    title: title ?? source.title,
    category: category ?? source.category,
    city: source.city,
    date: source.date,
    time: source.time,
    price: source.price,
    seatsLeft: source.seatsLeft,
    compatibility: source.compatibility,
    image: source.image,
    organizer: source.organizer,
    venue: venue ?? source.venue,
    distance: source.distance,
    dressCode: source.dressCode,
    ageRange: source.ageRange,
    language: source.language,
    palette: source.palette,
    intent: source.intent,
    interests: source.interests,
    agenda: source.agenda,
    startAt: source.startAt,
    endAt: source.endAt,
    description: source.description,
    capacity: source.capacity,
    registeredCount: source.registeredCount,
    eventStatus: source.eventStatus,
    registrationOpen: source.registrationOpen,
    attendees: source.attendees,
    participationStatus: source.participationStatus,
  );
}
