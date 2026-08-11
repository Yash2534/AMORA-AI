import 'dart:async';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:flutter/material.dart';

class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({super.key, this.discoverApiService});
  static const routeName = '/profile-boost';
  final DiscoverApiService? discoverApiService;
  @override
  State<ProfileBoostScreen> createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen> {
  List<BoostProduct> _products = const [];
  BoostState? _boost;
  int _selected = 0;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  String? _activationIdempotencyKey;
  Timer? _timer;
  late final DiscoverApiService _discoverApi;
  @override
  void initState() {
    super.initState();
    _discoverApi = widget.discoverApiService ?? DiscoverApiService();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _boost?.active == true) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = MonetizationRepository.instance;
      final products = await repo.boostProducts();
      final boost = await repo.boostState();
      if (mounted) {
        setState(() {
          _products = products;
          _boost = boost;
          _selected = _selected.clamp(
            0,
            products.isEmpty ? 0 : products.length - 1,
          );
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  int get _seconds => _boost?.activeUntil == null
      ? 0
      : (_boost!.activeUntil!.difference(DateTime.now()).inSeconds).clamp(
          0,
          86400,
        );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ResponsiveMobileFrame(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: FilledButton(
                  onPressed: _load,
                  child: const Text('Retry Boost'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  AmoraSpacing.navigationContentInset,
                ),
                children: [
                  Row(
                    children: [
                      AmoraHeaderBackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: AmoraScreenTitle(title: 'Profile Boost'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PremiumCard(
                    color: AppColors.premiumGold.withValues(alpha: .14),
                    child: Column(
                      children: [
                        Text(
                          _seconds > 0
                              ? _format(_seconds)
                              : '${_boost?.available ?? 0} available',
                          style: const TextStyle(
                            color: AppColors.deepWine,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _seconds > 0
                              ? 'Boost is live in nearby discovery.'
                              : 'Inventory and activation are controlled by AMORAA.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var index = 0; index < _products.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _selected == index
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: AppColors.primaryPurple,
                        ),
                        title: Text(_products[index].name),
                        subtitle: Text(
                          '${_products[index].durationMinutes} minutes · ${_products[index].walletCost} credits · ₹${_products[index].priceMinor ~/ 100}',
                        ),
                        onTap: _acting
                            ? null
                            : () => setState(() => _selected = index),
                      ),
                    ),
                  if (_products.isEmpty)
                    const PremiumCard(
                      child: Text('No Boost products are available.'),
                    ),
                  if ((_boost?.available ?? 0) > 0)
                    AppPrimaryButton(
                      label: _seconds > 0 ? 'Boost Active' : 'Activate Boost',
                      icon: AmoraIcons.boost,
                      onPressed: _seconds > 0 || _acting ? null : _activate,
                    ),
                  if ((_boost?.available ?? 0) == 0 &&
                      _products.isNotEmpty) ...[
                    AppPrimaryButton(
                      label: 'Buy with Wallet',
                      icon: AmoraIcons.wallet,
                      onPressed: _acting ? null : _buyWithWallet,
                    ),
                    const SizedBox(height: 10),
                    AppPrimaryButton(
                      label: 'Pay with Razorpay',
                      icon: Icons.payment_rounded,
                      variant: AppPrimaryButtonVariant.outlined,
                      onPressed: _acting ? null : _pay,
                    ),
                  ],
                ],
              ),
      ),
    ),
  );

  Future<void> _activate() async {
    if (_acting) return;
    setState(() => _acting = true);
    _activationIdempotencyKey ??= MonetizationRepository.instance
        .newIdempotencyKey('boost-activation');
    try {
      final result = await _discoverApi.boost(_activationIdempotencyKey!);
      if (!result.success) {
        if (!isRetryableDiscoverFailure(result.statusCode)) {
          _activationIdempotencyKey = null;
        }
        if (mounted) showPremiumSnack(context, result.message);
        return;
      }
      _activationIdempotencyKey = null;
      final canonical = await MonetizationRepository.instance.boostState();
      if (mounted) setState(() => _boost = canonical);
    } catch (error) {
      if (mounted) {
        showPremiumSnack(context, 'Boost activation could not be confirmed');
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _buyWithWallet() async {
    setState(() => _acting = true);
    try {
      _boost = await MonetizationRepository.instance.purchaseBoost(
        _products[_selected].id,
        'wallet',
        MonetizationRepository.instance.newIdempotencyKey('boost-wallet'),
      );
      if (mounted) showPremiumSnack(context, 'Boost added to inventory');
    } catch (_) {
      if (mounted) {
        showPremiumSnack(context, 'Boost purchase could not be completed');
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _pay() async {
    final product = _products[_selected];
    await Navigator.of(context).pushNamed(
      PaymentScreen.routeName,
      arguments: PaymentArgs(
        productId: product.id,
        productType: 'boost',
        title: product.name,
        subtitle: 'AMORAA Boost',
        billingCycle: 'One-time boost entitlement',
        amountMinor: product.priceMinor,
        currency: product.currency,
      ),
    );
    if (mounted) _load();
  }

  String _format(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
}
