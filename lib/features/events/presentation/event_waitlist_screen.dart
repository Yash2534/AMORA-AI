import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class EventWaitlistScreen extends StatefulWidget {
  const EventWaitlistScreen({super.key});

  static const routeName = '/event-waitlist';

  @override
  State<EventWaitlistScreen> createState() => _EventWaitlistScreenState();
}

class _EventWaitlistScreenState extends State<EventWaitlistScreen> {
  bool _notify = true;
  bool _joined = true;
  int _position = 4;

  @override
  Widget build(BuildContext context) {
    final progress = ((12 - _position) / 12).clamp(0, 1).toDouble();
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
                  color: AppColors.lavenderBackground,
                  child: Column(
                    children: [
                      const Text(
                        'Current Position',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '#$_position',
                        style: const TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 46,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress, minHeight: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PremiumCard(
                  child: Column(
                    children: [
                      _InfoRow('People ahead', '${_position - 1}'),
                      _InfoRow('Estimated entry', 'High chance by Friday'),
                      _InfoRow(
                        'Queue status',
                        _joined ? 'Joined' : 'Cancelled',
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _notify,
                        onChanged: (value) => setState(() => _notify = value),
                        title: const Text('Notify me'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (MediaQuery.sizeOf(context).width < 380) ...[
                  AppPrimaryButton(
                    label: 'Upgrade VIP',
                    icon: Icons.workspace_premium_rounded,
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed(SubscriptionScreen.routeName),
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: _joined ? 'Cancel' : 'Rejoin',
                    icon: Icons.cancel_rounded,
                    variant: AppPrimaryButtonVariant.outlined,
                    onPressed: () => setState(() {
                      _joined = !_joined;
                      if (_joined) _position = 4;
                    }),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Upgrade VIP',
                          icon: Icons.workspace_premium_rounded,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(SubscriptionScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppPrimaryButton(
                          label: _joined ? 'Cancel' : 'Rejoin',
                          icon: Icons.cancel_rounded,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: () => setState(() {
                            _joined = !_joined;
                            if (_joined) _position = 4;
                          }),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                AppPrimaryButton(
                  label: 'Simulate Queue Movement',
                  icon: Icons.trending_up_rounded,
                  variant: AppPrimaryButtonVariant.dark,
                  onPressed: () {
                    setState(() => _position = (_position - 1).clamp(1, 12));
                    _success('Queue updated locally');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _success(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Waitlist updated'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(AmoraIcons.back),
      ),
      const SizedBox(width: AmoraSpacing.space12),
      Expanded(
        child: Text(
          'Event Waitlist',
          style: AmoraTextStyles.headlineSmall.copyWith(
            color: AppColors.deepWine,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}
