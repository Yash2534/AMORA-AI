import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_badge.dart';
import 'package:amora_ai/core/widgets/amora_card.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semantic colors map directly into the Material 3 color scheme', () {
    const scheme = AmoraTheme.colorScheme;

    expect(scheme.primary, AppColors.primary);
    expect(scheme.onPrimary, AppColors.onPrimary);
    expect(scheme.surface, AppColors.surface);
    expect(scheme.onSurface, AppColors.onSurface);
    expect(scheme.error, AppColors.error);
    expect(scheme.outline, AppColors.outline);
  });

  testWidgets('shared controls preserve accessible touch targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AmoraTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: AmoraSpacing.screen,
            child: Column(
              children: [
                AppPrimaryButton(
                  key: const Key('primary-button'),
                  label: 'Continue',
                  onPressed: () {},
                ),
                IconButton(
                  key: const Key('icon-button'),
                  tooltip: 'Close',
                  onPressed: () {},
                  icon: const Icon(Icons.close_rounded),
                ),
                const AmoraCard(child: AmoraBadge.premium()),
              ],
            ),
          ),
        ),
      ),
    );

    final primarySize = tester.getSize(find.byKey(const Key('primary-button')));
    final iconSize = tester.getSize(find.byKey(const Key('icon-button')));

    expect(primarySize.height, AmoraSpacing.controlHeight);
    expect(
      iconSize.width,
      greaterThanOrEqualTo(AmoraSpacing.minimumTouchTarget),
    );
    expect(
      iconSize.height,
      greaterThanOrEqualTo(AmoraSpacing.minimumTouchTarget),
    );
    expect(tester.takeException(), isNull);
  });
}
