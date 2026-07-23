import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/main.dart';

const _productionRoutes = [
  '/advanced-ai-discovery',
  '/ai-deepfake-detection',
  '/ai-group-dating-rooms',
  '/ai-learning-dashboard',
  '/ai-icebreakers',
  '/astrology-matching',
  '/auth',
  '/account-verification',
  '/bio-builder',
  '/browse',
  '/business-networking',
  '/camera-roll-scan',
  '/chat-detail',
  '/chats',
  '/compatibility',
  '/community-events',
  '/community-filters',
  '/dark-mode-settings',
  '/dating-recap',
  '/dealbreakers',
  '/discover',
  '/event-detail',
  '/event-group-chat',
  '/event-planning-dashboard',
  '/event-waitlist',
  '/events',
  '/faq-support',
  '/filters',
  '/first-date-question-deck',
  '/friendship-mode',
  '/gift-shop-catalog',
  '/group-meetups',
  '/human-matchmaker',
  '/kyc',
  '/landing',
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
  '/phone-login',
  '/photo-manager',
  '/poll-prompts',
  '/post-event-feedback',
  '/professional-networking',
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
  '/relationship-ecosystem',
  '/relationship-prediction',
  '/report-flow',
  '/safety-privacy',
  '/send-gift',
  '/settings',
  '/shared-media-gallery',
  '/signup',
  '/splash',
  '/stories',
  '/subscription',
  '/success-stories',
  '/super-like',
  '/ticket-booking',
  '/twenty-questions',
  '/travel-mode',
  '/video-speed-dating-room',
  '/virtual-speed-dating',
  '/why-we-matched',
];

const _hiddenRoutes = [
  '/accessibility-settings',
  '/sos-checkin',
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
  '/ticket-booking',
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
];

void main() {
<<<<<<< HEAD
  testWidgets('AMORA AI begins with Sign In or Create Account', (tester) async {
=======
  testWidgets('AMORA AI launches through splash into authentication', (
    tester,
  ) async {
>>>>>>> main
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 500));

<<<<<<< HEAD
    expect(find.byKey(const Key('auth-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('auth-create-account')), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
=======
    expect(find.text('Preparing your compatibility engine'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome to AMORA AI'), findsOneWidget);
    expect(find.text('Create a new account'), findsOneWidget);
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
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Date of birth'), findsWidgets);
    expect(find.text('Preferred gender'), findsOneWidget);
    expect(find.text('City'), findsWidgets);

    final continueButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(continueButton.onPressed, isNull);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Select your gender'), findsOneWidget);
    expect(find.text('Select your date of birth'), findsOneWidget);
    expect(find.text('Select a preferred gender'), findsOneWidget);
    expect(find.text('City is required'), findsOneWidget);
  });

  testWidgets('login continues through profile information to Discover', (
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
    await tester.ensureVisible(find.text('Log in'));
    await tester.pump();
    await tester.tap(find.text('Log in'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Tell us about yourself'), findsOneWidget);

    await tester.tap(find.text('Man'));
    await tester.ensureVisible(find.byIcon(Icons.calendar_month_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('${DateTime.now().year - 24}').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Women'));
    await tester.pump();
    await tester.tap(find.text('Women'));
    await tester.ensureVisible(find.byType(TextFormField).last);
    await tester.enterText(find.byType(TextFormField).last, '  Ahmedabad  ');
    await tester.ensureVisible(find.text('Continue'));
    await tester.pump();

    final continueButton = tester.widget<FilledButton>(
      find.byType(FilledButton),
    );
    expect(continueButton.onPressed, isNotNull);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(BrowseGridScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('discover-search-field')), findsOneWidget);
  });

  testWidgets('signup continues to the four-question profile screen', (
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
    await tester.enterText(fields.at(0), 'Amora Member');
    await tester.enterText(fields.at(1), 'new.member@amora.ai');
    await tester.enterText(fields.at(2), '9876543210');
    await tester.enterText(fields.at(3), 'Amora123!');
    await tester.enterText(fields.at(4), 'Amora123!');

    final checkboxes = find.byType(Checkbox);
    await tester.ensureVisible(checkboxes.at(0));
    await tester.tap(checkboxes.at(0));
    await tester.ensureVisible(checkboxes.at(1));
    await tester.tap(checkboxes.at(1));
    await tester.ensureVisible(find.text('Create account'));
    await tester.pump();
    await tester.tap(find.text('Create account'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Tell us about yourself'), findsOneWidget);
    expect(find.text('Preferred gender'), findsOneWidget);
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
>>>>>>> main
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
<<<<<<< HEAD
        reason: '/home failed at ${size.width.toInt()}x${size.height.toInt()}',
=======
        reason: '/browse failed at ${width.toInt()}px',
>>>>>>> main
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
}
