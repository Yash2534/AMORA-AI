import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AmoraaIdentityBadgeType { none, verified, premium, premiumVerified }

AmoraaIdentityBadgeType resolveAmoraaIdentityBadge({
  required bool isAadhaarVerified,
  required bool isPremium,
}) {
  if (isAadhaarVerified && isPremium) {
    return AmoraaIdentityBadgeType.premiumVerified;
  }
  if (isAadhaarVerified) return AmoraaIdentityBadgeType.verified;
  if (isPremium) return AmoraaIdentityBadgeType.premium;
  return AmoraaIdentityBadgeType.none;
}

class AmoraaIdentityBadge extends StatelessWidget {
  const AmoraaIdentityBadge({
    super.key,
    required this.isAadhaarVerified,
    required this.isPremium,
  });

  final bool isAadhaarVerified;
  final bool isPremium;

  AmoraaIdentityBadgeType get type => resolveAmoraaIdentityBadge(
    isAadhaarVerified: isAadhaarVerified,
    isPremium: isPremium,
  );

  @override
  Widget build(BuildContext context) {
    final resolved = type;
    if (resolved == AmoraaIdentityBadgeType.none) {
      return const SizedBox.shrink();
    }
    final premiumOnly = resolved == AmoraaIdentityBadgeType.premium;
    final premiumVerified = resolved == AmoraaIdentityBadgeType.premiumVerified;
    final label = premiumOnly ? 'Premium' : 'Verified';
    final semanticLabel = switch (resolved) {
      AmoraaIdentityBadgeType.verified => 'Verified profile',
      AmoraaIdentityBadgeType.premium => 'Premium member',
      AmoraaIdentityBadgeType.premiumVerified => 'Premium verified profile',
      AmoraaIdentityBadgeType.none => '',
    };
    final background = resolved == AmoraaIdentityBadgeType.verified
        ? AppColors.secondary
        : AppColors.primary;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        key: ValueKey('amoraa-identity-badge-${resolved.name}'),
        height: 28,
        constraints: const BoxConstraints(maxWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              premiumOnly
                  ? Icons.workspace_premium_rounded
                  : Icons.verified_rounded,
              color: AppColors.surface,
              size: 15,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.labelSmall.copyWith(
                  color: AppColors.surface,
                  fontWeight: premiumVerified
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
