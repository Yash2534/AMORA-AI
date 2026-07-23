import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  static const routeName = '/subscription';

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  var _annual = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightPinkBackground,
              AppColors.background,
              AppColors.lavenderBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.x5,
                AmoraSpacing.x5,
                AmoraSpacing.x5,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonetizationHeader(
                    title: 'AMORA Premium',
                    subtitle: 'Choose visibility, trust, and smarter matches.',
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AmoraSpacing.space20),
                  PremiumCard(
                    padding: const EdgeInsets.all(AmoraSpacing.x2),
                    radius: AmoraRadius.xxl,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Monthly')),
                        ButtonSegment(
                          value: true,
                          label: Text('Annual'),
                          icon: Icon(AmoraIcons.savings),
                        ),
                      ],
                      selected: {_annual},
                      onSelectionChanged: (selection) =>
                          setState(() => _annual = selection.first),
                    ),
                  ),
                  if (_annual) ...[
                    const SizedBox(height: AmoraSpacing.space12),
                    const _AnnualSavingsBanner(),
                  ],
                  const SizedBox(height: AmoraSpacing.x4),
                  const _PremiumPreviewStrip(),
                  const SizedBox(height: AmoraSpacing.x4),
                  for (final plan in subscriptionPlans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PremiumPlanCard(
                        plan: plan,
                        annual: _annual,
                        onUpgrade: () => _openPayment(plan),
                      ),
                    ),
                  const SizedBox(height: AmoraSpacing.x2),
                  const SectionTitle(
                    title: 'Compare all plans',
                    subtitle: 'A quick view of the premium difference',
                  ),
                  const SizedBox(height: AmoraSpacing.space12),
                  PremiumCard(
                    child: Column(
                      children: [
                        const _MatrixHeader(),
                        const Divider(height: 24),
                        for (final item in featureMatrix)
                          FeatureMatrixRow(item: item),
                      ],
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.x4),
                  AppPrimaryButton(
                    label: 'Continue with Gold',
                    icon: AmoraIcons.premium,
                    onPressed: () => _openPayment(subscriptionPlans[1]),
                  ),
                  const SizedBox(height: AmoraSpacing.space12),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          size: AmoraButtonSize.compact,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: () => showPremiumSnack(
                            context,
                            'Restore purchase placeholder ready',
                          ),
                          icon: AmoraIcons.restore,
                          label: 'Restore',
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space8),
                      Expanded(
                        child: AppPrimaryButton(
                          size: AmoraButtonSize.compact,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: () => showPremiumSnack(
                            context,
                            'Terms and refund policy placeholder opened',
                          ),
                          icon: AmoraIcons.policy,
                          label: 'Terms',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPayment(SubscriptionPlan plan) {
    final amount = _annual ? plan.monthlyPrice * 10 : plan.monthlyPrice;
    if (amount == 0) {
      showPremiumSnack(context, 'Free plan is already active');
      return;
    }
    Navigator.of(context).pushNamed(
      PaymentScreen.routeName,
      arguments: PaymentArgs(
        title: plan.name,
        billingCycle: _annual ? 'Annual - Save 2 months' : 'Monthly',
        amount: amount,
      ),
    );
  }
}

class _AnnualSavingsBanner extends StatelessWidget {
  const _AnnualSavingsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AmoraSpacing.compactCard,
      decoration: BoxDecoration(
        color: AppColors.premiumGold.withValues(alpha: .18),
        borderRadius: AmoraRadius.card,
        border: Border.all(color: AppColors.premiumGold),
      ),
      child: Row(
        children: [
          Icon(AmoraIcons.sparkle, color: AppColors.premiumGold),
          SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Text(
              'Annual shows Save 2 months on every paid plan.',
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.deepWine,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixHeader extends StatelessWidget {
  const _MatrixHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'Feature',
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: _PlanCode('Plus')),
        Expanded(child: _PlanCode('Gold')),
        Expanded(child: _PlanCode('Plat')),
      ],
    );
  }
}

class _PremiumPreviewStrip extends StatelessWidget {
  const _PremiumPreviewStrip();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Premium previews',
            subtitle: 'Locked features are softened, clear, and upgrade-ready.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _LockedPreview(label: 'See Who Likes You'),
              _LockedPreview(label: 'Passport'),
              _LockedPreview(label: 'Incognito'),
              _LockedPreview(label: 'Advanced Filters'),
              _LockedPreview(label: 'Unlimited Rewinds'),
              _LockedPreview(label: 'Premium Events'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LockedPreview extends StatelessWidget {
  const _LockedPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.champagne.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.premiumGold.withValues(alpha: .38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, color: AppColors.premiumGold, size: 16),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.deepWine,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCode extends StatelessWidget {
  const _PlanCode(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.deepWine,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
