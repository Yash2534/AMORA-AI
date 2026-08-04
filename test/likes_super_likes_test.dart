import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/settings/presentation/likes_super_likes_screen.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProfileRelationshipController controller;
  late DummyProfile liked;
  late DummyProfile superLiked;

  setUp(() {
    controller = ProfileRelationshipController();
    liked = ImageRepository.profileAt(4);
    superLiked = ImageRepository.profileAt(9);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text('Destination ${settings.name}'),
        ),
        home: LikesSuperLikesScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts empty with truthful states and no dummy profiles', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('No liked profiles yet'), findsOneWidget);
    expect(find.text('Profiles you like will appear here.'), findsOneWidget);
    expect(find.text('Likes (0)'), findsOneWidget);
    expect(find.text('Super Likes (0)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('super-likes-tab')));
    await tester.pumpAndSettle();
    expect(find.text('No Super Likes yet'), findsOneWidget);
    expect(
      find.text('Profiles you Super Like will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('real reactions are unique and Super Like removal is confirmed', (
    tester,
  ) async {
    controller
      ..likeProfile(liked)
      ..likeProfile(liked)
      ..superLikeProfile(superLiked)
      ..superLikeProfile(superLiked);
    await pumpPage(tester);

    expect(controller.likedProfileIds, [liked.id]);
    expect(controller.superLikedProfileIds, [superLiked.id]);
    expect(find.text('Likes (1)'), findsOneWidget);
    expect(find.textContaining(liked.name), findsOneWidget);
    expect(find.textContaining(superLiked.name), findsNothing);

    await tester.tap(find.byKey(const ValueKey('super-likes-tab')));
    await tester.pumpAndSettle();
    expect(find.textContaining(superLiked.name), findsOneWidget);
    expect(find.textContaining(liked.name), findsNothing);

    await tester.tap(
      find.byKey(ValueKey('Remove Super Like-${superLiked.id}')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Remove Super Like from ${superLiked.name}?'),
      findsOneWidget,
    );
    expect(
      find.text('This profile will be removed from your Super Likes list.'),
      findsOneWidget,
    );
    expect(controller.superLikedProfileIds, [superLiked.id]);

    await tester.tap(find.text('Remove Super Like'));
    await tester.pumpAndSettle();
    expect(controller.superLikedProfileIds, isEmpty);
    expect(find.text('No Super Likes yet'), findsOneWidget);
  });

  testWidgets(
    'Unlike names the real profile, supports cancel, and removes one',
    (tester) async {
      final other = ImageRepository.profileAt(5);
      controller
        ..likeProfile(liked)
        ..likeProfile(other);
      await pumpPage(tester);

      await tester.tap(find.byKey(ValueKey('Unlike-${liked.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Unlike ${liked.name}?'), findsOneWidget);
      expect(
        find.text('This profile will be removed from your Likes list.'),
        findsOneWidget,
      );
      expect(find.text('Keep Like'), findsOneWidget);

      await tester.tap(find.text('Keep Like'));
      await tester.pumpAndSettle();
      expect(controller.likedProfileIds, [liked.id, other.id]);

      await tester.tap(find.byKey(ValueKey('Unlike-${liked.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlike'));
      await tester.pumpAndSettle();

      expect(controller.likedProfileIds, [other.id]);
      expect(find.textContaining(liked.name), findsNothing);
      expect(find.textContaining(other.name), findsOneWidget);
      expect(find.text('Likes (1)'), findsOneWidget);
    },
  );

  testWidgets('real profile card opens the canonical profile detail route', (
    tester,
  ) async {
    controller.likeProfile(liked);
    await pumpPage(tester);
    await tester.tap(find.byType(ManagedProfileCard));
    await tester.pumpAndSettle();
    expect(
      find.text('Destination ${ProfileDetailScreen.routeName}'),
      findsOneWidget,
    );
  });

  testWidgets('segmented page and cards fit every supported width', (
    tester,
  ) async {
    controller
      ..likeProfile(liked)
      ..superLikeProfile(superLiked);
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      await pumpPage(tester, size: Size(width, 700));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Likes page overflowed at ${width.toInt()} px.',
      );
    }
  });

  testWidgets('Profile Quick Actions use exact order and all four callbacks', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: ProfileQuickActions(
              onLikesSuperLikes: () => calls.add('likes'),
              onSavedProfiles: () => calls.add('saved'),
              onBlockedProfiles: () => calls.add('blocked'),
              onSupport: () => calls.add('support'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const labels = <String>[
      'Likes & Super Likes',
      'Saved Profiles',
      'Blocked Profiles',
      'Support',
    ];
    for (final label in labels) {
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text(label));
    }
    expect(calls, ['likes', 'saved', 'blocked', 'support']);
    expect(tester.takeException(), isNull);
  });
}
