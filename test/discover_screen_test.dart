import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDiscover(
    WidgetTester tester, {
    ValueChanged<RouteSettings>? onNamedRoute,
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
    DiscoverActionController? controller,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BrowseGridScreen(
          controller: controller,
          apiService: _FixtureDiscoverApiService(),
        ),
        navigatorObservers: observers,
        onGenerateRoute: (settings) {
          onNamedRoute?.call(settings);
          if (<String>{
            '/filters',
            '/notifications',
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

    final filters = find.byKey(const ValueKey('discover-filter-rail'));
    final firstProfile = ImageRepository.profiles.first;
    final card = find.byKey(
      ValueKey('discover-profile-card-${firstProfile.id}'),
    );

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('AI Matches'), findsOneWidget);
    expect(find.text('Events'), findsNothing);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('discover-menu-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('discover-notifications-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('discover-search-field')), findsNothing);
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
    expect(tester.getTopLeft(filters).dy, lessThan(tester.getTopLeft(card).dy));
    expect(tester.getSize(card).height, greaterThan(450));
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

    expect(tester.getSize(card).width, lessThanOrEqualTo(512));
    expect(tester.getSize(card).height, lessThanOrEqualTo(760));
    expect(find.byType(PremiumImage), findsOneWidget);
    expect(tester.getCenter(card).dx, moreOrLessEquals(600, epsilon: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation has exactly four tabs and no Events or Home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
    );

    const labels = <String>['Discover', 'Chat', 'AI Matches', 'Profile'];
    for (final label in labels) {
      expect(find.byKey(ValueKey('bottom-nav-$label')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('bottom-nav-Home')), findsNothing);
    expect(find.byKey(const ValueKey('bottom-nav-Events')), findsNothing);
    expect(find.text('Home'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-AI Matches')));
    await tester.pumpAndSettle();
    expect(openedRoute?.name, '/matches');
    expect(find.text('/matches destination'), findsOneWidget);
  });

  testWidgets(
    'Discover header uses official branding and a clean notification action',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpDiscover(tester);
      expect(find.byKey(const ValueKey('discover-search-field')), findsNothing);
      expect(
        find.byKey(const ValueKey('discover-notifications')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  AmoraBrandAssets.wordmark,
        ),
        findsOneWidget,
      );
      expect(find.text('7'), findsNothing);
      expect(
        find.byKey(const ValueKey('discover-filter-rail')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

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

    await tester.drag(
      find.descendant(of: rail, matching: find.byType(ListView)),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    final onlineFilter = find.byKey(const ValueKey('discover-filter-Online'));
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

  testWidgets('Profile settings control opens the existing route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await tester.pumpWidget(
      MaterialApp(
        home: const ProfileScreen(showNavigation: false),
        onGenerateRoute: (settings) {
          openedRoute = settings;
          if (settings.name == ProfileSettingsScreen.routeName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('${ProfileSettingsScreen.routeName} destination'),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-settings-button')));
    await tester.pumpAndSettle();

    expect(openedRoute?.name, ProfileSettingsScreen.routeName);
    expect(
      find.text('${ProfileSettingsScreen.routeName} destination'),
      findsOneWidget,
    );
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
    expect(
      (observer.lastRoute?.settings.arguments as DummyProfile).id,
      firstProfile.id,
    );
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
    expect(find.text('Unlike ${firstProfile.name}?'), findsOneWidget);
    expect(
      find.text('This profile will be removed from your Likes list.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Unlike'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-profile-card-${firstProfile.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Super Like sends directly without opening a route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AmoraSession.logIn();
    RouteSettings? openedRoute;
    final controller = DiscoverActionController(
      profileIds: ImageRepository.profiles.map((profile) => profile.id),
      apiService: _FixtureDiscoverApiService(),
      transitionDuration: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);

    await pumpDiscover(
      tester,
      onNamedRoute: (settings) => openedRoute = settings,
      controller: controller,
    );
    final firstProfile = ImageRepository.profiles.first;
    await tester.tap(find.byKey(const ValueKey('discover-super-like-button')));
    await tester.pumpAndSettle();

    expect(openedRoute, isNull);
    expect(controller.superLikedProfileIds, contains(firstProfile.id));
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

class _FixtureDiscoverApiService extends DiscoverApiService {
  @override
  Future<DiscoverApiResult<DiscoverFeedPage>> getFeed({
    required int page,
    int limit = 10,
    Iterable<String> communicationStyles = const <String>[],
  }) async {
    final profiles = ImageRepository.profiles.map(_profileJson).toList();
    return DiscoverApiResult.success(
      DiscoverFeedPage(profiles: profiles, hasMore: false),
      statusCode: 200,
    );
  }

  @override
  Future<DiscoverApiResult<DiscoverSwipeResult>> swipe({
    required String targetUserId,
    required String action,
  }) async => DiscoverApiResult.success(
    const DiscoverSwipeResult(matched: false),
    statusCode: 200,
  );

  @override
  Future<DiscoverApiResult<Map<String, dynamic>>> rewind() async =>
      const DiscoverApiResult.success(<String, dynamic>{}, statusCode: 200);

  Map<String, dynamic> _profileJson(DummyProfile profile) => {
    'id': profile.id,
    'gender': profile.gender.name,
    'name': profile.name,
    'age': profile.age,
    'city': profile.city,
    'profession': profile.profession,
    'education': profile.education,
    'distance': int.tryParse(profile.distance.split(' ').first),
    'score': profile.score,
    'intent': profile.intent,
    'status': profile.status,
    'bio': profile.bio,
    'interests': profile.interests,
    'imageUrl': profile.imageUrl,
    'gallery': profile.gallery,
    'languages': profile.languages,
    'verification': 'verified',
    'lifestyle': profile.lifestyle,
    'promptAnswers': profile.promptAnswers,
    'religion': profile.religion,
    'community': profile.community,
    'height': profile.height,
    'smoking': profile.smoking,
    'drinking': profile.drinking,
    'weed': profile.weed,
    'hometown': profile.hometown,
    'valuedQualities': profile.valuedQualities,
    'pronouns': profile.pronouns,
    'sexuality': profile.sexuality,
    'preferredTalkingHours': profile.preferredTalkingHours,
    'loveLanguages': profile.loveLanguages,
    'communicationStyle': profile.communicationStyle?.storageValue,
  };
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? lastRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    lastRoute = route;
  }
}
