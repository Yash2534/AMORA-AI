import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary navigation preserves the five approved destinations', () {
    expect(FloatingBottomNav.items, hasLength(5));
    expect(
      FloatingBottomNav.items.map((item) => item.label),
      orderedEquals(['Discover', 'Chats', 'AI Matches', 'Events', 'Profile']),
    );
  });

  testWidgets('main shell remains responsive at compact phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: AmoraTheme.light(), home: const MainShell()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingBottomNav), findsOneWidget);
    expect(find.text('Discover'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
