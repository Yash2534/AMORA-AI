import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class DatingRecapScreen extends StatelessWidget {
  const DatingRecapScreen({super.key});

  static const routeName = '/dating-recap';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Dating Recap',
                        style: TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: const [
                    _Metric('Weekly Matches', '12', Icons.favorite_rounded),
                    _Metric('Likes', '48', Icons.thumb_up_rounded),
                    _Metric('Chats', '9', Icons.chat_rounded),
                    _Metric('Events', '2', Icons.event_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                const _TrendCard(),
                const SizedBox(height: 16),
                const _InsightCard(
                  title: 'Mood Tracker',
                  body:
                      'Your best conversations happened after thoughtful prompts and coffee-date suggestions.',
                  icon: Icons.mood_rounded,
                ),
                const SizedBox(height: 12),
                const _InsightCard(
                  title: 'Conversation Quality',
                  body:
                      'Warmth 88%, curiosity 82%, clarity 85%. Ask one specific follow-up earlier.',
                  icon: Icons.forum_rounded,
                ),
                const SizedBox(height: 12),
                const _InsightCard(
                  title: 'Date Success',
                  body:
                      'Event-led matches performed 2.1x better than swipe-only matches.',
                  icon: Icons.celebration_rounded,
                ),
                const SizedBox(height: 12),
                const _InsightCard(
                  title: 'AI Recommendations',
                  body:
                      'Add one candid outdoor photo and mention your preferred first-date rhythm.',
                  icon: Icons.auto_awesome_rounded,
                ),
                const SizedBox(height: 16),
                AppPrimaryButton(
                  label: 'Share Recap',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Recap share card prepared'),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryPurple),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.deepWine,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard();
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compatibility Trend',
          style: TextStyle(
            color: AppColors.deepWine,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final height in [54, 72, 66, 92, 108, 96])
                Expanded(
                  child: Container(
                    height: height.toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryRose,
                          AppColors.primaryPurple,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.premiumGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textGray,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
