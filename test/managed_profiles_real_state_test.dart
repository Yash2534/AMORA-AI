import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AmoraSession.logIn();
    ProfileRelationshipController.instance.clear();
  });

  tearDown(() {
    ProfileRelationshipController.instance.clear();
    AmoraSession.logOut();
  });

  test(
    'saved and blocked state starts empty and de-duplicates real profiles',
    () {
      final controller = ProfileRelationshipController();
      final first = ImageRepository.profiles.first;
      final second = ImageRepository.profiles[1];

      expect(controller.savedProfiles, isEmpty);
      expect(controller.blockedProfiles, isEmpty);

      controller.saveProfile(first);
      controller.saveProfile(first);
      controller.blockProfile(second);
      controller.blockProfile(second);

      expect(controller.savedProfileIds, [first.id]);
      expect(controller.savedProfiles.single, same(first));
      expect(controller.blockedProfileIds, [second.id]);
      expect(controller.blockedProfiles.single, same(second));

      controller.removeSaved(first.id);
      controller.unblockProfile(second.id);
      expect(controller.savedProfiles, isEmpty);
      expect(controller.blockedProfiles, isEmpty);
    },
  );

  testWidgets(
    'Saved Profiles uses action-driven state and removes immediately',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ProfileRelationshipController();
      final profile = ImageRepository.profiles[14];

      await tester.pumpWidget(
        MaterialApp(home: SavedProfilesScreen(controller: controller)),
      );
      expect(find.text('No saved profiles yet'), findsOneWidget);
      expect(find.text('Profiles you save will appear here.'), findsOneWidget);
      expect(find.byType(ProfileDetailScreen), findsNothing);

      controller.saveProfile(profile);
      await tester.pump();
      expect(find.text('${profile.name}, ${profile.age}'), findsOneWidget);
      expect(
        find.byKey(ValueKey('managed-profile-${profile.id}')),
        findsOneWidget,
      );

      controller.saveProfile(profile);
      await tester.pump();
      expect(
        find.byKey(ValueKey('managed-profile-${profile.id}')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(ValueKey('Remove saved profile-${profile.id}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('No saved profiles yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Saved profile card opens the existing profile details screen', (
    tester,
  ) async {
    final controller = ProfileRelationshipController();
    final profile = ImageRepository.profiles[18];
    controller.saveProfile(profile);

    await tester.pumpWidget(
      MaterialApp(
        home: SavedProfilesScreen(controller: controller),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              ProfileDetailScreen(profile: settings.arguments as DummyProfile?),
        ),
      ),
    );
    await tester.tap(find.text('${profile.name}, ${profile.age}'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Blocked Profiles uses real state and unblocks immediately', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ProfileRelationshipController();
    final profile = ImageRepository.profiles[24];

    await tester.pumpWidget(
      MaterialApp(home: BlockedProfilesScreen(controller: controller)),
    );
    expect(find.text('No blocked profiles'), findsOneWidget);
    expect(find.text('Profiles you block will appear here.'), findsOneWidget);

    controller.blockProfile(profile);
    controller.blockProfile(profile);
    await tester.pump();
    expect(
      find.byKey(ValueKey('managed-profile-${profile.id}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(ValueKey('Unblock profile-${profile.id}')));
    await tester.pumpAndSettle();
    expect(find.text('No blocked profiles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile details save action synchronizes shared saved state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final profile = ImageRepository.profiles[28];

    await tester.pumpWidget(
      MaterialApp(home: ProfileDetailScreen(profile: profile)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pump();

    expect(ProfileRelationshipController.instance.savedProfileIds, [
      profile.id,
    ]);
    expect(find.byTooltip('Remove saved profile'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pump();
    expect(ProfileRelationshipController.instance.savedProfiles, isEmpty);
  });

  testWidgets(
    'profile details block action synchronizes shared blocked state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final profile = ImageRepository.profiles[32];

      await tester.pumpWidget(
        MaterialApp(home: ProfileDetailScreen(profile: profile)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-more-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Block User'));
      await tester.pumpAndSettle();

      expect(ProfileRelationshipController.instance.blockedProfileIds, [
        profile.id,
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}
