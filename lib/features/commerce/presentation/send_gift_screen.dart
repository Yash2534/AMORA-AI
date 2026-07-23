import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class SendGiftScreen extends StatelessWidget {
  const SendGiftScreen({super.key});

  static const routeName = '/send-gift';

  @override
  Widget build(BuildContext context) {
    final gifts = const [
      _GiftOption(
        'Coffee Date',
        'A thoughtful cafe invite',
        Icons.coffee_rounded,
      ),
      _GiftOption('Flowers', 'Classic and warm', Icons.local_florist_rounded),
      _GiftOption(
        'Book Note',
        'For readers and slow conversations',
        Icons.menu_book_rounded,
      ),
    ];

    return Scaffold(
      body: SafeArea(
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
                      child: Text(
                        'Send a Gift',
                        style: AmoraTextStyles.headlineSmall.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 220,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const PremiumAssetImage(
                          imageUrl: AppImages.eventCoffee,
                          fallbackAsset: AppImages.fallbackEvent,
                          initials: 'GF',
                          borderRadius: BorderRadius.zero,
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.transparent,
                                AppColors.transparent,
                                AppColors.text,
                              ],
                              stops: [0, .50, 1],
                            ),
                          ),
                        ),
                        const Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Text(
                            'Pick something simple, premium, and personal.',
                            style: TextStyle(
                              color: AppColors.surface,
                              fontSize: 22,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (final gift in gifts) ...[
                  PremiumCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.lavenderBackground,
                          child: Icon(
                            gift.icon,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift.title,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                gift.subtitle,
                                style: const TextStyle(
                                  color: AppColors.textGray,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AppPrimaryButton(
                  label: 'Send Gift',
                  icon: Icons.card_giftcard_rounded,
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Gift flow ready')),
                      );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftOption {
  const _GiftOption(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}
