import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:flutter/material.dart';

class AiDatingCoachScreen extends StatelessWidget {
  const AiDatingCoachScreen({super.key});

  static const routeName = '/ai-coach';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'AI Dating Coach',
        subtitle: 'Thoughtful guidance for serious conversations.',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PremiumBadge(),
                  const SizedBox(height: 16),
                  const PremiumCard(
                    color: AppColors.lavenderBackground,
                    child: Text(
                      'Daily tip: Ask something specific from their profile instead of sending a generic hi.',
                      style: TextStyle(
                        color: AppColors.deepWine,
                        height: 1.4,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _AssistantQuickActions(),
                  const SizedBox(height: 18),
                  const _ConversationScoreCard(),
                  const SizedBox(height: 18),
                  const SectionTitle(title: 'First date ideas'),
                  const SizedBox(height: 12),
                  const _DateIdeaCarousel(),
                  const SizedBox(height: 10),
                  const SectionTitle(title: 'Reflection Prompts'),
                  const SizedBox(height: 12),
                  for (final prompt in reflectionPrompts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CoachInsightCard(
                        icon: Icons.favorite_border_rounded,
                        title: 'Reflection',
                        value: prompt,
                      ),
                    ),
                  const SizedBox(height: 10),
                  const SectionTitle(title: 'Relationship Insights'),
                  const SizedBox(height: 12),
                  const CoachInsightCard(
                    icon: Icons.forum_rounded,
                    title: 'Communication style',
                    value: 'Thoughtful',
                  ),
                  const SizedBox(height: 10),
                  const CoachInsightCard(
                    icon: Icons.trending_up_rounded,
                    title: 'Match energy',
                    value: 'Growing',
                  ),
                  const SizedBox(height: 10),
                  const CoachInsightCard(
                    icon: Icons.local_cafe_rounded,
                    title: 'Next best move',
                    value: 'Suggest a simple coffee plan',
                  ),
                  const SizedBox(height: 18),
                  const SectionTitle(title: 'Profile improvement suggestions'),
                  const SizedBox(height: 12),
                  const CoachInsightCard(
                    icon: Icons.photo_camera_rounded,
                    title: 'Photo signal',
                    value: 'Add one candid outdoor photo and one event photo.',
                  ),
                  const SizedBox(height: 10),
                  const CoachInsightCard(
                    icon: Icons.edit_note_rounded,
                    title: 'Bio signal',
                    value: 'Mention one value and one date idea clearly.',
                  ),
                  const SizedBox(height: 18),
                  AppPrimaryButton(
                    label: 'Get AI Advice',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: () => showPremiumSnack(
                      context,
                      'AI advice will be personalized after backend integration',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Generate Date Plan',
                    icon: Icons.event_rounded,
                    variant: AppPrimaryButtonVariant.outlined,
                    onPressed: () => showPremiumSnack(
                      context,
                      'Local date-plan preview is ready',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Improve My Profile',
                    icon: Icons.person_rounded,
                    variant: AppPrimaryButtonVariant.dark,
                    onPressed: () => showPremiumSnack(
                      context,
                      'Profile improvement tips queued',
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Open AI Icebreakers',
                    icon: Icons.chat_bubble_rounded,
                    variant: AppPrimaryButtonVariant.outlined,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/ai-icebreakers'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantQuickActions extends StatelessWidget {
  const _AssistantQuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = const [
      ('Improve My Profile', Icons.person_rounded),
      ('Suggest Reply', Icons.reply_rounded),
      ('Opening Messages', Icons.chat_bubble_rounded),
      ('Plan a Date', Icons.event_available_rounded),
      ('Confidence Coach', Icons.psychology_rounded),
      ('Relationship Advice', Icons.favorite_rounded),
      ('Conversation Tips', Icons.tips_and_updates_rounded),
    ];
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.deepWine,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.surface,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AMORAA assistant',
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                ActionChip(
                  avatar: Icon(action.$2, size: 17),
                  label: Text(action.$1),
                  onPressed: () =>
                      showPremiumSnack(context, '${action.$1} opened'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateIdeaCarousel extends StatelessWidget {
  const _DateIdeaCarousel();

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return SizedBox(
      height: textScale > 1.2 ? 280 : 246,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dateIdeas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final idea = dateIdeas[index];
          final mood = _dateMoods[index % _dateMoods.length];
          return SizedBox(
            width: 238,
            child: PremiumCard(
              padding: const EdgeInsets.all(14),
              radius: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Icon(
                        _dateIcons[index % _dateIcons.length],
                        color: AppColors.primaryPurple,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    idea,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.deepWine,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniTag(label: mood),
                      const _MiniTag(label: 'Rs 800-1800'),
                      const _MiniTag(label: 'AI pick'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textGray,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

const _dateMoods = [
  'Calm',
  'Curious',
  'Playful',
  'Warm',
  'Social',
  'Away',
  'Creative',
  'Live',
];

const _dateIcons = [
  Icons.local_cafe_rounded,
  Icons.museum_rounded,
  Icons.menu_book_rounded,
  Icons.wb_twilight_rounded,
  Icons.restaurant_rounded,
  Icons.luggage_rounded,
  Icons.palette_rounded,
  Icons.music_note_rounded,
];

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.premiumGold.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.premiumGold),
      ),
      child: const Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.workspace_premium_rounded, color: AppColors.premiumGold),
          SizedBox(width: 8),
          Text(
            'Gold/VIP Feature',
            style: TextStyle(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationScoreCard extends StatelessWidget {
  const _ConversationScoreCard();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Conversation Score',
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '84/100',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final score in coachScores)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          score.label,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${score.value}%',
                        style: const TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: score.value / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                    color: AppColors.primaryRose,
                    backgroundColor: AppColors.lavenderBackground,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
