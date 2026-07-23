import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class AmoraDialog extends StatelessWidget {
  const AmoraDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.primaryLabel = 'Continue',
    this.secondaryLabel,
    this.onPrimary,
    this.onSecondary,
  });

  final String title;
  final String message;
  final IconData? icon;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AmoraSpacing.space24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AmoraRadius.dialog,
          border: Border.all(color: AppColors.borderGray.withValues(alpha: .7)),
          boxShadow: AmoraShadows.dialog,
        ),
        padding: AmoraSpacing.dialog,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: AmoraSpacing.space64,
                height: AmoraSpacing.space64,
                decoration: BoxDecoration(
                  color: AppColors.roseQuartz,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Icon(icon, color: AppColors.primary, size: 32),
              ),
              const SizedBox(height: AmoraSpacing.x5),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.dialogTitle,
            ),
            const SizedBox(height: AmoraSpacing.x3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.dialogBody.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AmoraSpacing.x6),
            AppPrimaryButton(label: primaryLabel, onPressed: onPrimary),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AmoraSpacing.x3),
              AppPrimaryButton(
                label: secondaryLabel!,
                onPressed:
                    onSecondary ?? () => Navigator.of(context).maybePop(),
                variant: AppPrimaryButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<T?> showAmoraDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  IconData? icon,
  String primaryLabel = 'Continue',
  String? secondaryLabel,
  VoidCallback? onPrimary,
  VoidCallback? onSecondary,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.text.withValues(alpha: .36),
    transitionDuration: AmoraMotion.standard,
    pageBuilder: (_, _, _) => AmoraDialog(
      title: title,
      message: message,
      icon: icon,
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
    ),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AmoraMotion.curve,
        reverseCurve: AmoraMotion.curve,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
