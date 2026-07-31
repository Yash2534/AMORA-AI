import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:amora_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';

class AmoraLandingScreen extends StatefulWidget {
  const AmoraLandingScreen({super.key});

  static const routeName = '/landing';

  @override
  State<AmoraLandingScreen> createState() => _AmoraLandingScreenState();
}

class _AmoraLandingScreenState extends State<AmoraLandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: AmoraMotion.emphasized)
      ..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 390
                    ? AmoraSpacing.space16
                    : AmoraSpacing.space24;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AmoraSpacing.space20,
                    padding,
                    AmoraSpacing.space24 +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LandingHeader(
                        onSignIn: () => Navigator.of(
                          context,
                        ).pushNamed(AmoraAuthScreen.routeName),
                      ),
                      const SizedBox(height: AmoraSpacing.space24),
                      _Staggered(
                        controller: _intro,
                        index: 0,
                        child: const _HeroSection(),
                      ),
                      const SizedBox(height: AmoraSpacing.space24),
                      _Staggered(
                        controller: _intro,
                        index: 1,
                        child: const _MetricStrip(),
                      ),
                      const SizedBox(height: AmoraSpacing.space20),
                      _SectionGrid(
                        title: 'Everything intentional dating needs',
                        items: _featureItems,
                      ),
                      const SizedBox(height: AmoraSpacing.space20),
                      const _EventsCoachSection(),
                      const SizedBox(height: AmoraSpacing.space20),
                      const _TestimonialSection(),
                      const SizedBox(height: AmoraSpacing.space20),
                      const _PremiumTeaser(),
                      const SizedBox(height: AmoraSpacing.space24),
                      AppPrimaryButton(
                        label: 'Create your AMORA AI',
                        icon: Icons.favorite_rounded,
                        onPressed: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(OnboardingScreen.routeName),
                      ),
                      const SizedBox(height: AmoraSpacing.space8),
                      AppPrimaryButton(
                        label: 'Already a member? Sign in',
                        variant: AppPrimaryButtonVariant.text,
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AmoraAuthScreen.routeName),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'amora-logo',
          child: Image.asset(
            AppImages.logo,
            width: 42,
            height: 42,
            fit: BoxFit.contain,
            semanticLabel: 'Amora',
          ),
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              AmoraBrandAssets.wordmark,
              height: 21,
              fit: BoxFit.contain,
              semanticLabel: 'AMORAA',
            ),
          ),
        ),
        AppPrimaryButton(
          label: 'Sign in',
          onPressed: onSignIn,
          variant: AppPrimaryButtonVariant.text,
          size: AmoraButtonSize.compact,
          fullWidth: false,
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Meet someone worth bringing home.',
          style: AmoraTextStyles.displaySmall,
        ),
        const SizedBox(height: AmoraSpacing.space12),
        Text(
          'A premium Indian dating experience with AI compatibility, verified profiles, safer dates, and curated real-world events.',
          style: AmoraTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space24),
        AspectRatio(
          aspectRatio: .92,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AmoraRadius.card,
                    color: AppColors.primary,
                    boxShadow: AmoraShadows.premiumCard,
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: AmoraRadius.card,
                  child: PremiumAssetImage(
                    imageUrl: AppImages.networkProfileKavya,
                    fallbackAsset: AppImages.profileAadhya,
                    initials: 'KA',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    borderRadius: AmoraRadius.card,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AmoraRadius.card,
                    color: AppColors.primary.withValues(alpha: .38),
                  ),
                ),
              ),
              const Positioned(
                left: AmoraSpacing.space16,
                right: AmoraSpacing.space16,
                bottom: AmoraSpacing.space16,
                child: _HeroMatchCard(),
              ),
              const Positioned(
                top: AmoraSpacing.space16,
                right: AmoraSpacing.space16,
                child: _SolidBadge(
                  icon: Icons.auto_awesome_rounded,
                  label: '94% AI',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroMatchCard extends StatelessWidget {
  const _HeroMatchCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      color: AppColors.surface,
      padding: AmoraSpacing.compactCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kavya, 26',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.titleMedium,
                ),
              ),
              const Icon(Icons.verified_rounded, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            'Family-oriented, loves heritage cafes, ready for a meaningful relationship.',
            style: AmoraTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _Metric(value: '92%', label: 'match clarity'),
        ),
        SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: _Metric(value: 'ID+', label: 'verified profiles'),
        ),
        SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: _Metric(value: '24/7', label: 'safety tools'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space8,
        vertical: AmoraSpacing.space12,
      ),
      radius: AmoraRadius.large,
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: AmoraTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.title, required this.items});

  final String title;
  final List<_LandingItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AmoraTextStyles.titleLarge),
        const SizedBox(height: AmoraSpacing.space12),
        for (final item in items) ...[
          _FeatureTile(item: item),
          const SizedBox(height: AmoraSpacing.space8),
        ],
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});

  final _LandingItem item;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: AmoraSpacing.compactCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBubble(icon: item.icon),
          const SizedBox(width: AmoraSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AmoraTextStyles.titleSmall),
                const SizedBox(height: AmoraSpacing.space8),
                Text(item.body, style: AmoraTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsCoachSection extends StatelessWidget {
  const _EventsCoachSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 620;
        const first = _ImageStoryCard(
          imageUrl: AppImages.eventGarbaNight,
          asset: AppImages.eventGarba,
          title: 'Curated events',
          body:
              'Garba nights, rooftop mixers, coffee dates, and invite-only singles tables.',
          icon: Icons.celebration_rounded,
        );
        const second = _ImageStoryCard(
          imageUrl: AppImages.eventCoffeeMeetup,
          asset: AppImages.eventCoffee,
          title: 'AI dating coach',
          body:
              'Profile edits, icebreakers, date plans, and thoughtful nudges before you meet.',
          icon: Icons.psychology_rounded,
        );
        return wide
            ? const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: first),
                  SizedBox(width: AmoraSpacing.space12),
                  Expanded(child: second),
                ],
              )
            : const Column(
                children: [
                  first,
                  SizedBox(height: AmoraSpacing.space12),
                  second,
                ],
              );
      },
    );
  }
}

