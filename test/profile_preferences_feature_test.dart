import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_preference_display.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_preference_selectors.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final repository = LocalProfileRepository.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await repository.resetForTesting(_fixture());
    appliedProfilePreferenceFilters.value =
        const ProfilePreferenceFilterState();
  });

  tearDown(() async {
    await repository.resetForTesting();
    appliedProfilePreferenceFilters.value =
        const ProfilePreferenceFilterState();
  });

  test('all six approved option sources are exact and centralized', () {
    expect(ProfileFormOptions.hometowns, [
      'Gandhinagar',
      'Ahmedabad',
      'Surat',
      'Vadodara',
    ]);
    expect(ProfileFormOptions.qualities, [
      'Ambition',
      'Confidence',
      'Empathy',
      'Generosity',
      'Humour',
      'Kindness',
      'Openness',
      'Optimism',
      'Playfulness',
      'Sassiness',
      'Leadership',
      'Curiosity',
      'Gratitude',
      'Humility',
      'Loyalty',
      'Sarcasm',
      'Emotional Intelligence',
    ]);
    expect(ProfileFormOptions.pronouns, [
      'she',
      'her',
      'hers',
      'he',
      'him',
      'his',
      'they',
      'them',
      'theirs',
    ]);
    expect(ProfileFormOptions.sexualities, [
      'Straight',
      'Gay',
      'Lesbian',
      'Bisexual',
      'Allosexual',
      'Androsexual',
      'Asexual',
      'Autosexual',
      'Bicurious',
      'Demisexual',
    ]);
    expect(ProfileFormOptions.preferredTalkingHours, [
      'Early Morning',
      'Morning',
      'Afternoon',
      'Evening',
      'Late Night',
      'Flexible',
    ]);
    expect(ProfileFormOptions.loveLanguages, [
      'Words of Affirmation',
      'Quality Time',
      'Acts of Service',
      'Receiving Gifts',
      'Physical Touch',
    ]);
    expect(
      ProfileFormOptions.preferenceOptions.keys,
      ProfilePreferenceType.values,
    );
    expect(
      ProfileFormOptions.hometowns,
      isNot(containsAll(<String>['Mumbai', 'Pune', 'New Delhi', 'Bengaluru'])),
    );
  });

  test('profile preference values serialize, normalize, and preload', () {
    final encoded = _fixture().toJson();
    final restored = UserProfile.fromJson(encoded);
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);

    expect(restored.hometown, 'Ahmedabad');
    expect(restored.valuedQualities, ['Empathy', 'Loyalty']);
    expect(restored.pronouns, ['she', 'her']);
    expect(restored.sexuality, 'Bisexual');
    expect(restored.preferredTalkingHours, ['Evening', 'Late Night']);
    expect(restored.loveLanguages, ['Quality Time', 'Physical Touch']);
    expect(controller.hometown, 'Ahmedabad');
    expect(controller.valuedQualities, {'Empathy', 'Loyalty'});
    expect(controller.pronouns, {'she', 'her'});
    expect(controller.sexuality, 'Bisexual');
  });

  test('controller keeps edit limits without silently replacing values', () {
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);

    controller.setValuedQualities({
      'Ambition',
      'Confidence',
      'Empathy',
      'Loyalty',
    });
    controller.setPronouns({'she', 'her', 'hers', 'they', 'them'});

    expect(controller.valuedQualities, {'Ambition', 'Confidence', 'Empathy'});
    expect(controller.pronouns, {'she', 'her', 'hers', 'they'});
  });

  testWidgets('profile editors enforce limits and single-select behavior', (
    tester,
  ) async {
    await repository.resetForTesting(
      _fixture().copyWith(
        hometown: '',
        valuedQualities: const ['Ambition', 'Confidence', 'Empathy'],
        pronouns: const [],
        sexuality: '',
        preferredTalkingHours: const [],
        loveLanguages: const [],
      ),
    );
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AmoraaPersonalPreferencesEditor(controller: controller),
                AmoraaConnectionPreferencesEditor(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('profile-hometown-selector')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('amoraa-select-search')),
      'sur',
    );
    await tester.pump();
    expect(find.text('Surat'), findsWidgets);
    expect(find.text('Mumbai'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('amoraa-select-option-Surat')));
    await tester.pumpAndSettle();
    expect(controller.hometown, 'Surat');

    await tester.tap(find.byKey(const ValueKey('profile-sexuality-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('amoraa-select-option-Gay')));
    await tester.pumpAndSettle();
    expect(controller.sexuality, 'Gay');

    final fourthQuality = find.byKey(
      const ValueKey('quality-option-Generosity'),
    );
    await tester.ensureVisible(fourthQuality);
    await tester.pumpAndSettle();
    await tester.tap(fourthQuality.hitTestable());
    await tester.pump();
    expect(controller.valuedQualities.length, 3);
    expect(controller.valuedQualities, isNot(contains('Generosity')));
    expect(find.text('You can select up to 3 qualities.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('profile-pronouns-selector')),
    );
    await tester.tap(find.byKey(const ValueKey('profile-pronouns-selector')));
    await tester.pumpAndSettle();
    for (final pronoun in const ['she', 'her', 'hers', 'they', 'them']) {
      final option = find.byKey(ValueKey('pronoun-option-$pronoun'));
      await tester.ensureVisible(option);
      await tester.pump();
      await tester.tap(option.hitTestable());
      await tester.pump();
    }
    expect(find.text('You can select up to 4 pronouns.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pronoun-selector-done')));
    await tester.pumpAndSettle();
    expect(controller.pronouns.length, 4);
    expect(controller.pronouns, isNot(contains('them')));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all six filter controls are multi-select and reset/apply state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: const AdvancedFiltersScreen(),
          routes: {'/browse': (_) => const Scaffold(body: Text('Browse'))},
        ),
      );
      await tester.pumpAndSettle();

      await _selectOptions(
        tester,
        const ValueKey('filters-hometown-selector'),
        const ['Surat', 'Vadodara'],
        searchEach: true,
      );
      expect(
        tester
            .widget<AmoraaSearchableSelect<String>>(
              find.byKey(const ValueKey('filters-hometown-selector')),
            )
            .selectionMode,
        AmoraaSelectionMode.multiple,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('filters-section-toggle-identity')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(const ValueKey('filters-section-toggle-identity'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      await _selectOptions(
        tester,
        const ValueKey('filters-pronouns-selector'),
        const ['she', 'her'],
      );
      await _selectOptions(
        tester,
        const ValueKey('filters-sexuality-selector'),
        const ['Gay', 'Bisexual'],
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('filters-section-toggle-compatibility')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .byKey(const ValueKey('filters-section-toggle-compatibility'))
            .hitTestable(),
      );
      await tester.pumpAndSettle();
      await _selectOptions(
        tester,
        const ValueKey('filters-qualities-selector'),
        const ['Ambition', 'Confidence', 'Empathy', 'Generosity'],
        searchEach: true,
      );
      await _selectOptions(
        tester,
        const ValueKey('filters-talking-hours-selector'),
        const ['Early Morning', 'Morning'],
      );
      await _selectOptions(
        tester,
        const ValueKey('filters-love-languages-selector'),
        const ['Quality Time', 'Words of Affirmation'],
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('filters-apply-button')),
      );
      await tester.tap(find.byKey(const ValueKey('filters-apply-button')));
      await tester.pumpAndSettle();
      final applied = appliedProfilePreferenceFilters.value;
      expect(applied.hometowns, {'Surat', 'Vadodara'});
      expect(applied.qualities.length, 4);
      expect(applied.pronouns, {'she', 'her'});
      expect(applied.sexualities, {'Gay', 'Bisexual'});
      expect(applied.preferredTalkingHours, {'Early Morning', 'Morning'});
      expect(applied.loveLanguages, {'Words of Affirmation', 'Quality Time'});

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: AmoraTheme.light(),
          home: const AdvancedFiltersScreen(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filters-bottom-reset')));
      await tester.pump();
      expect(appliedProfilePreferenceFilters.value.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Preview and Detail use the same compact public display', (
    tester,
  ) async {
    final current = AmoraaPublicProfileData.fromProfile(
      repository.profile,
      const [],
    ).toPublicDisplayProfile();
    final viewed = ImageRepository.profileAt(4);

    for (final profile in [current, viewed]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: AmoraaProfilePreferenceDisplay(profile: profile),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('public-profile-preferences')),
        findsOneWidget,
      );
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('Connection Style'), findsOneWidget);
      expect(find.text('Pronouns'), findsOneWidget);
      expect(find.text('Love Languages'), findsOneWidget);
      expect(find.textContaining('['), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('empty preference values create no public card at 320 px', (
    tester,
  ) async {
    final empty = AmoraaPublicProfileData.fromProfile(
      _fixture().copyWith(
        hometown: '',
        valuedQualities: const [],
        pronouns: const [],
        sexuality: '',
        preferredTalkingHours: const [],
        loveLanguages: const [],
      ),
      const [],
    ).toPublicDisplayProfile();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(body: AmoraaProfilePreferenceDisplay(profile: empty)),
      ),
    );
    expect(
      find.byKey(const ValueKey('public-profile-preferences')),
      findsNothing,
    );
    expect(find.text('null'), findsNothing);
    expect(find.text('[]'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _selectOptions(
  WidgetTester tester,
  Key selectorKey,
  List<String> options, {
  bool searchEach = false,
}) async {
  final selector = find.byKey(selectorKey);
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  await tester.tap(selector.hitTestable());
  await tester.pumpAndSettle();
  for (final option in options) {
    if (searchEach) {
      await tester.enterText(
        find.byKey(const ValueKey('amoraa-select-search')),
        option,
      );
      await tester.pump();
    }
    final optionFinder = find.byKey(ValueKey('amoraa-select-option-$option'));
    expect(optionFinder, findsOneWidget);
    tester.widget<AmoraaSelectOptionTile<String>>(optionFinder).onTap();
    await tester.pump();
  }
  await tester.tap(find.byKey(const ValueKey('amoraa-select-done')));
  await tester.pumpAndSettle();
}

UserProfile _fixture() => const UserProfile(
  name: 'Aarohi Shah',
  email: 'aarohi@example.com',
  phoneNumber: '+91 90000 00000',
  birthdate: '14/02/1998',
  gender: 'Woman',
  bio: 'Coffee, books and thoughtful conversations.',
  profession: 'Designer',
  company: 'Studio',
  education: 'Postgraduate',
  location: 'Surat',
  datingIntention: 'Long-Term Relationship',
  interests: ['Coffee'],
  prompts: {'Together we could...': 'Explore Gujarat.'},
  lifestyle: {'Exercise': 'Daily'},
  photos: [],
  primaryPhotoIndex: 0,
  voicePrompt: null,
  videoPrompt: null,
  hometown: 'Ahmedabad',
  valuedQualities: ['Empathy', 'Loyalty'],
  pronouns: ['she', 'her'],
  sexuality: 'Bisexual',
  preferredTalkingHours: ['Evening', 'Late Night'],
  loveLanguages: ['Quality Time', 'Physical Touch'],
);
