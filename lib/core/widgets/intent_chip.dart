import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class IntentChip extends StatelessWidget {
  const IntentChip({
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
          vertical: AmoraSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AmoraRadius.pillBorder,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: selected ? AppColors.surface : AppColors.secondary,
            ),
            const SizedBox(width: AmoraSpacing.x2),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.caption.copyWith(
                  color: selected ? AppColors.surface : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const relationshipIntentions = [
  '💍 Marriage Minded',
  '❤️ Long-Term Relationship',
  '☕ Meaningful Dating',
  '✨ Exploring Possibilities',
  '🤝 Friendship First',
  '🌿 Casual Connection',
];
