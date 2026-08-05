import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme_controller.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/main.dart';

const _productionRoutes = [
  '/ai-icebreakers',
  '/account-verification',
  '/bio-builder',
  '/browse',
  '/chat-detail',
  '/chats',
  '/compatibility',
  '/dark-mode-settings',
  '/dating-recap',
  '/dealbreakers',
  '/discover',
  '/event-detail',
  '/event-group-chat',
  '/event-waitlist',
  '/events',
  '/faq-support',
  '/filters',
  '/forgot-password',
  '/gift-shop-catalog',
  '/kyc',
  '/liked-you',
  '/liked-you-paywall',
  '/login',
  '/match',
  '/matches',
  '/main',
  '/my-events',
  '/notifications',
  '/notification-preferences',
  '/onboarding',
  '/payment',
  '/photo-manager',
  '/post-event-feedback',
  '/profile',
  '/profile-basic-details',
  '/profile-completion',
  '/profile-onboarding',
  '/profile-preview',
  '/profile-boost',
  '/profile-detail',
  '/profile-settings',
  '/profile-setup',
  '/referral-leaderboard',
  '/report-flow',
  '/reset-password',
  '/safety-privacy',
  '/safety-center',
  '/sos-checkin',
  '/support',
  '/terms',
  '/terms-and-conditions',
  '/privacy-policy',
  '/community-guidelines',
  '/membership',
  '/manage-subscription',
  '/logout',
  '/delete-account',
  '/send-gift',
  '/settings',
  '/signup',
  '/subscription',
  '/success-stories',
  '/why-we-matched',
];

const _hiddenRoutes = [
  '/auth',
  '/landing',
  '/phone-login',
  '/accessibility-settings',
  '/ai-coach',
  '/offline-mode',
  '/trusted-contacts',
  '/data-export',
  '/language-selection',
  '/wallet',
  '/date-spots',
  '/refer-earn',
  '/liveness-check',
  '/admin-panel',
  '/host-dashboard',
  '/voice-prompt',
  '/video-prompt',
  '/stories',
  '/twenty-questions',
  '/video-speed-dating-room',
  '/poll-prompts',
  '/relationship-ecosystem',
  '/ai-learning-dashboard',
  '/camera-roll-scan',
  '/ai-deepfake-detection',
  '/first-date-question-deck',
  '/relationship-prediction',
  '/virtual-speed-dating',
  '/group-meetups',
  '/event-planning-dashboard',
  '/human-matchmaker',
  '/travel-mode',
  '/advanced-ai-discovery',
  '/astrology-matching',
  '/friendship-mode',
  '/professional-networking',
  '/community-filters',
  '/business-networking',
  '/ai-group-dating-rooms',
  '/community-events',
];

const _visibilityAuditRoutes = [
  '/profile',
  '/settings',
  '/profile-settings',
  '/notifications',
  '/onboarding',
  '/faq-support',
  '/subscription',
  '/payment',
  '/safety-privacy',
  '/notification-preferences',
  '/browse',
  '/profile-detail',
  '/referral-leaderboard',
];

const _hiddenLabels = [
  'Accessibility',
  'SOS',
  'AI Coach',
  'AI Dating Coach',
  'Offline Mode',
  'Trusted Contacts',
  'Data Export',
  'Download My Data',
  'Language Selection',
  'Wallet',
  'Date Spots',
  'Refer & Earn',
  'Refer and Earn',
  'Liveness',
  'Admin Panel',
  'Admin Dashboard',
  'Host Dashboard',
  'Voice Prompt',
  'Video Prompt',
  'AI relationship ecosystem',
  'Open Modules',
  'Phase 2+3',
  'Question Deck',
];

