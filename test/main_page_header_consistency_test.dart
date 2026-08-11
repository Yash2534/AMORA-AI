import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Rect rectFor(Element element) {
    final box = element.renderObject! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Element contentRowFor(Element header) {
    Element? row;
    header.visitChildElements((child) {
      void visit(Element element) {
        if (row != null) return;
        if (element.widget is Row) {
          row = element;
          return;
        }
        element.visitChildElements(visit);
      }

      visit(child);
    });
    return row!;
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

    final headerContext = tester.element(headers.first);
    expect(
      AmoraaMainPageHeader.sliverExtentFor(headerContext) -
          AmoraaMainPageHeader.toolbarHeightFor(headerContext),
      AmoraaMainPageHeader.safeTopSpacing,
    );
    expect(AmoraaMainPageHeader.contentSpacing, 8);
    expect(AmoraaMainPageHeader.contentHorizontalInset, 20);
    for (final header in headers.evaluate()) {
      final rect = rectFor(header);
      final contentRect = rectFor(contentRowFor(header));
      expect(rect.left, 0);
      expect(rect.right, 320);
      expect(rect.top, 0);
      expect(
        rect.height,
        AmoraaMainPageHeader.extentFor(tester.element(headers.first)),
      );
      expect(contentRect.left, AmoraaMainPageHeader.contentHorizontalInset);
      expect(
        contentRect.right,
        320 - AmoraaMainPageHeader.contentHorizontalInset,
      );
      expect(contentRect.top, AmoraaMainPageHeader.safeTopSpacing);
      expect(contentRect.height, AmoraaMainPageHeader.compactHeight);
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

  testWidgets('Discover wordmark is moderately larger within shared bounds', (
    tester,
  ) async {
    await pumpMainShell(tester, width: 320);

    final logo = find.descendant(
      of: find.byType(AmoraaMainPageHeader, skipOffstage: false),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.width == AmoraHeaderTokens.discoverLogoWidth &&
            widget.height == AmoraHeaderTokens.discoverLogoHeight &&
            widget.fit == BoxFit.contain,
        skipOffstage: false,
      ),
    );
    expect(logo, findsOneWidget);
    expect(
      tester.getSize(logo),
      const Size(
        AmoraHeaderTokens.discoverLogoWidth,
        AmoraHeaderTokens.discoverLogoHeight,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('main page titles use one token without redundant subtitles', (
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
      find.descendant(
        of: find.byType(AmoraaMainPageHeader, skipOffstage: false),
        matching: find.text('Profile', skipOffstage: false),
      ),
    ];
    for (final finder in titleFinders) {
      expect(
        tester.widget<Text>(finder).style,
        AmoraaMainPageHeader.titleStyle,
      );
    }

    for (final redundantSubtitle in <String>[
      'Your conversations',
      'Curated for you',
      'Meaningful ways to meet',
      'Your dating identity',
    ]) {
      expect(find.text(redundantSubtitle, skipOffstage: false), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('headers remain aligned and overflow-free at 1.3 text scale', (
    tester,
  ) async {
    await pumpMainShell(tester, textScale: 1.3);

    final headers = find.byType(AmoraaMainPageHeader, skipOffstage: false);
    expect(headers, findsNWidgets(5));
    for (final header in headers.evaluate()) {
      final rect = rectFor(header);
      final contentRect = rectFor(contentRowFor(header));
      expect(rect.left, 0);
      expect(rect.right, 320);
      expect(
        rect.height,
        AmoraaMainPageHeader.scaledHeight + AmoraaMainPageHeader.safeTopSpacing,
      );
      expect(contentRect.left, AmoraaMainPageHeader.contentHorizontalInset);
      expect(contentRect.height, AmoraaMainPageHeader.scaledHeight);
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

  testWidgets('main-page body controls share the header content line', (
    tester,
  ) async {
    await pumpMainShell(tester, width: 320);

    for (final finder in <Finder>[
      find.byKey(const ValueKey('discover-filter-rail'), skipOffstage: false),
      find.byKey(const ValueKey('chats-search-container'), skipOffstage: false),
      find.byType(ProfileHero, skipOffstage: false),
    ]) {
      expect(finder, findsOneWidget);
      expect(
        tester.getRect(finder).left,
        closeTo(AmoraaMainPageHeader.contentHorizontalInset, .1),
      );
    }
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
        final headerElements = headers.evaluate().toList(growable: false);
        for (final rect in headerElements.map(rectFor)) {
          expect(
            rect.height,
            AmoraaMainPageHeader.extentFor(context),
            reason: 'Header height at $width px and ${textScale}x text scale',
          );
          expect(rect.height, lessThanOrEqualTo(60));
        }
        const internalInset = AmoraaMainPageHeader.contentHorizontalInset;
        for (final header in headerElements) {
          final headerRect = rectFor(header);
          final contentRect = rectFor(contentRowFor(header));
          expect(
            contentRect.left,
            closeTo(headerRect.left + internalInset, .1),
          );
          expect(
            contentRect.right,
            closeTo(headerRect.right - internalInset, .1),
          );
          expect(
            contentRect.width,
            closeTo(headerRect.width - (internalInset * 2), .1),
          );
        }
        final actionCenters = find
            .byType(AmoraaMainPageHeaderAction, skipOffstage: false)
            .evaluate()
            .map(rectFor)
            .map((rect) => rect.center.dy)
            .toSet();
        expect(actionCenters, hasLength(1));
        expect(
          tester.takeException(),
          isNull,
          reason: 'Header overflow at $width px and ${textScale}x text scale',
        );
      }
    }
  });

  testWidgets('each main header has exactly one SafeArea ancestor', (
    tester,
  ) async {
    await pumpMainShell(tester, width: 430);

    final headers = find.byType(AmoraaMainPageHeader, skipOffstage: false);
    for (final header in headers.evaluate()) {
      var safeAreaAncestors = 0;
      header.visitAncestorElements((ancestor) {
        if (ancestor.widget is SafeArea) safeAreaAncestors++;
        return true;
      });
      expect(safeAreaAncestors, 1);
    }
  });
}
