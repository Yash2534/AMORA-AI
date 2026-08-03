import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
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

  testWidgets('deactivation is reversible and never fakes service success', (
    tester,
  ) async {
    await pumpAction(tester, const DeactivateAccountScreen());

    expect(find.text('Deactivate your account?'), findsOneWidget);
    expect(find.textContaining('reactivate it later'), findsOneWidget);
    expect(find.text('Keep My Account'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('deactivate-account-understood')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('confirm-deactivate-account')));
    await tester.pump();

    expect(
      find.textContaining('No account-deactivation service'),
      findsOneWidget,
    );
    expect(AmoraSession.isLoggedIn.value, isTrue);
  });

  testWidgets('deactivation blocks duplicate submissions', (tester) async {
    final result = Completer<bool>();
    var calls = 0;
    await pumpAction(
      tester,
      DeactivateAccountScreen(
        onDeactivate: () {
          calls += 1;
          return result.future;
        },
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('deactivate-account-understood')),
    );
    await tester.pump();
    final submit = find.byKey(const ValueKey('confirm-deactivate-account'));
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
    expect(calls, 1);

    result.complete(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Please try again'), findsOneWidget);
    expect(AmoraSession.isLoggedIn.value, isTrue);
  });

  testWidgets('permanent deletion requires a deliberate second confirmation', (
    tester,
  ) async {
    await pumpAction(tester, const DeleteAccountInformationScreen());

    expect(find.text('Delete your account permanently?'), findsOneWidget);
    expect(find.textContaining('cannot be undone'), findsOneWidget);
    expect(find.text('Delete Permanently'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('settings-delete-continue')));
    await tester.pump();
    expect(find.text('Type DELETE to continue'), findsOneWidget);

    final deleteButton = tester.widget<AppPrimaryButton>(
      find.byKey(const ValueKey('settings-delete-permanently')),
    );
    expect(deleteButton.onPressed, isNull);
  });

  testWidgets('missing or failed deletion service preserves session and data', (
    tester,
  ) async {
    final nameBefore = profiles.profile.name;
    await pumpAction(tester, const DeleteAccountInformationScreen());
    await tester.tap(find.byKey(const ValueKey('settings-delete-continue')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('settings-delete-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('settings-delete-permanently')));
    await tester.pump();

    expect(find.textContaining('no delete-account service'), findsOneWidget);
    expect(AmoraSession.isLoggedIn.value, isTrue);
    expect(profiles.profile.name, nameBefore);
  });

  testWidgets('confirmed server deletion clears local state then logs out', (
    tester,
  ) async {
    var calls = 0;
    await pumpAction(
      tester,
      DeleteAccountInformationScreen(
        onDeleteAccount: () async {
          calls += 1;
          return true;
        },
      ),
    );
    await tester.tap(find.byKey(const ValueKey('settings-delete-continue')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('settings-delete-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('settings-delete-permanently')));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(AmoraSession.isLoggedIn.value, isFalse);
    expect(profiles.profile.name, isEmpty);
    expect(chats.conversations, isEmpty);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('account action screens remain overflow-free at 320 px', (
    tester,
  ) async {
    await pumpAction(
      tester,
      const DeactivateAccountScreen(),
      size: const Size(320, 700),
    );
    expect(tester.takeException(), isNull);
  });
}
