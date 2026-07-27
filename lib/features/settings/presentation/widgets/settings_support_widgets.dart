import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:flutter/material.dart';

void showSettingsSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(AmoraIcons.back),
          ),
          const SizedBox(width: AmoraSpacing.space12),
        ],
        Container(
          width: AmoraSpacing.controlHeight,
          height: AmoraSpacing.controlHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryRose, AppColors.primaryPurple],
            ),
            borderRadius: AmoraRadius.card,
          ),
          child: Icon(icon, color: AppColors.surface),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.title.copyWith(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.caption.copyWith(
                  color: AppColors.textGray,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AmoraTextStyles.subtitle.copyWith(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AmoraSpacing.space4),
            Text(
              subtitle!,
              style: AmoraTextStyles.caption.copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AmoraSpacing.space12),
          ...children,
        ],
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.errorRed : AppColors.primaryPurple;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AmoraSpacing.space4),
      onTap: onTap,
      minLeadingWidth: 48,
      leading: Container(
        width: AmoraSpacing.minimumTouchTarget,
        height: AmoraSpacing.minimumTouchTarget,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: AmoraRadius.button,
        ),
        child: Icon(icon, color: color, size: AmoraIconSizes.medium),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AmoraTextStyles.titleSmall.copyWith(
          color: danger ? AppColors.errorRed : AppColors.deepWine,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AmoraTextStyles.caption.copyWith(
          color: AppColors.textGray,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing ?? const Icon(AmoraIcons.forward),
    );
  }
}

class PrivacyToggleTile extends StatelessWidget {
  const PrivacyToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon = Icons.privacy_tip_rounded,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AmoraSpacing.space4),
      secondary: Container(
        width: AmoraSpacing.minimumTouchTarget,
        height: AmoraSpacing.minimumTouchTarget,
        decoration: BoxDecoration(
          color: AppColors.lavenderBackground,
          borderRadius: AmoraRadius.button,
        ),
        child: Icon(
          icon,
          color: AppColors.primaryPurple,
          size: AmoraIconSizes.medium,
        ),
      ),
      title: Text(
        title,
        style: AmoraTextStyles.titleSmall.copyWith(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AmoraTextStyles.caption.copyWith(
          color: AppColors.textGray,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class AmoraSafetyCard extends StatelessWidget {
  const AmoraSafetyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.lavenderBackground,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppColors.primaryPurple, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumDangerButton extends StatelessWidget {
  const PremiumDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.delete_forever_rounded,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: label,
      icon: icon,
      variant: AppPrimaryButtonVariant.destructive,
      onPressed: onPressed,
    );
  }
}

class TrustPill extends StatelessWidget {
  const TrustPill({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.successGreen,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space12,
        vertical: AmoraSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AmoraIconSizes.small),
          const SizedBox(width: AmoraSpacing.space4),
          Text(
            label,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SheetPrimaryButton extends StatelessWidget {
  const SheetPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(label: label, icon: icon, onPressed: onPressed);
  }
}
