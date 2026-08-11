import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class ReferralLeaderboardScreen extends StatefulWidget {
  const ReferralLeaderboardScreen({super.key});

  static const routeName = '/referral-leaderboard';

  @override
  State<ReferralLeaderboardScreen> createState() =>
      _ReferralLeaderboardScreenState();
}

class _ReferralLeaderboardScreenState extends State<ReferralLeaderboardScreen> {
  String _period = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Referral Leaderboard',
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
                AmoraaCompactSelect<String>(
                  key: const ValueKey('referral-period-selector'),
                  label: 'Leaderboard period',
                  value: _period,
                  prefixIcon: Icons.calendar_view_month_rounded,
                  options: const [
                    AmoraaSelectOption(value: 'Weekly', label: 'Weekly'),
                    AmoraaSelectOption(value: 'Monthly', label: 'Monthly'),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _period = value);
                  },
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  color: AppColors.lavenderBackground,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Referral Streak',
                        style: TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _period == 'Weekly' ? .72 : .48,
                        minHeight: 9,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _period == 'Weekly'
                            ? '5 day streak'
                            : '12 successful invites',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _leaders.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LeaderTile(rank: i + 1, leader: _leaders[i]),
                  ),
                const SizedBox(height: 14),
                const PremiumCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('City Champion')),
                      Chip(label: Text('Gold Inviter')),
                      Chip(label: Text('7 Day Streak')),
                    ],
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

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({required this.rank, required this.leader});
  final int rank;
  final (String, int, String) leader;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(14),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final avatar = CircleAvatar(
          backgroundColor: rank == 1
              ? AppColors.premiumGold
              : AppColors.lavenderBackground,
          child: Text('$rank'),
        );
        const nameStyle = TextStyle(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w900,
        );
        const coinsStyle = TextStyle(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w900,
        );

        if (constraints.maxWidth < 280) {
          return Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(leader.$1, style: nameStyle)),
                        const SizedBox(width: 8),
                        Text('${leader.$2} coins', style: coinsStyle),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: leader.$2 / 2000),
                    const SizedBox(height: 4),
                    Text(leader.$3),
                  ],
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leader.$1, style: nameStyle),
                  LinearProgressIndicator(value: leader.$2 / 2000),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${leader.$2} coins', style: coinsStyle),
                Text(leader.$3),
              ],
            ),
          ],
        );
      },
    ),
  );
}

const _leaders = [
  ('Riya', 1600, 'VIP reward'),
  ('Aarav', 1240, 'Gold bonus'),
  ('Kavya', 980, 'Coffee pass'),
  ('Dev', 720, 'Coins'),
];
