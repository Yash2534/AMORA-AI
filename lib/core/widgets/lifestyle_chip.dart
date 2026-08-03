import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class LifestyleChip extends StatelessWidget {
  const LifestyleChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AmoraRadius.pillBorder,
      child: AnimatedContainer(
        duration: AmoraMotion.fast,
        curve: AmoraMotion.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.x4,
          vertical: AmoraSpacing.x2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tertiary.withValues(alpha: .28)
              : AppColors.surface,
          borderRadius: AmoraRadius.pillBorder,
          border: Border.all(
            color: selected
                ? AppColors.secondary.withValues(alpha: .44)
                : AppColors.borderGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: AmoraSpacing.x1),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.caption.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
