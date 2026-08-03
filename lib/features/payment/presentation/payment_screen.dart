import 'dart:async';

import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/material.dart';

enum _PaymentViewState {
  review,
  processing,
  success,
  failure,
  cancelled,
  pending,
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  static const routeName = '/payment';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PaymentViewState _state = _PaymentViewState.review;
  String? _selectedMethod;
  bool _termsAccepted = false;
  bool _productionFailed = false;
  Timer? _processingTimer;

  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final review = _reviewData(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 760,
          child: AnimatedSwitcher(
            duration: AmoraMotion.page,
            child: switch (_state) {
              _PaymentViewState.review => _PaymentReview(
                key: const ValueKey('payment-review'),
                data: review,
                selectedMethod: _selectedMethod,
                termsAccepted: _termsAccepted,
                productionFailed: _productionFailed,
                onBack: () => Navigator.of(context).maybePop(),
                onChangePlan: () => Navigator.of(context).maybePop(),
                onMethodSelected: (value) =>
                    setState(() => _selectedMethod = value),
                onTermsChanged: (value) =>
                    setState(() => _termsAccepted = value),
                onPay: () => _pay(review),
              ),
              _PaymentViewState.processing => const PaymentStateView(
                key: ValueKey('payment-processing'),
                icon: Icons.sync_rounded,
                title: 'Confirming your membership',
                subtitle: 'Please keep this screen open.',
                processing: true,
              ),
              _PaymentViewState.success => PaymentStateView(
                key: const ValueKey('payment-success'),
                icon: Icons.favorite_rounded,
                title: 'Welcome to AMORAA Membership',
                subtitle: 'Your premium experience is ready.',
                benefits: const [
                  'Premium Events',
                  'Enhanced AI Matches',
                  'Advanced Filters',
                ],
                primaryLabel: 'Explore Events',
                onPrimary: _openEvents,
                secondaryLabel: 'View Membership',
                onSecondary: _openMembership,
              ),
              _PaymentViewState.failure => PaymentStateView(
                key: const ValueKey('payment-failure'),
                icon: Icons.error_outline_rounded,
                title: 'Payment wasn’t completed',
                subtitle: 'Try again or choose another payment method.',
                primaryLabel: 'Try Again',
                onPrimary: () =>
                    setState(() => _state = _PaymentViewState.review),
                secondaryLabel: 'Change Plan',
                onSecondary: () => Navigator.of(context).maybePop(),
              ),
              _PaymentViewState.cancelled => PaymentStateView(
                key: const ValueKey('payment-cancelled'),
                icon: Icons.close_rounded,
                title: 'Payment cancelled',
                subtitle: 'No membership changes were made.',
                primaryLabel: 'Return to Payment',
                onPrimary: () =>
                    setState(() => _state = _PaymentViewState.review),
                secondaryLabel: 'Return to Membership',
                onSecondary: () => Navigator.of(context).maybePop(),
              ),
              _PaymentViewState.pending => PaymentStateView(
                key: const ValueKey('payment-pending'),
                icon: Icons.schedule_rounded,
                title: 'Confirmation is pending',
                subtitle:
                    'We’ll update your membership when the payment is confirmed.',
                primaryLabel: membershipTestMode ? 'Continue Testing' : 'Done',
                onPrimary: () => membershipTestMode
                    ? setState(() => _state = _PaymentViewState.review)
                    : Navigator.of(context).maybePop(),
                secondaryLabel: 'View Membership',
                onSecondary: _openMembership,
              ),
            },
          ),
        ),
      ),
    );
  }

  _PaymentReviewData _reviewData(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (membershipTestMode && args is MembershipPaymentArgs) {
      return _PaymentReviewData.test(args.plan);
    }
    if (args is PaymentArgs) return _PaymentReviewData.production(args);
    return _PaymentReviewData.production(
      const PaymentArgs(title: 'Gold', billingCycle: 'Monthly', amount: 1999),
    );
  }

  void _pay(_PaymentReviewData review) {
    if (_selectedMethod == null) {
      showPremiumSnack(context, 'Select a payment method');
      return;
    }
    if (!_termsAccepted) {
      showPremiumSnack(context, 'Accept the membership terms to continue');
      return;
    }
    if (!membershipTestMode) {
      _runExistingProductionPresentation(review);
      return;
    }

    final controller = MembershipTestFlowController.instance;
    setState(() => _state = _PaymentViewState.processing);
    controller.setProcessing(true);
    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted) return;
      controller.setProcessing(false);
      switch (controller.nextOutcome) {
        case TestPaymentOutcome.success:
          controller.activateMembership();
          setState(() => _state = _PaymentViewState.success);
        case TestPaymentOutcome.failure:
          setState(() => _state = _PaymentViewState.failure);
        case TestPaymentOutcome.cancelled:
          setState(() => _state = _PaymentViewState.cancelled);
        case TestPaymentOutcome.pending:
          setState(() => _state = _PaymentViewState.pending);
      }
    });
  }

  void _runExistingProductionPresentation(_PaymentReviewData review) {
    if (_selectedMethod == 'Razorpay Gateway' && !_productionFailed) {
      setState(() => _productionFailed = true);
      showPremiumSnack(context, 'Payment could not be completed. Try again.');
      return;
    }
    showAmoraDialog<void>(
      context: context,
      title: 'Payment successful',
      message: 'Your ${review.title} plan is now active.',
      icon: Icons.check_rounded,
      primaryLabel: 'Continue',
      onPrimary: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false),
    );
  }

  void _openEvents() {
    if (!membershipTestMode ||
        !MembershipTestFlowController.instance.membershipActive) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(EventsScreen.routeName, (route) => false);
  }

  void _openMembership() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(SubscriptionScreen.routeName, (route) => false);
  }
}

