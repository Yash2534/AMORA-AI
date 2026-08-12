import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/settings/presentation/account_action_screens.dart';
import 'package:amora_ai/features/settings/presentation/widgets/amoraa_delete_account_flow.dart';
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
    await tester.pump();
  }

  Future<void> selectDeleteReason(WidgetTester tester, String reasonCode) =>
      tapVisible(tester, find.byKey(ValueKey('delete-reason-$reasonCode')));

  Future<void> continueToFinalConfirmation(WidgetTester tester) async {
    await tapVisible(
      tester,
      find.byKey(const ValueKey('delete-reason-continue')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('delete-account-final-step')),
      findsOneWidget,
    );
  }

  testWidgets('deactivation clearly describes account hiding', (tester) async {
    await pumpAction(tester, const DeactivateAccountScreen());

    expect(find.text('Deactivate your account?'), findsOneWidget);
    expect(find.textContaining('hidden'), findsWidgets);
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

  test('delete reasons have the exact centralized labels and mappings', () {
    expect(deleteAccountReasons.map((reason) => reason.label), const [
      'I found someone',
      'I\u2019m taking a break',
      'I\u2019m not finding the right matches',
      'Privacy concerns',
      'Too many notifications',
      'App experience issues',
      'Other',
    ]);
    expect(deleteAccountReasons.map((reason) => reason.code), const [
      'found_someone',
      'taking_a_break',
      'not_finding_matches',
      'privacy_concerns',
      'too_many_notifications',
      'app_experience_issues',
      'other',
    ]);
    expect(
      deleteAccountReasons.where((reason) => reason.label == 'Other'),
      hasLength(1),
    );
  });

  testWidgets('typed keyword confirmation is absent and a reason is required', (
    tester,
  ) async {
    await pumpAction(tester, const DeleteAccountInformationScreen());

    expect(find.text('Why are you deleting your account?'), findsOneWidget);
    expect(find.textContaining('Type DELETE'), findsNothing);
    expect(find.textContaining('Enter DELETE'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Delete Permanently'), findsNothing);

    final continueButton = tester.widget<AppPrimaryButton>(
      find.byKey(const ValueKey('delete-reason-continue')),
    );
    expect(continueButton.onPressed, isNull);
  });

  testWidgets('reason selection is single-select and enables Continue', (
    tester,
  ) async {
    await pumpAction(tester, const DeleteAccountInformationScreen());

    await selectDeleteReason(tester, 'found_someone');
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    await selectDeleteReason(tester, 'privacy_concerns');
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

    final continueButton = tester.widget<AppPrimaryButton>(
      find.byKey(const ValueKey('delete-reason-continue')),
    );
    expect(continueButton.onPressed, isNotNull);
    await continueToFinalConfirmation(tester);
    expect(find.text('Delete your account permanently?'), findsOneWidget);
    expect(find.text('Privacy concerns'), findsOneWidget);
    expect(find.text('Delete Permanently'), findsOneWidget);
  });

  testWidgets('Other requires trimmed non-empty details and preserves text', (
    tester,
  ) async {
    await pumpAction(tester, const DeleteAccountInformationScreen());

    await selectDeleteReason(tester, 'other');
    final field = find.byKey(const ValueKey('delete-other-reason-field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, '   ');
    await tester.pump();
    expect(
      tester
          .widget<AppPrimaryButton>(
            find.byKey(const ValueKey('delete-reason-continue')),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(field, '  Moving away from the service  ');
    await tester.pump();
    expect(
      tester
          .widget<AppPrimaryButton>(
            find.byKey(const ValueKey('delete-reason-continue')),
          )
          .onPressed,
      isNotNull,
    );

    await selectDeleteReason(tester, 'found_someone');
    expect(field, findsNothing);
    await selectDeleteReason(tester, 'other');
    expect(
      tester.widget<TextFormField>(field).controller?.text,
      '  Moving away from the service  ',
    );
    await continueToFinalConfirmation(tester);
    expect(find.text('Moving away from the service'), findsOneWidget);
  });

  testWidgets('failed deletion keeps session, data, and selected reason', (
    tester,
  ) async {
    final nameBefore = profiles.profile.name;
    var calls = 0;
    await pumpAction(
      tester,
      DeleteAccountInformationScreen(
        onDeleteAccount: () async {
          calls += 1;
          return false;
        },
      ),
    );
    await selectDeleteReason(tester, 'privacy_concerns');
    await continueToFinalConfirmation(tester);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('settings-delete-permanently')),
    );
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.text('Couldn\u2019t delete your account'), findsOneWidget);
    expect(find.text('Privacy concerns'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(AmoraSession.isLoggedIn.value, isTrue);
    expect(profiles.profile.name, nameBefore);
  });

  testWidgets('delete submission blocks duplicates', (tester) async {
    final result = Completer<bool>();
    var calls = 0;
    await pumpAction(
      tester,
      DeleteAccountInformationScreen(
        onDeleteAccount: () {
          calls += 1;
          return result.future;
        },
      ),
    );
    await selectDeleteReason(tester, 'found_someone');
    await continueToFinalConfirmation(tester);
    final submit = find.byKey(const ValueKey('settings-delete-permanently'));
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
    expect(calls, 1);

    result.complete(false);
    await tester.pumpAndSettle();
    expect(AmoraSession.isLoggedIn.value, isTrue);
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
    await selectDeleteReason(tester, 'app_experience_issues');
    await continueToFinalConfirmation(tester);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('settings-delete-permanently')),
    );
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

    await pumpAction(
      tester,
      const DeleteAccountInformationScreen(),
      size: const Size(320, 700),
    );
    expect(tester.takeException(), isNull);
  });
}
