import 'dart:ui';

import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class AmoraFilterChip extends StatefulWidget {
  const AmoraFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.showCheckmark = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final bool showCheckmark;
  final VoidCallback? onTap;

  @override
  State<AmoraFilterChip> createState() => _AmoraFilterChipState();
}

class _AmoraFilterChipState extends State<AmoraFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _animate(double target, {double velocity = 0}) {
    _scaleController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .75, stiffness: 520, damping: 30),
        _scaleController.value,
        target,
        velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selected = widget.selected;

    final Color backgroundColor;
    final Color borderColor;
    final List<BoxShadow> shadows;
    final Color contentColor;
    final Color iconColor;

    if (isDark) {
      if (selected) {
        backgroundColor = AppColors.primary.withValues(alpha: 0.32);
        borderColor = AppColors.primaryLight.withValues(alpha: 0.65);
        contentColor = Colors.white;
        iconColor = AppColors.primaryLight;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ];
      } else {
        backgroundColor = const Color(0xFF1E1428).withValues(alpha: 0.48);
        borderColor = Colors.white.withValues(alpha: 0.20);
        contentColor = Colors.white.withValues(alpha: 0.85);
        iconColor = Colors.white.withValues(alpha: 0.70);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ];
      }
    } else {
      if (selected) {
        backgroundColor = AppColors.primary.withValues(alpha: 0.14);
        borderColor = AppColors.primary.withValues(alpha: 0.55);
        contentColor = AppColors.primary;
        iconColor = AppColors.primary;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.16),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ];
      } else {
        backgroundColor = Colors.white.withValues(alpha: 0.45);
        borderColor = Colors.white.withValues(alpha: 0.65);
        contentColor = AppColors.textPrimary;
        iconColor = AppColors.primary.withValues(alpha: 0.75);
        shadows = [
          BoxShadow(
            color: const Color(0xFF6B4E71).withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ];
      }
    }

    void handleTap() {
      if (widget.onTap != null) {
        widget.onTap!();
      } else {
        widget.onSelected(!selected);
      }
    }

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${widget.label}, ${selected ? 'selected' : 'unselected'}',
      onTap: handleTap,
      child: ExcludeSemantics(
        child: Listener(
          onPointerDown: (_) => _animate(0.96, velocity: -1),
          onPointerUp: (_) => _animate(1.0, velocity: 1),
          onPointerCancel: (_) => _animate(1.0),
          child: ScaleTransition(
            scale: _scaleController,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: shadows,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: borderColor,
                        width: selected ? 1.4 : 1.1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: handleTap,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.showCheckmark && selected) ...[
                                Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 5),
                              ] else if (widget.icon != null) ...[
                                Icon(widget.icon, size: 16, color: iconColor),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  widget.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: AmoraTextStyles.caption.copyWith(
                                    color: contentColor,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    letterSpacing: 0.1,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AmoraaHorizontalFilterBar<T> extends StatelessWidget {
  const AmoraaHorizontalFilterBar({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.multiSelect,
    required this.labelBuilder,
    required this.optionKeyPrefix,
    required this.onChanged,
    this.iconBuilder,
    this.showCheckmark = false,
  });

  final List<T> options;
  final Set<T> selectedValues;
  final bool multiSelect;
  final String Function(T option) labelBuilder;
  final String optionKeyPrefix;
  final IconData? Function(T option)? iconBuilder;
  final ValueChanged<Set<T>> onChanged;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        key: ValueKey('$optionKeyPrefix-scroll'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AmoraSpacing.space20),
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: AmoraSpacing.space8),
        itemBuilder: (context, index) {
          final option = options[index];
          final label = labelBuilder(option);
          final selected = selectedValues.contains(option);
          return AmoraFilterChip(
            key: ValueKey('$optionKeyPrefix-$label'),
            label: label,
            selected: selected,
            icon: iconBuilder?.call(option),
            showCheckmark: showCheckmark,
            onSelected: (_) {
              if (!multiSelect) {
                if (!selected) onChanged(<T>{option});
                return;
              }
              final updated = Set<T>.of(selectedValues);
              selected ? updated.remove(option) : updated.add(option);
              onChanged(updated);
            },
          );
        },
      ),
    );
  }
}
