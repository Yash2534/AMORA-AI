import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/events_browse_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> loadEvidenceFonts() async {
    Future<ByteData> readFont(String path) async {
      final bytes = await File(path).readAsBytes();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    }

    final textLoader = FontLoader('QAEvidence')
      ..addFont(readFont(r'C:\Windows\Fonts\arial.ttf'));
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(
        readFont(
          r'C:\src\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
        ),
      );
    await Future.wait([textLoader.load(), iconLoader.load()]);
  }

  setUpAll(loadEvidenceFonts);

  Future<void> capture(
    WidgetTester tester, {
    required Widget screen,
    required Size size,
    required String fileName,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    final baseTheme = AmoraTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(fontFamily: 'QAEvidence'),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            fontFamily: 'QAEvidence',
          ),
        ),
        home: screen,
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    for (var index = 0; index < 5; index++) {
      await tester.pump(const Duration(milliseconds: 220));
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/qa_evidence/$fileName'),
    );
  }

  testWidgets('capture authentication mobile evidence', (tester) async {
    await capture(
      tester,
      screen: const LoginScreen(),
      size: const Size(390, 844),
      fileName: 'EV-UI-001_auth_mobile.png',
    );
  });

  testWidgets('capture discover mobile evidence', (tester) async {
    await capture(
      tester,
      screen: const BrowseGridScreen(showNavigation: false),
      size: const Size(390, 844),
      fileName: 'EV-UI-002_discover_mobile.png',
    );
  });

  testWidgets('capture events mobile evidence', (tester) async {
    await capture(
      tester,
      screen: const EventsBrowseScreen(showNavigation: false),
      size: const Size(390, 844),
      fileName: 'EV-UI-003_events_mobile.png',
    );
  });

  testWidgets('capture event detail mobile evidence', (tester) async {
    await capture(
      tester,
      screen: const EventDetailScreen(),
      size: const Size(390, 844),
      fileName: 'EV-UI-004_event_detail_mobile.png',
    );
  });

  testWidgets('capture profile mobile evidence', (tester) async {
    await capture(
      tester,
      screen: const ProfileScreen(showNavigation: false),
      size: const Size(390, 844),
      fileName: 'EV-UI-005_profile_mobile.png',
    );
  });

  testWidgets('capture AI Matches selector evidence', (tester) async {
    await capture(
      tester,
      screen: const MatchesScreen(showNavigation: false),
      size: const Size(390, 844),
      fileName: 'EV-UI-008_ai_matches_mobile.png',
    );
  });

  testWidgets('capture global switch states evidence', (tester) async {
    await capture(
      tester,
      screen: const NotificationPreferencesScreen(),
      size: const Size(390, 844),
      fileName: 'EV-UI-009_switch_states_mobile.png',
    );
  });

  testWidgets('capture FAQ support mobile evidence', (tester) async {
    await capture(
      tester,
      screen: FaqSupportScreen(launchEmail: (_) async => true),
      size: const Size(390, 844),
      fileName: 'EV-UI-006_faq_support_mobile.png',
    );
  });

  testWidgets('capture events desktop evidence', (tester) async {
    await capture(
      tester,
      screen: const EventsBrowseScreen(showNavigation: false),
      size: const Size(1280, 900),
      fileName: 'EV-UI-007_events_desktop.png',
    );
  });
}
