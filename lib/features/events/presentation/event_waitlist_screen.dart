import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 620,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Event Waitlist',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const EventsMemberBadge(compact: true),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.tertiary),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.secondary,
                        size: 34,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your position',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _joined ? '#$_position' : 'Not joined',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _joined
                            ? '${_position - 1} members ahead · High chance by Friday'
                            : 'Rejoin whenever it feels right.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notify,
                    onChanged: _joined
                        ? (value) => setState(() => _notify = value)
                        : null,
                    title: const Text(
                      'Waitlist updates',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Use the existing notification preference for changes.',
                    ),
                    secondary: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: _joined ? 'Leave Waitlist' : 'Rejoin Waitlist',
                  icon: _joined
                      ? Icons.logout_rounded
                      : Icons.hourglass_top_rounded,
                  variant: _joined
                      ? AppPrimaryButtonVariant.outlined
                      : AppPrimaryButtonVariant.primary,
                  onPressed: () {
                    setState(() {
                      _joined = !_joined;
                      if (_joined) _position = 4;
                    });
                    showEventSnack(
                      context,
                      _joined
                          ? 'Waitlist joined'
                          : 'You left the event waitlist',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
