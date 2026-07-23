import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class SuperLikeScreen extends StatefulWidget {
  const SuperLikeScreen({super.key});

  static const routeName = '/super-like';

  @override
  State<SuperLikeScreen> createState() => _SuperLikeScreenState();
}

class _SuperLikeScreenState extends State<SuperLikeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _icebreakerController = TextEditingController(
    text:
        'Your architecture and heritage walk interests caught my attention - coffee and old city stories sometime?',
  );
  bool _routeProfileApplied = false;
  DummyProfile? _routeProfile;
  DummyProfile get _profile => _routeProfile ?? _superLikeProfile;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeProfileApplied) return;
    _routeProfileApplied = true;
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    try {
      final name = args?.name as String?;
      if (name != null && name.trim().isNotEmpty) {
        _routeProfile = ImageRepository.profileByName(name);
      }
    } catch (_) {
      _routeProfile = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _icebreakerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightPinkBackground,
              AppColors.lavenderBackground,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 380
                    ? AmoraSpacing.space16
                    : AmoraSpacing.space24;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AmoraSpacing.space12,
                    padding,
                    AmoraSpacing.space32 +
                        MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onBack: () => Navigator.of(context).maybePop()),
                      const SizedBox(height: 14),
                      _ProfileCard(profile: _profile),
                      const SizedBox(height: 18),
                      _AnimatedSuperLike(controller: _controller),
                      const SizedBox(height: 14),
                      Text(
                        'Stand out with a Super Like',
                        textAlign: TextAlign.center,
                        style: AmoraTextStyles.headlineLarge.copyWith(
                          color: AppColors.deepWine,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_profile.name.split(' ').first} will be notified instantly that you are genuinely interested.',
                        textAlign: TextAlign.center,
                        style: AmoraTextStyles.bodyMedium.copyWith(
                          color: AppColors.textGray,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const _BenefitsCard(),
                      const SizedBox(height: 14),
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI icebreaker preview',
                              style: AmoraTextStyles.titleMedium.copyWith(
                                color: AppColors.deepWine,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _icebreakerController.text,
                              style: AmoraTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        label: 'Send Super Like',
                        icon: Icons.star_rounded,
                        onPressed: _showSuccessDialog,
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: 'Edit Icebreaker',
                        icon: Icons.edit_rounded,
                        variant: AppPrimaryButtonVariant.outlined,
                        onPressed: _showEditSheet,
                      ),
                      const SizedBox(height: 12),
                      AppPrimaryButton(
                        label: 'Maybe Later',
                        variant: AppPrimaryButtonVariant.text,
                        onPressed: () => Navigator.of(context).maybePop(),
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

  void _showEditSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            18,
            22,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Icebreaker',
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.deepWine,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _icebreakerController,
                label: 'Icebreaker',
                hint: 'Write a thoughtful opener',
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              AppPrimaryButton(
                label: 'Save Icebreaker',
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    showAmoraDialog<void>(
      context: context,
      title: 'Super Like Sent',
      message: '${_profile.name.split(' ').first} has been notified.',
      icon: Icons.star_rounded,
      primaryLabel: 'Done',
      onPrimary: () => Navigator.pop(context),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.deepWine,
        ),
        Expanded(
          child: Text(
            'Super Like',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.deepWine,
            ),
          ),
        ),
        const SizedBox(width: AmoraSpacing.minimumTouchTarget),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AmoraProfileImage(
              imageUrl: profile.imageUrl,
              assetPath: profile.fallbackAsset,
              initials: profile.initials,
              width: 86,
              height: 104,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${profile.name.split(' ').first}, ${profile.age}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.titleLarge.copyWith(
                          color: AppColors.deepWine,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.primaryPurple,
                      size: 19,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.city} - ${profile.distance} away',
                  style: AmoraTextStyles.bodyMedium.copyWith(
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 8),
                _MiniPill(text: '${profile.score}% AMORA Match'),
                const SizedBox(height: 7),
                _MiniPill(text: profile.intent, gold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _superLikeProfile = ImageRepository.profileByName('Aadhya');

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, this.gold = false});

  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: (gold ? AppColors.premiumGold : AppColors.primaryPurple)
            .withValues(alpha: .12),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: AmoraTextStyles.labelMedium.copyWith(
            color: AppColors.deepWine,
          ),
        ),
      ),
    );
  }
}

class _AnimatedSuperLike extends StatelessWidget {
  const _AnimatedSuperLike({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(scale: 1 + controller.value * .08, child: child);
      },
      child: Container(
        height: 112,
        width: 112,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.premiumGold, AppColors.primaryRose],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.premiumGold.withValues(alpha: .30),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: AppColors.surface,
          size: 64,
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  @override
  Widget build(BuildContext context) {
    return const PremiumCard(
      child: Column(
        children: [
          _Benefit(
            icon: Icons.visibility_rounded,
            text: '3x higher match visibility',
          ),
          _Benefit(
            icon: Icons.notifications_active_rounded,
            text: 'Priority notification',
          ),
          _Benefit(
            icon: Icons.auto_awesome_rounded,
            text: 'AI icebreaker suggestion',
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
