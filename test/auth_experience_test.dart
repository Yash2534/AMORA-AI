import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
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
    setUp(LocalOnboardingRepository.instance.resetForTesting);
    tearDown(LocalOnboardingRepository.instance.resetForTesting);

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

    testWidgets('Create Account setup chip stays on the padded right edge', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in const <double>[320, 360, 390, 412, 430, 600, 768]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        await tester.pumpWidget(
          app(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: const TextScaler.linear(1.3),
              ),
              child: const SignupScreen(),
            ),
          ),
        );
        await settleEntrance(tester);

        final chip = find.byKey(const ValueKey('signup-account-setup-chip'));
        final header = find.byType(AuthBrandHeader);
        final formSurface = find.byType(AuthFormSurface);
        final horizontalPadding = width < 360
            ? AmoraSpacing.space16
            : width < 600
            ? AmoraSpacing.space20
            : AmoraSpacing.space32;
        final availableWidth = width - (horizontalPadding * 2);
        final contentWidth = availableWidth > 520 ? 520.0 : availableWidth;
        final expectedRightEdge = (width + contentWidth) / 2;
        expect(chip, findsOneWidget, reason: '${width.toInt()}px');
        expect(find.text('Account setup'), findsOneWidget);
        expect(
          tester.getTopRight(chip).dx,
          moreOrLessEquals(expectedRightEdge, epsilon: .01),
          reason: '${width.toInt()}px page padding',
        );
        expect(
          tester.getTopRight(chip).dx,
          moreOrLessEquals(tester.getTopRight(header).dx, epsilon: .01),
          reason: '${width.toInt()}px header edge',
        );
        expect(
          tester.getTopRight(chip).dx,
          moreOrLessEquals(tester.getTopRight(formSurface).dx, epsilon: .01),
          reason: '${width.toInt()}px form edge',
        );
        expect(
          tester.getCenter(chip).dy,
          moreOrLessEquals(tester.getCenter(header).dy, epsilon: .01),
          reason: '${width.toInt()}px vertical alignment',
        );
        expect(find.byKey(const ValueKey('signup-name-field')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('signup-email-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('signup-phone-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('signup-password-field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('signup-confirm-password-field')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: '${width.toInt()}px');
      }

      final chip = find.byKey(const ValueKey('signup-account-setup-chip'));
      await tester.tap(chip);
      await tester.pump();
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('signup-name-field')), findsOneWidget);
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
      final semantics = tester.ensureSemantics();
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
      for (var index = 0; index < 6; index++) {
        final digitSemantics = tester.getSemantics(
          find.byKey(ValueKey('otp-cell-$index')),
        );
        expect(
          digitSemantics.label,
          contains('Verification digit ${index + 1} of 6'),
        );
      }
      semantics.dispose();
    });

    /* Replaced by mobile verification coverage below.
    testWidgets(
      'email verification accepts six digits and replaces OTP on success',
      (tester) async {
        var requestedEmail = '';
        var verifiedPayload = '';
        await tester.pumpWidget(
          app(
            home: AccountVerificationScreen(
              arguments: const EmailVerificationArguments(
                email: 'new.member@amora.ai',
              ),
              requestCode: (email) async => requestedEmail = email,
              verifyCode: (email, code) async {
                verifiedPayload = '$email:$code';
              },
            ),
            routes: {
              ProfileOnboardingFlow.routeName: (_) => const Scaffold(
                body: Center(child: Text('Profile Onboarding reached')),
              ),
            },
          ),
        );
        await settleEntrance(tester);

        expect(requestedEmail, 'new.member@amora.ai');
        expect(find.text('Verify your email'), findsOneWidget);
        expect(find.text('new.member@amora.ai'), findsOneWidget);
        expect(
          tester
              .widget<AuthPrimaryButton>(
                find.byKey(const ValueKey('verify-account-button')),
              )
              .onPressed,
          isNull,
        );

        final nativeInput = find.byKey(const ValueKey('otp-native-input'));
        await tester.enterText(nativeInput, '12a!34');
        await tester.pump();
        expect(tester.widget<TextField>(nativeInput).controller!.text, '1234');
        expect(
          tester
              .widget<AuthPrimaryButton>(
                find.byKey(const ValueKey('verify-account-button')),
              )
              .onPressed,
          isNull,
        );

        await tester.enterText(nativeInput, '123456');
        await tester.pump();
        expect(
          tester.widget<TextField>(nativeInput).controller!.text,
          '123456',
        );
        expect(
          tester
              .widget<AuthPrimaryButton>(
                find.byKey(const ValueKey('verify-account-button')),
              )
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.byKey(const ValueKey('verify-account-button')));
        await tester.pump();
        expect(verifiedPayload, 'new.member@amora.ai:123456');
        expect(find.text('Email verified'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 301));
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Profile Onboarding reached'), findsOneWidget);
        expect(find.byType(AccountVerificationScreen), findsNothing);
        expect(
          LocalOnboardingRepository.instance.state.accountVerified,
          isTrue,
        );
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        expect(await navigator.maybePop(), isFalse);
        await tester.pump();
        expect(find.text('Profile Onboarding reached'), findsOneWidget);
      },
    );

    testWidgets('email verification maps incorrect and expired code failures', (
      tester,
    ) async {
      for (final scenario in <(EmailVerificationFailure, String)>[
        (
          EmailVerificationFailure.incorrectCode,
          'That code doesnâ€™t match. Please try again.',
        ),
        (
          EmailVerificationFailure.expiredCode,
          'This code has expired. Request a new one.',
        ),
      ]) {
        await tester.pumpWidget(
          app(
            home: AccountVerificationScreen(
              arguments: const EmailVerificationArguments(
                email: 'member@example.com',
              ),
              requestCode: (_) async {},
              verifyCode: (_, _) async {
                throw EmailVerificationException(scenario.$1);
              },
            ),
          ),
        );
        await settleEntrance(tester);
        await tester.enterText(
          find.byKey(const ValueKey('otp-native-input')),
          '123456',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('verify-account-button')));
        await tester.pump();
        expect(find.text(scenario.$2), findsOneWidget);
        expect(find.byType(AccountVerificationScreen), findsOneWidget);
      }
    });

    testWidgets(
      'verification resend is rate-limited and resets after success',
      (tester) async {
        var sendAttempts = 0;
        await tester.pumpWidget(
          app(
            home: AccountVerificationScreen(
              arguments: const EmailVerificationArguments(
                email: 'member@example.com',
              ),
              resendSeconds: 1,
              requestCode: (_) async {
                sendAttempts++;
                if (sendAttempts == 2) {
                  throw const EmailVerificationException(
                    EmailVerificationFailure.network,
                  );
                }
              },
              verifyCode: (_, _) async {},
            ),
          ),
        );
        await settleEntrance(tester);

        expect(sendAttempts, 1);
        expect(
          find.byKey(const ValueKey('verification-resend-countdown')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('verification-resend')), findsNothing);

        await tester.pump(const Duration(seconds: 1));
        final resend = find.byKey(const ValueKey('verification-resend'));
        await tester.ensureVisible(resend);
        await tester.tap(resend);
        await tester.pump();
        expect(sendAttempts, 2);
        expect(find.textContaining('couldnâ€™t send a code'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('verification-resend')),
          findsOneWidget,
        );

        await tester.ensureVisible(resend);
        await tester.tap(resend);
        await tester.pump();
        expect(sendAttempts, 3);
        expect(
          find.text('A new verification code has been sent.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('verification-resend-countdown')),
          findsOneWidget,
        );
      },
    );

    testWidgets('duplicate email verification taps call the service once', (
      tester,
    ) async {
      final completion = Completer<void>();
      var verificationCalls = 0;
      await tester.pumpWidget(
        app(
          home: AccountVerificationScreen(
            arguments: const EmailVerificationArguments(
              email: 'member@example.com',
            ),
            requestCode: (_) async {},
            verifyCode: (_, _) {
              verificationCalls++;
              return completion.future;
            },
          ),
          routes: {
            ProfileOnboardingFlow.routeName: (_) =>
                const Scaffold(body: Text('Profile Onboarding reached')),
          },
        ),
      );
      await settleEntrance(tester);
      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '123456',
      );
      await tester.pump();

      final verifyButton = find.byKey(const ValueKey('verify-account-button'));
      await tester.tap(verifyButton);
      await tester.pump();
      await tester.tap(verifyButton, warnIfMissed: false);
      expect(verificationCalls, 1);

      completion.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 301));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Profile Onboarding reached'), findsOneWidget);
    });

    test('production code does not hardcode, log, or persist an email OTP', () {
      final verificationSource = File(
        'lib/features/auth/presentation/account_verification_screen.dart',
      ).readAsStringSync();
      final onboardingSource = File(
        'lib/features/onboarding/data/local_onboarding_repository.dart',
      ).readAsStringSync();

      expect(verificationSource, isNot(contains('print(')));
      expect(verificationSource, isNot(contains('debugPrint(')));
      expect(verificationSource, isNot(contains('SharedPreferences')));
      expect(onboardingSource, isNot(contains('demoVerificationCode')));
      expect(onboardingSource, isNot(contains('verifyCode(String code)')));
    });

    */

    testWidgets(
      'mobile verification sends an E.164 number and completes OTP verification',
      (tester) async {
        var requestedPhone = '';
        var verifiedPayload = '';
        await tester.pumpWidget(
          app(
            home: AccountVerificationScreen(
              arguments: const MobileVerificationArguments(
                phoneNumber: '9876543210',
              ),
              requestOtp: (phone) async => requestedPhone = phone,
              verifyOtp: (phone, code) async =>
                  verifiedPayload = '$phone:$code',
            ),
            routes: {
              ProfileOnboardingFlow.routeName: (_) => const Scaffold(
                body: Center(child: Text('Profile Onboarding reached')),
              ),
            },
          ),
        );
        await settleEntrance(tester);
        expect(find.text('Verify your mobile number'), findsOneWidget);
        expect(find.text('Verify your email'), findsNothing);
        expect(
          find.byKey(const ValueKey('country-code-selector')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('send-otp-button')));
        await tester.pump(const Duration(milliseconds: 250));
        expect(requestedPhone, '+919876543210');
        expect(
          find.byKey(const ValueKey('account-verification-otp')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('otp-native-input')),
          '123456',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('verify-mobile-button')));
        await tester.pump();
        expect(verifiedPayload, '+919876543210:123456');
        expect(find.text('Verification complete'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        expect(find.text('Profile Onboarding reached'), findsOneWidget);
      },
    );

    testWidgets(
      'mobile verification blocks invalid numbers and supports changing the number',
      (tester) async {
        await tester.pumpWidget(
          app(
            home: const AccountVerificationScreen(
              arguments: MobileVerificationArguments(phoneNumber: ''),
            ),
          ),
        );
        await settleEntrance(tester);
        expect(
          tester
              .widget<AuthPrimaryButton>(
                find.byKey(const ValueKey('send-otp-button')),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(const ValueKey('mobile-number-field')));
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(find.text('Mobile number is required.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('mobile-number-field')),
          '12345',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        expect(find.text('Enter a valid mobile number.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('country-code-selector')));
        await tester.pumpAndSettle();
        expect(find.text('Select country code'), findsOneWidget);
        await tester.tap(find.text('India'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('mobile-number-field')),
          '9876543210',
        );
        await tester.pump();
        expect(find.text('Enter a valid mobile number.'), findsNothing);
        expect(
          tester
              .widget<AuthPrimaryButton>(
                find.byKey(const ValueKey('send-otp-button')),
              )
              .onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      'mobile number field remains aligned and contained at supported widths',
      (tester) async {
        const configurations = <(double, double)>[
          (280, 1.0),
          (300, 1.3),
          (320, 1.3),
          (360, 1.0),
          (390, 1.0),
          (412, 1.0),
          (430, 1.0),
          (600, 1.15),
          (768, 1.0),
        ];

        for (final configuration in configurations) {
          final (width, textScale) = configuration;
          await tester.binding.setSurfaceSize(Size(width, 900));
          await tester.pumpWidget(
            app(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
                child: const AccountVerificationScreen(
                  arguments: MobileVerificationArguments(
                    phoneNumber: '9876543210',
                  ),
                ),
              ),
            ),
          );
          await settleEntrance(tester);

          final field = tester.getRect(
            find.byKey(const ValueKey('unified-mobile-number-field')),
          );
          final country = tester.getRect(
            find.byKey(const ValueKey('country-code-selector')),
          );
          final number = tester.getRect(
            find.byKey(const ValueKey('mobile-number-field')),
          );
          final phoneIcon = tester.getRect(
            find.descendant(
              of: find.byKey(const ValueKey('unified-mobile-number-field')),
              matching: find.byIcon(Icons.phone_iphone_rounded),
            ),
          );

          expect(field.height, AmoraSpacing.controlHeight);
          expect(country.left, greaterThanOrEqualTo(field.left));
          expect(country.right, lessThanOrEqualTo(field.right));
          expect(number.left, greaterThanOrEqualTo(country.right));
          expect(number.right, closeTo(field.right, 1.1));
          expect(number.width, greaterThan(72));
          expect(country.center.dy, closeTo(field.center.dy, 1));
          expect(number.center.dy, closeTo(field.center.dy, 1));
          expect(phoneIcon.center.dy, closeTo(field.center.dy, 1));
          expect(field.left, greaterThanOrEqualTo(0));
          expect(field.right, lessThanOrEqualTo(width));
          expect(tester.takeException(), isNull);
        }
        addTearDown(() => tester.binding.setSurfaceSize(null));
      },
    );

    testWidgets(
      'mobile verification respects horizontal safe areas at compact heights',
      (tester) async {
        const configurations = <(Size, EdgeInsets, double)>[
          (Size(280, 568), EdgeInsets.fromLTRB(8, 24, 8, 16), 1.0),
          (Size(320, 640), EdgeInsets.fromLTRB(8, 24, 8, 16), 1.3),
          (Size(360, 640), EdgeInsets.only(top: 24, bottom: 16), 1.0),
          (Size(430, 932), EdgeInsets.only(top: 24, bottom: 16), 1.0),
        ];

        for (final configuration in configurations) {
          final (size, safeInsets, textScale) = configuration;
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            app(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: safeInsets,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: const AccountVerificationScreen(
                  arguments: MobileVerificationArguments(
                    phoneNumber: '9876543210',
                  ),
                ),
              ),
            ),
          );
          await settleEntrance(tester);

          final card = tester.getRect(find.byType(AuthFormSurface));
          final field = tester.getRect(
            find.byKey(const ValueKey('unified-mobile-number-field')),
          );
          final button = tester.getRect(
            find.byKey(const ValueKey('send-otp-button')),
          );
          final info = tester.getRect(find.byType(AuthTrustNote));
          final header = tester.getRect(find.byType(AuthBrandHeader));
          final country = tester.getRect(
            find.byKey(const ValueKey('country-code-selector')),
          );
          final phoneText = tester.getRect(find.byType(EditableText));
          final safeLeft = safeInsets.left;
          final safeRight = size.width - safeInsets.right;
          final safeCenter = (safeLeft + safeRight) / 2;

          for (final rect in <Rect>[card, field, button, info, header]) {
            expect(rect.left, greaterThanOrEqualTo(safeLeft));
            expect(rect.right, lessThanOrEqualTo(safeRight));
          }
          expect(card.center.dx, closeTo(safeCenter, .1));
          expect(field.left, closeTo(button.left, .1));
          expect(field.right, closeTo(button.right, .1));
          expect(info.left, closeTo(button.left, .1));
          expect(info.right, closeTo(button.right, .1));
          expect(country.center.dy, closeTo(field.center.dy, 1));
          expect(phoneText.center.dy, closeTo(field.center.dy, 1));
          expect(tester.takeException(), isNull);
        }
        addTearDown(() => tester.binding.setSurfaceSize(null));
      },
    );

    testWidgets('mobile number error leaves the field geometry unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          home: AccountVerificationScreen(
            arguments: const MobileVerificationArguments(
              phoneNumber: '9876543210',
            ),
            requestOtp: (_) async =>
                throw const MobileVerificationException('OTP_SEND_FAILED'),
          ),
        ),
      );
      await settleEntrance(tester);
      final before = tester.getRect(
        find.byKey(const ValueKey('unified-mobile-number-field')),
      );

      await tester.tap(find.byKey(const ValueKey('send-otp-button')));
      await tester.pump();

      final after = tester.getRect(
        find.byKey(const ValueKey('unified-mobile-number-field')),
      );
      expect(find.textContaining("Couldn't send the code"), findsOneWidget);
      expect(after, before);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'resend failure does not restart countdown and invalid OTP is shown safely',
      (tester) async {
        var sends = 0;
        await tester.pumpWidget(
          app(
            home: AccountVerificationScreen(
              arguments: const MobileVerificationArguments(
                phoneNumber: '9876543210',
              ),
              resendSeconds: 1,
              requestOtp: (_) async {
                sends++;
                if (sends == 2) {
                  throw const MobileVerificationException('NETWORK_ERROR');
                }
              },
              verifyOtp: (_, _) async =>
                  throw const MobileVerificationException('OTP_INVALID'),
            ),
          ),
        );
        await settleEntrance(tester);
        await tester.tap(find.byKey(const ValueKey('send-otp-button')));
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byKey(const ValueKey('verification-resend')));
        await tester.pump();
        expect(
          find.text("Couldn't resend the code. Please try again."),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('verification-resend')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('otp-native-input')),
          '123456',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('verify-mobile-button')));
        await tester.pump();
        expect(find.textContaining('Incorrect code'), findsOneWidget);
      },
    );

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
                email: 'member@example.com',
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
