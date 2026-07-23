import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/discover/presentation/discover_action_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary navigation exposes exactly the four approved destinations', () {
    expect(FloatingBottomNav.items, hasLength(4));
    expect(
      FloatingBottomNav.items.map((item) => item.label),
      orderedEquals(['Discover', 'Likes', 'Messages', 'Profile']),
    );
  });

  testWidgets('IndexedStack preserves the active Discover profile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const MainShell()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final first = ImageRepository.profiles.first;
    final second = ImageRepository.profiles[1];
    expect(find.text('${first.name}, ${first.age}'), findsOneWidget);
    await tester.tap(find.byKey(const Key('discover-like-button')));
    await tester.pumpAndSettle();
    expect(find.text('${second.name}, ${second.age}'), findsOneWidget);

    await tester.tap(_navLabel('Messages'));
    await tester.pumpAndSettle();
    expect(find.text('Messages'), findsWidgets);
    await tester.tap(_navLabel('Discover'));
    await tester.pumpAndSettle();
    expect(find.text('${second.name}, ${second.age}'), findsOneWidget);
  });

  testWidgets('Discover is single-card, single-image, and search-free', (
    tester,
  ) async {
    await _pumpDiscover(tester);

    expect(find.byKey(const Key('discover-filter-button')), findsOneWidget);
    expect(find.byKey(const Key('discover-profile-card')), findsOneWidget);
    expect(find.byKey(const Key('discover-cover-image')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Search by'), findsNothing);
    expect(find.byTooltip('Super Like'), findsNothing);
    expect(find.byTooltip('Boost'), findsNothing);
  });

  testWidgets('Discover photo tap zones change only the visible photo', (
    tester,
  ) async {
    await _pumpDiscover(tester);
    final profile = ImageRepository.profiles.first;
    expect(
      find.byKey(ValueKey('discover-cover-${profile.id}-0')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('discover-next-photo')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-cover-${profile.id}-1')),
      findsOneWidget,
    );
    expect(find.text('${profile.name}, ${profile.age}'), findsOneWidget);

    await tester.tap(find.byKey(const Key('discover-previous-photo')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('discover-cover-${profile.id}-0')),
      findsOneWidget,
    );
  });

  testWidgets('Discover shows a live compact completion line below 100%', (
    tester,
  ) async {
    final repository = LocalProfileRepository.instance;
    final original = repository.profile;
    addTearDown(() => repository.save(original));
    repository.save(
      original.copyWith(interests: const ['Coffee', 'Travel', 'Music']),
    );
    await _pumpDiscover(tester);

    final percent = repository.profile.completionPercent;
    expect(percent, lessThan(100));
    expect(
      find.byKey(const Key('discover-profile-completion-line')),
      findsOneWidget,
    );
    expect(find.textContaining('$percent% complete'), findsOneWidget);

    await tester.tap(find.byKey(const Key('discover-profile-completion-line')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-completion-hub')), findsOneWidget);
  });

  testWidgets('completion line updates and hides when profile reaches 100%', (
    tester,
  ) async {
    final repository = LocalProfileRepository.instance;
    final original = repository.profile;
    addTearDown(() => repository.save(original));
    repository.save(
      original.copyWith(interests: const ['Coffee', 'Travel', 'Music']),
    );
    await _pumpDiscover(tester);
    expect(
      find.byKey(const Key('discover-profile-completion-line')),
      findsOneWidget,
    );

    repository.save(
      original.copyWith(
        interests: const ['Coffee', 'Travel', 'Music', 'Design', 'Nature'],
      ),
    );
    await tester.pump();
    expect(find.text('Your profile is complete'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(
      find.byKey(const Key('discover-profile-completion-line')),
      findsNothing,
    );
  });

  testWidgets(
    'right and left gestures use Like and Reject controller actions',
    (tester) async {
      final ids = ImageRepository.profiles.take(3).map((profile) => profile.id);
      final controller = DiscoverActionController(
        profileIds: ids,
        transitionDuration: Duration.zero,
      );
      addTearDown(controller.dispose);
      await _pumpDiscover(tester, controller: controller);

      final firstId = controller.currentProfileId!;
      await tester.drag(
        find.byKey(const Key('discover-horizontal-swipe')),
        const Offset(180, 0),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(controller.likedProfileIds, contains(firstId));

      final secondId = controller.currentProfileId!;
      await tester.drag(
        find.byKey(const Key('discover-horizontal-swipe')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      expect(controller.passedProfileIds, contains(secondId));
    },
  );

  testWidgets(
    'vertical and short horizontal drags do not advance the profile',
    (tester) async {
      final controller = DiscoverActionController(
        profileIds: ImageRepository.profiles
            .take(2)
            .map((profile) => profile.id),
        transitionDuration: Duration.zero,
      );
      addTearDown(controller.dispose);
      await _pumpDiscover(tester, controller: controller);
      final initial = controller.currentProfileId;

      await tester.drag(
        find.byKey(const Key('discover-horizontal-swipe')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('discover-horizontal-swipe')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('discover-horizontal-swipe')),
        const Offset(40, 0),
      );
      await tester.pumpAndSettle();

      expect(controller.currentProfileId, initial);
      expect(controller.likedProfileIds, isEmpty);
      expect(controller.passedProfileIds, isEmpty);
    },
  );

  testWidgets('buttons and Chrome keyboard shortcuts use the same actions', (
    tester,
  ) async {
    final controller = DiscoverActionController(
      profileIds: ImageRepository.profiles.take(3).map((profile) => profile.id),
      transitionDuration: Duration.zero,
    );
    addTearDown(controller.dispose);
    await _pumpDiscover(tester, controller: controller);

    final first = controller.currentProfileId!;
    await tester.tap(find.byKey(const Key('discover-reject-button')));
    await tester.pumpAndSettle();
    expect(controller.passedProfileIds, contains(first));

    final second = controller.currentProfileId!;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(controller.likedProfileIds, contains(second));
  });

  testWidgets('empty state appears and can explicitly refresh the local deck', (
    tester,
  ) async {
    final controller = DiscoverActionController(
      profileIds: [ImageRepository.profiles.first.id],
      transitionDuration: Duration.zero,
    );
    addTearDown(controller.dispose);
    await _pumpDiscover(tester, controller: controller);

    await tester.tap(find.byKey(const Key('discover-reject-button')));
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
    expect(find.text('Adjust Filters'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('actions stay guarded while the exit animation is running', (
    tester,
  ) async {
    final controller = DiscoverActionController(
      profileIds: ImageRepository.profiles.take(3).map((profile) => profile.id),
      transitionDuration: const Duration(milliseconds: 250),
    );
    addTearDown(controller.dispose);
    await _pumpDiscover(tester, controller: controller);

    await tester.tap(find.byKey(const Key('discover-like-button')));
    expect(controller.isTransitioning, isTrue);
    await tester.tap(find.byKey(const Key('discover-reject-button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(controller.history, hasLength(1));
  });

  testWidgets('applying a non-default filter shows the active indicator', (
    tester,
  ) async {
    await _pumpDiscover(tester);
    await tester.tap(find.byKey(const Key('discover-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verified profiles only'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('discover-active-filter-indicator')),
      findsOneWidget,
    );
  });

  testWidgets('image tap opens the existing scrollable profile details route', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          ProfileDetailScreen.routeName: (_) => const ProfileDetailScreen(),
        },
        home: const BrowseGridScreen(showNavigation: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discover-profile-card')));
    await tester.pumpAndSettle();

    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(find.byKey(const Key('profile-detail-reject')), findsOneWidget);
    expect(find.byKey(const Key('profile-detail-like')), findsOneWidget);
    final heroes = tester.widgetList<Hero>(
      find.byType(Hero, skipOffstage: false),
    );
    expect(heroes, hasLength(2));
    expect(heroes.map((hero) => hero.tag).toSet(), hasLength(1));
    expect(find.byKey(const Key('profile-detail-back')), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-detail-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discover-profile-card')), findsOneWidget);
  });

  testWidgets('sticky detail actions return through the Discover controller', (
    tester,
  ) async {
    final profiles = ImageRepository.profiles.take(3).toList();
    final controller = DiscoverActionController(
      profileIds: profiles.map((profile) => profile.id),
      transitionDuration: Duration.zero,
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          ProfileDetailScreen.routeName: (_) => const ProfileDetailScreen(),
        },
        home: BrowseGridScreen(showNavigation: false, controller: controller),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    final likedId = controller.currentProfileId!;
    await tester.tap(find.byKey(const Key('discover-profile-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-detail-like')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(controller.likedProfileIds, contains(likedId));

    final rejectedId = controller.currentProfileId!;
    await tester.tap(find.byKey(const Key('discover-profile-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-detail-reject')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(controller.passedProfileIds, contains(rejectedId));
  });

  testWidgets('profile details expose the complete editorial image sequence', (
    tester,
  ) async {
    final profile = ImageRepository.profiles.first;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: ProfileDetailScreen(key: const Key('details'), profile: profile),
      ),
    );
    await tester.pumpAndSettle();
    final lastIndex = profile.gallery.length - 1;
    if (lastIndex > 0) {
      await tester.scrollUntilVisible(
        find.byKey(Key('profile-detail-image-$lastIndex')),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.byKey(Key('profile-detail-image-$lastIndex')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discover and details remain overflow-free across key sizes', (
    tester,
  ) async {
    const sizes = [
      Size(320, 568),
      Size(390, 844),
      Size(430, 932),
      Size(768, 1024),
    ];
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            theme: AmoraTheme.light(),
            home: const BrowseGridScreen(showNavigation: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$size overflowed');
    }
  });
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(FloatingBottomNav),
  matching: find.text(label),
);

Future<void> _pumpDiscover(
  WidgetTester tester, {
  DiscoverActionController? controller,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AmoraTheme.light(),
      routes: {
        ProfileCompletionScreen.routeName: (_) =>
            const ProfileCompletionScreen(),
      },
      home: BrowseGridScreen(showNavigation: false, controller: controller),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
}
