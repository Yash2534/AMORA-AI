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
    final shellScaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(shellScaffold.extendBody, isTrue);
    final contentMedia = tester.widget<MediaQuery>(
      find.byKey(const ValueKey('main-shell-navigation-content-inset')),
    );
    expect(
      contentMedia.data.padding.bottom,
      greaterThanOrEqualTo(FloatingBottomNav.contentBottomPadding),
    );

    for (final destination in <(String, String)>[
      ('Chats', 'Your conversations'),
      ('AI Matches', 'Curated for you'),
      ('Events', 'Meaningful ways to meet'),
      ('Profile', 'Your dating identity'),
    ]) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-${destination.$1}')));
      await tester.pumpAndSettle();
      expect(find.text(destination.$2), findsOneWidget);
      expect(find.byType(FloatingBottomNav), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
