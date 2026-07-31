import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
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

  group('production authentication presentation', () {
    testWidgets(
      'login uses official branding, Google asset, and no back action',
      (tester) async {
        await tester.pumpWidget(app(home: const LoginScreen()));
        await settleEntrance(tester);

        expect(find.text('Welcome back'), findsOneWidget);
        expect(find.textContaining('AMORAA'), findsWidgets);
        expect(find.text('Continue with Google'), findsOneWidget);
        expect(find.textContaining('phone'), findsNothing);
        expect(find.byTooltip('Go back'), findsNothing);
        expect(find.byTooltip('Back'), findsNothing);
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
      },
    );

    testWidgets('official wordmark remains visible at supported widths', (
      tester,
    ) async {
      for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
        await tester.binding.setSurfaceSize(
          Size(width, width >= 600 ? 800 : 760),
        );
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

    testWidgets('active auth routes are overflow-free at supported widths', (
      tester,
    ) async {
      const widths = <double>[320, 360, 390, 430, 600, 768, 1024];
      const screens = <Widget>[
        LoginScreen(),
        SignupScreen(),
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

    testWidgets('login accepts a non-empty legacy password', (tester) async {
      await tester.pumpWidget(app(home: const LoginScreen()));
      await settleEntrance(tester);

      await tester.enterText(
        find.byKey(const ValueKey('login-email-field')),
        'member@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password-field')),
        'old',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsNothing);
    });

    testWidgets('signup requires matching eight-character passwords', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        app(
          home: const SignupScreen(),
          routes: {
            TermsConditionsScreen.routeName: (_) =>
                const TermsConditionsScreen(),
            PrivacyPolicyScreen.routeName: (_) => const PrivacyPolicyScreen(),
          },
        ),
      );
      await settleEntrance(tester);

      await tester.enterText(
        find.byKey(const ValueKey('signup-name-field')),
        'AMORAA Member',
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
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(find.text('Create account'));
      await tester.tap(find.text('Create account'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('shared OTP supports paste and updates all six cells', (
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
    });

    testWidgets(
      'forgot password uses email request and verification callbacks',
      (tester) async {
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
        expect(
          find.byKey(const ValueKey('recovery-code-step')),
          findsOneWidget,
        );
        expect(find.textContaining('Resend code in 00:'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('otp-native-input')),
          '123456',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('verify-recovery-code')));
        await tester.pumpAndSettle();
        expect(verified, 'member@example.com:123456');
        expect(find.byType(ResetPasswordScreen), findsOneWidget);
      },
    );

    testWidgets('reset password executes callback before success', (
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
  });
}
