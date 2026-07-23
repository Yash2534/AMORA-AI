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
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
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
        overflow: TextOverflow.ellipsis,
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
    );
  }
}
