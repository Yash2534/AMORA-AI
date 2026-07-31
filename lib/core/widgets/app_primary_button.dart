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
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !isLoading;
    final foreground = switch (variant) {
      AppPrimaryButtonVariant.primary => scheme.onPrimary,
      AppPrimaryButtonVariant.tonal => AppColors.onSecondary,
      AppPrimaryButtonVariant.outlined ||
      AppPrimaryButtonVariant.text => scheme.primary,
      AppPrimaryButtonVariant.destructive => scheme.onError,
      AppPrimaryButtonVariant.dark => scheme.onInverseSurface,
    };
    final disabledForeground = AppColors.primary.withValues(alpha: .55);
    final height = size == AmoraButtonSize.compact
        ? AmoraSpacing.compactControlHeight
        : AmoraSpacing.controlHeight;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: Row(
        key: ValueKey(isLoading ? 'loading' : 'content'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            SizedBox.square(
              dimension: AmoraIconSizes.medium,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            ),
            const SizedBox(width: AmoraSpacing.space8),
          ] else if (icon != null) ...[
            Icon(icon, size: AmoraIconSizes.medium),
            const SizedBox(width: AmoraSpacing.space8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: enabled || isLoading ? foreground : disabledForeground,
              ),
            ),
          ),
        ],
      ),
    );

    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: foreground,
      disabledBackgroundColor: scheme.surfaceContainerHighest,
      disabledForegroundColor: disabledForeground,
    );
    final outlinedStyle = OutlinedButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: disabledForeground,
      side: BorderSide(color: enabled ? scheme.primary : scheme.outlineVariant),
    );
    final textStyle = TextButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: disabledForeground,
    );

    final button = switch (variant) {
      AppPrimaryButtonVariant.primary => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: primaryStyle,
        child: content,
      ),
      AppPrimaryButtonVariant.tonal => FilledButton.tonal(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: foreground,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: disabledForeground,
        ),
        child: content,
      ),
      AppPrimaryButtonVariant.outlined => OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: outlinedStyle,
        child: content,
      ),
      AppPrimaryButtonVariant.text => TextButton(
        onPressed: enabled ? onPressed : null,
        style: textStyle,
        child: content,
      ),
      AppPrimaryButtonVariant.destructive => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: foreground,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: disabledForeground,
        ),
        child: content,
      ),
      AppPrimaryButtonVariant.dark => FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.inverseSurface,
          foregroundColor: foreground,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: disabledForeground,
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
