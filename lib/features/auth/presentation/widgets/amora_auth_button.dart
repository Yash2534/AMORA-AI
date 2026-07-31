import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AuthButtonStyle { primary, outlined, soft }

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.style = AuthButtonStyle.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AuthButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final background = switch (style) {
      AuthButtonStyle.primary => AppColors.primary,
      AuthButtonStyle.outlined => AppColors.surface,
      AuthButtonStyle.soft => AppColors.tertiary,
    };
    final foreground = style == AuthButtonStyle.primary
        ? AppColors.surface
        : AppColors.primary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? '$label, in progress' : label,
      hint: enabled ? null : 'This action is currently unavailable',
      child: SizedBox(
        height: AmoraSpacing.controlHeight,
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.tertiary;
              }
              return background;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppColors.primary.withValues(alpha: .62);
              }
              return foreground;
            }),
            overlayColor: WidgetStatePropertyAll(
              foreground.withValues(alpha: .08),
            ),
            side: WidgetStatePropertyAll(
              BorderSide(
                color: style == AuthButtonStyle.primary
                    ? AppColors.primary
                    : AppColors.tertiary,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 20),
              if (isLoading || icon != null)
                const SizedBox(width: AmoraSpacing.space8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AmoraGoogleButton extends StatelessWidget {
  const AmoraGoogleButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: isLoading ? '$label, in progress' : label,
      child: SizedBox(
        height: AmoraSpacing.controlHeight,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.text,
            disabledForegroundColor: AppColors.text.withValues(alpha: .56),
            side: const BorderSide(color: AppColors.tertiary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: isLoading
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.asset(
                        AmoraBrandAssets.googleG,
                        key: const ValueKey('official-google-g'),
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        semanticLabel: 'Google',
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
