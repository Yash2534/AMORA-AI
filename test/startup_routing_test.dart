import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(AmoraSession.logOut);
  tearDown(AmoraSession.logOut);

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
    AmoraSession.logIn();

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(MainShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });
}
