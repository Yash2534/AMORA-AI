import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:flutter/material.dart';
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

  testWidgets('authentication entry exposes Sign In and Create Account', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const AmoraAuthScreen()),
    );
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byKey(const Key('auth-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('auth-create-account')), findsOneWidget);
    expect(find.text('Explore AMORA AI'), findsNothing);
  });

  testWidgets('quick onboarding has four questions and opens Discover', (
    tester,
  ) async {
    profiles.startNewProfile('New Member');
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

    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('How do you identify?'), findsOneWidget);
    await tester.tap(find.text('Non-binary'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 4'), findsOneWidget);
    await tester.ensureVisible(find.text('Everyone'));
    await tester.tap(find.text('Everyone'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 4'), findsOneWidget);
    await tester.tap(find.text('Long-term relationship'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Step 4 of 4'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('onboarding-city')));
    await tester.enterText(
      find.byKey(const Key('onboarding-city')),
      'Ahmedabad',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-continue')));
    await tester.pumpAndSettle();

    expect(find.text('Discover reached'), findsOneWidget);
    expect(onboarding.state.onboardingCompleted, isTrue);
    expect(profiles.profile.gender, 'Non-binary');
    expect(profiles.profile.location, 'Ahmedabad');
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

    expect(find.text('Step 3 of 4'), findsOneWidget);
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
}
