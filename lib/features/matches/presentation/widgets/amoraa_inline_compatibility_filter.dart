import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int minimumCompatibilityThreshold = 50;
const int maximumCompatibilityThreshold = 95;
const int compatibilityThresholdStep = 5;
const int defaultCompatibilityThreshold = 70;

String compatibilityFilterLabel(int value) {
  final score = value.clamp(
    minimumCompatibilityThreshold,
    maximumCompatibilityThreshold,
  );
  return switch (score) {
    >= 90 => 'Best Matches',
    >= 80 => 'Highly Compatible',
    >= 70 => 'Recommended Matches',
    >= 60 => 'Good Matches',
    _ => 'Open Matches',
  };
}

String compatibilityCardLabel(int value) {
  final score = value.clamp(0, 100);
  return switch (score) {
    >= 90 => 'Best Match',
    >= 80 => 'Highly Compatible',
    >= 70 => 'Recommended Match',
    >= 60 => 'Good Match',
    _ => 'Open Match',
  };
}

String compatibilityFilterSupportingCopy(int value) {
  final score = value.clamp(
    minimumCompatibilityThreshold,
    maximumCompatibilityThreshold,
  );
  if (score == maximumCompatibilityThreshold) {
    return 'Showing only the strongest available matches.';
  }
  final label = compatibilityFilterLabel(score).toLowerCase();
  return 'Showing $label with $score% compatibility or higher.';
}

class AmoraaInlineCompatibilityFilter extends StatefulWidget {
  const AmoraaInlineCompatibilityFilter({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onReset,
    this.min = minimumCompatibilityThreshold,
    this.max = maximumCompatibilityThreshold,
    this.step = compatibilityThresholdStep,
  }) : assert(min < max),
       assert(step > 0),
       assert((max - min) % step == 0);

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final VoidCallback onReset;

  @override
  State<AmoraaInlineCompatibilityFilter> createState() =>
      _AmoraaInlineCompatibilityFilterState();
}

class _AmoraaInlineCompatibilityFilterState
    extends State<AmoraaInlineCompatibilityFilter> {
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
    final value = widget.value.clamp(widget.min, widget.max).toInt();
    final divisions = (widget.max - widget.min) ~/ widget.step;

    return Semantics(
      container: true,
      label: 'Minimum compatibility, $value percent',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.tertiary),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .07),
              blurRadius: 18,
              spreadRadius: -12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AmoraSpacing.space16,
            AmoraSpacing.space12,
            AmoraSpacing.space16,
            AmoraSpacing.space12,
          ),
          child: Column(
            key: const ValueKey('inline-compatibility-filter'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Minimum compatibility',
                          style: AmoraTextStyles.labelMedium.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: duration,
                          child: Text(
                            compatibilityFilterLabel(value),
                            key: ValueKey('compatibility-label-$value'),
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space8),
                  AnimatedSwitcher(
                    duration: duration,
                    child: Text(
                      '$value%+',
                      key: ValueKey('compatibility-value-$value'),
                      style: AmoraTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  if (value != defaultCompatibilityThreshold) ...[
                    const SizedBox(width: AmoraSpacing.space4),
                    IconButton(
                      key: const ValueKey('compatibility-filter-reset'),
                      tooltip: 'Reset compatibility to 70 percent',
                      onPressed: widget.onReset,
                      icon: const Icon(Icons.restart_alt_rounded, size: 20),
                      color: AppColors.secondary,
                    ),
                  ],
                ],
              ),
              SizedBox(
                height: 48,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: AppColors.tertiary,
                    thumbColor: AppColors.secondary,
                    overlayColor: AppColors.tertiary.withValues(alpha: .24),
                    activeTickMarkColor: AppColors.surface,
                    inactiveTickMarkColor: AppColors.secondary,
                    valueIndicatorColor: AppColors.primary,
                    valueIndicatorTextStyle: AmoraTextStyles.labelMedium
                        .copyWith(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w800,
                        ),
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: const _AmoraaCompatibilityThumbShape(),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 24,
                    ),
                    tickMarkShape: const RoundSliderTickMarkShape(
                      tickMarkRadius: 2,
                    ),
                    showValueIndicator: ShowValueIndicator.onDrag,
                  ),
                  child: Slider(
                    key: const ValueKey('minimum-compatibility-slider'),
                    focusNode: _focusNode,
                    value: value.toDouble(),
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
                    divisions: divisions,
                    label: '$value%',
                    semanticFormatterCallback: (sliderValue) =>
                        'Minimum compatibility, '
                        '${sliderValue.round()} percent',
                    onChanged: (nextValue) {
                      final snapped =
                          widget.min +
                          (((nextValue - widget.min) / widget.step).round() *
                              widget.step);
                      final nextStep = snapped
                          .clamp(widget.min, widget.max)
                          .toInt();
                      if (_lastHapticStep != nextStep &&
                          defaultTargetPlatform != TargetPlatform.linux &&
                          defaultTargetPlatform != TargetPlatform.windows) {
                        HapticFeedback.selectionClick();
                      }
                      _lastHapticStep = nextStep;
                      widget.onChanged(nextStep);
                    },
                    onChangeStart: (_) => _focusNode.requestFocus(),
                    onChangeEnd: (_) => _lastHapticStep = null,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.min}',
                    style: AmoraTextStyles.caption.copyWith(
                      color: AppColors.text.withValues(alpha: .68),
                    ),
                  ),
                  Text(
                    '${widget.max}',
                    style: AmoraTextStyles.caption.copyWith(
                      color: AppColors.text.withValues(alpha: .68),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AmoraSpacing.space4),
              AnimatedSwitcher(
                duration: duration,
                child: Text(
                  compatibilityFilterSupportingCopy(value),
                  key: ValueKey('compatibility-support-$value'),
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.text.withValues(alpha: .76),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmoraaCompatibilityThumbShape extends SliderComponentShape {
  const _AmoraaCompatibilityThumbShape();

  static const double _radius = 10;

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
    final radius = _radius + activationAnimation.value;
    canvas.drawCircle(center, radius + 2, Paint()..color = AppColors.surface);
    canvas.drawCircle(center, radius, Paint()..color = AppColors.secondary);
  }
}
