import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  static const routeName = '/subscription';
  static const membershipRoute = '/membership';
  static const manageRoute = '/manage-subscription';

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  var _selectedProductionPlan = 0;
  var _plans = const <MonetizationPlan>[];
  var _membership = MembershipState.none;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!membershipTestMode) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plans = await MonetizationRepository.instance.plans();
      final membership = await MonetizationRepository.instance
          .refreshMembership();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _membership = membership;
        _selectedProductionPlan = plans.length > 1 ? 1 : 0;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final testFlow = MembershipTestFlowController.instance;
    if (!membershipTestMode && _loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!membershipTestMode && _error != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Membership could not be loaded.'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }
    return ListenableBuilder(
      listenable: testFlow,
      builder: (context, _) {
        final activeProductionPlan = _membership.premium
            ? _membership.plan
            : null;
        final memberActive =
            testFlow.membershipActive || activeProductionPlan != null;
        final manageView =
            ModalRoute.of(context)?.settings.name ==
            SubscriptionScreen.manageRoute;
        if (manageView) {
          return _buildManageSubscription(
            memberActive: memberActive,
            planName: activeProductionPlan?.name ?? testFlow.selectedPlan.title,
            billingLabel: membershipTestMode
                ? '${formatMembershipAmount(testFlow.selectedPlan.amount)} · ${testFlow.selectedPlan.intervalLabel}'
                : activeProductionPlan == null
                ? 'No billing schedule'
                : '${formatMembershipAmount(activeProductionPlan.priceMajor)} · billed ${activeProductionPlan.billingPeriod}',
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AmoraAppBar(
            title: 'AMORAA Membership',
            subtitle: 'Connect better. Meet meaningfully.',
            onBack: () => Navigator.of(context).maybePop(),
            maxContentWidth: 980,
          ),
          body: SafeArea(
            top: false,
            child: ResponsiveMobileFrame(
              maxWidth: 980,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
                    sliver: SliverList.list(
                      children: [
                        const MembershipHeroCompact(),
                        const SizedBox(height: 26),
                        if (memberActive)
                          CurrentMembershipCard(
                            planName:
                                activeProductionPlan?.name ??
                                testFlow.selectedPlan.title,
                            onEvents: () => Navigator.of(
                              context,
                            ).pushNamed(EventsScreen.routeName),
                            onManage: _manageMembership,
                          )
                        else ...[
                          const _SectionTitle(
                            title: 'Choose your membership',
                            subtitle:
                                'Select the pace that feels right for you.',
                          ),
                          const SizedBox(height: 12),
                          if (membershipTestMode)
                            _TestPlanSelector(
                              selected: testFlow.selectedPlan,
                              onSelected: testFlow.selectPlan,
                            )
                          else
                            _ProductionPlanSelector(
                              plans: _plans,
                              selectedIndex: _selectedProductionPlan,
                              onSelected: (index) => setState(
                                () => _selectedProductionPlan = index,
                              ),
                            ),
                        ],
                        if (!membershipTestMode && !memberActive) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Monthly billing is the only duration currently '
                            'configured for these plans.',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        const _BillingTrustCard(),
                        const SizedBox(height: 20),
                        if (!memberActive)
                          AppPrimaryButton(
                            label: membershipTestMode
                                ? 'Continue with ${testFlow.selectedPlan.title}'
                                : _plans.isEmpty
                                ? 'No plans available'
                                : 'Continue with ${_plans[_selectedProductionPlan].name}',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: !membershipTestMode && _plans.isEmpty
                                ? null
                                : _continueToPayment,
                          )
                        else
                          AppPrimaryButton(
                            label: 'Explore Member Events',
                            icon: Icons.event_rounded,
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(EventsScreen.routeName),
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _restoreOrManage,
                          icon: const Icon(Icons.restore_rounded),
                          label: Text(
                            memberActive
                                ? 'Manage Membership'
                                : 'Restore Purchase',
                          ),
                        ),
                        if (membershipTestMode) ...[
                          const SizedBox(height: 10),
                          const _TestModeNotice(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildManageSubscription({
    required bool memberActive,
    required String planName,
    required String billingLabel,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AmoraAppBar(
        title: 'Manage Subscription',
        subtitle: 'Billing and membership controls',
        onBack: () => Navigator.of(context).maybePop(),
        maxContentWidth: 760,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 760,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space16,
                  AmoraSpacing.space20,
                  AmoraSpacing.space32,
                ),
                sliver: SliverList.list(
                  children: [
                    if (!memberActive)
                      PremiumCard(
                        radius: 24,
                        padding: const EdgeInsets.all(AmoraSpacing.space20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.card_membership_rounded,
                              size: 36,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AmoraSpacing.space12),
                            Text(
                              'No Active Subscription',
                              textAlign: TextAlign.center,
                              style: AmoraTextStyles.sectionTitle,
                            ),
                            const SizedBox(height: AmoraSpacing.space8),
                            Text(
                              'Choose a plan before billing, renewal, and cancellation controls become available.',
                              textAlign: TextAlign.center,
                              style: AmoraTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AmoraSpacing.space20),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pushReplacementNamed(
                                    SubscriptionScreen.membershipRoute,
                                  ),
                              child: const Text('View Membership Plans'),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      PremiumCard(
                        radius: 24,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _ManageSubscriptionRow(
                              icon: Icons.verified_rounded,
                              title: 'Current Subscription',
                              subtitle: '$planName · Active',
                            ),
                            const Divider(),
                            _ManageSubscriptionRow(
                              icon: Icons.receipt_long_rounded,
                              title: 'Billing',
                              subtitle: billingLabel,
                            ),
                            const Divider(),
                            const _ManageSubscriptionRow(
                              icon: Icons.autorenew_rounded,
                              title: 'Renewal',
                              subtitle:
                                  'Managed by the configured payment provider',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space16),
                      OutlinedButton.icon(
                        onPressed: _manageMembership,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancellation Options'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueToPayment() {
    if (membershipTestMode) {
      Navigator.of(context).pushNamed(
        PaymentScreen.routeName,
        arguments: MembershipPaymentArgs(
          plan: MembershipTestFlowController.instance.selectedPlan,
        ),
      );
      return;
    }
    final plan = _plans[_selectedProductionPlan];
    Navigator.of(context).pushNamed(
      PaymentScreen.routeName,
      arguments: PaymentArgs(
        productId: plan.id,
        productType: 'subscription',
        title: plan.name,
        billingCycle: '${plan.billingInterval} ${plan.billingPeriod}',
        amountMinor: plan.priceMinor,
        currency: plan.currency,
      ),
    );
  }

  Future<void> _restoreOrManage() async {
    if (membershipTestMode) {
      showPremiumSnack(
        context,
        MembershipTestFlowController.instance.membershipActive
            ? 'Test membership is active for this app session'
            : 'No test purchase is available to restore',
      );
      return;
    }
    try {
      final restored = await MonetizationRepository.instance
          .restoreMembership();
      if (!mounted) return;
      setState(() => _membership = restored);
      showPremiumSnack(
        context,
        restored.premium
            ? 'Membership restored'
            : 'No previous purchase was found',
      );
    } catch (_) {
      if (mounted) {
        showPremiumSnack(context, 'Membership could not be restored');
      }
    }
  }

  Future<void> _manageMembership() async {
    if (membershipTestMode) {
      MembershipTestFlowController.instance.reset();
      showPremiumSnack(context, 'Test membership reset');
      return;
    }
    try {
      final updated = await MonetizationRepository.instance.cancelMembership();
      if (!mounted) return;
      setState(() => _membership = updated);
      showPremiumSnack(
        context,
        'Renewal cancelled; access remains until the period ends',
      );
    } catch (_) {
      if (mounted) showPremiumSnack(context, 'Membership could not be updated');
    }
  }
}

class _ManageSubscriptionRow extends StatelessWidget {
  const _ManageSubscriptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 72),
      child: Padding(
        padding: const EdgeInsets.all(AmoraSpacing.space16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AmoraTextStyles.cardTitle),
                  const SizedBox(height: AmoraSpacing.space4),
                  Text(
                    subtitle,
                    style: AmoraTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
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

class MembershipHeroCompact extends StatelessWidget {
  const MembershipHeroCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Symbol(icon: Icons.favorite_rounded),
                _Symbol(icon: Icons.verified_rounded),
                _Symbol(icon: Icons.auto_awesome_rounded),
                _Symbol(icon: Icons.chat_bubble_rounded),
                _Symbol(icon: Icons.event_rounded),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'More intention in every connection',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 23,
                height: 1.12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Designed for people who want thoughtful matches and curated '
              'ways to meet offline.',
              style: TextStyle(
                color: AppColors.surface.withValues(alpha: .88),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Symbol extends StatelessWidget {
  const _Symbol({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .14),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface.withValues(alpha: .25)),
      ),
      child: Icon(icon, size: 20, color: AppColors.surface),
    );
  }
}

class _TestPlanSelector extends StatelessWidget {
  const _TestPlanSelector({required this.selected, required this.onSelected});

  final MembershipTestPlan selected;
  final ValueChanged<MembershipTestPlan> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final cards = [
          for (final plan in membershipTestPlans)
            SubscriptionPlanCard.test(
              key: ValueKey(plan.id),
              plan: plan,
              selected: plan.id == selected.id,
              onTap: () => onSelected(plan),
            ),
        ];
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    Expanded(child: cards[index]),
                    if (index != cards.length - 1) const SizedBox(width: 12),
                  ],
                ],
              )
            : Column(
                children: [
                  for (var index = 0; index < cards.length; index++) ...[
                    cards[index],
                    if (index != cards.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
      },
    );
  }
}

class _ProductionPlanSelector extends StatelessWidget {
  const _ProductionPlanSelector({
    required this.plans,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<MonetizationPlan> plans;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < plans.length; index++) ...[
          SubscriptionPlanCard.production(
            key: ValueKey(plans[index].id),
            plan: plans[index],
            selected: selectedIndex == index,
            onTap: () => onSelected(index),
          ),
          if (index != plans.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  SubscriptionPlanCard.test({
    super.key,
    required MembershipTestPlan plan,
    required this.selected,
    required this.onTap,
  }) : _title = plan.title,
       _duration = plan.durationLabel,
       _amount = plan.amount,
       _monthly = plan.monthlyEquivalent,
       _bestValue = plan.bestValue,
       _tagline = '',
       _features = const [],
       _billingTerms = plan.intervalLabel;

  SubscriptionPlanCard.production({
    super.key,
    required MonetizationPlan plan,
    required this.selected,
    required this.onTap,
  }) : _title = plan.name,
       _duration = '${plan.billingInterval} ${plan.billingPeriod}',
       _amount = plan.priceMajor,
       _monthly = plan.priceMajor,
       _bestValue = plan.offerText != null,
       _tagline = plan.description ?? '',
       _features = plan.features,
       _billingTerms =
           'Billed every ${plan.billingInterval} ${plan.billingPeriod}';

  final String _title;
  final String _duration;
  final int _amount;
  final int _monthly;
  final bool _bestValue;
  final String _tagline;
  final List<String> _features;
  final String _billingTerms;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$_title plan, ${formatMembershipAmount(_amount)}',
      child: AnimatedContainer(
        duration: AmoraMotion.selection,
        decoration: BoxDecoration(
          color: selected ? AppColors.tertiary : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.secondary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: AmoraMotion.selection,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.surface,
                                size: 18,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _title,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_bestValue) const _BestValueBadge(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_duration · '
                              '${formatMembershipAmount(_monthly)}/month',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatMembershipAmount(_amount),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (_tagline.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _tagline,
                      style: const TextStyle(
                        color: AppColors.text,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (_features.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    for (final feature in _features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(feature)),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _billingTerms,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}

class _BestValueBadge extends StatelessWidget {
  const _BestValueBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Best value',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class MembershipBenefitGroup extends StatelessWidget {
  const MembershipBenefitGroup({
    super.key,
    required this.icon,
    required this.title,
    required this.benefits,
  });

  final IconData icon;
  final String title;
  final List<String> benefits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .65)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final benefit in benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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

class MembershipComparison extends StatelessWidget {
  const MembershipComparison({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Advanced Filters', 'Basic', 'Full access'),
      ('AI Match Insights', 'Limited', 'Enhanced'),
      ('Premium Events', 'Preview', 'Included'),
      ('Priority visibility', 'Standard', 'Included'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 2, child: Text('Feature')),
              Expanded(child: Text('Free', textAlign: TextAlign.center)),
              Expanded(child: Text('Member', textAlign: TextAlign.end)),
            ],
          ),
          const Divider(height: 22, color: AppColors.tertiary),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$3,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

class CurrentMembershipCard extends StatelessWidget {
  const CurrentMembershipCard({
    super.key,
    required this.planName,
    required this.onEvents,
    required this.onManage,
  });

  final String planName;
  final VoidCallback onEvents;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Membership active',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            planName,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Open Events',
            icon: Icons.event_rounded,
            onPressed: onEvents,
          ),
          const SizedBox(height: 8),
          AppPrimaryButton(
            label: 'Manage Membership',
            variant: AppPrimaryButtonVariant.outlined,
            onPressed: onManage,
          ),
        ],
      ),
    );
  }
}

class _BillingTrustCard extends StatelessWidget {
  const _BillingTrustCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Review your selected plan before continuing. Payment details '
              'are handled by the configured payment experience.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestModeNotice extends StatelessWidget {
  const _TestModeNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: const Row(
        children: [
          Icon(Icons.science_rounded, size: 18, color: AppColors.secondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Membership test mode · session-only simulation',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
