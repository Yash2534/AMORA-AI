import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/phone_otp_screen.dart';
import 'package:amora_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app({
    Widget? home,
    Map<String, WidgetBuilder> routes = const {},
    RouteFactory? onGenerateRoute,
  }) {
    return MaterialApp(
      theme: AmoraTheme.light(),
      home: home,
      routes: routes,
      onGenerateRoute: onGenerateRoute,
    );
  }

  Future<void> settleEntrance(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('premium authentication presentation', () {
    testWidgets('auth landing presents the intended hierarchy and assets', (
      tester,
    ) async {
      await tester.pumpWidget(app(home: const AmoraAuthScreen()));
      await settleEntrance(tester);

      expect(find.text('Meaningful connections start here.'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with phone'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  AmoraBrandAssets.googleG,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('official wordmark remains visible at small phone widths', (
      tester,
    ) async {
      for (final width in <double>[320, 360, 390]) {
        await tester.binding.setSurfaceSize(Size(width, 760));
        await tester.pumpWidget(app(home: const LoginScreen()));
        await settleEntrance(tester);
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Image && widget.semanticLabel == 'AMORAA',
          ),
          findsOneWidget,
          reason: 'Official wordmark missing at ${width.toInt()}px',
        );
        expect(tester.takeException(), isNull);
      }
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('every auth route is overflow-free at supported widths', (
      tester,
    ) async {
      const widths = <double>[320, 360, 390, 430, 600, 768, 1024];
      const screens = <Widget>[
        AmoraAuthScreen(),
        LoginScreen(),
        SignupScreen(),
        PhoneOtpScreen(),
        ForgotPasswordScreen(),
        ResetPasswordScreen(),
        AccountVerificationScreen(),
      ];
      for (final width in widths) {
        await tester.binding.setSurfaceSize(
          Size(width, width >= 600 ? 800 : 760),
        );
        for (final screen in screens) {
          await tester.pumpWidget(app(home: screen));
          await settleEntrance(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '$screen overflowed at ${width.toInt()}px',
          );
        }
      }
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('email login validates input and password visibility', (
      tester,
    ) async {
      await tester.pumpWidget(app(home: const LoginScreen()));
      await settleEntrance(tester);

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'legacy',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);

      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('login-password-field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isFalse);
    });

    testWidgets('signup rejects mismatched passwords', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(app(home: const SignupScreen()));
      await settleEntrance(tester);

      await tester.enterText(
        find.byKey(const ValueKey('signup-name-field')),
        'Amora Member',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-email-field')),
        'member@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-phone-field')),
        '9876543210',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-password-field')),
        'password1',
      );
      await tester.enterText(
        find.byKey(const ValueKey('signup-confirm-password-field')),
        'password2',
      );
      await tester.ensureVisible(find.text('I accept the Terms of Service.'));
      await tester.tap(find.text('I accept the Terms of Service.'));
      await tester.ensureVisible(find.text('I accept the Privacy Policy.'));
      await tester.tap(find.text('I accept the Privacy Policy.'));
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('phone entry is numeric and unavailable backend is truthful', (
      tester,
    ) async {
      await tester.pumpWidget(app(home: const PhoneOtpScreen()));
      await settleEntrance(tester);

      await tester.enterText(
        find.byKey(const ValueKey('phone-number-field')),
        'abc9876543210',
      );
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('phone-number-field')),
      );
      expect(field.controller!.text, '9876543210');
      await tester.tap(find.text('Send verification code'));
      await tester.pump();
      expect(
        find.textContaining('not connected to an authentication service'),
        findsOneWidget,
      );
    });

    testWidgets('phone callback opens shared OTP and starts cooldown', (
      tester,
    ) async {
      var requests = 0;
      await tester.pumpWidget(
        app(
          home: PhoneOtpScreen(
            requestOtp: (country, phone) async => requests++,
          ),
        ),
      );
      await settleEntrance(tester);
      await tester.enterText(
        find.byKey(const ValueKey('phone-number-field')),
        '9876543210',
      );
      await tester.tap(find.text('Send verification code'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(requests, 1);
      expect(
        find.byKey(const ValueKey('otp-verification-view')),
        findsOneWidget,
      );
      expect(find.byType(AmoraOtpInput), findsOneWidget);
      expect(find.textContaining('Resend code in 00:'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shared OTP supports paste and backspace-sized updates', (
      tester,
    ) async {
      final controllers = List.generate(6, (_) => TextEditingController());
      final nodes = List.generate(6, (_) => FocusNode());
      addTearDown(() {
        for (final controller in controllers) {
          controller.dispose();
        }
        for (final node in nodes) {
          node.dispose();
        }
      });
      String? pasted;

      await tester.pumpWidget(
        app(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: AmoraOtpInput(
                  controllers: controllers,
                  nodes: nodes,
                  onChanged: () {},
                  onPaste: (value) => pasted = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '123456',
      );
      await tester.pump();
      expect(controllers.map((item) => item.text).join(), '123456');
      expect(pasted, '123456');

      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '12345',
      );
      await tester.pump();
      expect(controllers.map((item) => item.text).join(), '12345');
      expect(tester.takeException(), isNull);
    });

    testWidgets('forgot password uses request and verification callbacks', (
      tester,
    ) async {
      var requested = '';
      var verified = '';
      await tester.pumpWidget(
        app(
          home: ForgotPasswordScreen(
            requestCode: (destination) async => requested = destination,
            verifyCode: (destination, code) async {
              verified = '$destination:$code';
              return 'recovery-token';
            },
          ),
          routes: {
            ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
          },
        ),
      );
      await settleEntrance(tester);
      await tester.enterText(
        find.byKey(const ValueKey('recovery-email-field')),
        'member@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('send-recovery-code')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(requested, 'member@example.com');
      expect(find.byKey(const ValueKey('recovery-code-step')), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '123456',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('verify-recovery-code')),
      );
      await tester.tap(find.byKey(const ValueKey('verify-recovery-code')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(verified, 'member@example.com:123456');
      expect(find.byType(ResetPasswordScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('reset password validates match and executes callback', (
      tester,
    ) async {
      var resetPassword = '';
      await tester.pumpWidget(
        app(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: const RouteSettings(
              arguments: ResetPasswordArgs(
                destination: 'member@example.com',
                recoveryToken: 'token',
              ),
            ),
            builder: (_) => ResetPasswordScreen(
              onReset: (destination, token, password) async {
                resetPassword = password;
              },
            ),
          ),
        ),
      );
      await settleEntrance(tester);

      await tester.enterText(
        find.byKey(const ValueKey('new-password-field')),
        'password1',
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirm-new-password-field')),
        'password2',
      );
      await tester.tap(find.byKey(const ValueKey('reset-password-submit')));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('confirm-new-password-field')),
        'password1',
      );
      await tester.tap(find.byKey(const ValueKey('reset-password-submit')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(resetPassword, 'password1');
      expect(
        find.byKey(const ValueKey('reset-password-success')),
        findsOneWidget,
      );
    });

    testWidgets('browser-style back returns from email login to auth landing', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          home: const AmoraAuthScreen(),
          routes: {LoginScreen.routeName: (_) => const LoginScreen()},
        ),
      );
      await settleEntrance(tester);
      await tester.tap(find.byKey(const ValueKey('auth-email')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AmoraAuthScreen), findsOneWidget);
    });

    testWidgets('disabled auth button keeps its label visible', (tester) async {
      await tester.pumpWidget(app(home: const LoginScreen()));
      await settleEntrance(tester);
      expect(find.text('Sign in'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Sign in'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });
}
