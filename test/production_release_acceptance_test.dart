import 'dart:io';

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(430, 900),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: screen),
    );
    await tester.pumpAndSettle();
  }

  test('removed authentication flows have no files or active routes', () {
    expect(
      File(
        'lib/features/landing/presentation/amora_landing_screen.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'lib/features/auth/presentation/amora_auth_screen.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File('lib/features/auth/presentation/phone_otp_screen.dart').existsSync(),
      isFalse,
    );

    final mainSource = File('lib/main.dart').readAsStringSync();
    expect(mainSource, isNot(contains('/landing')));
    expect(mainSource, isNot(contains('/phone-login')));
    expect(mainSource, isNot(contains('/phone-otp')));
  });

  testWidgets('Profile Settings owns managed profiles and Membership', (
    tester,
  ) async {
    await pumpScreen(tester, const ProfileSettingsScreen());

    expect(find.text('Saved Profiles'), findsOneWidget);
    expect(find.text('Blocked Profiles'), findsOneWidget);
    expect(find.text('Membership'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile Completion summarizes required identity details', (
    tester,
  ) async {
    await pumpScreen(tester, const ProfileCompletionScreen());

    final identitySection = find.byKey(
      const ValueKey('completion-section-identityDetails'),
    );
    await tester.scrollUntilVisible(
      identitySection,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(identitySection);
    await tester.pumpAndSettle();
    expect(find.text('Height, Languages & Religion'), findsOneWidget);
    expect(find.textContaining('details remain'), findsWidgets);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Children'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Photo Manager uses one horizontal reorderable gallery', (
    tester,
  ) async {
    await pumpScreen(tester, const PhotoManagerScreen());

    expect(
      find.byKey(const ValueKey('horizontal-photo-gallery')),
      findsOneWidget,
    );
    final gallery = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    expect(gallery.scrollDirection, Axis.horizontal);
    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notification Preferences renders grouped premium controls', (
    tester,
  ) async {
    await pumpScreen(tester, const NotificationPreferencesScreen());

    expect(find.text('What you hear about'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Delivery channels'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Delivery channels'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Quiet hours'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Quiet hours'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
