import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AppPrimaryButtonVariant {
  primary,
  tonal,
  outlined,
  text,
  destructive,
  dark,
}

enum AmoraButtonSize { compact, standard }

/// Unified button primitive for default, pressed, focused, disabled and loading
/// states. The historical class name is retained to avoid screen-level churn.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppPrimaryButtonVariant.primary,
    this.size = AmoraButtonSize.standard,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppPrimaryButtonVariant variant;
  final AmoraButtonSize size;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final height = size == AmoraButtonSize.compact
        ? AmoraSpacing.compactControlHeight
        : AmoraSpacing.controlHeight;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: isLoading
          ? const SizedBox.square(
              key: ValueKey('loading'),
              dimension: AmoraIconSizes.medium,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AmoraIconSizes.medium),
                  const SizedBox(width: AmoraSpacing.space8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );

    final button = switch (variant) {
      AppPrimaryButtonVariant.primary => FilledButton(
        onPressed: enabled ? onPressed : null,
        child: content,
      ),
      AppPrimaryButtonVariant.tonal => FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.onSecondary,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.textDisabled,
        ),
        child: content,
      ),
      AppPrimaryButtonVariant.outlined => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        child: content,
      ),
      AppPrimaryButtonVariant.text => TextButton(
        onPressed: enabled ? onPressed : null,
        child: content,
      ),
      AppPrimaryButtonVariant.destructive => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.onError,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          disabledForegroundColor: AppColors.textDisabled,
        ),
        child: content,
      ),
      AppPrimaryButtonVariant.dark => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.onSurface,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          disabledForegroundColor: AppColors.textDisabled,
        ),
        child: content,
      ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? '$label, loading' : label,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: button,
      ),
    );
  }
}
