import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _ambient;
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambient.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ambient,
        builder: (context, _) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(
                AppColors.surfaceContainerLow,
                AppColors.surface,
                _ambient.value,
              ),
            ),
            child: SafeArea(
              child: ResponsiveMobileFrame(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final padding = constraints.maxWidth < 390
                        ? AmoraSpacing.space16
                        : AmoraSpacing.space24;
                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            AmoraSpacing.space16,
                            padding,
                            AmoraSpacing.space8,
                          ),
                          child: Row(
                            children: [
                              const Flexible(child: _MiniBrand()),
                              const Spacer(),
                              AppPrimaryButton(
                                label: 'Skip',
                                variant: AppPrimaryButtonVariant.text,
                                size: AmoraButtonSize.compact,
                                fullWidth: false,
                                onPressed: _goToAuth,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _slides.length,
                            onPageChanged: (value) {
                              setState(() => _index = value);
                            },
                            itemBuilder: (context, index) {
                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  padding,
                                  AmoraSpacing.space12,
                                  padding,
                                  AmoraSpacing.space20,
                                ),
                                child: _OnboardingPage(
                                  slide: _slides[index],
                                  active: index == _index,
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            AmoraSpacing.space8,
                            padding,
                            AmoraSpacing.space24 +
                                MediaQuery.viewPaddingOf(context).bottom,
                          ),
                          child: Column(
                            children: [
                              _ProgressDots(index: _index),
                              const SizedBox(height: AmoraSpacing.space16),
                              AppPrimaryButton(
                                label: _isLast ? 'Get Started' : 'Next',
                                icon: _isLast
                                    ? Icons.favorite_rounded
                                    : Icons.arrow_forward_rounded,
                                onPressed: _isLast ? _goToAuth : _next,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: AmoraMotion.slow,
      curve: AmoraMotion.curve,
    );
  }

  void _goToAuth() {
    Navigator.of(context).pushReplacementNamed(AmoraAuthScreen.routeName);
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide, required this.active});

  final _OnboardingSlide slide;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : .72,
      duration: AmoraMotion.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Hero(
            tag: 'onboarding-${slide.title}',
            child: AspectRatio(
              aspectRatio: .92,
              child: PremiumCard(
                padding: const EdgeInsets.all(AmoraSpacing.space12),
                radius: AmoraRadius.extraLarge,
                child: ClipRRect(
                  borderRadius: AmoraRadius.card,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PremiumAssetImage(
                        imageUrl: slide.imageUrl,
                        fallbackAsset: slide.assetPath,
                        initials: slide.initials,
                        fit: BoxFit.cover,
                        alignment: slide.alignment,
                        borderRadius: AmoraRadius.card,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.transparent,
                              AppColors.text.withValues(alpha: .10),
                              AppColors.text.withValues(alpha: .70),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: AmoraSpacing.space16,
                        right: AmoraSpacing.space16,
                        bottom: AmoraSpacing.space16,
                        child: _InsightPanel(slide: slide),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space24),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AmoraTextStyles.headlineMedium,
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.large,
      color: AppColors.surface,
      padding: AmoraSpacing.compactCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                slide.icon,
                color: AppColors.primary,
                size: AmoraIconSizes.medium,
              ),
              const SizedBox(width: AmoraSpacing.space8),
              Expanded(
                child: Text(
                  slide.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            slide.microcopy,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _slides.length; i++)
          AnimatedContainer(
            duration: AmoraMotion.standard,
            margin: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space4),
            width: i == index ? 28 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.primaryPurple
                  : AppColors.borderGray,
              borderRadius: AmoraRadius.pillBorder,
            ),
          ),
      ],
    );
  }
}

class _MiniBrand extends StatelessWidget {
  const _MiniBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            AppImages.logo,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => CircleAvatar(
              backgroundColor: AppColors.primaryPurple,
              child: Text(
                'a',
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AmoraSpacing.space8),
        const Flexible(
          child: Text(
            'AMORA AI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.badge,
    required this.microcopy,
    required this.icon,
    required this.imageUrl,
    required this.assetPath,
    required this.initials,
    this.alignment = Alignment.center,
  });

  final String title;
  final String description;
  final String badge;
  final String microcopy;
  final IconData icon;
  final String imageUrl;
  final String assetPath;
  final String initials;
  final Alignment alignment;
}

const _slides = [
  _OnboardingSlide(
    title: 'AI Matching',
    description:
        'Understand why someone fits your life, not just how close they live.',
    badge: 'Compatibility insight',
    microcopy: 'Values, routine, ambition, and communication style aligned.',
    icon: Icons.auto_awesome_rounded,
    imageUrl: AppImages.networkProfileKavya,
    assetPath: AppImages.profileAadhya,
    initials: 'AI',
    alignment: Alignment.topCenter,
  ),
  _OnboardingSlide(
    title: 'Real Verification',
    description:
        'Selfie and ID-first signals create a more trusted Indian dating circle.',
    badge: 'Verified community',
    microcopy: 'Real people, clearer intent, and stronger safety defaults.',
    icon: Icons.verified_user_rounded,
    imageUrl: AppImages.networkProfileAarav,
    assetPath: AppImages.profileYash,
    initials: 'RV',
    alignment: Alignment.topCenter,
  ),
  _OnboardingSlide(
    title: 'Events',
    description:
        'Move beyond chat with curated mixers, cultural nights, and date tables.',
    badge: 'Offline introductions',
    microcopy: 'Rooftop socials, Garba evenings, coffee circles, and more.',
    icon: Icons.celebration_rounded,
    imageUrl: AppImages.eventGarbaNight,
    assetPath: AppImages.eventGarba,
    initials: 'EV',
  ),
  _OnboardingSlide(
    title: 'Safe Dating',
    description: 'Privacy, reporting, and softer guardrails from day one.',
    badge: 'Safety-first experience',
    microcopy: 'Built for confidence before, during, and after first dates.',
    icon: Icons.shield_rounded,
    imageUrl: AppImages.dateSpotRooftopOnline,
    assetPath: AppImages.dateSpotRestaurant,
    initials: 'SD',
  ),
];
