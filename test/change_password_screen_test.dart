import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    PasswordChangeSubmitter submitter,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: ChangePasswordScreen(onChangePassword: submitter),
      ),
    );
  }

  Future<void> enterPasswords(
    WidgetTester tester, {
    required String current,
    required String next,
    String? confirmation,
  }) async {
    await tester.enterText(
      find.byKey(const ValueKey('change-current-password-field')),
      current,
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-new-password-field')),
      next,
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-confirm-password-field')),
      confirmation ?? next,
    );
    await tester.tap(find.byKey(const ValueKey('change-password-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('rejects an identical new password locally', (tester) async {
    var submitted = false;
    await pump(tester, (_, _) async => submitted = true);

    await enterPasswords(
      tester,
      current: 'CurrentPass123!',
      next: 'CurrentPass123!',
    );

    expect(submitted, isFalse);
    expect(find.text(ChangePasswordScreen.samePasswordMessage), findsOneWidget);
  });

  testWidgets('maps the authoritative backend same-password error', (
    tester,
  ) async {
    await pump(
      tester,
      (_, _) async => throw const AuthException(
        'Unexpected text',
        code: 'NEW_PASSWORD_SAME_AS_CURRENT',
        statusCode: 409,
      ),
    );

    await enterPasswords(
      tester,
      current: 'CurrentPass123!',
      next: 'DifferentPass123!',
    );

    expect(find.text(ChangePasswordScreen.samePasswordMessage), findsOneWidget);
  });

  testWidgets('submits a valid different password and shows success', (
    tester,
  ) async {
    String? current;
    String? next;
    await pump(tester, (oldPassword, newPassword) async {
      current = oldPassword;
      next = newPassword;
    });

    await enterPasswords(
      tester,
      current: 'CurrentPass123!',
      next: 'DifferentPass123!',
    );

    expect(current, 'CurrentPass123!');
    expect(next, 'DifferentPass123!');
    expect(
      find.byKey(const ValueKey('change-password-success')),
      findsOneWidget,
    );
  });
}
