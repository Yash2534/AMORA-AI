import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary navigation contains the four visible destinations', () {
    expect(FloatingBottomNav.items, hasLength(4));
    expect(
      FloatingBottomNav.items.map((item) => item.label),
      orderedEquals(['Discover', 'Chats', 'AI Matches', 'Profile']),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

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

    const destinations = <String, String>{
      'Chats': 'Chats',
      'AI Matches': 'AI Matches',
      'Profile': 'Profile',
    };
    for (final entry in destinations.entries) {
      final destination = entry.key;
      await tester.tap(find.byKey(ValueKey('bottom-nav-$destination')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      if (destination == 'Chats') {
        expect(
          find.descendant(
            of: find.byType(ChatsAppBar),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
      } else {
        expect(
          find.descendant(
            of: find.byType(AmoraaMainPageHeader),
            matching: find.text(entry.value),
          ),
          findsOneWidget,
        );
      }
      expect(find.byType(FloatingBottomNav), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('bottom-nav-Events')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
