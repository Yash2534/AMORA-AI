import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;
  late UserProfile originalProfile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalProfile = repository.profile;
  });

  tearDown(() async {
    await repository.resetForTesting(originalProfile);
  });

  UserProfile validProfile({
    List<String> photos = const [
      AppImages.profileYash,
      'assets/images/profiles/male/male_06.jpg',
    ],
    List<String> interests = const [
      'Coffee',
      'Cooking',
      'Road trips',
      'Yoga',
      'Reading',
    ],
  }) => originalProfile.copyWith(
    name: 'Validation Member',
    birthdate: '14/02/1998',
    gender: 'Female',
    profession: 'Designer',
    education: 'Postgraduate',
    location: 'Surat',
    datingIntention: 'Marriage Minded',
    bio:
        'A thoughtful AMORAA member who values kind conversation and meaningful plans.',
    photos: photos,
    interests: interests,
  );

  Future<void> pumpEditForm(
    WidgetTester tester, {
    required UserProfile profile,
    required VoidCallback onSaved,
  }) async {
    await repository.resetForTesting(profile);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: AmoraaProfileForm(onSaved: (_, _) async => onSaved()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapSaveAndWaitForValidation(WidgetTester tester) async {
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
  }

  group('profile requirement counts', () {
    test('counts only unique usable active photos', () {
      final onePhoto = validProfile(photos: const [AppImages.profileYash]);
      expect(ProfileFormValidators.validPhotoCount(onePhoto), 1);
      expect(
        ProfileFormValidators.photos(onePhoto),
        'Add at least 2 profile photos before saving.',
      );

      final duplicateAndPlaceholders = validProfile(
        photos: const [
          AppImages.profileYash,
          AppImages.profileYash,
          '',
          AppImages.fallbackProfile,
          'assets/images/profile_placeholder.png',
        ],
      );
      expect(
        ProfileFormValidators.validPhotoCount(duplicateAndPlaceholders),
        1,
      );

      final twoPhotos = validProfile();
      expect(ProfileFormValidators.validPhotoCount(twoPhotos), 2);
      expect(ProfileFormValidators.photos(twoPhotos), isNull);
    });

    test('does not count deleting or failed photos without a preview', () {
      final profile = validProfile(
        photos: const [
          'https://images.example/active.jpg',
          'https://images.example/deleting.jpg',
          'https://images.example/failed.jpg',
        ],
      );
      const states = <ProfilePhotoViewData>[
        ProfilePhotoViewData(
          id: 'active',
          source: 'https://images.example/active.jpg',
          order: 0,
          isPrimary: true,
          uploadState: ProfilePhotoUploadState.uploaded,
        ),
        ProfilePhotoViewData(
          id: 'deleting',
          source: 'https://images.example/deleting.jpg',
          order: 1,
          isPrimary: false,
          uploadState: ProfilePhotoUploadState.deleting,
        ),
        ProfilePhotoViewData(
          id: 'failed',
          source: 'https://images.example/failed.jpg',
          order: 2,
          isPrimary: false,
          uploadState: ProfilePhotoUploadState.failed,
        ),
      ];

      expect(
        ProfileFormValidators.validPhotoCount(profile, photoStates: states),
        1,
      );
    });

    test('requires five unique approved interests', () {
      expect(
        ProfileFormValidators.interests(validProfile(interests: const [])),
        'Select at least 5 interests before saving.',
      );
      expect(
        ProfileFormValidators.interests(
          validProfile(
            interests: const ['Coffee', 'Cooking', 'Road trips', 'Yoga'],
          ),
        ),
        'Select at least 5 interests before saving.',
      );
      expect(
        ProfileFormValidators.interests(
          validProfile(
            interests: const [
              'Coffee',
              'Coffee',
              'Cooking',
              'Road trips',
              'Yoga',
              'Technology',
              '',
            ],
          ),
        ),
        'Select at least 5 interests before saving.',
      );
      expect(ProfileFormValidators.interests(validProfile()), isNull);
    });
  });

  testWidgets('zero photos block save and highlight Photos first', (
    tester,
  ) async {
    var saveCompletions = 0;
    final semantics = tester.ensureSemantics();
    await pumpEditForm(
      tester,
      profile: validProfile(photos: const []),
      onSaved: () => saveCompletions++,
    );

    await tapSaveAndWaitForValidation(tester);

    expect(saveCompletions, 0);
    expect(
      find.text('Add at least 2 profile photos before saving.'),
      findsWidgets,
    );
    expect(_highlightedTarget('Profile Photos'), findsOneWidget);
    expect(find.text('Profile changes saved'), findsNothing);
    semantics.dispose();
  });

  testWidgets('one photo blocks save before persistence', (tester) async {
    var saveCompletions = 0;
    final profile = validProfile(photos: const [AppImages.profileYash]);
    await pumpEditForm(
      tester,
      profile: profile,
      onSaved: () => saveCompletions++,
    );
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-field')),
      'This name must not persist',
    );

    await tapSaveAndWaitForValidation(tester);

    expect(saveCompletions, 0);
    expect(repository.profile.name, profile.name);
  });

  testWidgets('four interests block save and highlight Interests', (
    tester,
  ) async {
    var saveCompletions = 0;
    final semantics = tester.ensureSemantics();
    await pumpEditForm(
      tester,
      profile: validProfile(
        interests: const ['Coffee', 'Cooking', 'Road trips', 'Yoga'],
      ),
      onSaved: () => saveCompletions++,
    );

    await tapSaveAndWaitForValidation(tester);

    expect(saveCompletions, 0);
    expect(
      find.text('Select at least 5 interests before saving.'),
      findsWidgets,
    );
    expect(_highlightedTarget('Interests'), findsOneWidget);
    expect(find.text('Profile changes saved'), findsNothing);
    semantics.dispose();
  });

  testWidgets('zero interests block save', (tester) async {
    var saveCompletions = 0;
    await pumpEditForm(
      tester,
      profile: validProfile(interests: const []),
      onSaved: () => saveCompletions++,
    );

    await tapSaveAndWaitForValidation(tester);

    expect(saveCompletions, 0);
    expect(repository.profile.interests, isEmpty);
  });

  testWidgets('valid requirements complete save exactly once', (tester) async {
    var saveCompletions = 0;
    await pumpEditForm(
      tester,
      profile: validProfile(),
      onSaved: () => saveCompletions++,
    );

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(saveCompletions, 1);
    expect(
      find.text('Add at least 2 profile photos before saving.'),
      findsNothing,
    );
    expect(
      find.text('Select at least 5 interests before saving.'),
      findsNothing,
    );
  });
}

Finder _highlightedTarget(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.label == '$label, ready for editing',
);
