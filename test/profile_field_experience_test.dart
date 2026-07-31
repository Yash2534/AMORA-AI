import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_section_editor_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_dating_intention_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_language_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_fields.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_prompt_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_story_image.dart';
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
      'English, Hindi & Gujarati',
    );
  });

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
      'English, Hindi & Gujarati',
    );

    final reloaded = ProfileFormController(repository: repository);
    addTearDown(reloaded.dispose);
    expect(reloaded.languages, {'English', 'Hindi', 'Gujarati'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile prompt uses selectable cards and loads saved value', (
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

    await tester.tap(
      find.byKey(const ValueKey('profile-prompt-card-selector')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('prompt-option-A green flag I value is...')),
    );
    await tester.pumpAndSettle();
    expect(controller.promptTitle, 'A green flag I value is...');
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
      final option = find.byKey(ValueKey('dating-intention-$intention'));
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
      'Casual Connection',
    ]) {
      expect(find.text(retired), findsNothing);
    }

    final travel = find.byKey(
      const ValueKey('dating-intention-Travel Companion'),
    );
    await tester.ensureVisible(travel);
    await tester.tap(travel);
    await tester.pumpAndSettle();
    expect(selected, 'Travel Companion');
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
        .widgetList<AspectRatio>(find.byType(AspectRatio))
        .map((widget) => widget.aspectRatio)
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

    expect(
      find.byType(AmoraaProfileStoryImage),
      findsNWidgets(repository.profile.photos.length - 1),
    );
    expect(find.text('English · Hindi · Gujarati'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('approved dating intentions and descriptions are exact', () {
    expect(ProfileFormOptions.datingIntentions, const [
      'Marriage Minded',
      'Long-Term Relationship',
      'Meaningful Dating',
      'Exploring Possibilities',
      'Friendship First',
      'Travel Companion',
      'Fun & Experiences',
    ]);
    expect(ProfileFormOptions.datingIntentionDescriptions, hasLength(7));
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
      'Travel Companion':
          'Looking for someone to explore new places and shared experiences with.',
      'Fun & Experiences':
          'Interested in exciting activities, events, and memorable experiences.',
    });
    expect(
      ProfileFormOptions.normalizeDatingIntention('Marriage'),
      'Marriage Minded',
    );
    expect(
      ProfileFormOptions.normalizeDatingIntention('Travel Partner'),
      'Travel Companion',
    );
  });
}
