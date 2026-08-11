import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
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
    final contentMedia = MediaQuery.of(
      tester.element(find.byType(BrowseGridScreen)),
    );
    expect(
      contentMedia.padding.bottom,
      FloatingBottomNav.barHeight + FloatingBottomNav.minimumBottomSpacing,
    );

    for (final destination in <String>[
      'Chats',
      'AI Matches',
      'Events',
      'Profile',
    ]) {
      await tester.tap(find.byKey(ValueKey('bottom-nav-$destination')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AmoraaMainPageHeader),
          matching: find.text(destination),
        ),
        findsOneWidget,
      );
      expect(find.byType(FloatingBottomNav), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
