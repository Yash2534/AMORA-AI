import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/monetization/presentation/widgets/monetization_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

  static const routeName = '/refer-earn';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonetizationHeader(
                    title: 'Refer & Earn',
                    subtitle: 'Invite serious singles and earn AMORAA Coins.',
                    icon: Icons.card_giftcard_rounded,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  _ReferralHero(onCopy: () => _copyCode(context)),
                  const SizedBox(height: 18),
                  const SectionTitle(title: 'Share'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    children: [
                      _ShareButton('WhatsApp', Icons.chat_rounded),
                      _ShareButton('SMS', Icons.sms_rounded),
                      _ShareButton('Instagram', Icons.camera_alt_rounded),
                      _ShareButton('More', Icons.ios_share_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Your stats'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                        ),
                    itemCount: referralStats.length,
                    itemBuilder: (context, index) =>
                        ReferralStatsCard(stat: referralStats[index]),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'How it works'),
                  const SizedBox(height: 12),
                  const PremiumCard(
                    child: Column(
                      children: [
                        _StepTile(1, 'Share your code'),
                        _StepTile(2, 'Friend signs up'),
                        _StepTile(3, 'Friend buys first plan'),
                        _StepTile(4, 'You both earn rewards'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle(title: 'Top referrers this week'),
                  const SizedBox(height: 12),
                  const PremiumCard(
                    child: Column(
                      children: [
                        _LeaderboardRow('Riya', '1,400 coins'),
                        _LeaderboardRow('Aarav', '1,100 coins'),
                        _LeaderboardRow('Kavya', '900 coins'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppPrimaryButton(
                    label: 'Invite Friends',
                    icon: Icons.group_add_rounded,
                    onPressed: () =>
                        showPremiumSnack(context, 'Invite link prepared'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: 'AMORAA-LOVE25'));
    if (context.mounted) showPremiumSnack(context, 'Referral code copied');
  }
}

class _ReferralHero extends StatelessWidget {
  const _ReferralHero({required this.onCopy});

  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Code',
            style: AmoraTextStyles.labelLarge.copyWith(
              color: AppColors.premiumGold,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AMORAA-LOVE25',
            style: TextStyle(
              color: AppColors.surface,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Earn Rs 100 AMORAA Coins when your friend subscribes. Friend gets Rs 150 off first subscription.',
            style: TextStyle(
              color: AppColors.surface,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Copy Code',
            icon: Icons.copy_rounded,
            variant: AppPrimaryButtonVariant.dark,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton(this.label, this.icon);

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => showPremiumSnack(context, '$label invite prepared'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRose.withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile(this.number, this.label);

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.surface,
        child: Text('$number'),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow(this.name, this.reward);

  final String name;
  final String reward;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.lavenderBackground,
        child: Icon(Icons.emoji_events_rounded, color: AppColors.premiumGold),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w900,
        ),
      ),
      trailing: Text(
        reward,
        style: const TextStyle(
          color: AppColors.primaryPurple,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
