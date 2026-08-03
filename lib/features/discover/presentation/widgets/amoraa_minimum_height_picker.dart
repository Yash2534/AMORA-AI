import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int minimumSupportedHeightCm = 137;
const int maximumSupportedHeightCm = 213;
const int defaultHeightWheelCm = 165;

enum HeightDisplayUnit { feet, centimeters }

int heightInchesToCentimeters(int inches) => (inches * 2.54).round();

int heightCentimetersToNearestInches(int centimeters) =>
    (centimeters / 2.54).round();

String formatHeightFeet(int centimeters) {
  final inches = heightCentimetersToNearestInches(centimeters);
  return '${inches ~/ 12}\'${inches % 12}"';
}

String formatHeightCentimeters(int centimeters) => '$centimeters cm';

String minimumHeightSummary(int? centimeters) =>
    centimeters == null ? 'Any height' : '${formatHeightFeet(centimeters)}+';

String heightSemanticsLabel(int centimeters) {
  final inches = heightCentimetersToNearestInches(centimeters);
  final feet = inches ~/ 12;
  final remainingInches = inches % 12;
  return 'Selected height, $feet feet $remainingInches inches';
}

class MinimumHeightPickerResult {
  const MinimumHeightPickerResult(this.minimumCentimeters);

  final int? minimumCentimeters;
}

class AmoraaMinimumHeightPicker extends StatefulWidget {
  const AmoraaMinimumHeightPicker({
    super.key,
    required this.initialMinimumCentimeters,
    required this.onClose,
    required this.onApply,
  });

  final int? initialMinimumCentimeters;
  final VoidCallback onClose;
  final ValueChanged<int?> onApply;

  @override
  State<AmoraaMinimumHeightPicker> createState() =>
      _AmoraaMinimumHeightPickerState();
}

class _AmoraaMinimumHeightPickerState extends State<AmoraaMinimumHeightPicker> {
  static final List<int> _centimeterValues = List<int>.unmodifiable(
    List<int>.generate(
      maximumSupportedHeightCm - minimumSupportedHeightCm + 1,
      (index) => minimumSupportedHeightCm + index,
    ),
  );
  static final List<int> _inchValues = List<int>.unmodifiable(
    List<int>.generate(84 - 54 + 1, (index) => 54 + index),
  );

  late int _selectedCentimeters;
  late bool _unrestricted;
  HeightDisplayUnit _unit = HeightDisplayUnit.feet;
  late FixedExtentScrollController _wheelController;
  int? _lastHapticIndex;

  List<int> get _values =>
      _unit == HeightDisplayUnit.feet ? _inchValues : _centimeterValues;

  int get _selectedIndex {
    if (_unit == HeightDisplayUnit.feet) {
      final inches = heightCentimetersToNearestInches(_selectedCentimeters);
      return (inches - _inchValues.first).clamp(0, _inchValues.length - 1);
    }
    return (_selectedCentimeters - minimumSupportedHeightCm).clamp(
      0,
      _centimeterValues.length - 1,
    );
  }

