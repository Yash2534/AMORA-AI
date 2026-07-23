import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  static const routeName = '/payment';

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _couponController = TextEditingController();
  String? _selectedMethod;
  var _couponApplied = false;
  var _termsAccepted = false;
  var _failed = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = _args(context);
    final gst = (args.amount * .18).round();
    final discount = _couponApplied ? (args.amount * .30).round() : 0;
    final grandTotal = args.amount + gst - discount;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.lavenderBackground],
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
                    title: 'Secure Payment',
                    subtitle:
                        'Protected checkout with encrypted payment details.',
                    icon: AmoraIcons.lock,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AmoraSpacing.space20),
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          args.subtitle,
                          style: AmoraTextStyles.labelLarge.copyWith(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${args.title} plan',
                          style: AmoraTextStyles.headlineSmall.copyWith(
                            color: AppColors.deepWine,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          args.billingCycle,
                          style: AmoraTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_failed) ...[
                    PremiumCard(
                      color: AppColors.background,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_rounded,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Payment failed in placeholder mode. Try another method or retry.',
                              style: TextStyle(
                                color: AppColors.deepWine,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _failed = false),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SectionTitle(title: 'Order Summary'),
                  const SizedBox(height: 12),
                  PremiumCard(
                    child: Column(
                      children: [
                        _PriceRow('Amount', args.amount),
                        _PriceRow('GST', gst),
                        _PriceRow('Discount coupon', -discount),
                        _PriceRow('GST invoice', 0),
                        const Divider(height: 24),
                        _PriceRow('Grand total', grandTotal, strong: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle(title: 'Coupon'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _couponController,
                          label: 'Coupon code',
                          hint: 'AMORA30',
                          icon: AmoraIcons.ticket,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 100,
                        child: AppPrimaryButton(
                          label: 'Apply',
                          onPressed: _applyCoupon,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const SectionTitle(title: 'Payment Methods'),
                  const SizedBox(height: 12),
                  for (final method in paymentMethods)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PaymentMethodTile(
                        method: method,
                        selected: _selectedMethod == method.name,
                        onTap: () =>
                            setState(() => _selectedMethod = method.name),
                      ),
                    ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _termsAccepted,
                    onChanged: (value) =>
                        setState(() => _termsAccepted = value ?? false),
                    title: const Text(
                      'I agree to AMORA payment terms and cashless billing.',
                      style: TextStyle(
                        color: AppColors.deepWine,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Pay Now',
                    icon: AmoraIcons.lock,
                    onPressed: () => _pay(args),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PaymentArgs _args(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PaymentArgs) return args;
    return const PaymentArgs(
      title: 'Gold',
      billingCycle: 'Monthly',
      amount: 1999,
    );
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (_couponApplied) {
      showPremiumSnack(context, 'Coupon already applied');
      return;
    }
    if (code != 'AMORA30') {
      showPremiumSnack(context, 'Enter valid coupon AMORA30');
      return;
    }
    setState(() => _couponApplied = true);
    showPremiumSnack(context, 'AMORA30 applied: 30% off');
  }

  void _pay(PaymentArgs args) {
    if (_selectedMethod == null) {
      showPremiumSnack(context, 'Select a payment method');
      return;
    }
    if (!_termsAccepted) {
      showPremiumSnack(context, 'Accept terms to continue');
      return;
    }
    if (_selectedMethod == 'Razorpay Gateway' && !_failed) {
      setState(() => _failed = true);
      showPremiumSnack(context, 'Razorpay placeholder failure simulated');
      return;
    }
    showAmoraDialog<void>(
      context: context,
      title: 'Payment successful',
      message: 'Your ${args.title} plan is now active.',
      icon: AmoraIcons.check,
      primaryLabel: 'Continue',
      onPrimary: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.amount, {this.strong = false});

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: strong ? AppColors.deepWine : AppColors.textGray,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}${money(amount.abs())}',
            style: TextStyle(
              color: amount < 0 ? AppColors.successGreen : AppColors.deepWine,
              fontSize: strong ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
