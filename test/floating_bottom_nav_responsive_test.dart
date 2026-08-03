import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpNavigation(
    WidgetTester tester, {
    required Size size,
    AmoraNavTab activeTab = AmoraNavTab.discover,
    ValueChanged<AmoraNavTab>? onTabSelected,
    double textScale = 1,
    double bottomInset = 0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: bottomInset),
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: FloatingBottomNav(
              activeTab: activeTab,
              onTabSelected: onTabSelected,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders five equal items at every supported viewport', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final expectedBarWidths = <Size, double>{
      Size(320, 640): 296,
      Size(360, 800): 328,
      Size(375, 812): 343,
      Size(390, 844): 358,
      Size(412, 915): 372,
      Size(430, 932): 382,
      Size(480, 932): 432,
      Size(600, 960): FloatingBottomNav.maxBarWidth,
      Size(768, 1024): FloatingBottomNav.maxBarWidth,
      Size(1024, 768): FloatingBottomNav.maxBarWidth,
      Size(844, 390): FloatingBottomNav.maxBarWidth,
    };

    for (final entry in expectedBarWidths.entries) {
      await pumpNavigation(tester, size: entry.key);

      expect(FloatingBottomNav.items, hasLength(5));
      expect(find.byType(InkWell), findsNWidgets(5));
      final barSize = tester.getSize(
        find.byKey(const ValueKey('floating-bottom-nav-bar')),
      );
      expect(barSize.height, FloatingBottomNav.barHeight);
      expect(barSize.width, closeTo(entry.value, .01));

      final itemSizes = <Size>[
        for (final item in FloatingBottomNav.items)
          tester.getSize(find.byKey(ValueKey('bottom-nav-${item.label}'))),
      ];
      expect(
        itemSizes.map((size) => size.width).toSet(),
        hasLength(1),
        reason: 'Items must remain equal at ${entry.key}.',
      );
      expect(
        itemSizes.every((size) => size.height == FloatingBottomNav.itemHeight),
        isTrue,
      );

      for (final item in FloatingBottomNav.items) {
        final labelFinder = find.byKey(
          ValueKey('bottom-nav-label-${item.label}'),
        );
        expect(labelFinder, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(labelFinder);
        expect(paragraph.maxLines, 1);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '${item.label} clipped at ${entry.key}.',
        );
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow at ${entry.key}',
      );
    }
  });

  testWidgets('S23 Ultra keeps the standard-phone visual dimensions', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpNavigation(tester, size: const Size(390, 844));
    final standardBar = tester.getSize(
      find.byKey(const ValueKey('floating-bottom-nav-bar')),
    );
    final standardIndicator = tester.getSize(
      find.byKey(const ValueKey('bottom-nav-indicator-Discover')),
    );
    final standardIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-nav-indicator-Discover')),
        matching: find.byType(Icon),
      ),
    );

    await pumpNavigation(tester, size: const Size(412, 915));
    final s23Bar = tester.getSize(
      find.byKey(const ValueKey('floating-bottom-nav-bar')),
    );
    final s23Indicator = tester.getSize(
      find.byKey(const ValueKey('bottom-nav-indicator-Discover')),
    );
    final s23Icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-nav-indicator-Discover')),
        matching: find.byType(Icon),
      ),
    );

    expect(s23Bar.height, standardBar.height);
    expect(s23Indicator, standardIndicator);
    expect(s23Icon.size, standardIcon.size);
    expect(s23Bar.width - standardBar.width, 14);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active tab uses the compact pill and rounded selected icon', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpNavigation(tester, size: const Size(390, 844));

    final selectedIndicatorFinder = find.byKey(
      const ValueKey('bottom-nav-indicator-Discover'),
    );
    final selectedIndicator = tester.widget<AnimatedContainer>(
      selectedIndicatorFinder,
    );
    final inactiveIndicator = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('bottom-nav-indicator-Chats')),
    );
    final selectedIcon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-nav-indicator-Discover')),
        matching: find.byType(Icon),
      ),
    );

    expect(
      tester.getSize(selectedIndicatorFinder),
      const Size(
        FloatingBottomNav.iconContainerWidth,
        FloatingBottomNav.iconContainerHeight,
      ),
    );
    expect(
      (selectedIndicator.decoration! as BoxDecoration).borderRadius,
      AmoraRadius.pillBorder,
    );
    expect(
      (inactiveIndicator.decoration! as BoxDecoration).color,
      AppColors.transparent,
    );
    expect(selectedIcon.icon, Icons.explore_rounded);
    expect(selectedIcon.size, FloatingBottomNav.selectedIconSize);
  });

  testWidgets('selection changes preserve geometry and callbacks', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var activeTab = AmoraNavTab.discover;
    var callbackCount = 0;
    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: FloatingBottomNav(
              activeTab: activeTab,
              onTabSelected: (tab) {
                callbackCount += 1;
                setState(() => activeTab = tab);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final beforeBar = tester.getRect(
      find.byKey(const ValueKey('floating-bottom-nav-bar')),
    );
    final beforeItems = <Rect>[
      for (final item in FloatingBottomNav.items)
        tester.getRect(find.byKey(ValueKey('bottom-nav-${item.label}'))),
    ];

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Chats')));
    await tester.pumpAndSettle();

    expect(activeTab, AmoraNavTab.chats);
    expect(callbackCount, 1);
    expect(
      tester.getRect(find.byKey(const ValueKey('floating-bottom-nav-bar'))),
      beforeBar,
    );
    final afterItems = <Rect>[
      for (final item in FloatingBottomNav.items)
        tester.getRect(find.byKey(ValueKey('bottom-nav-${item.label}'))),
    ];
    expect(afterItems, orderedEquals(beforeItems));

    await tester.tap(find.byKey(const ValueKey('bottom-nav-Chats')));
    await tester.pumpAndSettle();
    expect(callbackCount, 1, reason: 'The active tab remains a no-op.');

    final selectedSemantics = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where(
          (widget) =>
              widget.properties.label == 'Chats' &&
              widget.properties.selected == true,
        );
    expect(selectedSemantics, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SafeArea applies one controlled bottom inset', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpNavigation(tester, size: const Size(390, 844));
    final withoutSystemInset = tester.getSize(find.byType(FloatingBottomNav));

    await pumpNavigation(tester, size: const Size(390, 844), bottomInset: 34);
    final withSystemInset = tester.getSize(find.byType(FloatingBottomNav));

    expect(withoutSystemInset.height, FloatingBottomNav.barHeight + 8);
    expect(withSystemInset.height, FloatingBottomNav.barHeight + 34);
    expect(withSystemInset.height - withoutSystemInset.height, 26);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web keyboard focus activates tabs without changing layout', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    AmoraNavTab? selectedTab;
    await pumpNavigation(
      tester,
      size: const Size(768, 1024),
      onTabSelected: (tab) => selectedTab = tab,
    );
    final originalBar = tester.getRect(
      find.byKey(const ValueKey('floating-bottom-nav-bar')),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selectedTab, AmoraNavTab.chats);
    expect(
      tester.getRect(find.byKey(const ValueKey('floating-bottom-nav-bar'))),
      originalBar,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('supported text scaling keeps every label visible at 320px', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final textScale in <double>[1, 1.15, 1.3]) {
      await pumpNavigation(
        tester,
        size: const Size(320, 640),
        textScale: textScale,
      );

      for (final item in FloatingBottomNav.items) {
        final labelFinder = find.byKey(
          ValueKey('bottom-nav-label-${item.label}'),
        );
        expect(find.text(item.label), findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(labelFinder);
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '${item.label} clipped at $textScale text scale.',
        );
      }
      expect(
        tester.takeException(),
        isNull,
        reason: 'Text scale $textScale overflowed.',
      );
    }
  });
}
