import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/legal/presentation/community_guidelines_screen.dart';
import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/settings/presentation/account_action_screens.dart';
import 'package:amora_ai/features/settings/presentation/likes_super_likes_screen.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/profile_settings_hub_widgets.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHub(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) {
    return tester.binding.setSurfaceSize(size).then((_) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(
              body: Center(child: Text('Destination ${settings.name}')),
            ),
          ),
          home: const ProfileSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Profile Settings is a grouped navigation hub', (tester) async {
    await pumpHub(tester);

    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Manage your AMORAA account'), findsOneWidget);
    for (final group in const [
      'ACCOUNT',
      'MEMBERSHIP',
      'NOTIFICATIONS',
      'SUPPORT',
      'LEGAL',
      'ACCOUNT ACTIONS',
    ]) {
      await tester.scrollUntilVisible(
        find.text(group),
        360,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(group), findsOneWidget);
    }
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(Radio<dynamic>), findsNothing);
    expect(find.text('Who can discover me'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every hub row opens its assigned destination', (tester) async {
    final destinations = <Key, String>{
      const ValueKey('settings-personal-information'):
          ProfileBasicDetailsScreen.routeName,
      const ValueKey('settings-likes-super-likes'):
          LikesSuperLikesScreen.routeName,
      const ValueKey('settings-saved-profiles'): SavedProfilesScreen.routeName,
      const ValueKey('settings-blocked-profiles'):
          BlockedProfilesScreen.routeName,
      const ValueKey('settings-membership'): SubscriptionScreen.membershipRoute,
      const ValueKey('settings-manage-subscription'):
          SubscriptionScreen.manageRoute,
      const ValueKey('settings-notification-preferences'):
          NotificationPreferencesScreen.routeName,
      const ValueKey('settings-safety-center'): SafetyPrivacyScreen.routeName,
      const ValueKey('settings-privacy-policy'): PrivacyPolicyScreen.routeName,
      const ValueKey('settings-terms'): TermsConditionsScreen.routeName,
      const ValueKey('settings-guidelines'):
          CommunityGuidelinesScreen.routeName,
      const ValueKey('settings-email-support'): FaqSupportScreen.routeName,
      const ValueKey('settings-change-password'):
          ForgotPasswordScreen.routeName,
      const ValueKey('settings-logout'): LogoutAccountScreen.routeName,
      const ValueKey('settings-deactivate-account'):
          DeactivateAccountScreen.routeName,
      const ValueKey('settings-delete-account'):
          DeleteAccountInformationScreen.routeName,
    };

    for (final entry in destinations.entries) {
      await pumpHub(tester, size: const Size(390, 2400));
      final row = tester.widget<ProfileSettingsHubRow>(
        find.byKey(entry.key, skipOffstage: false),
      );
      row.onTap();
      await tester.pumpAndSettle();
      expect(
        find.text('Destination ${entry.value}'),
        findsOneWidget,
        reason: '${entry.key} did not open ${entry.value}',
      );
    }
  });

  testWidgets('Account entries use the required canonical order', (
    tester,
  ) async {
    await pumpHub(tester, size: const Size(390, 2400));

    const labels = <String>[
      'Personal Information',
      'Likes & Super Likes',
      'Saved Profiles',
      'Blocked Profiles',
    ];
    final verticalPositions = labels
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(verticalPositions, orderedEquals([...verticalPositions]..sort()));
    expect(find.text('Deactivate Account'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('support and legal live only in Profile Settings', (
    tester,
  ) async {
    await pumpHub(tester, size: const Size(390, 2400));

    for (final label in const [
      'Email Support',
      'Terms & Conditions',
      'Privacy Policy',
      'Community Guidelines',
      'Safety Center',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('support@amora.ai'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);

    final profileSource = File(
      'lib/features/profile/presentation/profile_screen.dart',
    ).readAsStringSync();
    for (final removed in const [
      "title: 'Support'",
      "title: 'Legal'",
      "title: 'Terms & Conditions'",
      "title: 'Privacy policy'",
      "title: 'Community guidelines'",
      "title: 'Safety center'",
      'EmailSupportProfileCard',
    ]) {
      expect(profileSource, isNot(contains(removed)));
    }
  });

  testWidgets('hub is overflow-free at supported widths', (tester) async {
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      await pumpHub(tester, size: Size(width, width >= 768 ? 900 : 700));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('Delete Account'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Overflow at $width');
    }
  });

  testWidgets('new dedicated destinations render professional content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          '/kyc': (_) => const Scaffold(body: Text('KYC')),
          '/photo-manager': (_) => const Scaffold(body: Text('Photos')),
          '/sos-checkin': (_) => const Scaffold(body: Text('Check-in')),
          '/support': (_) => const Scaffold(body: Text('Support')),
          '/report-flow': (_) => const Scaffold(body: Text('Report')),
        },
        home: const CommunityGuidelinesScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community Guidelines'), findsWidgets);
    expect(find.textContaining('Respect'), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        routes: {
          '/kyc': (_) => const Scaffold(body: Text('KYC')),
          '/photo-manager': (_) => const Scaffold(body: Text('Photos')),
          '/sos-checkin': (_) => const Scaffold(body: Text('Check-in')),
          '/support': (_) => const Scaffold(body: Text('Support')),
          '/report-flow': (_) => const Scaffold(body: Text('Report')),
        },
        home: const SafetyPrivacyScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Safety Center'), findsOneWidget);
    expect(find.text('Aadhaar & selfie verification'), findsNothing);
    expect(find.text('Verified Profile'), findsNothing);
    expect(find.text('Photo Verification'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
