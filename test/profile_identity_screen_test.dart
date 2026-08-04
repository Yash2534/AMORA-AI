import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalProfileDraft original;

  setUp(() {
    original = LocalProfileRepository.instance.profile;
  });

  tearDown(() {
    LocalProfileRepository.instance.save(original);
  });

  testWidgets('profile is an identity-first story at compact phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(child: Text('${settings.name} destination')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'Initial compact Profile layout overflowed',
    );

    expect(find.text('My Dating Identity'), findsOneWidget);
    expect(find.textContaining(original.name), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-settings-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profile-notifications-button')),
      findsNothing,
    );
    // Overflow assertions are checked after the responsive scroll pass below.

    final scrollable = find.byType(Scrollable).first;
    for (final section in [
      '❤️ About Me',
      'Photo Gallery',
      '🎯 Interests',
      '🧳 Lifestyle',
      '💬 Profile prompts',
      'Verification & trust',
      'Premium membership',
      'Quick Actions',
    ]) {
      for (
        var attempt = 0;
        attempt < 16 && find.text(section).evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(scrollable, const Offset(0, -360));
        await tester.pumpAndSettle();
      }
      expect(find.text(section), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow while revealing $section',
      );
      if (section == 'Premium membership') {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('premium-membership-section')),
          240,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(find.text('AMORAA Premium'), findsOneWidget);
        expect(find.text('See likes'), findsOneWidget);
        expect(find.text('Advanced filters'), findsOneWidget);
        expect(find.text('Priority visibility'), findsOneWidget);
        expect(find.text('Exclusive features'), findsOneWidget);
        expect(find.text('View premium'), findsOneWidget);
        expect(find.text('Manage'), findsOneWidget);
      }
    }

    for (final action in const [
      'Likes & Super Likes',
      'Saved Profiles',
      'Blocked Profiles',
      'Support',
    ]) {
      expect(find.text(action), findsOneWidget);
    }
    expect(find.text('Log out'), findsNothing);
    expect(find.text('Delete account'), findsNothing);

    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('Create Ticket'), findsNothing);
    expect(find.textContaining('Phone Support'), findsNothing);
    expect(find.text('Legal'), findsNothing);
    expect(find.text('Email Support'), findsNothing);
    expect(find.text('Terms & Conditions'), findsNothing);
    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('Community Guidelines'), findsNothing);
    expect(find.text('Safety Center'), findsNothing);
  });

  testWidgets('Profile header settings and membership actions keep routes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    RouteSettings? openedRoute;

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
        onGenerateRoute: (settings) {
          openedRoute = settings;
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(
              body: Center(child: Text('${settings.name} destination')),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final settingsButton = find.byKey(
      const ValueKey('profile-settings-button'),
    );
    expect(settingsButton, findsOneWidget);
    expect(find.bySemanticsLabel('Open profile settings'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-notifications-button')),
      findsNothing,
    );
    expect(tester.getSize(settingsButton), const Size(48, 48));

    await tester.tap(settingsButton);
    await tester.pumpAndSettle();
    expect(openedRoute?.name, ProfileSettingsScreen.routeName);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('premium-membership-section')),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-view-premium-button')));
    await tester.pumpAndSettle();
    expect(openedRoute?.name, SubscriptionScreen.routeName);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-manage-membership-button')),
      420,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('profile-manage-membership-button')),
    );
    await tester.pumpAndSettle();
    expect(openedRoute?.name, SubscriptionScreen.manageRoute);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile header and membership stay responsive', (tester) async {
    for (final width in <double>[320, 360, 390, 430, 600, 768, 1024]) {
      await tester.binding.setSurfaceSize(
        Size(width, width >= 600 ? 900 : 760),
      );
      await tester.pumpWidget(
        MaterialApp(theme: AmoraTheme.light(), home: const ProfileScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Dating Identity'), findsOneWidget);
      expect(find.text('Your dating identity'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('profile-settings-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profile-notifications-button')),
        findsNothing,
      );

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('premium-membership-section')),
        520,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('AMORAA Premium'), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('premium-membership-section')))
            .width,
        lessThanOrEqualTo(width - 32),
      );
      expect(tester.takeException(), isNull, reason: 'Overflow at $width px');
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('profile uses a centred responsive identity canvas on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const ProfileScreen(showNavigation: false),
      ),
    );
    await tester.pumpAndSettle();

    final scroll = find.byKey(
      const PageStorageKey<String>('main-profile-scroll'),
    );
    expect(tester.getSize(scroll).width, lessThanOrEqualTo(1040));
    expect(tester.getCenter(scroll).dx, moreOrLessEquals(640, epsilon: 1));
    expect(find.byType(ProfileHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit profile saves through the existing local repository', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    LocalProfileRepository.instance.save(
      original.copyWith(
        interests: const ['Coffee', 'Cooking', 'Road trips', 'Yoga', 'Reading'],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const ProfileEditScreen()),
    );
    await tester.pumpAndSettle();

    final existingVoicePrompt = original.voicePrompt;
    expect(
      find.textContaining(RegExp('voice introduction', caseSensitive: false)),
      findsNothing,
    );
    expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
    expect(find.byIcon(Icons.graphic_eq_rounded), findsNothing);

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'Updated AMORAA Member');
    await tester.tap(find.byKey(const ValueKey('profile-save-button')));
    await tester.pumpAndSettle();

    expect(
      LocalProfileRepository.instance.profile.name,
      'Updated AMORAA Member',
    );
    expect(
      LocalProfileRepository.instance.profile.voicePrompt,
      existingVoicePrompt,
    );
    expect(find.text('Profile changes saved'), findsOneWidget);
  });
}
