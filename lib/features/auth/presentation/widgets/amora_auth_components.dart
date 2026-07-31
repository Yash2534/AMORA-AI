import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.tertiary.withValues(alpha: .8)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space12),
          child: Text(
            label,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.text.withValues(alpha: .62),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.tertiary.withValues(alpha: .8)),
        ),
      ],
    );
  }
}

class AuthTrustNote extends StatelessWidget {
  const AuthTrustNote({
    super.key,
    required this.text,
    this.icon = Icons.lock_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Container(
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .72)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(
              child: Text(
                text,
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.text.withValues(alpha: .74),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthInlineAlert extends StatelessWidget {
  const AuthInlineAlert({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(
              child: Text(
                message,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmoraPasswordRules extends StatelessWidget {
  const AmoraPasswordRules({
    super.key,
    required this.password,
    required this.requirement,
  });

  final String password;
  final String requirement;

  @override
  Widget build(BuildContext context) {
    final valid = password.length >= 8;
    return Semantics(
      liveRegion: true,
      label: valid ? 'Password requirement met' : requirement,
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_outline_rounded : Icons.info_outline,
            size: 18,
            color: valid ? AppColors.primary : AppColors.secondary,
          ),
          const SizedBox(width: AmoraSpacing.space8),
          Expanded(
            child: Text(
              requirement,
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.text.withValues(alpha: .7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
