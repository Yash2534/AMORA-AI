import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required String title,
    String? subtitle,
    double width = 320,
    double textScale = 1,
    int actionCount = 1,
    bool useAmoraTheme = true,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: useAmoraTheme ? AmoraTheme.light() : null,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          appBar: AmoraAppBar(
            title: title,
            subtitle: subtitle,
            onBack: () {},
            actions: [
              for (var index = 0; index < actionCount; index++)
                AmoraHeaderActionButton(
                  tooltip: index == 0 ? 'More' : 'Action $index',
                  icon: index == 0
                      ? Icons.mark_email_read_rounded
                      : Icons.settings_rounded,
                  onPressed: () {},
                ),
            ],
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shared secondary header uses the main header type scale', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      title: 'Profile settings',
      subtitle: 'Manage your AMORAA account',
    );

    final appBar = tester.widget<AmoraAppBar>(find.byType(AmoraAppBar));
    expect(appBar.preferredSize.height, AmoraHeaderTokens.titleSubtitleHeight);
    expect(
      tester.widget<Text>(find.text('Profile settings')).style,
      AmoraTextStyles.pageHeaderTitle,
    );
    expect(
      tester.widget<Text>(find.text('Manage your AMORAA account')).style,
      AmoraTextStyles.pageHeaderSubtitle,
    );
    final backIconButton = find.descendant(
      of: find.byType(AmoraHeaderBackButton),
      matching: find.byType(IconButton),
    );
    expect(tester.getSize(backIconButton), const Size.square(48));
    expect(
      tester.getSize(find.byType(AmoraHeaderActionButton)),
      const Size.square(AmoraHeaderTokens.touchTarget),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-line headers remain compact and usable at 1.3x scale', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      title: 'A deliberately long profile settings title',
      textScale: 1.3,
    );

    final appBar = tester.widget<AmoraAppBar>(find.byType(AmoraAppBar));
    expect(appBar.preferredSize.height, AmoraHeaderTokens.singleLineHeight);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('More'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default AppBar theme shares compact secondary-header tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Appearance'),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
            ],
          ),
        ),
      ),
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.preferredSize.height, AmoraSpacing.appBarHeight);
    final appBarTheme = Theme.of(
      tester.element(find.byType(AppBar)),
    ).appBarTheme;
    expect(appBarTheme.titleSpacing, AmoraSpacing.space20);
    expect(appBarTheme.titleTextStyle, AmoraTextStyles.pageHeaderTitle);
    expect(appBarTheme.iconTheme?.size, 20);
    expect(appBarTheme.actionsIconTheme?.size, 20);
  });

  testWidgets('subtitle title block uses the shared header tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: const Scaffold(
          body: AmoraScreenTitle(
            title: 'Profile Completion',
            subtitle: 'Your progress dashboard',
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Profile Completion')).style,
      AmoraTextStyles.pageHeaderTitle,
    );
    expect(
      tester.widget<Text>(find.text('Your progress dashboard')).style,
      AmoraTextStyles.pageHeaderSubtitle,
    );
  });

  testWidgets('secondary headers stay overflow-free at supported widths', (
    tester,
  ) async {
    for (final width in <double>[320, 360, 390, 412, 430, 600, 768]) {
      for (final scale in <double>[1, 1.15, 1.3]) {
        await pumpHeader(
          tester,
          title: 'Notification Preferences',
          subtitle: 'Stay informed without the noise.',
          width: width,
          textScale: scale,
        );
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(find.byTooltip('More'), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Secondary header overflow at $width px and ${scale}x',
        );
      }
    }
  });

  testWidgets('secondary headers align to the responsive content grid', (
    tester,
  ) async {
    for (final width in <double>[320, 390, 430, 600, 768]) {
      await pumpHeader(
        tester,
        title: 'Notification Preferences',
        subtitle: 'Stay informed without the noise.',
        width: width,
      );

      final frameWidth = width < 460 ? width : 460.0;
      final frameLeft = (width - frameWidth) / 2;
      final expectedLeft = frameLeft + AmoraHeaderTokens.contentHorizontalInset;
      final expectedRight =
          frameLeft + frameWidth - AmoraHeaderTokens.contentHorizontalInset;
      final back = tester.getRect(find.byType(AmoraHeaderBackButton));
      final action = tester.getRect(find.byType(AmoraHeaderActionButton));
      final title = tester.getRect(find.text('Notification Preferences'));

      expect(back.left, closeTo(expectedLeft, .1));
      expect(action.right, closeTo(expectedRight, .1));
      expect(
        title.left,
        closeTo(back.right + AmoraHeaderTokens.backTitleGap, .1),
      );
      expect(back.center.dy, closeTo(action.center.dy, .1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('two-action headers fit compact scaled layouts', (tester) async {
    await pumpHeader(
      tester,
      title: 'Notifications',
      width: 320,
      textScale: 1.3,
      actionCount: 2,
      useAmoraTheme: false,
    );

    expect(find.byType(AmoraHeaderActionButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
