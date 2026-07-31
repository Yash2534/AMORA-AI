import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
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

  Future<void> pumpProfile(
    WidgetTester tester, {
    ProfileAccountDeletionCallback? onDeleteAccount,
  }) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {'/login': (_) => const Scaffold(body: Text('Login'))},
        home: ProfileScreen(
          showNavigation: false,
          onDeleteAccount: onDeleteAccount,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDeleteAccount(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Delete account'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Delete account')),
      alignment: .5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
  }

  FilledButton primaryButton(WidgetTester tester, String label) {
    expect(find.text(label), findsOneWidget);
    return tester.widget<FilledButton>(
      find.byKey(const ValueKey('delete-primary-action')),
    );
  }

  Future<void> chooseReason(WidgetTester tester, String code) async {
    final reason = find.byKey(ValueKey('delete-reason-$code'));
    await tester.scrollUntilVisible(
      reason,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await Scrollable.ensureVisible(tester.element(reason), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(reason);
    await tester.pump();
  }

  Future<void> tapPrimary(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('delete-primary-action')));
    await tester.pumpAndSettle();
  }

  testWidgets('Profile Settings exposes dedicated account action rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Logout'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Logout'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });

  testWidgets('canonical account actions appear once in Profile', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tester.scrollUntilVisible(
      find.text('Log out'),
      420,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    expect(
      find.text('Permanently delete your AMORAA account and associated data.'),
      findsOneWidget,
    );
  });

  testWidgets('reason and Other details are mandatory', (tester) async {
    await pumpProfile(tester, onDeleteAccount: (_, _) async => false);
    await openDeleteAccount(tester);

    expect(primaryButton(tester, 'Continue').onPressed, isNull);
    await chooseReason(tester, 'other');
    expect(primaryButton(tester, 'Continue').onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-other-reason-field')),
      'Too short',
    );
    await tester.pump();
    expect(primaryButton(tester, 'Continue').onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-other-reason-field')),
      'A meaningful custom reason',
    );
    await tester.pump();
    expect(primaryButton(tester, 'Continue').onPressed, isNotNull);
  });

  testWidgets('final confirmation is required and failure preserves session', (
    tester,
  ) async {
    await pumpProfile(tester, onDeleteAccount: (_, _) async => false);
    await openDeleteAccount(tester);

    await chooseReason(tester, 'found_partner');
    await tapPrimary(tester);
    expect(find.text('Understand what happens next'), findsOneWidget);

    await tapPrimary(tester);
    expect(primaryButton(tester, 'Delete my account').onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    expect(primaryButton(tester, 'Delete my account').onPressed, isNotNull);

    final nameBefore = profiles.profile.name;
    await tapPrimary(tester);
    expect(AmoraSession.isLoggedIn.value, isTrue);
    expect(profiles.profile.name, nameBefore);
    expect(find.textContaining('couldn’t delete'), findsOneWidget);
  });

  testWidgets('missing deletion endpoint never exposes a fake success action', (
    tester,
  ) async {
    await pumpProfile(tester);
    await openDeleteAccount(tester);

    await chooseReason(tester, 'found_partner');
    await tapPrimary(tester);
    await tapPrimary(tester);
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();

    expect(find.textContaining('no account-deletion endpoint'), findsOneWidget);
    expect(primaryButton(tester, 'Delete my account').onPressed, isNull);
    expect(AmoraSession.isLoggedIn.value, isTrue);
  });

  testWidgets('confirmed deletion clears local state and auth stack', (
    tester,
  ) async {
    String? submittedReason;
    await pumpProfile(
      tester,
      onDeleteAccount: (reason, details) async {
        submittedReason = reason;
        return true;
      },
    );
    await openDeleteAccount(tester);

    await chooseReason(tester, 'found_partner');
    await tapPrimary(tester);
    await tapPrimary(tester);
    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation-field')),
      'DELETE',
    );
    await tester.pump();
    await tapPrimary(tester);

    expect(submittedReason, 'found_partner');
    expect(AmoraSession.isLoggedIn.value, isFalse);
    expect(profiles.profile.name, isEmpty);
    expect(chats.conversations, isEmpty);
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
  });
}
