import 'dart:convert';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DOB utility normalizes and rejects invalid ages and dates', () {
    final today = DateTime(2026, 7, 30);
    expect(
      AmoraDateOfBirth.format(AmoraDateOfBirth.parse('7 / 3 / 1998')!),
      '07/03/1998',
    );
    expect(AmoraDateOfBirth.parse('31/02/2000'), isNull);
    expect(
      AmoraDateOfBirth.validate(DateTime(2027), now: today),
      contains('future'),
    );
    expect(
      AmoraDateOfBirth.validate(DateTime(2010, 1, 1), now: today),
      contains('18'),
    );
    expect(
      AmoraDateOfBirth.validate(DateTime(1998, 7, 30), now: today),
      isNull,
    );
  });

  testWidgets('shared primary button keeps labels in every important state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              AppPrimaryButton(label: 'Enabled action', onPressed: () {}),
              const AppPrimaryButton(label: 'Disabled action', onPressed: null),
              AppPrimaryButton(
                label: 'Saving changes',
                isLoading: true,
                onPressed: () {},
              ),
              AppPrimaryButton(
                label: 'Delete account',
                variant: AppPrimaryButtonVariant.destructive,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Enabled action'), findsOneWidget);
    expect(find.text('Disabled action'), findsOneWidget);
    expect(find.text('Saving changes'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    for (final label in [
      'Enabled action',
      'Disabled action',
      'Saving changes',
      'Delete account',
    ]) {
      expect(tester.getSize(find.text(label)).height, greaterThan(0));
    }
  });

  test('profile repository writes normalized data to device storage', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalProfileRepository.instance;
    final original = repository.profile;
    addTearDown(() => repository.save(original));

    await repository.savePersisted(
      original.copyWith(name: 'Persistent QA', birthdate: '7 / 3 / 1998'),
    );
    final preferences = await SharedPreferences.getInstance();
    final stored =
        jsonDecode(preferences.getString('amora.user_profile.v1')!)
            as Map<String, Object?>;

    expect(repository.profile.name, 'Persistent QA');
    expect(repository.profile.birthdate, '07/03/1998');
    expect(stored['name'], 'Persistent QA');
    expect(stored['birthdate'], '07/03/1998');
  });

  test('onboarding updates the same global UserProfile', () async {
    SharedPreferences.setMockInitialValues({});
    final profiles = LocalProfileRepository.instance;
    final original = profiles.profile;
    addTearDown(() => profiles.save(original));
    final onboarding = LocalOnboardingRepository.instance;

    onboarding.update(
      LocalOnboardingState(
        birthDate: DateTime(1998, 3, 7),
        gender: 'Woman',
        city: 'Surat',
        relationshipGoal: 'Long-term relationship',
      ),
    );

    expect(profiles.profile.birthdate, '07/03/1998');
    expect(profiles.profile.gender, 'Woman');
    expect(profiles.profile.location, 'Surat');
    expect(profiles.profile.datingIntention, 'Long-term relationship');
  });

  testWidgets('basic details DOB is picker-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileBasicDetailsScreen(),
      ),
    );
    expect(find.byType(AmoraDobField), findsOneWidget);
    final storedBirthdate = LocalProfileRepository.instance.profile.birthdate;
    if (storedBirthdate.isNotEmpty) {
      expect(
        find.descendant(
          of: find.byType(AmoraDobField),
          matching: find.text(storedBirthdate),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: find.byType(AmoraDobField),
        matching: find.byType(EditableText),
      ),
      findsNothing,
    );
  });

  testWidgets('Safety Center exposes only supported destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          FaqSupportScreen.routeName: (_) => const FaqSupportScreen(),
          ProfileBasicDetailsScreen.routeName: (_) =>
              const ProfileBasicDetailsScreen(),
        },
        home: const SafetyPrivacyScreen(),
      ),
    );

    expect(find.text('Aadhaar & selfie verification'), findsNothing);
    expect(find.text('Verified Profile'), findsNothing);
    expect(find.text('Photo Verification'), findsNothing);
    expect(find.text('Face Verification'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('safety-emergency-unavailable')),
      300,
    );
    expect(find.text('Emergency tools unavailable'), findsOneWidget);
    expect(find.text('Privacy controls unavailable'), findsOneWidget);
    expect(find.text('Report History'), findsNothing);
    expect(find.text('Report a Problem'), findsNothing);
    expect(find.text('Data Portability'), findsNothing);
    expect(find.text('Delete Account'), findsNothing);
    expect(find.text('Block User'), findsNothing);
  });

  testWidgets('settings prevents unsupported credential edits', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileSettingsScreen(),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Change Password'),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Phone Number'), findsNothing);
  });

  testWidgets('Return to Discover replaces the stack with /discover', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        initialRoute: ProfilePreviewScreen.routeName,
        routes: {
          ProfilePreviewScreen.routeName: (_) => const ProfilePreviewScreen(),
          DiscoverScreen.routeName: (_) =>
              const Scaffold(body: Text('Explicit discover destination')),
        },
      ),
    );

    await tester.tap(find.text('Return to Discover'));
    await tester.pumpAndSettle();
    expect(find.text('Explicit discover destination'), findsOneWidget);
    expect(find.byType(ProfilePreviewScreen), findsNothing);
  });

  testWidgets('membership never invents plans when its API is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const SubscriptionScreen()),
    );

    await tester.pumpAndSettle();
    expect(find.text('Membership could not be loaded.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Unlimited likes'), findsNothing);
  });

  testWidgets('events removes duplicate membership unlock actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const EventsScreen()),
    );
    expect(find.text('Unlock Events'), findsNothing);
    expect(find.text('View Membership'), findsNothing);
  });

  test('bottom sheets do not add an automatic duplicate handle', () {
    expect(AmoraTheme.light().bottomSheetTheme.showDragHandle, isFalse);
    expect(AmoraTheme.dark().bottomSheetTheme.showDragHandle, isFalse);
  });
}
