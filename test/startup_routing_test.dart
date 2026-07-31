import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:amora_ai/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AmoraSession.logOut);
  tearDown(AmoraSession.logOut);

  testWidgets('unauthenticated launch opens Auth with both account choices', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(AmoraAuthScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-create-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
    expect(find.text('Preparing your compatibility engine'), findsNothing);
  });

  testWidgets('authenticated launch preserves the existing app destination', (
    tester,
  ) async {
    AmoraSession.logIn();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(AmoraAuthScreen), findsNothing);
  });
}