  @override
  void initState() {
    super.initState();
    _unrestricted = widget.initialMinimumCentimeters == null;
    _selectedCentimeters =
        (widget.initialMinimumCentimeters ?? defaultHeightWheelCm).clamp(
          minimumSupportedHeightCm,
          maximumSupportedHeightCm,
        );
    _wheelController = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _wheelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final sheetHeight = (MediaQuery.sizeOf(context).height * .9).clamp(
      520.0,
      720.0,
    );

    return Material(
      key: const ValueKey('minimum-height-picker'),
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: sheetHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space8,
              AmoraSpacing.space20,
              AmoraSpacing.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Height',
                            style: AmoraTextStyles.screenTitle.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'Minimum preference',
                            style: AmoraTextStyles.labelMedium.copyWith(
                              color: AppColors.text.withValues(alpha: .66),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('height-picker-close'),
                      tooltip: 'Close height picker',
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Text(
                  'Choose the minimum height preference for matches.',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.text.withValues(alpha: .74),
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                _HeightUnitControl(
                  unit: _unit,
                  duration: duration,
                  onChanged: _changeUnit,
                ),
                const SizedBox(height: AmoraSpacing.space12),
                Expanded(child: _buildWheel(context, duration)),
                const SizedBox(height: AmoraSpacing.space8),
                AnimatedSwitcher(
                  duration: duration,
                  child: Text(
                    _unrestricted
                        ? 'Any height — scroll to choose a minimum.'
                        : 'Showing matches at ${minimumHeightSummary(_selectedCentimeters)}.',
                    key: ValueKey(
                      'height-status-$_unrestricted-$_selectedCentimeters',
                    ),
                    textAlign: TextAlign.center,
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.text.withValues(alpha: .72),
                    ),
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                Row(
                  children: [
                    SizedBox(
                      height: 52,
                      child: TextButton.icon(
                        key: const ValueKey('height-picker-reset'),
                        onPressed: () => setState(() => _unrestricted = true),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          key: const ValueKey('height-picker-apply'),
                          onPressed: () => widget.onApply(
                            _unrestricted ? null : _selectedCentimeters,
                          ),
                          child: const Text('Apply Height'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWheel(BuildContext context, Duration duration) {
    final values = _values;
    return Semantics(
      container: true,
      label: _unrestricted
          ? 'No minimum height selected'
          : heightSemanticsLabel(_selectedCentimeters),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(-1),
          const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(1),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ListWheelScrollView.useDelegate(
                key: ValueKey('height-wheel-${_unit.name}'),
                controller: _wheelController,
                itemExtent: 64,
                diameterRatio: 1.8,
                perspective: .002,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: _selectIndex,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: values.length,
                  builder: (context, index) {
                    final selected = index == _selectedIndex;
                    final centimeters = _unit == HeightDisplayUnit.feet
                        ? heightInchesToCentimeters(values[index])
                        : values[index];
                    final label = _unit == HeightDisplayUnit.feet
                        ? formatHeightFeet(centimeters)
                        : formatHeightCentimeters(centimeters);
                    return Center(
                      child: AnimatedDefaultTextStyle(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        style: selected
                            ? AmoraTextStyles.display.copyWith(
                                color: AppColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              )
                            : AmoraTextStyles.titleMedium.copyWith(
                                color: AppColors.text.withValues(alpha: .38),
                                fontWeight: FontWeight.w600,
                              ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: duration,
                              width: selected ? 28 : 14,
                              height: 2,
                              color: selected
                                  ? AppColors.secondary
                                  : AppColors.tertiary,
                            ),
                            const SizedBox(width: AmoraSpacing.space12),
                            Text(
                              label,
                              key: selected
                                  ? const ValueKey('selected-height-value')
                                  : null,
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              IgnorePointer(
                child: Container(
                  height: 64,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AmoraSpacing.space16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(color: AppColors.tertiary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectIndex(int index) {
    final value = _values[index];
    final centimeters = _unit == HeightDisplayUnit.feet
        ? heightInchesToCentimeters(value)
        : value;
    if (_lastHapticIndex != index &&
        defaultTargetPlatform != TargetPlatform.linux &&
        defaultTargetPlatform != TargetPlatform.windows) {
      HapticFeedback.selectionClick();
    }
    _lastHapticIndex = index;
    setState(() {
      _selectedCentimeters = centimeters.clamp(
        minimumSupportedHeightCm,
        maximumSupportedHeightCm,
      );
      _unrestricted = false;
    });
  }

  void _step(int delta) {
    final nextIndex = (_selectedIndex + delta).clamp(0, _values.length - 1);
    if (nextIndex == _selectedIndex) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _wheelController.animateToItem(
      nextIndex,
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _changeUnit(HeightDisplayUnit nextUnit) {
    if (nextUnit == _unit) return;
    final previousController = _wheelController;
    setState(() {
      _unit = nextUnit;
      _wheelController = FixedExtentScrollController(
        initialItem: _selectedIndex,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
    });
  }
}

class _HeightUnitControl extends StatelessWidget {
  const _HeightUnitControl({
    required this.unit,
    required this.duration,
    required this.onChanged,
  });

  final HeightDisplayUnit unit;
  final Duration duration;
  final ValueChanged<HeightDisplayUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Height unit, ${unit == HeightDisplayUnit.feet ? 'feet' : 'centimeters'} selected',
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Row(
          children: [
            _HeightUnitOption(
              key: const ValueKey('height-unit-feet'),
              label: 'FT',
              selected: unit == HeightDisplayUnit.feet,
              duration: duration,
              onTap: () => onChanged(HeightDisplayUnit.feet),
            ),
            _HeightUnitOption(
              key: const ValueKey('height-unit-centimeters'),
              label: 'CM',
              selected: unit == HeightDisplayUnit.centimeters,
              duration: duration,
              onTap: () => onChanged(HeightDisplayUnit.centimeters),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeightUnitOption extends StatelessWidget {
  const _HeightUnitOption({
    super.key,
    required this.label,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label height unit',
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(23),
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : AppColors.transparent,
                borderRadius: BorderRadius.circular(23),
                border: selected
                    ? Border.all(color: AppColors.secondary)
                    : null,
              ),
              child: Text(
                label,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
