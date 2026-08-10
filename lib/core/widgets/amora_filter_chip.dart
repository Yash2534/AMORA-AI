import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';

class AmoraFilterChip extends StatelessWidget {
  const AmoraFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.showCheckmark = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '$label, ${selected ? 'selected' : 'unselected'}',
      onTap: () => onSelected(!selected),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: FilterChip(
            selected: selected,
            onSelected: onSelected,
            showCheckmark: showCheckmark,
            checkmarkColor: AppColors.onActive,
            avatar: icon == null
                ? null
                : Icon(
                    icon,
                    size: AmoraIconSizes.small,
                    color: selected ? AppColors.onActive : AppColors.secondary,
                  ),
            label: Text(
              label,
              maxLines: 1,
              style: AmoraTextStyles.caption.copyWith(
                color: selected ? AppColors.onActive : AppColors.text,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            selectedColor: AppColors.active,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.active : AppColors.borderGray,
            ),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.x3,
              vertical: AmoraSpacing.x2,
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
      height: 48,
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
