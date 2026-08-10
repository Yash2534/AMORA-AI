import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:flutter/material.dart';

class EventWaitlistScreen extends StatefulWidget {
  const EventWaitlistScreen({super.key, this.event, this.controller});

  static const routeName = '/event-waitlist';

  final EventModel? event;
  final EventParticipationController? controller;

  @override
  State<EventWaitlistScreen> createState() => _EventWaitlistScreenState();
}

class _EventWaitlistScreenState extends State<EventWaitlistScreen> {
  bool _notify = true;
  bool _argumentsRead = false;
  EventModel? _event;

  EventParticipationController get _controller =>
      widget.controller ?? EventParticipationController.instance;

  bool get _joined =>
      _event != null &&
      _controller.statusFor(_event!.id) == TicketStatus.waitlisted;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _controller.addListener(_handleStateChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    _argumentsRead = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (_event == null && arguments is EventModel) _event = arguments;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStateChanged);
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

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
                    AmoraHeaderBackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: AmoraScreenTitle(title: 'Event Waitlist'),
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
                      Text(
                        _event?.title ?? 'Waitlist unavailable',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _event == null
                            ? 'Open a waitlisted event to manage it.'
                            : _joined
                            ? 'You’re on the waitlist'
                            : 'You are no longer on this waitlist.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
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
                ),
                const SizedBox(height: 18),
                AppPrimaryButton(
                  label: _joined ? 'Leave Waitlist' : 'Back to events',
                  icon: _joined
                      ? Icons.logout_rounded
                      : Icons.arrow_back_rounded,
                  variant: _joined
                      ? AppPrimaryButtonVariant.outlined
                      : AppPrimaryButtonVariant.primary,
                  onPressed: () {
                    final event = _event;
                    if (_joined && event != null) {
                      _controller.leaveWaitlist(event.id);
                      showEventSnack(context, 'You left the event waitlist');
                    } else {
                      Navigator.of(context).maybePop();
                    }
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
