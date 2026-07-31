import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class LikedYouPaywallScreen extends StatefulWidget {
  const LikedYouPaywallScreen({super.key});

  static const routeName = '/liked-you-paywall';
  static const aliasRouteName = '/liked-you';

  @override
  State<LikedYouPaywallScreen> createState() => _LikedYouPaywallScreenState();
}

class _LikedYouPaywallScreenState extends State<LikedYouPaywallScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final profiles = [
      'Kavya',
      'Aadhya',
      'Riya',
      'Ananya',
    ].map(ImageRepository.profileByName).toList();
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
                        'See Who Liked You',
                        style: AmoraTextStyles.headlineMedium.copyWith(
                          color: AppColors.deepWine,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space20),
                PremiumCard(
                  color: AppColors.lavenderBackground,
                  child: Text(
                    _unlocked
                        ? 'Preview unlocked locally for this session.'
                        : '18 people liked you. Unlock Gold to see every admirer.',
                    style: AmoraTextStyles.titleLarge.copyWith(
                      color: AppColors.deepWine,
                    ),
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: profiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AmoraSpacing.space12,
                    mainAxisSpacing: AmoraSpacing.space12,
                    childAspectRatio: .78,
                  ),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    return _LockedProfileCard(
                      imageUrl: profile.imageUrl,
                      fallback: profile.fallbackAsset,
                      name: _unlocked ? profile.name : 'Premium like',
                      locked: !_unlocked,
                    );
                  },
                ),
                const SizedBox(height: AmoraSpacing.space16),
                AppPrimaryButton(
                  label: _unlocked ? 'Unlocked' : 'Unlock With Gold',
                  icon: Icons.workspace_premium_rounded,
                  onPressed: _unlocked
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushNamed(SubscriptionScreen.routeName),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                AppPrimaryButton(
                  label: 'Demo unlock locally',
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: () => setState(() => _unlocked = true),
                  icon: Icons.lock_open_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedProfileCard extends StatelessWidget {
  const _LockedProfileCard({
    required this.imageUrl,
    required this.fallback,
    required this.name,
    required this.locked,
  });

  final String imageUrl;
  final String fallback;
  final String name;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      radius: AmoraRadius.extraLarge,
      child: ClipRRect(
        borderRadius: AmoraRadius.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumAssetImage(
              imageUrl: imageUrl,
              fallbackAsset: fallback,
              initials: 'AM',
              borderRadius: AmoraRadius.card,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .42),
              ),
            ),
            if (locked)
              Positioned(
                top: AmoraSpacing.space12,
                right: AmoraSpacing.space12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.deepWine,
                    borderRadius: AmoraRadius.pillBorder,
                    border: Border.all(color: AppColors.deepWine),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AmoraSpacing.space12,
                      vertical: AmoraSpacing.space8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.surface,
                          size: 15,
                        ),
                        const SizedBox(width: AmoraSpacing.space4),
                        Text(
                          'Gold',
                          style: AmoraTextStyles.labelMedium.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AmoraSpacing.space12,
              right: AmoraSpacing.space12,
              bottom: AmoraSpacing.space12,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
