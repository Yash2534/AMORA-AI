import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AmoraSession.logOut();
    LocalOnboardingRepository.instance.resetForTesting();
  });
  tearDown(() {
    AmoraSession.logOut();
    LocalOnboardingRepository.instance.resetForTesting();
  });

  testWidgets('unauthenticated launch opens Login directly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.text('Preparing your compatibility engine'), findsNothing);
  });

  test('authenticated launch preserves the existing app destination', () {
    LocalOnboardingRepository.instance.resetForTesting(
      const LocalOnboardingState(
        accountVerified: true,
        onboardingCompleted: true,
        stage: OnboardingStage.complete,
      ),
    );
    AmoraSession.logIn();

    expect(AmoraSession.authenticatedRecoveryRoute, MainShell.routeName);
  });

  test('authenticated unverified launch opens email verification', () {
    LocalOnboardingRepository.instance.resetForTesting(
      const LocalOnboardingState(stage: OnboardingStage.verification),
    );
    AmoraSession.logIn();

    expect(
      AmoraSession.authenticatedRecoveryRoute,
      AccountVerificationScreen.routeName,
    );
  });

  test('verified incomplete launch opens profile onboarding', () {
    LocalOnboardingRepository.instance.resetForTesting(
      const LocalOnboardingState(
        accountVerified: true,
        stage: OnboardingStage.age,
      ),
    );
    AmoraSession.logIn();

    expect(
      AmoraSession.authenticatedRecoveryRoute,
      ProfileOnboardingFlow.routeName,
    );
  });
}
