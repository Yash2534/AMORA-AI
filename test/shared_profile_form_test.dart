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
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_language_selector.dart';
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
    'Profile prompts',
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
    profession: 'Designer',
    education: 'Postgraduate',
    location: 'Surat',
    datingIntention: 'Marriage Minded',
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

  Future<void> openCompletionSection(WidgetTester tester, String title) async {
    final sectionTitle = find.text(title);
    await tester.scrollUntilVisible(
      sectionTitle,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(sectionTitle.first);
    await tester.pumpAndSettle();
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
    expect(find.text('Profile Completion'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completion-progress-header')),
      findsOneWidget,
    );

    await openCompletionSection(tester, 'Basic Details');
    expect(find.text('Edit destination'), findsNothing);
    expect(find.text('Profile Completion'), findsOneWidget);

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
      size: const Size(430, 8000),
    );
    for (final section in ProfileCompletionSectionId.values) {
      expect(
        find.byKey(ValueKey<String>('edit-section-${section.name}')),
        findsOneWidget,
        reason: 'Edit: ${section.name}',
      );
    }
    expect(
      find.byKey(const ValueKey<String>('edit-section-verification')),
      findsOneWidget,
    );
  });

  testWidgets('Completion opens approved shared fields inline', (tester) async {
    await repository.resetForTesting(blankProfile());
    await pumpFlow(tester, const ProfileCompletionScreen());

    await openCompletionSection(tester, 'Basic Details');
    expect(find.byType(AmoraaBasicDetailsSection), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-name-field')), findsOneWidget);
    expect(find.text('Edit destination'), findsNothing);

    await openCompletionSection(tester, 'Height, Languages & Religion');
    expect(find.byType(AmoraaIdentityDetailsSelector), findsOneWidget);
    expect(find.byType(AmoraaLanguageSelector), findsOneWidget);
  });

  testWidgets('Edit and Completion use the same vertical prompts section', (
    tester,
  ) async {
    final profile = completeProfile().copyWith(
      prompts: const {
        'My ideal Sunday is...': 'Coffee and a long walk.',
        'A green flag I value is...': 'Kind, direct communication.',
      },
    );
    await repository.resetForTesting(profile);

    await pumpFlow(
      tester,
      const ProfileCompletionScreen(),
      size: const Size(430, 5000),
    );
    expect(find.byType(AmoraaProfilePromptsSection), findsOneWidget);
    expect(find.byType(AmoraaEditableProfilePromptCard), findsNWidgets(2));
    expect(find.text('Profile prompts'), findsOneWidget);
    expect(
      find.text('Thoughtful openings for a real conversation.'),
      findsOneWidget,
    );
    final completionPrompts = find.byKey(
      const ValueKey('completion-section-prompt'),
    );
    expect(
      find.descendant(
        of: completionPrompts,
        matching: find.byIcon(Icons.expand_more_rounded),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('completion-save-prompt')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('edit-profile-prompt')).first);
    await tester.pumpAndSettle();
    final completionAnswer = find.byKey(
      const ValueKey('profile-prompt-answer-field'),
    );
    expect(completionAnswer, findsOneWidget);
    expect(find.text('Edit destination'), findsNothing);
    expect(find.text('Profile Completion'), findsOneWidget);
    await tester.enterText(
      completionAnswer,
      '  Build a kinder, more thoughtful life.  ',
    );
    await tester.tap(find.byKey(const ValueKey('save-profile-prompt-edit')));
    await tester.pumpAndSettle();
    expect(
      repository.profile.prompts['My ideal Sunday is...'],
      'Build a kinder, more thoughtful life.',
    );
    expect(
      find.text('“Build a kinder, more thoughtful life.”'),
      findsOneWidget,
    );

    await pumpFlow(
      tester,
      const ProfileEditScreen(),
      size: const Size(430, 8000),
    );
    expect(find.byType(AmoraaProfilePromptsSection), findsOneWidget);
    expect(find.byType(AmoraaEditableProfilePromptCard), findsNWidgets(2));
    expect(find.widgetWithText(TextButton, 'Edit'), findsNWidgets(2));
    await tester.tap(find.byKey(const ValueKey('edit-profile-prompt')).first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('profile-prompt-answer-field')),
      findsOneWidget,
    );
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Edit destination'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('cancel-profile-prompt-edit')));
    await tester.pumpAndSettle();
    expect(
      find.text('“Build a kinder, more thoughtful life.”'),
      findsOneWidget,
    );
    expect(find.text('Like'), findsNothing);
    expect(find.text('Reply'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('Completion progress follows the profile source of truth', (
    tester,
  ) async {
    await repository.resetForTesting(blankProfile());
    await pumpFlow(tester, const ProfileCompletionScreen());

    expect(find.text('0%'), findsOneWidget);
    repository.save(blankProfile().copyWith(name: 'Guided Member'));
    await tester.pumpAndSettle();

    expect(find.text('5%'), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-name-field')), findsNothing);
    expect(find.text('Edit destination'), findsNothing);
  });

  testWidgets('Completion saves an inline section and refreshes progress', (
    tester,
  ) async {
    await repository.resetForTesting(blankProfile());
    await pumpFlow(tester, const ProfileCompletionScreen());
    await openCompletionSection(tester, 'Bio');
    const bio =
        'A thoughtful profile introduction with enough detail to be complete.';
    await tester.enterText(
      find.byKey(const ValueKey('profile-bio-field')),
      bio,
    );
    await tester.tap(find.byKey(const ValueKey('completion-save-bio')));
    await tester.pumpAndSettle();

    expect(repository.profile.bio, bio);
    expect(repository.profile.completionPercent, 10);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('completion-progress-header')),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('Bio saved successfully.'), findsOneWidget);
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

  testWidgets('Edit Profile saves a custom Other occupation', (tester) async {
    await repository.resetForTesting(completeProfile());
    await pumpFlow(
      tester,
      const ProfileEditScreen(),
      size: const Size(390, 1600),
    );

    final selector = find.byKey(const ValueKey('profile-occupation-field'));
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('amoraa-select-search')),
      'Other',
    );
    await tester.pumpAndSettle();
    final other = find.byKey(const ValueKey('amoraa-select-option-Other'));
    await tester.tap(other);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profile-custom-occupation-field')),
      '  Business Consultant  ',
    );
    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pumpAndSettle();

    expect(repository.profile.profession, 'Business Consultant');
    expect(find.text('Profile changes saved'), findsOneWidget);
  });

  testWidgets('Completion saves Other only after valid custom occupation', (
    tester,
  ) async {
    await repository.resetForTesting(
      blankProfile().copyWith(education: 'Postgraduate'),
    );
    await pumpFlow(tester, const ProfileCompletionScreen());
    await openCompletionSection(tester, 'Work & Education');

    final selector = find.byKey(const ValueKey('profile-occupation-field'));
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('amoraa-select-search')),
      'Other',
    );
    await tester.pumpAndSettle();
    final other = find.byKey(const ValueKey('amoraa-select-option-Other'));
    await tester.tap(other);
    await tester.pumpAndSettle();

    final save = find.byKey(const ValueKey('completion-save-workEducation'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.profile.profession, isEmpty);
    expect(find.text('Please enter your occupation.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('profile-custom-occupation-field')),
      'Freelancer',
    );
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.profile.profession, 'Freelancer');
    expect(
      repository.profile.completionResult.sections
          .firstWhere(
            (section) => section.id == ProfileCompletionSectionId.workEducation,
          )
          .isComplete,
      isTrue,
    );
    expect(find.text('Work & Education saved successfully.'), findsOneWidget);
  });

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
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      for (final screen in const <Widget>[
        ProfileCompletionScreen(),
        ProfileEditScreen(),
      ]) {
        await pumpFlow(
          tester,
          screen,
          size: Size(width, width >= 600 ? 900 : 700),
        );
        if (screen is ProfileCompletionScreen) {
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('profile-completion-primary-button')),
            420,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
        }
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

  testWidgets(
    'shared habits editor keeps Smoking Drinking and Weed independent',
    (tester) async {
      await repository.resetForTesting(blankProfile());
      final controller = ProfileFormController(repository: repository);
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => AmoraaHabitsEditor(
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      for (final label in const ['Smoking', 'Drinking', 'Weed']) {
        expect(find.text(label), findsOneWidget);
      }
      for (final option in ProfileFormOptions.habitFrequencyOptions) {
        expect(find.text(option), findsNWidgets(3));
      }

      await tester.tap(
        find.byKey(const ValueKey('profile-habit-smoking-Yes')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('profile-habit-smoking-Never')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('profile-habit-drinking-Sometimes')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('profile-habit-weed-Prefer not to say')),
      );
      await tester.pump();

      expect(controller.lifestyle['Smoking'], 'Never');
      expect(controller.lifestyle['Drinking'], 'Sometimes');
      expect(controller.lifestyle['Weed'], 'Prefer not to say');
      expect(tester.takeException(), isNull);
    },
  );

  test('approved option sources are centralized and Technology-free', () {
    expect(ProfileFormOptions.occupations, isNotEmpty);
    expect(ProfileFormOptions.education, isNotEmpty);
    expect(ProfileFormOptions.datingIntentions, isNotEmpty);
    expect(ProfileFormOptions.interestGroups, isNot(contains('Technology')));
  });
}
