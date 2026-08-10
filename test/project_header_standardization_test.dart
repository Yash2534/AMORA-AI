import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/features/events/presentation/event_waitlist_screen.dart';
import 'package:amora_ai/features/insights/presentation/dating_recap_screen.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/settings_support_widgets.dart';
import 'package:amora_ai/features/theme/presentation/dark_mode_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    double width = 320,
    double textScale = 1.3,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    );
    await tester.pump();
  }

  testWidgets('registered secondary routes use shared header primitives', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final screens = <Widget>[
      const DarkModeSettingsScreen(),
      const EventWaitlistScreen(),
      const DatingRecapScreen(),
      const NotificationPreferencesScreen(),
    ];

    for (final screen in screens) {
      await pumpScreen(tester, screen);
      expect(
        find.byType(AmoraHeaderBackButton),
        findsOneWidget,
        reason: '${screen.runtimeType} must use the shared back control',
      );
      expect(
        find.byType(AmoraAppBar).evaluate().isNotEmpty ||
            find.byType(AmoraScreenTitle).evaluate().isNotEmpty,
        isTrue,
        reason: '${screen.runtimeType} must use a shared title primitive',
      );
      expect(
        tester.getSize(
          find.descendant(
            of: find.byType(AmoraHeaderBackButton),
            matching: find.byType(IconButton),
          ),
        ),
        const Size.square(AmoraHeaderTokens.touchTarget),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${screen.runtimeType} overflowed at 320 px and 1.3x text',
      );
    }
  });

  testWidgets('feature headers share title typography and back geometry', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(320, 480));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SettingsHeader(
                    title: 'Safety settings',
                    subtitle: 'Private controls for your account',
                    icon: Icons.shield_outlined,
                    onBack: () {},
                  ),
                  const SizedBox(height: 24),
                  MonetizationHeader(
                    title: 'AI Coach',
                    subtitle: 'Thoughtful support for better conversations',
                    onBack: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AmoraHeaderBackButton), findsNWidgets(2));
    expect(find.byType(AmoraScreenTitle), findsNWidgets(2));
    for (final title in <String>['Safety settings', 'AI Coach']) {
      expect(
        tester.widget<Text>(find.text(title)).style,
        AmoraHeaderTokens.titleStyle,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
