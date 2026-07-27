import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDiscover(
    WidgetTester tester, {
    ValueChanged<RouteSettings>? onNamedRoute,
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const BrowseGridScreen(),
        navigatorObservers: observers,
        onGenerateRoute: (settings) {
          onNamedRoute?.call(settings);
          if (<String>{
            '/filters',
            '/notifications',
            '/super-like',
            '/chats',
            '/matches',
            '/events',
            '/profile',
          }.contains(settings.name)) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(
                body: Center(child: Text('${settings.name} destination')),
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AmoraSession.logOut();
  });

  test('photo cleaning preserves order, removes blanks and duplicates', () {
    expect(
      cleanDiscoverPhotoPaths(const [
        '',
        'photo-a',
        ' photo-a ',
        'photo-b',
        'photo-a',
      ], fallback: 'fallback'),
      const ['photo-a', 'photo-b'],
    );
    expect(
      cleanDiscoverPhotoPaths(const ['', '   '], fallback: 'fallback'),
      const ['fallback'],
    );
  });

  testWidgets('renders the premium single-card hierarchy at 320px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);

    final search = find.byKey(const ValueKey('discover-search-field'));
    final filters = find.byKey(const ValueKey('discover-filter-rail'));
    final firstProfile = ImageRepository.profiles.first;
    final card = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('AI Matches'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('discover-menu-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('discover-notifications-button')),
      findsOneWidget,
    );
    expect(search, findsOneWidget);
    expect(filters, findsOneWidget);
    expect(card, findsOneWidget);
    expect(find.byType(PremiumImage), findsOneWidget);
    expect(find.byType(Hero), findsOneWidget);
    expect(find.byKey(const ValueKey('discover-pass-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('discover-undo-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('discover-super-like-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('discover-like-button')), findsOneWidget);
    expect(
      tester.getTopLeft(search).dy,
      lessThan(tester.getTopLeft(filters).dy),
    );
    expect(tester.getTopLeft(filters).dy, lessThan(tester.getTopLeft(card).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('centres and constrains the portrait experience on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final firstProfile = ImageRepository.profiles.first;
    final card = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );
    final search = find.byKey(const ValueKey('discover-search-field'));

    expect(tester.getSize(search).width, lessThanOrEqualTo(464));
    expect(tester.getSize(card).width, lessThanOrEqualTo(512));
    expect(find.byType(PremiumImage), findsOneWidget);
    expect(tester.getCenter(card).dx, moreOrLessEquals(600, epsilon: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation has exactly five tabs and no Home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
    );

    const labels = <String>[
      'Discover',
      'Chats',
      'AI Matches',
      'Events',
      'Profile',
    ];
    for (final label in labels) {
      expect(find.byKey(ValueKey('bottom-nav-$label')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('bottom-nav-Home')), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-AI Matches')));
    await tester.pumpAndSettle();
    expect(openedRoute?.name, '/matches');
    expect(find.text('/matches destination'), findsOneWidget);
  });

  testWidgets('search focus animates and local search exposes clear', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final search = find.byKey(const ValueKey('discover-search-field'));
    final container = find.byKey(const ValueKey('discover-search-container'));

    await tester.tap(search);
    await tester.pump(const Duration(milliseconds: 350));
    final field = tester.widget<TextField>(search);
    final decoration = tester.widget<AnimatedContainer>(container).decoration;
    expect(field.focusNode?.hasFocus, isTrue);
    expect((decoration as BoxDecoration).border, isNotNull);

    await tester.enterText(search, 'profile-that-does-not-exist');
    await tester.pump();
    expect(find.text('No profiles match'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('No profiles match'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter rail is horizontal and selection filters local data', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final rail = find.byKey(const ValueKey('discover-filter-rail'));
    final scrollable = tester.widget<ListView>(
      find.descendant(of: rail, matching: find.byType(ListView)),
    );
    expect(scrollable.scrollDirection, Axis.horizontal);

    final onlineFilter = find.byKey(const ValueKey('discover-filter-Online'));
    await tester.ensureVisible(onlineFilter);
    await tester.pumpAndSettle();
    await tester.tap(onlineFilter);
    await tester.pumpAndSettle();
    final firstOnline = ImageRepository.profiles.firstWhere(
      (profile) => profile.status == 'Online now',
    );
    expect(
      find.byKey(ValueKey('discover-profile-card-${firstOnline.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('visible Filters control opens the existing route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
    );
    expect(find.text('Filters'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('discover-filters-button')));
    await tester.pumpAndSettle();
    expect(openedRoute?.name, '/filters');
    expect(find.text('/filters destination'), findsOneWidget);
  });

  testWidgets('notification control opens the existing route', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
    );
    await tester.tap(
      find.byKey(const ValueKey('discover-notifications-button')),
    );
    await tester.pumpAndSettle();

    expect(openedRoute?.name, '/notifications');
    expect(find.text('/notifications destination'), findsOneWidget);
  });

  testWidgets('card opens profile detail with a named Hero route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final observer = _RecordingNavigatorObserver();

    await pumpDiscover(tester, observers: <NavigatorObserver>[observer]);
    final firstProfile = ImageRepository.profiles.first;
    await tester.tap(find.byKey(const ValueKey('discover-open-profile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(observer.lastRoute?.settings.name, '/profile-detail');
    expect(observer.lastRoute?.settings.arguments, same(firstProfile));
    expect(find.byType(ProfileDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gallery uses unique photos, tap zones, and progress segments', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final profile = ImageRepository.profiles.first;
    final photos = cleanDiscoverPhotoPaths(<String>[
      profile.imageUrl,
      ...profile.gallery,
    ], fallback: profile.fallbackAsset);

    expect(photos.length, greaterThan(1));
    expect(
      find.byKey(ValueKey('discover-photo-progress-${profile.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('discover-photo-${profile.id}-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discover-next-photo')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-photo-${profile.id}-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discover-previous-photo')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-photo-${profile.id}-0')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical and vertical-dominant drags never move or dismiss', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
    );
    final profile = ImageRepository.profiles.first;
    final card = find.byKey(ValueKey('discover-profile-card-${profile.id}'));

    await tester.drag(card, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    expect(openedRoute?.name, isNot('/super-like'));

    await tester.drag(card, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);

    await tester.drag(card, const Offset(55, -280));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);

    final slide = tester.widget<AnimatedSlide>(
      find.byKey(const ValueKey('discover-card-slide')),
    );
    expect(slide.offset.dy, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal-dominant diagonal drag remains X-only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final first = ImageRepository.profiles.first;
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(ValueKey('discover-profile-card-${first.id}')),
      ),
    );
    // The first move crosses Flutter's gesture-arena touch slop and locks the
    // recognizer; the second verifies that only the horizontal delta is used.
    await gesture.moveBy(const Offset(50, 12));
    await gesture.moveBy(const Offset(50, 12));
    await tester.pump();

    final slide = tester.widget<AnimatedSlide>(
      find.byKey(const ValueKey('discover-card-slide')),
    );
    expect(slide.offset.dx, greaterThan(0));
    expect(slide.offset.dy, 0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-profile-card-${first.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('small drags spring back and left swipes advance once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final firstProfile = ImageRepository.profiles.first;
    final firstCard = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );

    await tester.drag(firstCard, const Offset(-24, 2));
    await tester.pumpAndSettle();
    expect(firstCard, findsOneWidget);

    await tester.drag(firstCard, const Offset(-280, 4));
    await tester.pumpAndSettle();
    expect(firstCard, findsNothing);
    expect(
      find.byKey(
        ValueKey('discover-profile-card-${ImageRepository.profiles[1].id}'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('fast short horizontal flings dismiss in either direction', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final firstProfile = ImageRepository.profiles.first;
    final firstCard = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );

    await tester.fling(firstCard, const Offset(60, 0), 1200);
    await tester.pumpAndSettle();
    expect(firstCard, findsNothing);
    expect(
      find.byKey(
        ValueKey('discover-profile-card-${ImageRepository.profiles[1].id}'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpDiscover(tester);
    final resetFirstCard = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );
    await tester.fling(resetFirstCard, const Offset(-60, 0), 1200);
    await tester.pumpAndSettle();
    expect(resetFirstCard, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slow right drag and Pass button use the existing actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final firstProfile = ImageRepository.profiles.first;
    final firstCard = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );
    await tester.drag(firstCard, const Offset(280, 3));
    await tester.pumpAndSettle();
    expect(firstCard, findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpDiscover(tester);
    final resetFirstCard = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );
    await tester.tap(find.byKey(const ValueKey('discover-pass-button')));
    await tester.pumpAndSettle();
    expect(resetFirstCard, findsNothing);
    expect(
      find.byKey(
        ValueKey('discover-profile-card-${ImageRepository.profiles[1].id}'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating Like and Undo actions reuse the swipe sequence', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AmoraSession.logIn();

    await pumpDiscover(tester);
    final firstProfile = ImageRepository.profiles.first;
    await tester.tap(find.byKey(const ValueKey('discover-next-photo')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-photo-${firstProfile.id}-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discover-like-button')));
    await tester.pumpAndSettle();

    expect(find.text('Liked ${firstProfile.name}'), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('discover-profile-card-${ImageRepository.profiles[1].id}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        ValueKey('discover-photo-${ImageRepository.profiles[1].id}-0'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('discover-undo-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-profile-card-${firstProfile.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Super Like reuses its existing route and profile argument', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AmoraSession.logIn();
    RouteSettings? openedRoute;

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
    );
    final firstProfile = ImageRepository.profiles.first;
    await tester.tap(find.byKey(const ValueKey('discover-super-like-button')));
    await tester.pumpAndSettle();

    expect(openedRoute?.name, '/super-like');
    expect(openedRoute?.arguments, same(firstProfile));
  });

  testWidgets('filtered profiles reach and restart the end state safely', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpDiscover(tester);
    final onlineFilter = find.byKey(const ValueKey('discover-filter-Online'));
    await tester.ensureVisible(onlineFilter);
    await tester.pumpAndSettle();
    await tester.tap(onlineFilter);
    await tester.pumpAndSettle();
    final onlineProfiles = ImageRepository.profiles
        .where((profile) => profile.status == 'Online now')
        .toList(growable: false);

    for (final profile in onlineProfiles) {
      final card = find.byKey(ValueKey('discover-profile-card-${profile.id}'));
      expect(card, findsOneWidget);
      await tester.drag(card, const Offset(-300, 0));
      await tester.pumpAndSettle();
    }

    expect(find.text('You are all caught up'), findsOneWidget);
    await tester.tap(find.text('View profiles again'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-profile-card-${onlineProfiles.first.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    lastRoute = route;
  }
}
