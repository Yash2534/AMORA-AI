import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final onboarding = LocalOnboardingRepository.instance;
  final profiles = LocalProfileRepository.instance;
  late LocalProfileDraft originalProfile;

  setUp(() {
    originalProfile = profiles.profile;
    onboarding.resetForTesting();
  });

  tearDown(() {
    AmoraSession.logOut();
    onboarding.resetForTesting();
    profiles.save(originalProfile);
  });

  testWidgets('successful sign in resumes an incomplete saved question', (
    tester,
  ) async {
    onboarding.resetForTesting(
      const LocalOnboardingState(stage: OnboardingStage.interestedIn),
    );
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          ProfileOnboardingFlow.routeName: (_) =>
              const Scaffold(body: Text('Saved question opened')),
          MainShell.routeName: (_) =>
              const Scaffold(body: Text('Discover opened')),
        },
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AmoraSession.completeAuthentication(context),
            child: const Text('Complete sign in'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Complete sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Saved question opened'), findsOneWidget);
  });

  testWidgets('completed onboarding routes returning users to Discover', (
    tester,
  ) async {
    onboarding.resetForTesting(
      const LocalOnboardingState(
        stage: OnboardingStage.complete,
        onboardingCompleted: true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          ProfileOnboardingFlow.routeName: (_) =>
              const Scaffold(body: Text('Saved question opened')),
          MainShell.routeName: (_) =>
              const Scaffold(body: Text('Discover opened')),
        },
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => AmoraSession.completeAuthentication(context),
            child: const Text('Complete sign in'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Complete sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Discover opened'), findsOneWidget);
    expect(find.text('Saved question opened'), findsNothing);
  });

  testWidgets('authentication entry is the email Login screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const LoginScreen()),
    );
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.text('Explore AMORAA AI'), findsNothing);
  });

  testWidgets('quick onboarding includes birth date and opens Discover', (
    tester,
  ) async {
    profiles.startNewProfile('New Member');
    profiles.updatePhotos(originalProfile.photos.take(2).toList(), 0);
    onboarding.resetForTesting(
      LocalOnboardingState(
        stage: OnboardingStage.age,
        birthDate: DateTime(DateTime.now().year - 25, 1, 15),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          MainShell.routeName: (_) =>
              const Scaffold(body: Text('Discover reached')),
        },
        home: const ProfileOnboardingFlow(),
      ),
    );

    expect(find.text('Step 1 of 6'), findsOneWidget);
    expect(find.text("When's your birthday?"), findsOneWidget);
    expect(find.byKey(const Key('birthdate-day-wheel')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(onboarding.state.birthDate, isNotNull);
    expect(find.textContaining('Age:'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(find.text('How do you identify?'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('onboarding-gender-option-Other')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('onboarding-gender-option-Other')),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-custom-gender')),
      'Non-binary',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 6'), findsOneWidget);
    await tester.ensureVisible(find.text('Female'));
    await tester.tap(find.text('Female'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 6'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('onboarding-relationship-option-Long-Term Relationship'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('onboarding-relationship-option-Long-Term Relationship'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 5 of 6'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('onboarding-city')));
    await tester.tap(find.byKey(const Key('onboarding-city')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('amoraa-select-search')),
      'Ahmed',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('amoraa-select-option-Ahmedabad')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('onboarding-continue')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 6 of 6'), findsOneWidget);
    expect(find.text('2 of 6 photos added'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Discover reached'), findsOneWidget);
    expect(onboarding.state.onboardingCompleted, isTrue);
    expect(profiles.profile.gender, 'Non-binary');
    expect(profiles.profile.location, 'Ahmedabad');
    expect(profiles.profile.datingIntention, 'Long-Term Relationship');
  });

  testWidgets('birth date question shows inline minimum-age validation', (
    tester,
  ) async {
    final today = DateTime.now();
    onboarding.resetForTesting(
      LocalOnboardingState(
        stage: OnboardingStage.age,
        birthDate: DateTime(today.year - 17, today.month, today.day),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );
    await tester.pump();

    expect(find.text('Age: 17 years'), findsOneWidget);
    expect(find.text('You must be at least 18 years old.'), findsOneWidget);
    final continueButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('onboarding-continue')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton.onPressed, isNull);
  });

  testWidgets('gender step uses exclusive full-width radio cards', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    onboarding.resetForTesting(
      LocalOnboardingState(
        stage: OnboardingStage.gender,
        birthDate: DateTime(DateTime.now().year - 25, 1, 15),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 6'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-gender-selector')),
      findsNothing,
    );
    final cards = find.byKey(const ValueKey('onboarding-gender-cards'));
    expect(cards, findsOneWidget);
    for (final option in const ['Male', 'Female', 'Other']) {
      expect(
        find.descendant(of: cards, matching: find.text(option)),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('$option, unselected'), findsOneWidget);
    }
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('onboarding-continue')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('onboarding-gender-option-Male')),
    );
    await tester.pumpAndSettle();
    expect(onboarding.state.gender, 'Male');
    expect(find.bySemanticsLabel('Male, selected'), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-radio')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('onboarding-gender-option-Female')),
    );
    await tester.pumpAndSettle();
    expect(onboarding.state.gender, 'Female');
    expect(find.bySemanticsLabel('Male, unselected'), findsOneWidget);
    expect(find.bySemanticsLabel('Female, selected'), findsOneWidget);
    expect(find.byKey(const ValueKey('selected-radio')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('onboarding-continue')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );

    final femaleCard = find.byKey(
      const ValueKey('onboarding-gender-option-Female'),
    );
    final cardSize = tester.getSize(femaleCard);
    expect(cardSize.width, tester.getSize(cards).width);
    expect(cardSize.height, greaterThanOrEqualTo(48));
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: femaleCard, matching: find.byType(InkWell)),
          )
          .focusColor,
      isNotNull,
    );
    semantics.dispose();
  });

  testWidgets('saved gender value preselects its existing frontend option', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    onboarding.resetForTesting(
      LocalOnboardingState(
        stage: OnboardingStage.gender,
        birthDate: DateTime(DateTime.now().year - 25, 1, 15),
        gender: 'Woman',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Female, selected'), findsOneWidget);
    expect(find.bySemanticsLabel('Male, unselected'), findsOneWidget);
    expect(find.bySemanticsLabel('Other, unselected'), findsOneWidget);
    expect(onboarding.state.gender, 'Woman');
    semantics.dispose();
  });

  testWidgets('gender cards remain overflow-free at supported widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    onboarding.resetForTesting(
      LocalOnboardingState(
        stage: OnboardingStage.gender,
        birthDate: DateTime(DateTime.now().year - 25, 1, 15),
      ),
    );

    for (final width in const [
      320.0,
      360.0,
      390.0,
      412.0,
      430.0,
      600.0,
      768.0,
    ]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.6)),
            child: child!,
          ),
          home: const ProfileOnboardingFlow(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Gender cards overflowed at ${width.toInt()} px',
      );
      for (final option in const ['Male', 'Female', 'Other']) {
        expect(
          find.byKey(ValueKey('onboarding-gender-option-$option')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('onboarding-continue')), findsOneWidget);
    }
  });

  test('gender card values retain the existing stored mapping', () {
    expect(ProfileFormOptions.storedGenderValue('Male'), 'Man');
    expect(ProfileFormOptions.storedGenderValue('Female'), 'Woman');
    expect(
      ProfileFormOptions.storedGenderValue('Other', customValue: 'Non-binary'),
      'Non-binary',
    );
  });

  testWidgets('dating intentions support independent toggles per option', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    onboarding.resetForTesting(
      const LocalOnboardingState(stage: OnboardingStage.relationshipGoal),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('What are you looking for?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-relationship-selector')),
      findsNothing,
    );
    final cards = find.byKey(const ValueKey('onboarding-relationship-cards'));
    expect(cards, findsOneWidget);
    expect(
      find.descendant(
        of: cards,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'onboarding-relationship-option-',
              ),
        ),
      ),
      findsNWidgets(ProfileFormOptions.datingIntentions.length),
    );
    for (final option in ProfileFormOptions.datingIntentions) {
      expect(
        find.byKey(ValueKey('onboarding-relationship-option-$option')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('$option, unselected'), findsOneWidget);
    }
    expect(find.text('Travel Companion'), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding-relationship-count')),
      findsNothing,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('onboarding-continue')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    Future<void> toggle(String option) async {
      final card = find.byKey(
        ValueKey('onboarding-relationship-option-$option'),
      );
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(card);
      await tester.pumpAndSettle();
    }

    await toggle('Marriage Minded');
    expect(onboarding.state.selectedRelationshipGoals, {'Marriage Minded'});
    expect(find.text('1 selected'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('onboarding-continue')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNotNull,
    );

    await toggle('Meaningful Dating');
    await toggle('Friendship First');
    expect(onboarding.state.selectedRelationshipGoals, {
      'Marriage Minded',
      'Meaningful Dating',
      'Friendship First',
    });
    expect(onboarding.state.relationshipGoals, hasLength(3));
    expect(find.text('3 selected'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('selected-intention-checkmark')),
      findsNWidgets(3),
    );
    expect(profiles.profile.datingIntention, 'Marriage Minded');

    await toggle('Meaningful Dating');
    expect(onboarding.state.selectedRelationshipGoals, {
      'Marriage Minded',
      'Friendship First',
    });
    expect(onboarding.state.relationshipGoals, hasLength(2));
    expect(find.bySemanticsLabel('Marriage Minded, selected'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Meaningful Dating, unselected'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Friendship First, selected'), findsOneWidget);
    expect(find.text('2 selected'), findsOneWidget);

    final marriageCard = find.byKey(
      const ValueKey('onboarding-relationship-option-Marriage Minded'),
    );
    expect(tester.getSize(marriageCard).height, greaterThanOrEqualTo(48));
    expect(
      tester
          .widget<InkWell>(
            find.descendant(of: marriageCard, matching: find.byType(InkWell)),
          )
          .focusColor,
      isNotNull,
    );

    await toggle('Marriage Minded');
    await toggle('Friendship First');
    expect(onboarding.state.selectedRelationshipGoals, isEmpty);
    expect(onboarding.state.relationshipGoals, isEmpty);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('onboarding-continue')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
    semantics.dispose();
  });

  testWidgets('saved dating intentions preload without duplicates', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    onboarding.resetForTesting(
      LocalOnboardingState(
        stage: OnboardingStage.relationshipGoal,
        relationshipGoals: {'Marriage Minded', 'Meaningful Dating'},
        relationshipGoal: 'Marriage Minded',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );
    await tester.pumpAndSettle();

    expect(onboarding.state.selectedRelationshipGoals, {
      'Marriage Minded',
      'Meaningful Dating',
    });
    expect(find.bySemanticsLabel('Marriage Minded, selected'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Meaningful Dating, selected'),
      findsOneWidget,
    );
    expect(find.text('2 selected'), findsOneWidget);

    onboarding.resetForTesting(
      const LocalOnboardingState(
        stage: OnboardingStage.relationshipGoal,
        relationshipGoal: 'Friendship First',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );
    await tester.pumpAndSettle();

    expect(onboarding.state.selectedRelationshipGoals, {'Friendship First'});
    expect(find.bySemanticsLabel('Friendship First, selected'), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('dating intention cards remain responsive at supported widths', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    onboarding.resetForTesting(
      const LocalOnboardingState(
        stage: OnboardingStage.relationshipGoal,
        relationshipGoals: {
          'Marriage Minded',
          'Meaningful Dating',
          'Friendship First',
        },
        relationshipGoal: 'Marriage Minded',
      ),
    );

    for (final width in const [
      320.0,
      360.0,
      390.0,
      412.0,
      430.0,
      600.0,
      768.0,
    ]) {
      tester.view.physicalSize = Size(width, 900);
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const ProfileOnboardingFlow(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Dating Intention cards overflowed at ${width.toInt()} px',
      );
      expect(find.text('3 selected'), findsOneWidget);
      for (final option in ProfileFormOptions.datingIntentions) {
        final card = find.byKey(
          ValueKey('onboarding-relationship-option-$option'),
        );
        expect(card, findsOneWidget);
        expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      }
      expect(find.byKey(const Key('onboarding-continue')), findsOneWidget);
    }
  });

  test('profile contract remains a single primary dating intention', () {
    const state = LocalOnboardingState(
      relationshipGoals: {'Marriage Minded', 'Meaningful Dating'},
      relationshipGoal: 'Marriage Minded',
    );

    onboarding.update(state);
    expect(state.selectedRelationshipGoals, hasLength(2));
    expect(state.primaryRelationshipGoal, 'Marriage Minded');
    expect(profiles.profile.datingIntention, 'Marriage Minded');
  });

  testWidgets('photo step blocks completion until two photos exist', (
    tester,
  ) async {
    profiles.startNewProfile('New Member');
    onboarding.resetForTesting(
      const LocalOnboardingState(stage: OnboardingStage.photos),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );

    expect(find.text('Step 6 of 6'), findsOneWidget);
    expect(find.text('0 of 6 photos added'), findsOneWidget);
    final continueButton = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('onboarding-continue')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(continueButton.onPressed, isNull);
    expect(find.text('Start discovering'), findsOneWidget);
  });

  testWidgets('birthday step hides back action when there is no route to pop', (
    tester,
  ) async {
    onboarding.resetForTesting(
      const LocalOnboardingState(stage: OnboardingStage.age),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );

    expect(find.byTooltip('Go back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('birth date wheels support keyboard selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );

    await tester.tap(find.byKey(const Key('birthdate-year-wheel')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(onboarding.state.birthDate, isNotNull);
    expect(onboarding.state.birthDate!.year, DateTime.now().year - 25);
  });

  testWidgets('saved onboarding step and answers resume', (tester) async {
    onboarding.resetForTesting(
      const LocalOnboardingState(
        stage: OnboardingStage.relationshipGoal,
        gender: 'Woman',
        interestedIn: {'Everyone'},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileOnboardingFlow(),
      ),
    );

    expect(find.text('Step 4 of 6'), findsOneWidget);
    expect(find.text('What are you looking for?'), findsOneWidget);
    expect(onboarding.state.gender, 'Woman');
    expect(onboarding.state.interestedIn, contains('Everyone'));
  });

  test('completion percentage uses transparent weighted sections', () {
    final blank = originalProfile.copyWith(
      name: '',
      photos: const [],
      birthdate: '',
      gender: '',
      profession: '',
      education: '',
      location: '',
      datingIntention: '',
      bio: '',
      interests: const [],
      prompts: const {},
      lifestyle: const {},
    );
    expect(blank.completionPercent, 0);

    final complete = originalProfile.copyWith(
      interests: const [
        'Coffee',
        'Road trips',
        'Live music',
        'Design',
        'Wildlife',
      ],
      lifestyle: {
        ...originalProfile.lifestyle,
        'Height': '5′8″–5′11″',
        'Languages': 'English & Hindi',
        'Religion': 'Hindu',
      },
    );
    expect(complete.completionPercent, 100);
  });

  testWidgets('profile completion uses its dashboard with inline editing', (
    tester,
  ) async {
    profiles.startNewProfile('New Member');
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileCompletionScreen(),
      ),
    );
    expect(find.byType(AmoraaProfileForm), findsNothing);
    expect(find.text('Profile Completion'), findsOneWidget);
    expect(find.text('Recommended Next'), findsOneWidget);
    final basicSection = find.byKey(
      const ValueKey('completion-section-basicDetails'),
    );
    await tester.ensureVisible(basicSection);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: basicSection, matching: find.text('Basic Details')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-name-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('completion-save-basicDetails')),
      findsOneWidget,
    );
    expect(find.textContaining('details remain'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-completion-primary-button')),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('profile-completion-primary-button')),
      findsOneWidget,
    );
  });

  test('onboarding uses the exact shared city catalogue', () {
    expect(ProfileFormOptions.cities, const [
      'Gandhinagar',
      'Ahmedabad',
      'Surat',
      'Vadodara',
    ]);
    expect(
      ProfileFormOptions.cities.toSet(),
      hasLength(ProfileFormOptions.cities.length),
    );
  });
}