class _ImageStoryCard extends StatelessWidget {
  const _ImageStoryCard({
    required this.imageUrl,
    required this.asset,
    required this.title,
    required this.body,
    required this.icon,
  });

  final String imageUrl;
  final String asset;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: ClipRRect(
        borderRadius: AmoraRadius.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumAssetImage(
              imageUrl: imageUrl,
              fallbackAsset: asset,
              initials: 'AM',
              fit: BoxFit.cover,
              borderRadius: AmoraRadius.card,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .38),
              ),
            ),
            Positioned(
              left: AmoraSpacing.space16,
              right: AmoraSpacing.space16,
              bottom: AmoraSpacing.space16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SolidBadge(icon: icon, label: title),
                  const SizedBox(height: AmoraSpacing.space8),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface,
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

class _TestimonialSection extends StatelessWidget {
  const _TestimonialSection();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      padding: AmoraSpacing.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SolidBadge(
            icon: Icons.format_quote_rounded,
            label: 'Client-demo ready',
            dark: true,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Text(
            'It feels private, polished, and serious without becoming matrimonial. The match explanation is the part people remember.',
            style: AmoraTextStyles.titleMedium,
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Text(
            'Aarav and Meera, Ahmedabad beta circle',
            style: AmoraTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PremiumTeaser extends StatelessWidget {
  const _PremiumTeaser();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: AmoraSpacing.card,
      radius: AmoraRadius.extraLarge,
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: AppColors.premiumGold),
          const SizedBox(height: AmoraSpacing.space12),
          Text(
            'AMORA Gold',
            style: AmoraTextStyles.headlineSmall.copyWith(
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            'Boost visibility, unlock deeper compatibility reasons, see curated intros first, and access premium events.',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.surface.withValues(alpha: .84),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidBadge extends StatelessWidget {
  const _SolidBadge({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AmoraSpacing.space12,
        vertical: AmoraSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: dark ? AppColors.lavenderBackground : AppColors.deepWine,
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(
          color: dark ? AppColors.borderGray : AppColors.deepWine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AmoraIconSizes.small,
            color: dark ? AppColors.primaryPurple : AppColors.surface,
          ),
          const SizedBox(width: AmoraSpacing.space8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: dark ? AppColors.deepWine : AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AmoraSpacing.minimumTouchTarget,
      height: AmoraSpacing.minimumTouchTarget,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: .10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: AmoraIconSizes.medium),
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(index * .12, .78 + index * .08, curve: AmoraMotion.curve),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _LandingItem {
  const _LandingItem(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

const _featureItems = [
  _LandingItem(
    Icons.auto_awesome_rounded,
    'AI matching with reasons',
    'Compatibility cards explain values, lifestyle rhythm, family expectations, and dating intent.',
  ),
  _LandingItem(
    Icons.verified_user_rounded,
    'Real verification',
    'Selfie, ID, and behavior signals help keep the community safe and respectful.',
  ),
  _LandingItem(
    Icons.shield_rounded,
    'Safety-first dating',
    'Privacy controls, report flows, trusted contact readiness, and guided first-date confidence.',
  ),
];
