import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/main.dart';
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
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.textContaining('phone'), findsNothing);
    expect(find.text('Preparing your compatibility engine'), findsNothing);
  });

  testWidgets('authenticated launch preserves the existing app destination', (
    tester,
  ) async {
    LocalOnboardingRepository.instance.resetForTesting(
      const LocalOnboardingState(
        accountVerified: true,
        onboardingCompleted: true,
        stage: OnboardingStage.complete,
      ),
    );
    AmoraSession.logIn();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('authenticated unverified launch opens email verification', (
    tester,
  ) async {
    LocalOnboardingRepository.instance.resetForTesting(
      const LocalOnboardingState(stage: OnboardingStage.verification),
    );
    AmoraSession.logIn();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(AccountVerificationScreen), findsOneWidget);
    expect(find.byType(ProfileOnboardingFlow), findsNothing);
    expect(find.byType(MainShell), findsNothing);
  });

  testWidgets('verified incomplete launch opens profile onboarding', (
    tester,
  ) async {
    LocalOnboardingRepository.instance.resetForTesting(
      const LocalOnboardingState(
        accountVerified: true,
        stage: OnboardingStage.age,
      ),
    );
    AmoraSession.logIn();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(ProfileOnboardingFlow), findsOneWidget);
    expect(find.byType(AccountVerificationScreen), findsNothing);
    expect(find.byType(MainShell), findsNothing);
  });
}
