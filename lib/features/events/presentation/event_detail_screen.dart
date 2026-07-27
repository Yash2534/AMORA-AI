import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/event_group_chat_screen.dart';
import 'package:amora_ai/features/events/presentation/event_waitlist_screen.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, this.event});

  static const routeName = '/event-detail';

  final EventModel? event;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _saved = false;
  TicketStatus? _status;
  String? _eventId;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final event = widget.event ?? (args is EventModel ? args : events.first);
    if (_eventId != event.id) {
      _eventId = event.id;
      _status = _existingStatus(event);
    }

    if (!hasPremiumEventsAccess) {
      return _LockedEventDetail(event: event);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _DetailActionBar(
        event: event,
        status: _status,
        onPressed: () => _handlePrimaryAction(event),
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveMobileFrame(
          maxWidth: 940,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EventImagePanel(
                        event: event,
                        height: MediaQuery.sizeOf(context).width >= 700
                            ? 410
                            : 340,
                        hero: true,
                        radius: 30,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _OverlayButton(
                                    tooltip: 'Back',
                                    icon: Icons.arrow_back_rounded,
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                  ),
                                  const Spacer(),
                                  _OverlayButton(
                                    tooltip: _saved
                                        ? 'Remove saved event'
                                        : 'Save event',
                                    icon: _saved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    onPressed: () => _toggleSaved(event),
                                  ),
                                  const SizedBox(width: 8),
                                  _OverlayButton(
                                    tooltip: 'Share event',
                                    icon: Icons.ios_share_rounded,
                                    onPressed: () => showEventSnack(
                                      context,
                                      'Share link prepared',
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  EventStatusBadge(status: _status),
                                  const SizedBox(width: 8),
                                  const EventsMemberBadge(compact: true),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 28,
                                  height: 1.08,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.category,
                                style: const TextStyle(
                                  color: AppColors.surface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DetailMetadata(event: event),
                      const SizedBox(height: 20),
                      EventHostSection(host: event.host),
                      const SizedBox(height: 28),
                      const _DetailHeading('About this gathering'),
                      const SizedBox(height: 10),
                      Text(
                        'A curated ${event.category.toLowerCase()} for people '
                        'interested in ${event.intent.toLowerCase()}. Expect '
                        'thoughtful conversation around '
                        '${event.interests.join(', ').toLowerCase()}.',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          height: 1.55,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _DetailHeading('What to expect'),
                      const SizedBox(height: 12),
                      _AgendaList(items: eventAgenda),
                      const SizedBox(height: 28),
                      const _DetailHeading('Member requirements'),
                      const SizedBox(height: 12),
                      _Requirements(event: event),
                      const SizedBox(height: 28),
                      const _DetailHeading('Who’s joining'),
                      const SizedBox(height: 6),
                      const Text(
                        'Meet members attending this gathering.',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      EventAttendeePreview(attendees: eventAttendees),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 116,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: eventAttendees.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (_, index) =>
                              _AttendeeCard(attendee: eventAttendees[index]),
                        ),
                      ),
                      if (_status == TicketStatus.upcoming) ...[
                        const SizedBox(height: 28),
                        const _DetailHeading('Joined event tools'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.forum_rounded, size: 18),
                              label: const Text('Group Chat'),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(EventGroupChatScreen.routeName),
                            ),
                          ],
                        ),
                      ],
                      if (_status == TicketStatus.attended) ...[
                        const SizedBox(height: 28),
                        AppPrimaryButton(
                          label: 'Share feedback',
                          icon: Icons.rate_review_rounded,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(PostEventFeedbackScreen.routeName),
                        ),
                      ],
                      const SizedBox(height: 28),
                      EventSafetySection(
                        onGuidelines: () => Navigator.of(
                          context,
                        ).pushNamed(SafetyPrivacyScreen.routeName),
                        onReport: () => Navigator.of(
                          context,
                        ).pushNamed(ReportFlowScreen.routeName),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TicketStatus? _existingStatus(EventModel event) {
    for (final entry in myEventTickets) {
      if (entry.event.id == event.id) return entry.status;
    }
    return null;
  }

  void _toggleSaved(EventModel event) {
    AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () {
        if (!mounted) return;
        setState(() => _saved = !_saved);
        showEventSnack(
          context,
          _saved ? '${event.title} saved' : '${event.title} removed from saved',
        );
      },
    );
  }

  void _handlePrimaryAction(EventModel event) {
    if (_status == TicketStatus.waitlisted) {
      Navigator.of(context).pushNamed(EventWaitlistScreen.routeName);
      return;
    }
    if (_status == TicketStatus.attended) {
      Navigator.of(context).pushNamed(PostEventFeedbackScreen.routeName);
      return;
    }
    if (_status == TicketStatus.upcoming) {
      _confirmLeave(event);
      return;
    }
    if (_status == TicketStatus.cancelled) return;

    AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () {
        if (!mounted) return;
        setState(() => _status = TicketStatus.upcoming);
        showEventSnack(context, 'You joined ${event.title}');
      },
    );
  }

  void _confirmLeave(EventModel event) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Leave this event?',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You’ll leave ${event.title}.',
              style: const TextStyle(color: AppColors.text, fontSize: 15),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Leave Event',
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: () {
                Navigator.pop(sheetContext);
                setState(() => _status = null);
                showEventSnack(context, 'You left ${event.title}');
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Stay joined'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedEventDetail extends StatelessWidget {
  const _LockedEventDetail({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 620,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                EventImagePanel(event: event, height: 230, radius: 28),
                const SizedBox(height: 20),
                const Icon(
                  Icons.lock_rounded,
                  size: 42,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Events are for Amora members',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join curated gatherings designed for meaningful, '
                  'real-world connections.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                AppPrimaryButton(
                  label: 'Explore Membership',
                  icon: Icons.workspace_premium_rounded,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(SubscriptionScreen.routeName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.surface.withValues(alpha: .93),
        foregroundColor: AppColors.primary,
      ),
      icon: Icon(icon),
    );
  }
}

class _DetailMetadata extends StatelessWidget {
  const _DetailMetadata({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          EventInfoTile(
            icon: Icons.calendar_month_rounded,
            label: 'Date and time',
            value: '${event.date} · ${event.time}',
          ),
          const SizedBox(height: 16),
          EventInfoTile(
            icon: Icons.place_rounded,
            label: 'Location',
            value: '${event.venue}, ${event.city}',
          ),
          const SizedBox(height: 16),
          EventInfoTile(
            icon: Icons.near_me_rounded,
            label: 'Distance',
            value: event.distance,
          ),
        ],
      ),
    );
  }
}

class _Requirements extends StatelessWidget {
  const _Requirements({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _RequirementChip(icon: Icons.groups_rounded, label: event.ageRange),
        _RequirementChip(icon: Icons.checkroom_rounded, label: event.dressCode),
        _RequirementChip(icon: Icons.translate_rounded, label: event.language),
      ],
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 78,
                  child: Text(
                    items[index].$1,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[index].$2,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 5, bottom: 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 14,
                    child: VerticalDivider(
                      width: 2,
                      thickness: 2,
                      color: AppColors.tertiary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AttendeeCard extends StatelessWidget {
  const _AttendeeCard({required this.attendee});

  final EventAttendee attendee;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.tertiary,
                foregroundImage: AssetImage(attendee.photoAsset),
                child: Text(attendee.name.characters.first),
              ),
              const Spacer(),
              if (attendee.verified)
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            attendee.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            attendee.intent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.event,
    required this.status,
    required this.onPressed,
  });

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isJoined = status == TicketStatus.upcoming;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .1),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AppPrimaryButton(
            label: switch (status) {
              TicketStatus.upcoming => 'Leave Event',
              TicketStatus.attended => 'Share feedback',
              TicketStatus.waitlisted => 'View Waitlist',
              TicketStatus.cancelled => 'Event Cancelled',
              null => 'Join Event',
            },
            icon: switch (status) {
              TicketStatus.upcoming => Icons.logout_rounded,
              TicketStatus.attended => Icons.rate_review_rounded,
              TicketStatus.waitlisted => Icons.hourglass_top_rounded,
              TicketStatus.cancelled => Icons.event_busy_rounded,
              null => Icons.add_rounded,
            },
            variant: isJoined
                ? AppPrimaryButtonVariant.outlined
                : AppPrimaryButtonVariant.primary,
            onPressed: status == TicketStatus.cancelled ? null : onPressed,
          ),
        ),
      ),
    );
  }
}