void main() {
  testWidgets('AMORAA launches through its splash into Login', (tester) async {
    AmoraSession.logOut();
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Preparing your compatibility engine'), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byKey(const ValueKey('login-email-field')), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('profile information keeps all questions on one page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacementNamed('/profile-setup');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tell us about yourself'), findsOneWidget);
    expect(find.text('Gender'), findsWidgets);
    expect(find.text('Date of birth'), findsWidgets);
    expect(find.text('Preferred gender'), findsWidgets);
    expect(find.text('City'), findsWidgets);

    final continueButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(continueButton.onPressed, isNull);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Select your gender'), findsWidgets);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Select a preferred gender'), findsOneWidget);
    expect(find.text('City is required'), findsOneWidget);
  });

  testWidgets('login continues to the existing profile onboarding flow', (
    tester,
  ) async {
    AmoraSession.logOut();
    addTearDown(AmoraSession.logOut);
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacementNamed('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextFormField).at(0), 'member@amora.ai');
    await tester.enterText(find.byType(TextFormField).at(1), 'Amora123!');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text("When's your birthday?"), findsOneWidget);
    expect(find.text('Step 1 of 6'), findsOneWidget);
  });

  testWidgets('signup opens email verification before profile onboarding', (
    tester,
  ) async {
    AmoraSession.logOut();
    addTearDown(AmoraSession.logOut);
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushReplacementNamed('/signup');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'AMORAA Member');
    await tester.enterText(fields.at(1), 'new.member@amora.ai');
    await tester.enterText(fields.at(2), '9876543210');
    await tester.enterText(fields.at(3), 'Amora123!');
    await tester.enterText(fields.at(4), 'Amora123!');

    final checkboxes = find.byType(Checkbox);
    await tester.ensureVisible(checkboxes.at(0));
    await tester.tap(checkboxes.at(0));
    await tester.ensureVisible(find.text('Create account'));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('new.member@amora.ai'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-verification-otp')),
      findsOneWidget,
    );
    expect(find.text("When's your birthday?"), findsNothing);
    expect(find.text('Step 1 of 6'), findsNothing);
  });

  testWidgets('hidden routes fall through to the Discover screen', (
    tester,
  ) async {
    AmoraSession.logOut();
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in _hiddenRoutes) {
      navigator.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byType(BrowseGridScreen),
        findsOneWidget,
        reason: '$route exposed a hidden screen',
      );
      expect(tester.takeException(), isNull, reason: '$route threw an error');
      navigator.pop();
      await tester.pump();
    }
  });

  testWidgets('hidden feature labels are absent from normal runtime screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in _visibilityAuditRoutes) {
      navigator.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (final label in _hiddenLabels) {
        expect(
          find.textContaining(
            RegExp(RegExp.escape(label), caseSensitive: false),
          ),
          findsNothing,
          reason: '$label remains visible on $route',
        );
      }
      expect(tester.takeException(), isNull, reason: '$route threw an error');
      navigator.pop();
      await tester.pump();
    }
  });

  testWidgets('all registered production routes build', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in _productionRoutes) {
      navigator.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull, reason: 'Route $route failed');
      navigator.pop();
      await tester.pump();
    }
  });

  testWidgets('all registered production routes build in dark mode', (
    tester,
  ) async {
    AmoraThemeController.instance.update(ThemeMode.dark);
    addTearDown(() => AmoraThemeController.instance.update(ThemeMode.system));
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in _productionRoutes) {
      navigator.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Dark-mode route $route failed',
      );
      navigator.pop();
      await tester.pump();
    }
  });

  testWidgets('primary journeys stay exception-free at supported widths', (
    tester,
  ) async {
    const sizes = [
      Size(320, 568),
      Size(360, 800),
      Size(375, 812),
      Size(390, 844),
      Size(412, 915),
      Size(430, 932),
      Size(600, 960),
      Size(768, 1024),
      Size(1024, 768),
      Size(1024, 1366),
    ];
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in sizes) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.takeException(),
        isNull,
        reason: '/browse failed at ${size.width.toInt()}px',
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      for (final route in _productionRoutes) {
        navigator.pushNamed(route);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        final exception = tester.takeException();
        if (exception != null) {
          fail(
            '$route failed at '
            '${size.width.toInt()}x${size.height.toInt()}\n'
            '$exception',
          );
        }
        navigator.pop();
        await tester.pump(const Duration(milliseconds: 500));
        final popException = tester.takeException();
        if (popException != null) {
          fail(
            '$route failed while closing at '
            '${size.width.toInt()}x${size.height.toInt()}\n'
            '${popException.toStringDeep()}',
          );
        }
      }
    }
  });

  testWidgets('all production routes support 1.3 text scale at 320 px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 250));

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    for (final route in _productionRoutes) {
      navigator.pushNamed(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Route $route failed at 320 px with 1.3 text scale',
      );
      navigator.pop();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.takeException(),
        isNull,
        reason: 'Route $route failed while closing at 1.3 text scale',
      );
    }
  });
}
