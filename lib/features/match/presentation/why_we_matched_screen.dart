import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
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
    final profile = ImageRepository.profileByName(_profileName(context));
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
                    AmoraHeaderBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: AmoraSpacing.space8),
                    const Expanded(
                      child: AmoraScreenTitle(title: 'Why We Matched'),
                    ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space20),
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
                          '${profile.name.split(' ').first} and you align on intent, rhythm, and values.',
                          style: AmoraTextStyles.titleLarge.copyWith(
                            color: AppColors.deepWine,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                const _AiSummaryCard(),
                const SizedBox(height: AmoraSpacing.space16),
                const _CompatibilityOverview(),
                const SizedBox(height: AmoraSpacing.space16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reasons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AmoraSpacing.space12,
                    crossAxisSpacing: AmoraSpacing.space12,
                    childAspectRatio: .94,
                  ),
                  itemBuilder: (context, index) =>
                      _ReasonCard(reason: _reasons[index]),
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'View Profile',
                        icon: Icons.person_rounded,
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(ProfileDetailScreen.routeName),
                      ),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Icebreaker',
                        icon: Icons.chat_bubble_rounded,
                        variant: AppPrimaryButtonVariant.outlined,
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AiIcebreakersScreen.routeName),
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

  String _profileName(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['name'] != null) return args['name'].toString();
    return 'Aadhya';
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reason});

  final (String, int, IconData) reason;

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
                Icon(reason.$3, color: AppColors.primaryPurple),
                const SizedBox(width: AmoraSpacing.space8),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    value: reason.$2 / 100,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: AppColors.borderGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Text(
              reason.$1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.titleSmall.copyWith(
                color: AppColors.deepWine,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              '${reason.$2}% aligned',
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

class _CompatibilityOverview extends StatelessWidget {
  const _CompatibilityOverview();

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
            'AMORAA weighs emotional rhythm, communication ease, lifestyle, values, love language, goals, interests, future plans, and conversation chemistry.',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  const _AiSummaryCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      color: AppColors.lavenderBackground,
      child: Text(
        'AI summary: Strong long-term intent match with similar weekend rhythm, coffee-first date preferences, and family-aware decision making.',
        style: AmoraTextStyles.bodyMedium.copyWith(color: AppColors.deepWine),
      ),
    );
  }
}

const _reasons = [
  ('Overall compatibility', 92, Icons.auto_awesome_rounded),
  ('Emotional compatibility', 96, Icons.favorite_rounded),
  ('Communication style', 93, Icons.forum_rounded),
  ('Lifestyle rhythm', 91, Icons.self_improvement_rounded),
  ('Core values', 88, Icons.diversity_1_rounded),
  ('Love language', 90, Icons.spa_rounded),
  ('Relationship goals', 96, Icons.flag_rounded),
  ('Shared interests', 89, Icons.interests_rounded),
  ('Future plans', 86, Icons.event_available_rounded),
  ('Conversation chemistry', 94, Icons.psychology_alt_rounded),
];
