import 'dart:io';
import 'dart:math' as math;

import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_badge.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('approved AMORA_AI 2027 brand colors remain exact', () {
    expect(AppColors.primary, const Color(0xFF3D0B3F));
    expect(AppColors.secondary, const Color(0xFFEC5FA8));
    expect(AppColors.tertiary, const Color(0xFFF4A9CE));
    expect(AppColors.background, const Color(0xFFFDF1F7));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.textPrimary, const Color(0xFF2B2B2B));
  });

  test('Material states use the semantic brand hierarchy', () {
    final theme = AmoraTheme.light();
    final filled = theme.filledButtonTheme.style!;
    final nav = theme.navigationBarTheme;

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.secondary, AppColors.secondary);
    expect(theme.colorScheme.tertiary, AppColors.tertiary);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(filled.backgroundColor?.resolve({}), AppColors.primary);
    expect(filled.foregroundColor?.resolve({}), AppColors.onPrimary);
    expect(nav.indicatorColor, AppColors.activeContainer);
    expect(theme.progressIndicatorTheme.color, AppColors.active);
    expect(theme.tabBarTheme.labelColor, AppColors.active);
    expect(theme.chipTheme.selectedColor, AppColors.activeContainer);
    expect(
      theme.switchTheme.trackColor?.resolve({WidgetState.selected}),
      AppColors.active,
    );
    expect(theme.dialogTheme.backgroundColor, AppColors.surface);
    expect(theme.bottomSheetTheme.backgroundColor, AppColors.surface);
    expect(
      theme.inputDecorationTheme.focusedBorder,
      const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: AppColors.focus, width: 2),
      ),
    );
  });

  testWidgets(
    'secondary action, badges, and compact navigation stay on-brand',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AmoraTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                AppPrimaryButton(
                  label: 'Secondary action',
                  variant: AppPrimaryButtonVariant.tonal,
                  onPressed: () {},
                ),
                const Wrap(
                  children: [
                    AmoraBadge.premiumVerified(),
                    AmoraBadge.verified3d(),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: const FloatingBottomNav(
              activeTab: AmoraNavTab.discover,
            ),
          ),
        ),
      );

      final secondary = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(
        secondary.style?.backgroundColor?.resolve({}),
        AppColors.secondary,
      );
      expect(
        secondary.style?.foregroundColor?.resolve({}),
        AppColors.onSecondary,
      );
      final activeLabel = tester.widget<Text>(find.text('Discover'));
      expect(activeLabel.style?.color, AppColors.active);
      expect(find.text('Premium Verified'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('core palette combinations meet their required contrast thresholds', () {
    expect(_contrast(AppColors.onPrimary, AppColors.primary), greaterThan(4.5));
    expect(
      _contrast(AppColors.onSecondary, AppColors.secondary),
      greaterThan(3),
      reason:
          'The approved secondary accent is reserved for emphasized UI and '
          'large labels; body text continues to use the 4.5:1 combinations.',
    );
    expect(
      _contrast(AppColors.textPrimary, AppColors.background),
      greaterThan(4.5),
    );
    expect(
      _contrast(AppColors.textSecondary, AppColors.surface),
      greaterThan(4.5),
    );
  });

  test('feature code contains no raw Flutter color literals', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('app_colors.dart'));
    final rawHex = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
    final materialColor = RegExp(r'(?<!App)Colors\.[A-Za-z]+');

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(rawHex.hasMatch(source), isFalse, reason: file.path);
      expect(materialColor.hasMatch(source), isFalse, reason: file.path);
    }
  });
}

double _contrast(Color foreground, Color background) {
  final lighter = _luminance(foreground).clamp(0.0, 1.0);
  final darker = _luminance(background).clamp(0.0, 1.0);
  final high = lighter > darker ? lighter : darker;
  final low = lighter > darker ? darker : lighter;
  return (high + .05) / (low + .05);
}

double _luminance(Color color) {
  double channel(int value) {
    final normalized = value / 255;
    return normalized <= .04045
        ? normalized / 12.92
        : math.pow((normalized + .055) / 1.055, 2.4).toDouble();
  }

  final argb = color.toARGB32();
  return .2126 * channel((argb >> 16) & 0xFF) +
      .7152 * channel((argb >> 8) & 0xFF) +
      .0722 * channel(argb & 0xFF);
}
