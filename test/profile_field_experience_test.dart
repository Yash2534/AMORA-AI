import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_adaptive_image.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_section_editor_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_dating_intention_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_language_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_prompt_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_story_image.dart';
import 'package:amora_ai/features/profile/presentation/widgets/profile_photo_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;
  late UserProfile originalProfile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await repository.resetForTesting();
    originalProfile = repository.profile;
  });

  tearDown(() => repository.resetForTesting(originalProfile));

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(body: SafeArea(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('language codec preserves the existing string storage contract', () {
    expect(ProfileFormOptions.parseLanguages('English, Hindi & Gujarati'), {
      'English',
      'Hindi',
      'Gujarati',
    });
    expect(
      ProfileFormOptions.serializeLanguages({'Gujarati', 'English', 'Hindi'}),
      'Gujarati, Hindi & English',
    );
  });

  testWidgets(
    'Education Other is inline, validated, trimmed, and stored safely',
    (tester) async {
      await repository.resetForTesting(originalProfile.copyWith(education: ''));
      final controller = ProfileFormController(repository: repository);
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();
      await pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) =>
                  AmoraaWorkEducationSection(controller: controller),
            ),
          ),
        ),
        size: const Size(390, 844),
      );

      final selector = find.byKey(const ValueKey('profile-education-field'));
      await tester.tap(selector);
      await tester.pumpAndSettle();
      final other = find.byKey(const ValueKey('amoraa-select-option-Other'));
      await tester.scrollUntilVisible(
        other,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(other);
      await tester.pumpAndSettle();

      final custom = find.byKey(
        const ValueKey('profile-custom-education-field'),
      );
      expect(custom, findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Specify education'), findsNWidgets(2));

      await tester.enterText(custom, '  Montessori training  ');
      expect(formKey.currentState!.validate(), isTrue);
      await controller.save();
      expect(controller.customEducation.text, 'Montessori training');
      expect(repository.profile.education, 'Montessori training');

      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('amoraa-select-option-Undergraduate')),
      );
      await tester.pumpAndSettle();
      expect(custom, findsNothing);
      expect(controller.customEducation.text, 'Montessori training');
    },
  );

  testWidgets(
    'Occupation Other is inline, validated, restored, and stored as text',
    (tester) async {
      await repository.resetForTesting(
        originalProfile.copyWith(profession: ''),
      );
      final controller = ProfileFormController(repository: repository);
      addTearDown(controller.dispose);
      final formKey = GlobalKey<FormState>();
      await pump(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: formKey,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) =>
                  AmoraaWorkEducationSection(controller: controller),
            ),
          ),
        ),
        size: const Size(320, 700),
      );

      final selector = find.byKey(const ValueKey('profile-occupation-field'));
      await tester.tap(selector);
      await tester.pumpAndSettle();
      final other = find.byKey(const ValueKey('amoraa-select-option-Other'));
      await tester.scrollUntilVisible(
        other,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(other);
      await tester.pumpAndSettle();

      final custom = find.byKey(
        const ValueKey('profile-custom-occupation-field'),
      );
      expect(custom, findsOneWidget);
      expect(find.bySemanticsLabel('Specify occupation'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Please enter your occupation.'), findsOneWidget);

      await tester.enterText(custom, '   ');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.enterText(custom, '  Photographer  ');
      expect(formKey.currentState!.validate(), isTrue);
      await controller.save();
      expect(controller.customOccupation.text, 'Photographer');
      expect(repository.profile.profession, 'Photographer');
      expect(
        repository.profile.completionResult.sections
            .firstWhere((section) => section.title == 'Work & Education')
            .completedFields,
        greaterThanOrEqualTo(1),
      );

      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('amoraa-select-search')),
        'Designer',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('amoraa-select-option-Designer')),
      );
      await tester.pumpAndSettle();
      expect(custom, findsNothing);
      expect(controller.customOccupation.text, 'Photographer');

      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('amoraa-select-search')),
        'Other',
      );
      await tester.pumpAndSettle();
      await tester.tap(other);
      await tester.pumpAndSettle();
      expect(custom, findsOneWidget);
      expect(find.text('Photographer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('languages multi-selects without a dropdown and persists', (
    tester,
  ) async {
    await repository.resetForTesting(
      originalProfile.copyWith(
        lifestyle: {...originalProfile.lifestyle, 'Languages': 'English'},
      ),
    );
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);

    await pump(
      tester,
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AmoraaLanguageSelector(
          selectedLanguages: controller.languages,
          onChanged: controller.setLanguages,
        ),
      ),
      size: const Size(320, 700),
    );

    final selector = find.byType(AmoraaLanguageSelector);
    expect(
      find.descendant(
        of: selector,
        matching: find.byType(DropdownButton<String>),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: selector,
        matching: find.byType(DropdownMenu<String>),
      ),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('add-languages-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-option-Hindi')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-option-Gujarati')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('language-picker-done')));
    await tester.pumpAndSettle();

    expect(controller.languages, {'English', 'Hindi', 'Gujarati'});
    await controller.save();
    expect(
      repository.profile.lifestyle['Languages'],
      'Gujarati, Hindi & English',
    );

    final reloaded = ProfileFormController(repository: repository);
    addTearDown(reloaded.dispose);
    expect(reloaded.languages, {'English', 'Hindi', 'Gujarati'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile prompt edits the saved answer inside its card', (
    tester,
  ) async {
    await repository.resetForTesting(
      originalProfile.copyWith(
        prompts: const {'Together we could...': 'Explore somewhere new.'},
      ),
    );
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    await pump(
      tester,
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AmoraaProfilePromptField(controller: controller),
      ),
    );

    expect(find.text('Together we could...'), findsOneWidget);
    final promptField = find.byType(AmoraaProfilePromptField);
    expect(
      find.descendant(
        of: promptField,
        matching: find.byType(DropdownButtonFormField<String>),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: promptField,
        matching: find.byType(DropdownMenu<String>),
      ),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Edit').first);
    await tester.pumpAndSettle();
    final answerField = find.byKey(
      const ValueKey('profile-prompt-answer-field'),
    );
    expect(answerField, findsOneWidget);
    expect(
      tester.widget<TextFormField>(answerField).controller?.text,
      'Explore somewhere new.',
    );
    expect(find.byType(AmoraaProfilePromptSelector), findsNothing);
    await tester.enterText(answerField, '  Explore a new neighbourhood.  ');
    await tester.tap(find.byKey(const ValueKey('save-profile-prompt-edit')));
    await tester.pumpAndSettle();
    expect(controller.promptTitle, 'Together we could...');
    expect(
      repository.profile.prompts['Together we could...'],
      'Explore a new neighbourhood.',
    );
    expect(controller.draftProfile.completedPromptCount, 1);
  });

  testWidgets('standalone prompt editor also contains no prompt dropdown', (
    tester,
  ) async {
    await pump(
      tester,
      const ProfileSectionEditorScreen(section: ProfileSection.prompts),
    );
    expect(find.byType(AmoraaProfilePromptSelector), findsWidgets);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(DropdownMenu<String>), findsNothing);
  });

  testWidgets('dating intention picker exposes only approved values', (
    tester,
  ) async {
    String selected = '';
    await pump(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: AmoraaDatingIntentionSelector(
            value: selected,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose your intention'));
    await tester.pumpAndSettle();

    final intentionList = find.byType(Scrollable).last;
    for (final intention in ProfileFormOptions.datingIntentions) {
      final option = find.byKey(ValueKey('amoraa-select-option-$intention'));
      await tester.scrollUntilVisible(option, 180, scrollable: intentionList);
      expect(find.text(intention), findsOneWidget);
    }
    for (final retired in const [
      'Fun',
      'Date',
      'Dating',
      'Casual',
      'Serious',
      'Travel Partner',
      'Open to Anything',
      'New Friends',
      'See Where It Goes',
      'Life Partner',
      'Travel Companion',
      'Fun & Experiences',
    ]) {
      expect(find.text(retired), findsNothing);
    }

    final casual = find.byKey(
      const ValueKey('amoraa-select-option-Casual Connection'),
    );
    await tester.ensureVisible(casual);
    await tester.tap(casual);
    await tester.pumpAndSettle();
    expect(selected, 'Casual Connection');
  });

  test('intentions stay separate from existing lifestyle interests', () {
    final interests = ProfileFormOptions.interestGroups.values
        .expand((values) => values)
        .toSet();
    expect(
      interests.intersection(ProfileFormOptions.datingIntentions.toSet()),
      isEmpty,
    );
    expect(
      interests.intersection(const {
        'Fitness Partner',
        'Event Buddy',
        'Foodie Partner',
        'Adventure Seeker',
        'Road Trip Buddy',
        'Travel & Explore',
      }),
      isEmpty,
    );
  });

  testWidgets('story images safely preserve portrait square and landscape', (
    tester,
  ) async {
    await pump(
      tester,
      const SingleChildScrollView(
        child: Column(
          children: [
            AmoraaProfileStoryImage(
              image: '',
              semanticLabel: 'Portrait photo',
              aspectRatio: .6,
            ),
            AmoraaProfileStoryImage(
              image: '',
              semanticLabel: 'Square photo',
              aspectRatio: 1,
            ),
            AmoraaProfileStoryImage(
              image: '',
              semanticLabel: 'Landscape photo',
              aspectRatio: 2,
            ),
          ],
        ),
      ),
      size: const Size(390, 1500),
    );

    final ratios = tester
        .widgetList<AmoraaAdaptiveImage>(find.byType(AmoraaAdaptiveImage))
        .map(
          (widget) => (widget.originalAspectRatio ?? 4 / 5).clamp(
            AmoraaProfileStoryImage.minimumAspectRatio,
            AmoraaProfileStoryImage.maximumAspectRatio,
          ),
        )
        .toList(growable: false);
    expect(ratios, [
      AmoraaProfileStoryImage.minimumAspectRatio,
      1,
      AmoraaProfileStoryImage.maximumAspectRatio,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile story uses adaptive images and readable languages', (
    tester,
  ) async {
    await repository.resetForTesting(
      originalProfile.copyWith(
        lifestyle: {
          ...originalProfile.lifestyle,
          'Languages': 'English, Hindi & Gujarati',
        },
      ),
    );
    await pump(
      tester,
      const ProfileScreen(showNavigation: false),
      size: const Size(430, 5000),
    );

    expect(find.byType(ProfilePhotoGallery), findsOneWidget);
    expect(find.text('English • Hindi • Gujarati'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile and Preview display custom occupation text', (
    tester,
  ) async {
    await repository.resetForTesting(
      originalProfile.copyWith(profession: 'Photographer'),
    );
    await pump(
      tester,
      const ProfileScreen(showNavigation: false),
      size: const Size(430, 5000),
    );
    expect(find.text('Photographer'), findsOneWidget);

    await pump(
      tester,
      const ProfilePreviewScreen(),
      size: const Size(430, 5000),
    );
    expect(find.text('Photographer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('approved dating intentions and descriptions are exact', () {
    expect(ProfileFormOptions.datingIntentions, const [
      'Marriage Minded',
      'Long-Term Relationship',
      'Meaningful Dating',
      'Exploring Possibilities',
      'Friendship First',
      'Casual Connection',
    ]);
    expect(ProfileFormOptions.datingIntentionDescriptions, hasLength(6));
    expect(ProfileFormOptions.datingIntentionDescriptions, const {
      'Marriage Minded':
          'Focused on marriage and building a committed future together.',
      'Long-Term Relationship':
          'Looking for a serious relationship with long-term potential.',
      'Meaningful Dating':
          'Open to dating and building a genuine emotional connection.',
      'Exploring Possibilities':
          'Open-minded and seeing where a meaningful connection can lead.',
      'Friendship First':
          'Prefer to build trust and friendship before moving forward.',
      'Casual Connection':
          'Interested in exciting activities, events, and memorable experiences.',
    });
    expect(
      ProfileFormOptions.normalizeDatingIntention('Marriage'),
      'Marriage Minded',
    );
    expect(
      ProfileFormOptions.normalizeDatingIntention('Casual'),
      'Casual Connection',
    );
  });
}
