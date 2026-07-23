import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/phone_otp_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget home) {
    return MaterialApp(theme: AmoraTheme.light(), home: home);
  }

  group('premium authentication presentation', () {
    testWidgets('all auth screens render without overflow at 320px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final screen in const <Widget>[
        AmoraAuthScreen(),
        LoginScreen(),
        SignupScreen(),
        PhoneOtpScreen(),
      ]) {
        await tester.pumpWidget(app(screen));
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull, reason: '$screen overflowed');
      }
    });

    testWidgets('auth shell stays centered and constrained on desktop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(app(const LoginScreen()));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text('A private space for intentional connection.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone flow transitions to one responsive OTP state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(app(const PhoneOtpScreen()));
      await tester.enterText(
        find.byKey(const ValueKey('phone-number-field')),
        '9876543210',
      );
      await tester.ensureVisible(find.text('Send verification code'));
      await tester.tap(find.text('Send verification code'));
      await tester.pump(const Duration(milliseconds: 530));
      await tester.pump(const Duration(milliseconds: 260));

      expect(find.byKey(const ValueKey('phone-entry-view')), findsNothing);
      expect(
        find.byKey(const ValueKey('otp-verification-view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('responsive-otp-input')),
        findsOneWidget,
      );
      for (var index = 0; index < 6; index++) {
        expect(find.byKey(ValueKey('otp-cell-$index')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '12345',
      );
      await tester.pump();
      expect(_verifyButton(tester).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '123456',
      );
      await tester.pump();
      expect(_verifyButton(tester).onPressed, isNotNull);
    });

    testWidgets('responsive OTP supports four digits, paste, and backspace', (
      tester,
    ) async {
      final controllers = List.generate(4, (_) => TextEditingController());
      final nodes = List.generate(4, (_) => FocusNode());
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
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: ResponsiveOtpInput(
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
        '1234',
      );
      await tester.pump();
      expect(controllers.map((controller) => controller.text).join(), '1234');
      expect(pasted, '1234');

      await tester.enterText(
        find.byKey(const ValueKey('otp-native-input')),
        '123',
      );
      await tester.pump();
      expect(controllers.map((controller) => controller.text).join(), '123');
      expect(tester.takeException(), isNull);
    });

    testWidgets('six OTP cells stay contained at intermediate widths', (
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

      await tester.pumpWidget(
        app(
          Scaffold(
            body: Center(
              child: SizedBox(
                width: 328,
                child: ResponsiveOtpInput(
                  controllers: controllers,
                  nodes: nodes,
                  onChanged: () {},
                  onPaste: (_) {},
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

      expect(find.byKey(const ValueKey('otp-cell-5')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'focused auth fields remain overflow-free with keyboard inset',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 640));
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(() {
          tester.binding.setSurfaceSize(null);
          tester.view.resetViewInsets();
        });

        await tester.pumpWidget(app(const LoginScreen()));
        await tester.tap(find.byKey(const ValueKey('login-password-field')));
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.text('Welcome back'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

FilledButton _verifyButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.ancestor(
      of: find.text('Verify and continue'),
      matching: find.byType(FilledButton),
    ),
  );
}
