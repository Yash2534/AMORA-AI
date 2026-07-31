import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/commerce/presentation/send_gift_screen.dart';
import 'package:flutter/material.dart';

class GiftShopCatalogScreen extends StatefulWidget {
  const GiftShopCatalogScreen({super.key});

  static const routeName = '/gift-shop-catalog';

  @override
  State<GiftShopCatalogScreen> createState() => _GiftShopCatalogScreenState();
}

class _GiftShopCatalogScreenState extends State<GiftShopCatalogScreen> {
  String _category = 'Flowers';
  final List<_Gift> _cart = [];

  @override
  Widget build(BuildContext context) {
    final gifts = _gifts.where((gift) => gift.category == _category).toList();
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(AmoraIcons.back),
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gift Catalog',
                              style: AmoraTextStyles.headlineSmall.copyWith(
                                color: AppColors.deepWine,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Small gestures for warmer connections.',
                              style: TextStyle(
                                color: AppColors.textGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Text(
                          '${_cart.length} cart',
                          style: const TextStyle(
                            color: AppColors.deepWine,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in _categories)
                        ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          showCheckmark: false,
                          selectedColor: AppColors.primaryPurple,
                          labelStyle: TextStyle(
                            color: _category == category
                                ? AppColors.surface
                                : AppColors.deepWine,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final gift in gifts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GiftCard(
                        gift: gift,
                        onAdd: () {
                          setState(() => _cart.add(gift));
                          _snack('${gift.name} added to cart');
                        },
                        onPreview: () => _preview(gift),
                      ),
                    ),
                  const SizedBox(height: 10),
                  AppPrimaryButton(
                    label: 'Send Gift',
                    icon: Icons.card_giftcard_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(SendGiftScreen.routeName),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _preview(_Gift gift) {
    showAmoraBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            gift.name,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(gift.description),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: 'Gift Success Preview',
            icon: Icons.check_rounded,
            onPressed: () {
              Navigator.pop(context);
              _snack('Gift preview confirmed');
            },
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({
    required this.gift,
    required this.onAdd,
    required this.onPreview,
  });
  final _Gift gift;
  final VoidCallback onAdd;
  final VoidCallback onPreview;
  @override
  Widget build(BuildContext context) {
    final venue = ImageRepository.venueByName('Velvet Bean Luxury Cafe');
    return PremiumCard(
      child: Row(
        children: [
          PremiumAssetImage(
            imageUrl: venue.imageUrl,
            fallbackAsset: venue.fallbackAsset,
            initials: 'GF',
            width: 82,
            height: 92,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  gift.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Rs ${gift.price} - ${gift.popularity}% popular',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onPreview,
                        child: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: onAdd,
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Gift {
  const _Gift(
    this.category,
    this.name,
    this.price,
    this.description,
    this.popularity,
  );
  final String category;
  final String name;
  final int price;
  final String description;
  final int popularity;
}

const _categories = [
  'Flowers',
  'Coffee',
  'Chocolate',
  'Books',
  'Travel',
  'Luxury',
  'Virtual',
  'Festival',
];
const _gifts = [
  _Gift(
    'Flowers',
    'Rose Ritual',
    299,
    'A romantic rose note with AMORAA styling.',
    92,
  ),
  _Gift(
    'Coffee',
    'Coffee Date Pass',
    399,
    'A warm invite for a verified cafe date.',
    88,
  ),
  _Gift(
    'Chocolate',
    'Artisan Box',
    499,
    'Small-batch chocolate with a personal note.',
    84,
  ),
  _Gift(
    'Books',
    'Bookstore Token',
    599,
    'For readers and thoughtful first dates.',
    79,
  ),
  _Gift('Travel', 'Weekend Spark', 999, 'A travel-inspired digital gift.', 73),
  _Gift(
    'Luxury',
    'Fine Dining Invite',
    1999,
    'A premium dinner invitation for an intentional date.',
    91,
  ),
  _Gift('Virtual', 'Heart Burst', 99, 'Lightweight virtual affection.', 95),
  _Gift('Festival', 'Garba Glow', 699, 'Festival-season gift card.', 86),
];
