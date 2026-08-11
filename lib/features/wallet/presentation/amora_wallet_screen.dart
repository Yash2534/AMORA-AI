import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
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
  WalletState? _wallet;
  List<WalletProduct> _topUps = const [];
  List<WalletProduct> _redemptions = const [];
  List<WalletLedgerItem> _transactions = const [];
  WalletProduct? _selected;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = MonetizationRepository.instance;
      final wallet = await repo.wallet();
      final products = await repo.walletProducts();
      final ledger = await repo.walletTransactions(limit: 20);
      if (!mounted) return;
      setState(() {
        _wallet = wallet;
        _topUps = products.where((item) => item.type == 'top_up').toList();
        _redemptions = products
            .where((item) => item.type == 'redemption')
            .toList();
        _selected = _topUps.firstOrNull;
        _transactions = ledger.items;
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
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'AMORAA Wallet',
        subtitle: 'Server-owned credits and complete ledger',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Wallet could not be loaded.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AmoraSpacing.space16,
                      20,
                      20,
                      AmoraSpacing.navigationContentInset,
                    ),
                    children: [
                      PremiumCard(
                        color: AppColors.primaryPurple,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available balance',
                              style: TextStyle(
                                color: AppColors.surface.withValues(alpha: .7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_wallet!.balance} credits',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _wallet!.status,
                              style: TextStyle(
                                color: AppColors.surface.withValues(alpha: .7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Top-up products'),
                      const SizedBox(height: 10),
                      for (final product in _topUps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              _selected?.id == product.id
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: AppColors.primaryPurple,
                            ),
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.credits} credits · ₹${(product.priceMinor ?? 0) ~/ 100}',
                            ),
                            onTap: () => setState(() => _selected = product),
                          ),
                        ),
                      if (_selected != null)
                        AppPrimaryButton(
                          label: 'Top Up ${_selected!.credits} Credits',
                          icon: AmoraIcons.wallet,
                          onPressed: _acting ? null : _topUp,
                        ),
                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Redemption options'),
                      const SizedBox(height: 10),
                      if (_redemptions.isEmpty)
                        const Text(
                          'No redemption products are currently available.',
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final product in _redemptions)
                              ActionChip(
                                label: Text(
                                  '${product.name} · ${product.credits} credits',
                                ),
                                onPressed: _acting
                                    ? null
                                    : () => _redeem(product),
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      const SectionTitle(title: 'Transaction history'),
                      const SizedBox(height: 10),
                      if (_transactions.isEmpty)
                        const PremiumCard(
                          child: Text('No wallet transactions yet.'),
                        )
                      else
                        PremiumCard(
                          child: Column(
                            children: [
                              for (final item in _transactions)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item.description ?? item.type),
                                  subtitle: Text(
                                    '${item.createdAt.toLocal()} · ${item.status}',
                                  ),
                                  trailing: Text(
                                    '${item.direction == 'credit' ? '+' : '-'}${item.amount}',
                                    style: TextStyle(
                                      color: item.direction == 'credit'
                                          ? AppColors.successGreen
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _topUp() async {
    final product = _selected;
    if (product == null) return;
    await Navigator.of(context).pushNamed(
      PaymentScreen.routeName,
      arguments: PaymentArgs(
        productId: product.id,
        productType: 'wallet_top_up',
        title: product.name,
        subtitle: 'AMORAA Wallet Top Up',
        billingCycle: 'One-time wallet recharge',
        amountMinor: product.priceMinor!,
        currency: product.currency!,
      ),
    );
    if (mounted) _load();
  }

  Future<void> _redeem(WalletProduct product) async {
    setState(() => _acting = true);
    try {
      await MonetizationRepository.instance.redeem(
        product.id,
        MonetizationRepository.instance.newIdempotencyKey('wallet-redemption'),
      );
      if (mounted) {
        showPremiumSnack(context, '${product.name} redeemed');
        await _load();
      }
    } catch (_) {
      if (mounted) {
        showPremiumSnack(context, 'Redemption could not be completed');
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }
}
