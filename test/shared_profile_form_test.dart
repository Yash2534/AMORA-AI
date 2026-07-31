import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;
  late UserProfile originalProfile;

  const approvedSections = <String>[
    'Profile Photos',
    'Basic Details',
    'Work & Education',
    'Location & Dating Intentions',
    'Height, Languages & Religion',
    'Bio',
    'Interests',
    'Lifestyle',
    'Profile Prompt',
    'Verification',
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    originalProfile = repository.profile;
  });

  tearDown(() async {
    await repository.resetForTesting(originalProfile);
  });

  UserProfile completeProfile() => originalProfile.copyWith(
    name: 'Complete AMORAA Member',
    gender: 'Female',
    profession: 'Product Designer',
    education: 'MBA',
    location: 'Surat',
    datingIntention: 'Marriage',
    bio:
        'A thoughtful AMORAA member who values kind conversation and meaningful plans.',
    interests: const ['Coffee', 'Cooking', 'Road trips', 'Yoga', 'Reading'],
    prompts: const {'Together we could...': 'Build a thoughtful life.'},
    lifestyle: const {
      'Height': '5′8″–5′11″',
      'Languages': 'English & Hindi',
      'Religion': 'Hindu',
      'Exercise': 'A few times a week',
    },
  );

  UserProfile blankProfile() => originalProfile.copyWith(
    name: '',
    birthdate: '',
    gender: '',
    profession: '',
    education: '',
    location: '',
    datingIntention: '',
    bio: '',
    photos: const [],
    interests: const [],
    prompts: const {},
    lifestyle: const {},
  );

  Future<void> pumpFlow(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          DiscoverScreen.routeName: (_) =>
              const Scaffold(body: Text('Discover destination')),
          ProfileEditScreen.routeName: (_) =>
              const Scaffold(body: Text('Edit destination')),
          '/profile': (_) => const Scaffold(body: Text('Profile destination')),
          '/profile-preview': (_) => const Scaffold(body: Text('Preview')),
          '/photo-manager': (_) => const Scaffold(body: Text('Photos')),
          '/kyc': (_) => const Scaffold(body: Text('Verification')),
        },
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> expandAllCompletionSections(WidgetTester tester) async {
    for (final section in ProfileCompletionSectionId.values) {
      final title = repository.profile.completionResult.sections
          .firstWhere((item) => item.id == section)
          .title;
      await tester.tap(find.text(title).first);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('Completion and Edit are independent screen implementations', (
    tester,
  ) async {
    expect(ProfileCompletionScreen.routeName, '/profile-completion');
    expect(ProfileEditScreen.routeName, '/edit-profile');
    expect(
      ProfileCompletionScreen.routeName,
      isNot(ProfileEditScreen.routeName),
    );

    await repository.resetForTesting(blankProfile());
    await pumpFlow(tester, const ProfileCompletionScreen());
    expect(find.byType(AmoraaProfileForm), findsNothing);
    expect(find.text('Complete your profile'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completion-progress-header')),
      findsOneWidget,
    );

    await tester.tap(find.text('Basic Details'));
    await tester.pumpAndSettle();
    expect(find.text('Edit destination'), findsNothing);
    expect(find.text('Complete your profile'), findsOneWidget);

    await repository.resetForTesting(completeProfile());
    await pumpFlow(tester, const ProfileEditScreen());
    expect(find.byType(AmoraaProfileForm), findsOneWidget);
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Next best step'), findsNothing);
  });

  testWidgets('both screens contain the same approved sections', (
    tester,
  ) async {
    await repository.resetForTesting(completeProfile());
    await pumpFlow(
      tester,
      const ProfileCompletionScreen(),
      size: const Size(430, 5000),
    );
    for (final section in approvedSections) {
      expect(
        find.text(section),
        findsOneWidget,
        reason: 'Completion: $section',
      );
    }

    await pumpFlow(
      tester,
      const ProfileEditScreen(),
      size: const Size(430, 5000),
    );
    for (final section in approvedSections) {
      expect(find.text(section), findsOneWidget, reason: 'Edit: $section');
    }
  });

  testWidgets('both screens reuse every approved shared field component', (
    tester,
  ) async {
    await repository.resetForTesting(completeProfile());
    await pumpFlow(
      tester,
      const ProfileCompletionScreen(),
      size: const Size(430, 5000),
    );
    await expandAllCompletionSections(tester);

    final sharedTypes = <Type>[
      AmoraaProfilePhotoSection,
      AmoraaBasicDetailsSection,
      AmoraaWorkEducationSection,
      AmoraaLocationIntentionsSection,
      AmoraaIdentityDetailsSelector,
      AmoraaProfileBioField,
      AmoraaInterestsSelector,
      AmoraaLifestyleSelector,
      AmoraaProfilePromptField,
    ];
    for (final type in sharedTypes) {
      expect(find.byType(type), findsOneWidget, reason: 'Completion: $type');
    }

    await pumpFlow(
      tester,
      const ProfileEditScreen(),
      size: const Size(430, 5000),
    );
    for (final type in sharedTypes) {
      expect(find.byType(type), findsOneWidget, reason: 'Edit: $type');
    }
  });

  testWidgets('Completion progress updates while editing directly', (
    tester,
  ) async {
    await repository.resetForTesting(blankProfile());
    await pumpFlow(tester, const ProfileCompletionScreen());

    expect(find.text('0%'), findsOneWidget);
    await tester.tap(find.text('Basic Details'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-field')),
      'Guided Member',
    );
    await tester.pumpAndSettle();

    expect(find.text('5%'), findsOneWidget);
    expect(find.text('Edit destination'), findsNothing);
  });

  testWidgets('Completion saves partial progress without opening Edit', (
    tester,
  ) async {
    await repository.resetForTesting(blankProfile());
    await pumpFlow(tester, const ProfileCompletionScreen());
    await tester.tap(find.text('Basic Details'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-name-field')),
      'Persisted Guided Member',
    );

    await tester.tap(
      find.byKey(const ValueKey('profile-completion-primary-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.profile.name, 'Persisted Guided Member');
    expect(find.text('Profile progress saved'), findsOneWidget);
    expect(find.text('Edit destination'), findsNothing);
  });

  testWidgets(
    'Edit Profile saves independently through the shared controller',
    (tester) async {
      await repository.resetForTesting(completeProfile());
      await pumpFlow(tester, const ProfileEditScreen());

      await tester.enterText(
        find.byKey(const ValueKey('profile-name-field')),
        'Updated Existing Member',
      );
      await tester.tap(find.byKey(const ValueKey('profile-save-button')));
      await tester.pumpAndSettle();

      expect(repository.profile.name, 'Updated Existing Member');
      expect(find.text('Profile changes saved'), findsOneWidget);
    },
  );

  test('one prompt and all approved fields produce centralized completion', () {
    final profile = completeProfile();
    final result = profile.completionResult;

    expect(result.percentage, 100);
    expect(result.isComplete, isTrue);
    expect(result.remainingFieldCount, 0);
    expect(result.remainingSectionCount, 0);
    expect(profile.completedPromptCount, 1);
    expect(ProfileFormValidators.profile(profile), isEmpty);
  });

  testWidgets('removed fields and interests are absent from both flows', (
    tester,
  ) async {
    await repository.resetForTesting(completeProfile());
    for (final screen in const <Widget>[
      ProfileCompletionScreen(),
      ProfileEditScreen(),
    ]) {
      await pumpFlow(tester, screen, size: const Size(430, 5000));
      for (final removed in const [
        'Children',
        'Voice Introduction',
        'Technology',
        'Flutter',
        'Startups',
        'Product design',
        'Gaming',
      ]) {
        expect(find.text(removed), findsNothing);
      }
      expect(
        find.textContaining('Height, Languages & Religion'),
        findsOneWidget,
      );
    }
  });

  testWidgets('both screens remain usable at every supported width', (
    tester,
  ) async {
    await repository.resetForTesting(completeProfile());
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      for (final screen in const <Widget>[
        ProfileCompletionScreen(),
        ProfileEditScreen(),
      ]) {
        await pumpFlow(
          tester,
          screen,
          size: Size(width, width >= 600 ? 900 : 700),
        );
        expect(
          screen is ProfileCompletionScreen
              ? find.byKey(const ValueKey('profile-completion-primary-button'))
              : find.byKey(const ValueKey('profile-save-button')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '$screen at $width px');
      }
    }
  });

  test('Completion source contains no Edit Profile route dependency', () {
    final source = File(
      'lib/features/profile/presentation/profile_completion_screen.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('ProfileEditScreen')));
    expect(source, isNot(contains(ProfileEditScreen.routeName)));
  });

  test('shared controller writes through LocalProfileRepository', () async {
    await repository.resetForTesting(completeProfile());
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    controller.name.text = 'Shared Controller Member';
    final saved = await controller.save();

    expect(saved.name, 'Shared Controller Member');
    expect(repository.profile.name, 'Shared Controller Member');
  });

  test('approved option sources are centralized and Technology-free', () {
    expect(ProfileFormOptions.occupations, isNotEmpty);
    expect(ProfileFormOptions.education, isNotEmpty);
    expect(ProfileFormOptions.datingIntentions, isNotEmpty);
    expect(ProfileFormOptions.interestGroups, isNot(contains('Technology')));
  });
}
