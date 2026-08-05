import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Rect rectFor(Element element) {
    final box = element.renderObject! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> pumpMainShell(
    WidgetTester tester, {
    double width = 320,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const MainShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();
  }

  testWidgets('all five main pages use the same header geometry', (
    tester,
  ) async {
    await pumpMainShell(tester);

    final headers = find.byType(AmoraaMainPageHeader, skipOffstage: false);
    expect(headers, findsNWidgets(5));

    final rects = headers.evaluate().map(rectFor).toList(growable: false);
    final headerContext = tester.element(headers.first);
    expect(
      AmoraaMainPageHeader.sliverExtentFor(headerContext) -
          AmoraaMainPageHeader.heightFor(headerContext),
      AmoraaMainPageHeader.safeTopSpacing,
    );
    expect(AmoraaMainPageHeader.contentSpacing, inInclusiveRange(8, 12));
    for (final rect in rects) {
      expect(rect.left, closeTo(AmoraaMainPageHeader.pageHorizontalInset, .1));
      expect(rect.right, closeTo(304, .1));
      expect(rect.top, AmoraaMainPageHeader.safeTopSpacing);
      expect(
        rect.height,
        AmoraaMainPageHeader.heightFor(tester.element(headers.first)),
      );
      expect(rect.height, AmoraaMainPageHeader.compactHeight);
    }

    final actions = find.byType(
      AmoraaMainPageHeaderAction,
      skipOffstage: false,
    );
    expect(actions, findsNWidgets(7));
    for (final element in actions.evaluate()) {
      expect(
        rectFor(element).size,
        const Size.square(AmoraaMainPageHeader.actionSize),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('main page titles and subtitles use shared type tokens', (
    tester,
  ) async {
    await pumpMainShell(tester, width: 430);

    final titleFinders = <Finder>[
      find.descendant(
        of: find.byType(ChatsAppBar, skipOffstage: false),
        matching: find.text('Chats', skipOffstage: false),
      ),
      find.descendant(
        of: find.byType(AiMatchesAppBar, skipOffstage: false),
        matching: find.text('AI Matches', skipOffstage: false),
      ),
      find.descendant(
        of: find.byType(EventsAppBar, skipOffstage: false),
        matching: find.text('Events', skipOffstage: false),
      ),
      find.text('My Dating Identity', skipOffstage: false),
    ];
    for (final finder in titleFinders) {
      expect(
        tester.widget<Text>(finder).style,
        AmoraaMainPageHeader.titleStyle,
      );
    }

    for (final subtitle in <String>[
      'Your conversations',
      'Curated for you',
      'Meaningful ways to meet',
      'Your dating identity',
    ]) {
      expect(
        tester.widget<Text>(find.text(subtitle, skipOffstage: false)).style,
        AmoraaMainPageHeader.subtitleStyle,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('headers remain aligned and overflow-free at 1.3 text scale', (
    tester,
  ) async {
    await pumpMainShell(tester, textScale: 1.3);

    final headers = find.byType(AmoraaMainPageHeader, skipOffstage: false);
    expect(headers, findsNWidgets(5));
    for (final rect in headers.evaluate().map(rectFor)) {
      expect(rect.left, closeTo(AmoraaMainPageHeader.pageHorizontalInset, .1));
      expect(rect.right, closeTo(304, .1));
      expect(rect.height, AmoraaMainPageHeader.scaledHeight);
    }
    expect(
      find.byKey(const ValueKey('discover-notifications'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chats-compose-action'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('events-my-events-button'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('profile-settings-button'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('headers are transparent and actions keep 48 dp targets', (
    tester,
  ) async {
    await pumpMainShell(tester, width: 390);

    final headers = find.byType(AmoraaMainPageHeader, skipOffstage: false);
    for (final header in headers.evaluate()) {
      expect(
        find.descendant(
          of: find.byElementPredicate(
            (element) => identical(element, header),
            skipOffstage: false,
          ),
          matching: find.byType(DecoratedBox, skipOffstage: false),
        ),
        findsNothing,
      );
    }

    final actions = find.byType(
      AmoraaMainPageHeaderAction,
      skipOffstage: false,
    );
    for (final element in actions.evaluate()) {
      expect(
        rectFor(element).size,
        const Size.square(AmoraaMainPageHeader.actionSize),
      );
      final iconButton = tester.widget<IconButton>(
        find.descendant(
          of: find.byElementPredicate(
            (candidate) => identical(candidate, element),
            skipOffstage: false,
          ),
          matching: find.byType(IconButton, skipOffstage: false),
        ),
      );
      expect(
        iconButton.style?.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.transparent,
      );
      expect(iconButton.style?.side, isNull);
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byElementPredicate(
                  (candidate) => identical(candidate, element),
                  skipOffstage: false,
                ),
                matching: find.byType(Icon, skipOffstage: false),
              ),
            )
            .size,
        AmoraaMainPageHeader.actionIconSize,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact headers fit every supported width and text scale', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768, 1024]) {
      for (final textScale in <double>[1, 1.15, 1.3]) {
        await pumpMainShell(tester, width: width, textScale: textScale);

        final headers = find.byType(AmoraaMainPageHeader, skipOffstage: false);
        expect(headers, findsNWidgets(5));
        final context = tester.element(headers.first);
        for (final rect in headers.evaluate().map(rectFor)) {
          expect(
            rect.height,
            AmoraaMainPageHeader.heightFor(context),
            reason: 'Header height at $width px and ${textScale}x text scale',
          );
          expect(rect.height, lessThanOrEqualTo(70));
        }
        expect(
          tester.takeException(),
          isNull,
          reason: 'Header overflow at $width px and ${textScale}x text scale',
        );
      }
    }
  });
}
