import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String money(int amount) => 'Rs ${amount.toString()}';

void showPremiumSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

class MonetizationHeader extends StatelessWidget {
  const MonetizationHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = AmoraIcons.premium,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Row(
      children: [
        if (onBack != null) ...[
          IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(AmoraIcons.back),
          ),
          const SizedBox(width: AmoraSpacing.space8),
        ],
        Container(
          width: AmoraSpacing.minimumTouchTarget,
          height: AmoraSpacing.minimumTouchTarget,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: AmoraRadius.button,
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
                style:
                    (compact
                            ? AmoraTextStyles.titleLarge
                            : AmoraTextStyles.headlineSmall)
                        .copyWith(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w700,
                        ),
              ),
              const SizedBox(height: AmoraSpacing.space4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PremiumPlanCard extends StatelessWidget {
  const PremiumPlanCard({
    super.key,
    required this.plan,
    required this.annual,
    required this.onUpgrade,
  });

  final SubscriptionPlan plan;
  final bool annual;
  final VoidCallback onUpgrade;

  int get displayPrice => annual ? plan.monthlyPrice * 10 : plan.monthlyPrice;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                plan.name,
                style: AmoraTextStyles.headlineSmall.copyWith(
                  color: plan.highlight
                      ? AppColors.surface
                      : AppColors.deepWine,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (plan.current)
              const _Pill(label: 'Current plan')
            else if (plan.highlight)
              const _Pill(label: 'Best visibility', dark: true),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          plan.monthlyPrice == 0
              ? 'Rs 0'
              : annual
              ? '${money(displayPrice)}/yr'
              : '${money(displayPrice)}/mo',
          style: AmoraTextStyles.headlineMedium.copyWith(
            color: plan.highlight
                ? AppColors.premiumGold
                : AppColors.primaryPurple,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (annual && plan.monthlyPrice > 0) ...[
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            'Save 2 months',
            style: AmoraTextStyles.labelLarge.copyWith(
              color: plan.highlight
                  ? AppColors.surface
                  : AppColors.successGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          plan.tagline,
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: plan.highlight ? AppColors.surface : AppColors.textGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space16),
        for (final feature in plan.features)
          Padding(
            padding: const EdgeInsets.only(bottom: AmoraSpacing.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  AmoraIcons.check,
                  color: plan.highlight
                      ? AppColors.premiumGold
                      : AppColors.primaryRose,
                  size: AmoraIconSizes.medium,
                ),
                const SizedBox(width: AmoraSpacing.space8),
                Expanded(
                  child: Text(
                    feature,
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: plan.highlight
                          ? AppColors.surface
                          : AppColors.textDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AmoraSpacing.space12),
        AppPrimaryButton(
          label: plan.current ? 'Current Plan' : 'Upgrade to ${plan.name}',
          icon: plan.current ? AmoraIcons.check : AmoraIcons.forward,
          variant: plan.highlight
              ? AppPrimaryButtonVariant.dark
              : AppPrimaryButtonVariant.primary,
          onPressed: plan.current
              ? () => showPremiumSnack(context, 'Free plan is active')
              : onUpgrade,
        ),
      ],
    );

    if (!plan.highlight) return PremiumCard(child: child);
    return Container(
      padding: AmoraSpacing.card,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.tertiary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AmoraRadius.card,
        boxShadow: AmoraShadows.premiumCard,
      ),
      child: child,
    );
  }
}

class FeatureMatrixRow extends StatelessWidget {
  const FeatureMatrixRow({super.key, required this.item});

  final FeatureMatrixItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.feature,
              style: const TextStyle(
                color: AppColors.deepWine,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final available in item.availability)
            Expanded(
              child: Icon(
                available
                    ? Icons.check_circle_rounded
                    : Icons.remove_circle_outline_rounded,
                color: available
                    ? AppColors.successGreen
                    : AppColors.borderGray,
                size: 19,
              ),
            ),
        ],
      ),
    );
  }
}

class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavenderBackground : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primaryPurple : AppColors.borderGray,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(method.icon, color: AppColors.primaryPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.name,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    method.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primaryPurple : AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }
}

class CoachInsightCard extends StatelessWidget {
  const CoachInsightCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lavenderBackground,
            child: Icon(icon, color: AppColors.primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IcebreakerCard extends StatelessWidget {
  const IcebreakerCard({
    super.key,
    required this.text,
    required this.onCustomize,
    required this.onSend,
  });

  final String text;
  final VoidCallback onCustomize;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: text));
                  showPremiumSnack(context, 'Copied opening message');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy'),
              ),
              OutlinedButton.icon(
                onPressed: onCustomize,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
              FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Send'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: .24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.savings_rounded, color: AppColors.premiumGold, size: 34),
          SizedBox(height: 18),
          Text(
            '1,250 Amora Coins',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Approx value: Rs 1,250',
            style: TextStyle(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor:
            (transaction.positive
                    ? AppColors.successGreen
                    : AppColors.primaryRose)
                .withValues(alpha: .12),
        child: Icon(
          transaction.positive ? Icons.add_rounded : Icons.remove_rounded,
          color: transaction.positive
              ? AppColors.successGreen
              : AppColors.primaryRose,
        ),
      ),
      title: Text(
        transaction.title,
        style: const TextStyle(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(transaction.date),
      trailing: Text(
        '${transaction.positive ? '+' : '-'}${transaction.amount}',
        style: TextStyle(
          color: transaction.positive
              ? AppColors.successGreen
              : AppColors.primaryRose,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class ReferralStatsCard extends StatelessWidget {
  const ReferralStatsCard({super.key, required this.stat});

  final ReferralStat stat;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      radius: 22,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, color: AppColors.primaryPurple, size: 20),
            const SizedBox(height: 4),
            Text(
              stat.value,
              style: const TextStyle(
                color: AppColors.deepWine,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.deepWine,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.textGray,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.text.withValues(alpha: .24)
            : AppColors.lavenderBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? AppColors.surface : AppColors.primaryPurple,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
