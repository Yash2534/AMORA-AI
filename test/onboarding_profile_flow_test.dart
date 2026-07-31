import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/data/gujarat_cities.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
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
    await tester.tap(find.text('Non-binary'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 6'), findsOneWidget);
    await tester.ensureVisible(find.text('Everyone'));
    await tester.tap(find.text('Everyone'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 6'), findsOneWidget);
    await tester.tap(find.text('Long-term relationship'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 5 of 6'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('onboarding-city')));
    await tester.tap(find.byKey(const Key('onboarding-city')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gujarat-city-search')),
      'Ahmed',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gujarat-city-Ahmedabad')));
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
      interests: const ['Coffee', 'Travel', 'Music', 'Design', 'Nature'],
    );
    expect(complete.completionPercent, 100);
  });

  testWidgets('profile completion never blocks returning to Discover', (
    tester,
  ) async {
    profiles.startNewProfile('New Member');
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileCompletionScreen(),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('start-discovering-button')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('start-discovering-button')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Return to Discover'), findsOneWidget);
  });

  test('Gujarat city catalogue is unique and alphabetically sorted', () {
    final sorted = [...gujaratCities]..sort();
    expect(gujaratCities, orderedEquals(sorted));
    expect(gujaratCities.toSet(), hasLength(gujaratCities.length));
    expect(
      gujaratCities,
      containsAll(const ['Ahmedabad', 'Surat', 'Vadodara', 'Bilimora']),
    );
  });
}
