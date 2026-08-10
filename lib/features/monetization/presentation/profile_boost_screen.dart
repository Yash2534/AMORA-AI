import 'dart:async';

import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:flutter/material.dart';

class ProfileBoostScreen extends StatefulWidget {
  const ProfileBoostScreen({super.key});

  static const routeName = '/profile-boost';

  @override
  State<ProfileBoostScreen> createState() => _ProfileBoostScreenState();
}

class _ProfileBoostScreenState extends State<ProfileBoostScreen> {
  Timer? _timer;
  int _seconds = 0;
  int _selected = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _seconds > 0;
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
                const _Header(),
                const SizedBox(height: 18),
                PremiumCard(
                  color: AppColors.premiumGold.withValues(alpha: .14),
                  child: Column(
                    children: [
                      Text(
                        active ? _format(_seconds) : 'Peak Visibility',
                        style: const TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        active
                            ? 'Boost is live in nearby discovery.'
                            : 'Activate during high-intent evening windows.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: const [
                    _Benefit('5x visibility', Icons.visibility_rounded),
                    _Benefit('Priority Nearby', Icons.near_me_rounded),
                    _Benefit('More profile visits', Icons.trending_up_rounded),
                    _Benefit('Peak time boost', Icons.schedule_rounded),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _packages.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PackageTile(
                      package: _packages[i],
                      selected: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                  ),
                const SizedBox(height: 8),
                AppPrimaryButton(
                  label: active ? 'Boost Active' : 'Activate Boost',
                  icon: AmoraIcons.boost,
                  onPressed: active ? null : _activate,
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(
                  label: 'Pay Instead',
                  icon: AmoraIcons.wallet,
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: () => Navigator.of(context).pushNamed(
                    PaymentScreen.routeName,
                    arguments: PaymentArgs(
                      title: _packages[_selected].$1,
                      subtitle: 'AMORAA Boost',
                      billingCycle: 'One-time profile visibility boost',
                      amount: _packages[_selected].$3,
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

  void _activate() {
    setState(() => _seconds = _packages[_selected].$2 * 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String _format(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      AmoraHeaderBackButton(onPressed: () => Navigator.of(context).maybePop()),
      const SizedBox(width: AmoraSpacing.space8),
      const Expanded(child: AmoraScreenTitle(title: 'Profile Boost')),
    ],
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.label, this.icon);
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(8),
    radius: 24,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryPurple, size: 20),
        const Spacer(),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.deepWine,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.selected,
    required this.onTap,
  });
  final (String, int, int) package;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: PremiumCard(
      padding: const EdgeInsets.all(16),
      color: selected
          ? AppColors.primaryPurple.withValues(alpha: .10)
          : AppColors.surface,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: AppColors.primaryPurple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.$1,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text('${package.$2} minutes - Rs ${package.$3}'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

const _packages = [
  ('Starter Boost', 30, 299),
  ('Peak Boost', 60, 499),
  ('VIP Evening Boost', 120, 899),
];
