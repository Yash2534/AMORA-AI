import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int defaultCompatibilityThreshold = 70;

String compatibilityLabel(int percentage) {
  final score = percentage.clamp(0, 100);
  return switch (score) {
    >= 90 => 'Excellent Match',
    >= 80 => 'Highly Compatible',
    >= 70 => 'Great Match',
    >= 60 => 'Good Match',
    _ => 'Potential Match',
  };
}

class AmoraCompatibilitySlider extends StatefulWidget {
  const AmoraCompatibilitySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<AmoraCompatibilitySlider> createState() =>
      _AmoraCompatibilitySliderState();
}

class _AmoraCompatibilitySliderState extends State<AmoraCompatibilitySlider> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Minimum compatibility');
  int? _lastHapticStep;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final value = widget.value.clamp(0, 100);

    return Semantics(
      container: true,
      label: 'Minimum compatibility',
      value: '$value percent',
      child: Column(
        key: const ValueKey('compatibility-slider'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Match Filter',
                      style: AmoraTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space4),
                    Text(
                      'Choose the minimum compatibility you want to see.',
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: .72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AmoraSpacing.space12),
              AnimatedSwitcher(
                duration: duration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Text(
                  '$value% and above',
                  key: ValueKey(value),
                  style: AmoraTextStyles.titleSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space8),
          SizedBox(
            height: 56,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: AppColors.secondary,
                inactiveTrackColor: AppColors.tertiary,
                disabledActiveTrackColor: AppColors.tertiary,
                disabledInactiveTrackColor: AppColors.tertiary,
                thumbColor: AppColors.secondary,
                overlayColor: AppColors.tertiary.withValues(alpha: .24),
                activeTickMarkColor: AppColors.surface,
                inactiveTickMarkColor: AppColors.secondary,
                valueIndicatorColor: AppColors.primary,
                valueIndicatorTextStyle: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w800,
                ),
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const _AmoraCompatibilityThumbShape(),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
                tickMarkShape: const RoundSliderTickMarkShape(
                  tickMarkRadius: 2,
                ),
                showValueIndicator: ShowValueIndicator.onDrag,
              ),
              child: Slider(
                key: const ValueKey('minimum-compatibility-slider'),
                focusNode: _focusNode,
                value: value.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                label: '$value%',
                semanticFormatterCallback: (sliderValue) =>
                    'Minimum compatibility, ${sliderValue.round()} percent',
                onChanged: (nextValue) {
                  final step = (nextValue / 10).round() * 10;
                  if (_lastHapticStep != step &&
                      defaultTargetPlatform != TargetPlatform.linux &&
                      defaultTargetPlatform != TargetPlatform.windows) {
                    HapticFeedback.selectionClick();
                  }
                  _lastHapticStep = step;
                  widget.onChanged(step.clamp(0, 100));
                },
                onChangeStart: (_) => _focusNode.requestFocus(),
                onChangeEnd: (_) => _lastHapticStep = null,
              ),
            ),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: duration,
              child: Text(
                'Showing matches at $value% or higher',
                key: ValueKey('compatibility-support-$value'),
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: .74),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmoraCompatibilityThumbShape extends SliderComponentShape {
  const _AmoraCompatibilityThumbShape();

  static const double _radius = 12;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.square(_radius * 2);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final radius = _radius + (activationAnimation.value * 2);
    canvas.drawCircle(center, radius + 2, Paint()..color = AppColors.surface);
    canvas.drawCircle(center, radius, Paint()..color = AppColors.secondary);
  }
}