class _PaymentReview extends StatelessWidget {
  const _PaymentReview({
    super.key,
    required this.data,
    required this.selectedMethod,
    required this.termsAccepted,
    required this.productionFailed,
    required this.onBack,
    required this.onChangePlan,
    required this.onMethodSelected,
    required this.onTermsChanged,
    required this.onPay,
  });

  final _PaymentReviewData data;
  final String? selectedMethod;
  final bool termsAccepted;
  final bool productionFailed;
  final VoidCallback onBack;
  final VoidCallback onChangePlan;
  final ValueChanged<String> onMethodSelected;
  final ValueChanged<bool> onTermsChanged;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final testController = MembershipTestFlowController.instance;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
          sliver: SliverList.list(
            children: [
              _PaymentAppBar(onBack: onBack),
              const SizedBox(height: 20),
              _PaymentReviewCard(data: data, onChangePlan: onChangePlan),
              const SizedBox(height: 22),
              const _PaymentSectionTitle('Included with membership'),
              const SizedBox(height: 10),
              const _IncludedBenefits(),
              const SizedBox(height: 22),
              const _PaymentSectionTitle('Payment summary'),
              const SizedBox(height: 10),
              _PaymentBreakdown(data: data),
              const SizedBox(height: 22),
              const _PaymentSectionTitle('Payment method'),
              const SizedBox(height: 10),
              if (membershipTestMode)
                for (final method in membershipTestPaymentMethods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: PaymentMethodOption(
                      id: method.id,
                      label: method.label,
                      subtitle: method.subtitle,
                      icon: method.icon,
                      selected: selectedMethod == method.id,
                      onTap: () => onMethodSelected(method.id),
                    ),
                  )
              else
                for (final method in paymentMethods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: PaymentMethodOption(
                      id: method.name,
                      label: method.name,
                      subtitle: method.subtitle,
                      icon: method.icon,
                      selected: selectedMethod == method.name,
                      onTap: () => onMethodSelected(method.name),
                    ),
                  ),
              if (productionFailed) ...[
                const SizedBox(height: 4),
                const _InlineNotice(
                  icon: Icons.error_outline_rounded,
                  text:
                      'The configured payment presentation reported a failure. '
                      'Choose another method or try again.',
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                value: termsAccepted,
                onChanged: (value) => onTermsChanged(value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I agree to the membership terms and renewal disclosure.',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const _InlineNotice(
                icon: Icons.lock_rounded,
                text:
                    'Your plan renews according to the selected billing interval '
                    'until cancelled through membership management.',
              ),
              if (membershipTestMode) ...[
                const SizedBox(height: 18),
                _TestOutcomeControl(controller: testController),
              ],
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Pay ${formatMembershipAmount(data.amount)}',
                icon: Icons.lock_rounded,
                onPressed: onPay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentAppBar extends StatelessWidget {
  const _PaymentAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review membership',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Confirm your plan before continuing.',
                style: TextStyle(color: AppColors.text, fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.shield_rounded, color: AppColors.secondary),
      ],
    );
  }
}

class _PaymentReviewCard extends StatelessWidget {
  const _PaymentReviewCard({required this.data, required this.onChangePlan});

  final _PaymentReviewData data;
  final VoidCallback onChangePlan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.surface),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AMORAA Membership',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onChangePlan,
                style: TextButton.styleFrom(foregroundColor: AppColors.surface),
                child: const Text('Change Plan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${data.duration} · ${data.interval}',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha: .84),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            formatMembershipAmount(data.amount),
            semanticsLabel: '${data.amount} Indian rupees',
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodOption extends StatelessWidget {
  const PaymentMethodOption({
    super.key,
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: AmoraMotion.selection,
        decoration: BoxDecoration(
          color: selected ? AppColors.tertiary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.tertiary,
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          child: ListTile(
            minTileHeight: 64,
            onTap: onTap,
            leading: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.secondary),
            ),
            title: Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(subtitle),
            trailing: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({required this.data});

  final _PaymentReviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _AmountRow(label: 'Plan price', amount: data.amount),
          const Divider(height: 24, color: AppColors.tertiary),
          _AmountRow(label: 'Total', amount: data.amount, strong: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.strong = false,
  });

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: strong ? AppColors.primary : AppColors.text,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          formatMembershipAmount(amount),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: strong ? 19 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _IncludedBenefits extends StatelessWidget {
  const _IncludedBenefits();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BenefitPill('Premium Events'),
        _BenefitPill('Advanced Filters'),
        _BenefitPill('Enhanced AI Matches'),
        _BenefitPill('Priority visibility'),
      ],
    );
  }
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, color: AppColors.secondary, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestOutcomeControl extends StatelessWidget {
  const _TestOutcomeControl({required this.controller});

  final MembershipTestFlowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        collapsedBackgroundColor: AppColors.surface,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        leading: const Icon(Icons.science_rounded, color: AppColors.secondary),
        title: const Text(
          'Test Options',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text('Next result: ${_outcomeLabel(controller.nextOutcome)}'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: AmoraaCompactSelect<TestPaymentOutcome>(
              label: 'Next test result',
              value: controller.nextOutcome,
              prefixIcon: Icons.science_rounded,
              options: [
                for (final outcome in TestPaymentOutcome.values)
                  AmoraaSelectOption(
                    value: outcome,
                    label: 'Simulate ${_outcomeLabel(outcome)}',
                  ),
              ],
              onChanged: (outcome) {
                if (outcome != null) controller.selectOutcome(outcome);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentStateView extends StatelessWidget {
  const PaymentStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.processing = false,
    this.benefits = const [],
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool processing;
  final List<String> benefits;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FadeUp(
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.tertiary),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: processing
                        ? const Padding(
                            padding: EdgeInsets.all(23),
                            child: CircularProgressIndicator(
                              color: AppColors.secondary,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(icon, size: 34, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  if (benefits.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    for (final benefit in benefits)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.secondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(benefit)),
                          ],
                        ),
                      ),
                  ],
                  if (primaryLabel != null) ...[
                    const SizedBox(height: 22),
                    AppPrimaryButton(
                      label: primaryLabel!,
                      onPressed: onPrimary,
                    ),
                  ],
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: 7),
                    AppPrimaryButton(
                      label: secondaryLabel!,
                      variant: AppPrimaryButtonVariant.outlined,
                      onPressed: onSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentSectionTitle extends StatelessWidget {
  const _PaymentSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PaymentReviewData {
  const _PaymentReviewData({
    required this.title,
    required this.duration,
    required this.interval,
    required this.amount,
  });

  factory _PaymentReviewData.test(MembershipTestPlan plan) {
    return _PaymentReviewData(
      title: plan.title,
      duration: plan.durationLabel,
      interval: plan.intervalLabel,
      amount: plan.amount,
    );
  }

  factory _PaymentReviewData.production(PaymentArgs args) {
    return _PaymentReviewData(
      title: args.title,
      duration: args.billingCycle,
      interval: args.billingCycle,
      amount: args.amount,
    );
  }

  final String title;
  final String duration;
  final String interval;
  final int amount;
}

String _outcomeLabel(TestPaymentOutcome outcome) => switch (outcome) {
  TestPaymentOutcome.success => 'Success',
  TestPaymentOutcome.failure => 'Failure',
  TestPaymentOutcome.cancelled => 'Cancelled',
  TestPaymentOutcome.pending => 'Pending',
};
