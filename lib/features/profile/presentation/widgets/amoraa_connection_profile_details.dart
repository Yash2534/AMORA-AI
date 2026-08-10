import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:flutter/material.dart';

/// Compact public presentation shared by preview and viewed-profile detail.
class AmoraaConnectionProfileDetails extends StatelessWidget {
  const AmoraaConnectionProfileDetails({
    super.key,
    required this.iceBreaker,
    required this.communicationStyle,
  });

  final String iceBreaker;
  final CommunicationStyle? communicationStyle;

  @override
  Widget build(BuildContext context) {
    final trimmedIceBreaker = iceBreaker.trim();
    if (trimmedIceBreaker.isEmpty && communicationStyle == null) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const ValueKey('public-profile-section-connection-style'),
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (trimmedIceBreaker.isNotEmpty) ...[
            const _ConnectionDetailLabel(
              icon: Icons.format_quote_rounded,
              label: 'Ice Breaker',
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              trimmedIceBreaker,
              style: AmoraTextStyles.bodyLarge.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .84),
                height: 1.45,
              ),
            ),
          ],
          if (trimmedIceBreaker.isNotEmpty && communicationStyle != null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AmoraSpacing.space16),
              child: Divider(height: 1),
            ),
          if (communicationStyle case final style?) ...[
            const _ConnectionDetailLabel(
              icon: Icons.forum_outlined,
              label: 'Communication Style',
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              style.label,
              style: AmoraTextStyles.titleSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionDetailLabel extends StatelessWidget {
  const _ConnectionDetailLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: AmoraSpacing.space8),
        Text(label, style: AmoraTextStyles.titleSmall),
      ],
    );
  }
}
