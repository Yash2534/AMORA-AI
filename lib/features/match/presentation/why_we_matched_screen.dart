import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/ai_coach/presentation/ai_icebreakers_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';

class WhyWeMatchedScreen extends StatelessWidget {
  const WhyWeMatchedScreen({super.key});

  static const routeName = '/why-we-matched';

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final profile = arguments is DummyProfile
        ? arguments
        : arguments is Map && arguments['profile'] is DummyProfile
        ? arguments['profile'] as DummyProfile
        : null;
    if (profile == null) {
      return Scaffold(
        appBar: AmoraAppBar(
          title: 'Why We Matched',
          onBack: () => Navigator.of(context).maybePop(),
        ),
        body: const Center(child: Text('Match details are unavailable.')),
      );
    }
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Why We Matched',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space16,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumCard(
                  child: Row(
                    children: [
                      PremiumAvatar(
                        imageUrl: profile.imageUrl,
                        fallbackAsset: profile.fallbackAsset,
                        initials: profile.initials,
                        radius: 34,
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Text(
                          profile.compatibilityReasons.isEmpty
                              ? 'Compatibility details for ${profile.name.split(' ').first}'
                              : profile.compatibilityReasons.first.label,
                          style: AmoraTextStyles.titleLarge.copyWith(
                            color: AppColors.deepWine,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                _CompatibilitySummaryCard(profile: profile),
                const SizedBox(height: AmoraSpacing.space16),
                _CompatibilityOverview(profile: profile),
                const SizedBox(height: AmoraSpacing.space16),
                if (profile.compatibilityReasons.isEmpty)
                  const PremiumCard(
                    child: Text(
                      'Add more profile details to receive specific compatibility reasons.',
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: profile.compatibilityReasons.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AmoraSpacing.space12,
                          crossAxisSpacing: AmoraSpacing.space12,
                          childAspectRatio: .94,
                        ),
                    itemBuilder: (context, index) => _ReasonCard(
                      reason: profile.compatibilityReasons[index],
                    ),
                  ),
                const SizedBox(height: AmoraSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'View Profile',
                        icon: Icons.person_rounded,
                        onPressed: () => Navigator.of(context).pushNamed(
                          ProfileDetailScreen.routeName,
                          arguments: profile,
                        ),
                      ),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Icebreaker',
                        icon: Icons.chat_bubble_rounded,
                        variant: AppPrimaryButtonVariant.outlined,
                        onPressed: () => Navigator.of(context).pushNamed(
                          AiIcebreakersScreen.routeName,
                          arguments: <String, Object?>{
                            'id': profile.id,
                            'name': profile.name,
                            'subtitle': [profile.profession, profile.city]
                                .where((value) => value.trim().isNotEmpty)
                                .join(' · '),
                            'score': profile.score,
                            'interests': profile.interests,
                            'imageUrl': profile.imageUrl,
                            'fallbackAsset': profile.fallbackAsset,
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});

  final CompatibilityReason reason;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      radius: AmoraRadius.extraLarge,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _factorIcon(reason.factor),
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(width: AmoraSpacing.space8),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    value: reason.score / 100,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.borderGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Text(
              reason.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.titleSmall.copyWith(
                color: AppColors.deepWine,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              '${reason.score}% signal',
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _factorIcon(String factor) => switch (factor) {
  'relationship_goal' => Icons.flag_rounded,
  'interests' => Icons.interests_rounded,
  'languages' => Icons.translate_rounded,
  'values' => Icons.diversity_1_rounded,
  'communication_style' => Icons.forum_rounded,
  'lifestyle' => Icons.self_improvement_rounded,
  _ => Icons.auto_awesome_rounded,
};

class _CompatibilityOverview extends StatelessWidget {
  const _CompatibilityOverview({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.roseQuartz.withValues(alpha: .5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compatibility report',
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.deepWine,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space12),
          Text(
            profile.compatibilityDisclaimer.isNotEmpty
                ? profile.compatibilityDisclaimer
                : 'This estimate uses the profile fields both people chose to share. It is not a guarantee of relationship compatibility.',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompatibilitySummaryCard extends StatelessWidget {
  const _CompatibilitySummaryCard({required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.lavenderBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${profile.score}% compatibility estimate',
            style: AmoraTextStyles.titleMedium.copyWith(
              color: AppColors.deepWine,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            profile.compatibilityReasons.isEmpty
                ? 'There is not enough shared profile data for a detailed explanation yet.'
                : profile.compatibilityReasons
                      .take(2)
                      .map((reason) => reason.label)
                      .join('. '),
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.deepWine,
            ),
          ),
        ],
      ),
    );
  }
}
