import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';

class AmoraEmptyState extends StatelessWidget {
  const AmoraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.accentColor = AppColors.primary,
    this.illustration,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Color accentColor;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AmoraSpacing.screen,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              illustration!
            else
              Container(
                width: AmoraSpacing.stateIllustrationSize,
                height: AmoraSpacing.stateIllustrationSize,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: .1),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: .22)),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: AmoraIconSizes.large,
                ),
              ),
            const SizedBox(height: AmoraSpacing.x5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.title,
            ),
            const SizedBox(height: AmoraSpacing.x2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.body.copyWith(
                color: AppColors.textGray,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AmoraSpacing.x6),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppPrimaryButtonVariant.outlined,
              ),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AmoraSpacing.space8),
              AppPrimaryButton(
                label: secondaryActionLabel!,
                onPressed: onSecondaryAction,
                variant: AppPrimaryButtonVariant.text,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
