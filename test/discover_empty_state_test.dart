import 'dart:async';

import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDiscover(
    WidgetTester tester, {
    required _DiscoverFixtureApi api,
    required DiscoverActionController controller,
    required bool? Function() profileComplete,
    Future<void> Function()? refreshProfile,
    ValueChanged<RouteSettings>? onRoute,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BrowseGridScreen(
          showNavigation: false,
          apiService: api,
          controller: controller,
          profileCompletionResolver: profileComplete,
          refreshProfileCompletion: refreshProfile,
        ),
        onGenerateRoute: (settings) {
          onRoute?.call(settings);
          if (settings.name == ProfileCompletionScreen.routeName ||
              settings.name == ProfileEditScreen.routeName) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (routeContext) => Scaffold(
                body: Center(
                  child: FilledButton(
                    key: const ValueKey('profile-flow-done'),
                    onPressed: () => Navigator.of(routeContext).pop(),
                    child: Text('${settings.name} destination'),
                  ),
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  DiscoverActionController controllerFor(
    _DiscoverFixtureApi api,
    Iterable<String> ids,
  ) => DiscoverActionController(
    profileIds: ids,
    apiService: api,
    transitionDuration: const Duration(milliseconds: 1),
    refreshChats: () async {},
  );

  void expectEmpty({required bool complete}) {
    expect(find.text('Complete your profile to get matches.'), findsOneWidget);
    expect(
      find.text(complete ? 'Edit Profile' : 'Complete Profile'),
      findsOneWidget,
    );
    expect(
      find.text(complete ? 'Complete Profile' : 'Edit Profile'),
      findsNothing,
    );
    expect(find.text('You are all caught up'), findsNothing);
    expect(
      find.byKey(const ValueKey('discover-profile-empty-cta')),
      findsOneWidget,
    );
  }

  testWidgets(
    'new user zero results and incomplete profile use Complete Profile',
    (tester) async {
      final api = _DiscoverFixtureApi.empty();
      final controller = controllerFor(api, const []);
      addTearDown(controller.dispose);
      await pumpDiscover(
        tester,
        api: api,
        controller: controller,
        profileComplete: () => false,
      );
      expectEmpty(complete: false);
    },
  );

  testWidgets('new user zero results and complete profile use Edit Profile', (
    tester,
  ) async {
    final api = _DiscoverFixtureApi.empty();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => true,
    );
    expectEmpty(complete: true);
  });

  testWidgets('existing incomplete user receives the same empty state', (
    tester,
  ) async {
    final api = _DiscoverFixtureApi.empty();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => false,
    );
    expectEmpty(complete: false);
  });

  testWidgets('existing complete user receives the same empty state', (
    tester,
  ) async {
    final api = _DiscoverFixtureApi.empty();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => true,
    );
    expectEmpty(complete: true);
  });

  testWidgets('two profiles render and exhaust immediately to incomplete CTA', (
    tester,
  ) async {
    final profiles = ImageRepository.profiles.take(2).toList();
    final api = _DiscoverFixtureApi.singlePage(profiles);
    final controller = controllerFor(api, profiles.map((item) => item.id));
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => false,
    );
    expect(
      find.byKey(ValueKey('discover-profile-card-${profiles[0].id}')),
      findsOne,
    );
    await tester.tap(find.byKey(const ValueKey('discover-pass-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-profile-card-${profiles[0].id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('discover-profile-card-${profiles[1].id}')),
      findsOne,
    );
    await tester.tap(find.byKey(const ValueKey('discover-pass-button')));
    await tester.pumpAndSettle();
    expectEmpty(complete: false);
  });

  testWidgets('final swipe for complete profile uses Edit Profile CTA', (
    tester,
  ) async {
    final profile = ImageRepository.profiles.first;
    final api = _DiscoverFixtureApi.singlePage([profile]);
    final controller = controllerFor(api, [profile.id]);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => true,
    );
    await tester.tap(find.byKey(const ValueKey('discover-like-button')));
    await tester.pumpAndSettle();
    expectEmpty(complete: true);
  });

  testWidgets('Complete Profile CTA opens the existing completion route', (
    tester,
  ) async {
    final api = _DiscoverFixtureApi.empty();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    RouteSettings? route;
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => false,
      onRoute: (value) => route = value,
    );
    await tester.tap(find.text('Complete Profile'));
    await tester.pumpAndSettle();
    expect(route?.name, ProfileCompletionScreen.routeName);
  });

  testWidgets('Edit Profile CTA opens the existing edit route', (tester) async {
    final api = _DiscoverFixtureApi.empty();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    RouteSettings? route;
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => true,
      onRoute: (value) => route = value,
    );
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    expect(route?.name, ProfileEditScreen.routeName);
  });

  testWidgets(
    'returning from completion refreshes Complete Profile to Edit Profile',
    (tester) async {
      var complete = false;
      var refreshes = 0;
      final api = _DiscoverFixtureApi.empty();
      final controller = controllerFor(api, const []);
      addTearDown(controller.dispose);
      await pumpDiscover(
        tester,
        api: api,
        controller: controller,
        profileComplete: () => complete,
        refreshProfile: () async {
          refreshes += 1;
        },
      );
      await tester.tap(find.text('Complete Profile'));
      await tester.pumpAndSettle();
      complete = true;
      await tester.tap(find.byKey(const ValueKey('profile-flow-done')));
      await tester.pumpAndSettle();
      expect(refreshes, 1);
      expectEmpty(complete: true);
    },
  );

  testWidgets('loading never prematurely shows the empty state', (
    tester,
  ) async {
    final pending = Completer<DiscoverApiResult<DiscoverFeedPage>>();
    final api = _DiscoverFixtureApi.pending(pending.future);
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BrowseGridScreen(
          showNavigation: false,
          apiService: api,
          controller: controller,
          profileCompletionResolver: () => false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Complete your profile to get matches.'), findsNothing);
    pending.complete(
      const DiscoverApiResult.success(
        DiscoverFeedPage(profiles: [], hasMore: false),
        statusCode: 200,
      ),
    );
    await tester.pumpAndSettle();
    expectEmpty(complete: false);
  });

  testWidgets('API failure preserves the retry error instead of empty state', (
    tester,
  ) async {
    final api = _DiscoverFixtureApi.failure();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => false,
    );
    expect(find.text('Couldn’t load profiles'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Complete your profile to get matches.'), findsNothing);
  });

  testWidgets('unresolved profile completion never guesses a CTA', (
    tester,
  ) async {
    final api = _DiscoverFixtureApi.empty();
    final controller = controllerFor(api, const []);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => null,
    );
    expect(find.text('Couldn’t load your profile'), findsOneWidget);
    expect(find.text('Complete Profile'), findsNothing);
    expect(find.text('Edit Profile'), findsNothing);
  });

  testWidgets('pagination fetches another page before declaring exhaustion', (
    tester,
  ) async {
    final profiles = ImageRepository.profiles.take(2).toList();
    final api = _DiscoverFixtureApi.pages({
      1: DiscoverFeedPage(
        profiles: [_profileJson(profiles[0])],
        hasMore: true,
        nextPage: 2,
      ),
      2: DiscoverFeedPage(
        profiles: [_profileJson(profiles[1])],
        hasMore: false,
      ),
    });
    final controller = controllerFor(api, [profiles[0].id]);
    addTearDown(controller.dispose);
    await pumpDiscover(
      tester,
      api: api,
      controller: controller,
      profileComplete: () => false,
    );
    await tester.tap(find.byKey(const ValueKey('discover-pass-button')));
    await tester.pumpAndSettle();
    expect(find.text('Complete your profile to get matches.'), findsNothing);
    expect(
      find.byKey(ValueKey('discover-profile-card-${profiles[1].id}')),
      findsOne,
    );
    expect(api.requestedPages, containsAllInOrder([1, 2]));
  });

  testWidgets(
    'failed swipe keeps the current card and never fakes exhaustion',
    (tester) async {
      final profile = ImageRepository.profiles.first;
      final api = _DiscoverFixtureApi.singlePage([
        profile,
      ], swipeSuccess: false);
      final controller = controllerFor(api, [profile.id]);
      addTearDown(controller.dispose);
      await pumpDiscover(
        tester,
        api: api,
        controller: controller,
        profileComplete: () => false,
      );
      await tester.tap(find.byKey(const ValueKey('discover-pass-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('discover-profile-card-${profile.id}')),
        findsOne,
      );
      expect(find.text('Complete your profile to get matches.'), findsNothing);
    },
  );
}

class _DiscoverFixtureApi extends DiscoverApiService {
  _DiscoverFixtureApi._({
    this.feedPages = const {},
    this.feedFailure = false,
    this.swipeSuccess = true,
    this.pendingFeed,
  });

  factory _DiscoverFixtureApi.empty() => _DiscoverFixtureApi.pages({
    1: const DiscoverFeedPage(profiles: [], hasMore: false),
  });

  factory _DiscoverFixtureApi.singlePage(
    List<DummyProfile> profiles, {
    bool swipeSuccess = true,
  }) => _DiscoverFixtureApi._(
    feedPages: {
      1: DiscoverFeedPage(
        profiles: profiles.map(_profileJson).toList(),
        hasMore: false,
      ),
    },
    swipeSuccess: swipeSuccess,
  );

  factory _DiscoverFixtureApi.pages(Map<int, DiscoverFeedPage> pages) =>
      _DiscoverFixtureApi._(feedPages: pages);

  factory _DiscoverFixtureApi.failure() =>
      _DiscoverFixtureApi._(feedFailure: true);

  factory _DiscoverFixtureApi.pending(
    Future<DiscoverApiResult<DiscoverFeedPage>> pending,
  ) => _DiscoverFixtureApi._(pendingFeed: pending);

  final Map<int, DiscoverFeedPage> feedPages;
  final bool feedFailure;
  final bool swipeSuccess;
  final Future<DiscoverApiResult<DiscoverFeedPage>>? pendingFeed;
  final List<int> requestedPages = [];

  @override
  Future<DiscoverApiResult<DiscoverFeedPage>> getFeed({
    required int page,
    int limit = 10,
    Iterable<String> communicationStyles = const [],
  }) async {
    requestedPages.add(page);
    if (pendingFeed != null) return pendingFeed!;
    if (feedFailure) {
      return const DiscoverApiResult.failure(
        'Network unavailable.',
        statusCode: 503,
      );
    }
    return DiscoverApiResult.success(
      feedPages[page] ?? const DiscoverFeedPage(profiles: [], hasMore: false),
      statusCode: 200,
    );
  }

  @override
  Future<DiscoverApiResult<DiscoverSwipeResult>> swipe({
    required String targetUserId,
    required String action,
  }) async => swipeSuccess
      ? const DiscoverApiResult.success(
          DiscoverSwipeResult(matched: false),
          statusCode: 200,
        )
      : const DiscoverApiResult.failure('Action failed.', statusCode: 503);
}

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
