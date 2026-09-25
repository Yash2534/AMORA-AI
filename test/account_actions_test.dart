import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/welcome_back_reactivation_screen.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/settings/presentation/account_action_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profiles = LocalProfileRepository.instance;
  final onboarding = LocalOnboardingRepository.instance;
  final chats = LocalChatRepository.instance;
  late UserProfile originalProfile;

  setUp(() async {
    originalProfile = profiles.profile;
    AmoraSession.logIn();
    await chats.resetForTesting();
  });

  tearDown(() async {
    AmoraSession.logOut();
    await profiles.resetForTesting(originalProfile);
    onboarding.resetForTesting();
    await chats.resetForTesting();
  });

  Future<void> pumpAction(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          LoginScreen.routeName: (_) => const Scaffold(body: Text('Login')),
        },
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> confirmDeletionIntent(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const ValueKey('settings-delete-permanently')),
    );
    expect(
      find.text('Are you sure you want to permanently delete your account?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('delete-confirmation-continue')),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reachOtp(
    WidgetTester tester, {
    required Future<void> Function(String) sendOtp,
    Future<void> Function(String, String)? confirmDeletion,
  }) async {
    await pumpAction(
      tester,
      DeleteAccountInformationScreen(
        loadMethods: () async => const [
          AccountDeletionMethod(
            channel: 'EMAIL',
            maskedDestination: 'y***@example.com',
          ),
        ],
        sendOtp: sendOtp,
        confirmDeletion: confirmDeletion,
        resendCooldown: Duration.zero,
      ),
    );
    await confirmDeletionIntent(tester);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-send-otp')),
    );
    expect(
      find.byKey(const ValueKey('delete-account-otp-step')),
      findsOneWidget,
    );
  }

  testWidgets('deactivation requires confirmation and Cancel changes nothing', (
    tester,
  ) async {
    var calls = 0;
    await pumpAction(
      tester,
      DeactivateAccountScreen(
        onDeactivate: (_) async {
          calls += 1;
          return true;
        },
      ),
    );
    expect(find.text('Deactivate your account?'), findsOneWidget);
    expect(find.textContaining('hidden'), findsWidgets);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-deactivate-account')),
    );
    expect(
      find.text('Are you sure you want to deactivate your account?'),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('deactivate-confirmation-cancel')),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(AmoraSession.isLoggedIn.value, isTrue);
  });

  testWidgets('Continue requires password and wrong password is controlled', (
    tester,
  ) async {
    await pumpAction(
      tester,
      DeactivateAccountScreen(
        onDeactivate: (_) async => throw const AuthException(
          'internal detail',
          code: 'CURRENT_PASSWORD_INCORRECT',
          statusCode: 401,
        ),
      ),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-deactivate-account')),
    );
    await tester.tap(
      find.byKey(const ValueKey('deactivate-confirmation-continue')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirm your password'), findsOneWidget);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-deactivate-account')),
    );
    expect(find.text('Password is required.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('deactivate-password-field')),
      'WrongPass1!',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-deactivate-account')),
    );
    expect(find.text('Incorrect password. Please try again.'), findsOneWidget);
    expect(AmoraSession.isLoggedIn.value, isTrue);
  });

  testWidgets('successful password deactivation signs out', (tester) async {
    String? submittedPassword;
    await pumpAction(
      tester,
      DeactivateAccountScreen(
        onDeactivate: (password) async {
          submittedPassword = password;
          return true;
        },
      ),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-deactivate-account')),
    );
    await tester.tap(
      find.byKey(const ValueKey('deactivate-confirmation-continue')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('deactivate-password-field')),
      'LifecyclePass1!',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('confirm-deactivate-account')),
    );
    expect(submittedPassword, 'LifecyclePass1!');
    expect(AmoraSession.isLoggedIn.value, isFalse);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Welcome Back activates explicitly without onboarding UI', (
    tester,
  ) async {
    var calls = 0;
    var completed = 0;
    await pumpAction(
      tester,
      WelcomeBackReactivationScreen(
        reactivationToken: 'challenge-token',
        reactivate: (token) async {
          expect(token, 'challenge-token');
          calls += 1;
        },
        onReactivated: (_) async {
          completed += 1;
        },
      ),
    );
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Activate Your Account'), findsOneWidget);
    expect(find.textContaining('6-step'), findsNothing);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('activate-account-button')),
    );
    expect(calls, 1);
    expect(completed, 1);
  });

  testWidgets('deactivated login routes to Welcome Back, not onboarding', (
    tester,
  ) async {
    AmoraSession.logOut();
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          WelcomeBackReactivationScreen.routeName: (_) =>
              const WelcomeBackReactivationScreen(),
        },
        home: LoginScreen(
          login: (_, _) async => throw const AuthException(
            'This account is deactivated.',
            code: 'ACCOUNT_DEACTIVATED',
            statusCode: 403,
            data: {'reactivationToken': 'challenge-token'},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('login-email-field')),
        matching: find.byType(TextField),
      ),
      'returning@example.com',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('login-password-field')),
        matching: find.byType(TextField),
      ),
      'LifecyclePass1!',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Activate Your Account'), findsOneWidget);
    expect(find.byType(ProfileOnboardingFlow), findsNothing);
  });

  testWidgets('failed activation does not fake an authenticated session', (
    tester,
  ) async {
    AmoraSession.logOut();
    await pumpAction(
      tester,
      WelcomeBackReactivationScreen(
        reactivationToken: 'challenge-token',
        reactivate: (_) async => throw const AuthException(
          'Activation service unavailable.',
          code: 'NETWORK_ERROR',
        ),
      ),
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('activate-account-button')),
    );
    expect(find.text('Activation service unavailable.'), findsOneWidget);
    expect(AmoraSession.isLoggedIn.value, isFalse);
  });

  testWidgets('permanent warning renders and old request state is absent', (
    tester,
  ) async {
    await pumpAction(tester, const DeleteAccountInformationScreen());
    expect(find.text('Permanent account deletion'), findsOneWidget);
    expect(find.text('This action is permanent'), findsOneWidget);
    expect(find.text('Deletion request received'), findsNothing);
    expect(find.textContaining('additional review'), findsNothing);
  });

  testWidgets('explicit confirmation is required before methods load', (
    tester,
  ) async {
    var loads = 0;
    await pumpAction(
      tester,
      DeleteAccountInformationScreen(
        loadMethods: () async {
          loads += 1;
          return const [];
        },
      ),
    );
    expect(loads, 0);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('settings-delete-permanently')),
    );
    await tester.tap(find.byKey(const ValueKey('delete-confirmation-cancel')));
    await tester.pumpAndSettle();
    expect(loads, 0);
    await confirmDeletionIntent(tester);
    expect(loads, 1);
  });

  testWidgets('available email and phone methods render only masked values', (
    tester,
  ) async {
    await pumpAction(
      tester,
      DeleteAccountInformationScreen(
        loadMethods: () async => const [
          AccountDeletionMethod(
            channel: 'EMAIL',
            maskedDestination: 'y***@example.com',
          ),
          AccountDeletionMethod(
            channel: 'PHONE',
            maskedDestination: '+91 ******1234',
          ),
        ],
      ),
    );
    await confirmDeletionIntent(tester);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('y***@example.com'), findsOneWidget);
    expect(find.text('+91 ******1234'), findsOneWidget);
    expect(find.textContaining('yash'), findsNothing);
  });

  testWidgets('Send OTP uses the selected channel and shows OTP entry', (
    tester,
  ) async {
    String? sentChannel;
    await reachOtp(tester, sendOtp: (channel) async => sentChannel = channel);
    expect(sentChannel, 'EMAIL');
    expect(
      find.byKey(const ValueKey('delete-account-otp-input')),
      findsOneWidget,
    );
  });

  testWidgets('invalid and expired OTP errors use canonical copy', (
    tester,
  ) async {
    var code = 'OTP_INVALID';
    await reachOtp(
      tester,
      sendOtp: (_) async {},
      confirmDeletion: (_, _) async =>
          throw AuthException('provider detail', code: code, statusCode: 400),
    );
    await tester.enterText(
      find.byKey(const ValueKey('otp-native-input')),
      '123456',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-verify-delete')),
    );
    expect(find.text('Invalid verification code.'), findsOneWidget);

    code = 'OTP_EXPIRED';
    await tester.enterText(
      find.byKey(const ValueKey('otp-native-input')),
      '654321',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-verify-delete')),
    );
    expect(
      find.text(
        'This verification code has expired. Please request a new code.',
      ),
      findsOneWidget,
    );
    expect(AmoraSession.isLoggedIn.value, isTrue);
  });

  testWidgets('resend calls the same registered channel', (tester) async {
    final channels = <String>[];
    await reachOtp(tester, sendOtp: (channel) async => channels.add(channel));
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-resend-otp')),
    );
    expect(channels, ['EMAIL', 'EMAIL']);
  });

  testWidgets('backend failure never fakes deletion success', (tester) async {
    await reachOtp(
      tester,
      sendOtp: (_) async {},
      confirmDeletion: (_, _) async => throw const AuthException(
        'Service unavailable.',
        code: 'NETWORK_ERROR',
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('otp-native-input')),
      '123456',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-verify-delete')),
    );
    expect(AmoraSession.isLoggedIn.value, isTrue);
    expect(find.text('Login'), findsNothing);
    expect(find.text('Service unavailable.'), findsOneWidget);
  });

  testWidgets('confirmed backend deletion clears state and signs out', (
    tester,
  ) async {
    var confirmations = 0;
    await reachOtp(
      tester,
      sendOtp: (_) async {},
      confirmDeletion: (_, otp) async {
        expect(otp, '123456');
        confirmations += 1;
      },
    );
    await tester.enterText(
      find.byKey(const ValueKey('otp-native-input')),
      '123456',
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-account-verify-delete')),
    );
    expect(confirmations, 1);
    expect(AmoraSession.isLoggedIn.value, isFalse);
    expect(profiles.profile.name, isEmpty);
    expect(chats.conversations, isEmpty);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('duplicate verification submissions are blocked', (tester) async {
    final completer = Completer<void>();
    var calls = 0;
    await reachOtp(
      tester,
      sendOtp: (_) async {},
      confirmDeletion: (_, _) {
        calls += 1;
        return completer.future;
      },
    );
    await tester.enterText(
      find.byKey(const ValueKey('otp-native-input')),
      '123456',
    );
    final submit = find.byKey(const ValueKey('delete-account-verify-delete'));
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
    expect(calls, 1);
    completer.completeError(
      const AuthException('Service unavailable.', code: 'NETWORK_ERROR'),
    );
    await tester.pumpAndSettle();
  });
}
