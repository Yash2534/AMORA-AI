import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
import 'package:flutter/material.dart';

class GiftShopCatalogScreen extends StatefulWidget {
  const GiftShopCatalogScreen({super.key});
  static const routeName = '/gift-shop-catalog';
  @override
  State<GiftShopCatalogScreen> createState() => _GiftShopCatalogScreenState();
}

class _GiftShopCatalogScreenState extends State<GiftShopCatalogScreen> {
  List<GiftProduct> _gifts = const [];
  bool _loading = true;
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
      final gifts = await MonetizationRepository.instance.gifts();
      if (mounted) {
        setState(() {
          _gifts = gifts;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AmoraAppBar(
      title: 'Gift Catalog',
      subtitle: 'Prices are loaded from AMORAA',
      onBack: () => Navigator.of(context).maybePop(),
    ),
    body: SafeArea(
      top: false,
      child: ResponsiveMobileFrame(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: FilledButton(
                  onPressed: _load,
                  child: const Text('Retry Gift Catalog'),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    AmoraSpacing.space16,
                    20,
                    AmoraSpacing.navigationContentInset,
                  ),
                  children: [
                    if (_gifts.isEmpty)
                      const PremiumCard(
                        child: Text('No gifts are currently available.'),
                      ),
                    for (final gift in _gifts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PremiumCard(
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.lavenderBackground,
                                child: Icon(
                                  gift.type == 'rose'
                                      ? Icons.local_florist_rounded
                                      : Icons.card_giftcard_rounded,
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      gift.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (gift.description != null)
                                      Text(
                                        gift.description!,
                                        style: const TextStyle(
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '${gift.priceCredits} credits',
                                style: const TextStyle(
                                  color: AppColors.primaryPurple,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const PremiumCard(
                      child: Text(
                        'Open a profile or match to choose a recipient and send a gift. Your wallet is charged only after the server confirms the transaction.',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}
