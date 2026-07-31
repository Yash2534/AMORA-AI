import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_card.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:flutter/material.dart';

class AmoraWalletScreen extends StatefulWidget {
  const AmoraWalletScreen({super.key});

  static const routeName = '/wallet';

  @override
  State<AmoraWalletScreen> createState() => _AmoraWalletScreenState();
}

class _AmoraWalletScreenState extends State<AmoraWalletScreen> {
  WalletPackage _selectedPackage = walletPackages[1];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonetizationHeader(
                    title: 'Amora Wallet',
                    subtitle: 'Coins for boosts, roses, events, and AI perks.',
                    icon: AmoraIcons.wallet,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  const WalletBalanceCard(),
                  const SizedBox(height: 18),
                  const SectionTitle(title: 'Quick actions'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _QuickAction(
                        icon: Icons.add_card_rounded,
                        label: 'Top Up',
                        onTap: _topUp,
                      ),
                      _QuickAction(
                        icon: Icons.redeem_rounded,
                        label: 'Redeem',
                        onTap: () => showPremiumSnack(
                          context,
                          'Choose a redemption option below',
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.history_rounded,
                        label: 'History',
                        onTap: () => showPremiumSnack(
                          context,
                          'Transaction history is shown below',
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Referral Bonus',
                        onTap: () => showPremiumSnack(
                          context,
                          'Referral bonus: 100 coins per subscription',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Top-up packages'),
                  const SizedBox(height: 12),
                  for (final package in walletPackages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WalletPackageTile(
                        package: package,
                        selected: package == _selectedPackage,
                        onTap: () => setState(() => _selectedPackage = package),
                      ),
                    ),
                  const SizedBox(height: 10),
                  AppPrimaryButton(
                    label: 'Top Up ${_selectedPackage.coins} Coins',
                    icon: AmoraIcons.wallet,
                    onPressed: _topUp,
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Redemption options'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in redemptionOptions)
                        ActionChip(
                          avatar: const Icon(
                            AmoraIcons.sparkle,
                            size: 17,
                            color: AppColors.primaryPurple,
                          ),
                          label: Text(option),
                          onPressed: () => _confirmRedeem(option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Transaction history'),
                  const SizedBox(height: 12),
                  PremiumCard(
                    child: Column(
                      children: [
                        for (final transaction in walletTransactions)
                          TransactionTile(transaction: transaction),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _topUp() {
    Navigator.of(context).pushNamed(
      PaymentScreen.routeName,
      arguments: PaymentArgs(
        title: '${_selectedPackage.coins} Amora Coins',
        subtitle: 'Amora Wallet Top Up',
        billingCycle: 'One-time wallet recharge',
        amount: _selectedPackage.price,
      ),
    );
  }

  void _confirmRedeem(String option) {
    showAmoraDialog<void>(
      context: context,
      title: 'Redeem $option?',
      message:
          'This will update the local wallet ledger. Backend coin deduction is pending.',
      icon: AmoraIcons.gift,
      primaryLabel: 'Redeem',
      secondaryLabel: 'Cancel',
      onPrimary: () {
        Navigator.pop(context);
        showPremiumSnack(context, '$option redemption confirmed');
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmoraCard(
      variant: AmoraCardVariant.wallet,
      padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space12),
      onTap: onTap,
      semanticLabel: label,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.lavenderBackground,
              borderRadius: AmoraRadius.input,
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 19),
          ),
          const SizedBox(width: AmoraSpacing.space8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.deepWine,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletPackageTile extends StatelessWidget {
  const _WalletPackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final WalletPackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AmoraRadius.card,
      onTap: onTap,
      child: Container(
        padding: AmoraSpacing.compactCard,
        decoration: BoxDecoration(
          color: selected ? AppColors.lavenderBackground : AppColors.surface,
          borderRadius: AmoraRadius.card,
          border: Border.all(
            color: selected ? AppColors.primaryPurple : AppColors.borderGray,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected ? AmoraShadows.level2 : AmoraShadows.level1,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${package.coins} coins',
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              money(package.price),
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space8,
                vertical: AmoraSpacing.space4,
              ),
              decoration: BoxDecoration(
                color: AppColors.premiumGold.withValues(alpha: .18),
                borderRadius: AmoraRadius.pillBorder,
              ),
              child: Text(
                package.badge,
                style: AmoraTextStyles.labelSmall.copyWith(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
