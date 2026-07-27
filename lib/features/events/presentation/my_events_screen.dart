import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/event_waitlist_screen.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/material.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  static const routeName = '/my-events';

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late List<MyEventTicket> _entries;

  @override
  void initState() {
    super.initState();
    _entries = membershipTestMode
        ? _testEntries()
        : List<MyEventTicket>.from(myEventTickets);
    if (membershipTestMode) {
      MembershipTestFlowController.instance.addListener(_syncTestEntries);
    }
  }

  @override
  void dispose() {
    if (membershipTestMode) {
      MembershipTestFlowController.instance.removeListener(_syncTestEntries);
    }
    super.dispose();
  }

  List<MyEventTicket> _testEntries() {
    final joined = MembershipTestFlowController.instance.joinedEventIds;
    return events
        .where((event) => joined.contains(event.id))
        .map(
          (event) => MyEventTicket(
            event: event,
            ticketNumber: '',
            seat: '',
            status: TicketStatus.upcoming,
            position: 0,
            estimatedEntry: 'Joined',
          ),
        )
        .toList(growable: false);
  }

  void _syncTestEntries() {
    if (!mounted) return;
    setState(() => _entries = _testEntries());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveMobileFrame(
            maxWidth: 860,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 20, 0),
                  child: Row(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Events',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Your gatherings in one calm place',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const EventsMemberBadge(compact: true),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: _MyEventsContext(entries: _entries),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                      Tab(text: 'Waitlist'),
                      Tab(text: 'Cancelled'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _JoinedEventList(
                        status: TicketStatus.upcoming,
                        entries: _entries,
                        onLeave: _leaveEvent,
                      ),
                      _JoinedEventList(
                        status: TicketStatus.attended,
                        entries: _entries,
                      ),
                      _JoinedEventList(
                        status: TicketStatus.waitlisted,
                        entries: _entries,
                      ),
                      _JoinedEventList(
                        status: TicketStatus.cancelled,
                        entries: _entries,
                      ),
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

  void _leaveEvent(MyEventTicket entry) {
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
              'You’ll leave ${entry.event.title}.',
              style: const TextStyle(color: AppColors.text, fontSize: 15),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Leave Event',
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: () {
                Navigator.pop(sheetContext);
                if (membershipTestMode) {
                  MembershipTestFlowController.instance.leaveEvent(
                    entry.event.id,
                  );
                  showEventSnack(context, 'You left ${entry.event.title}');
                  return;
                }
                setState(() {
                  final index = _entries.indexOf(entry);
                  _entries[index] = MyEventTicket(
                    event: entry.event,
                    ticketNumber: entry.ticketNumber,
                    seat: entry.seat,
                    status: TicketStatus.cancelled,
                    position: 0,
                    estimatedEntry: 'Left event',
                  );
                });
                showEventSnack(context, 'You left ${entry.event.title}');
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

class _MyEventsContext extends StatelessWidget {
  const _MyEventsContext({required this.entries});

  final List<MyEventTicket> entries;

  @override
  Widget build(BuildContext context) {
    final upcoming = entries
        .where((entry) => entry.status == TicketStatus.upcoming)
        .toList(growable: false);
    final next = upcoming.isEmpty ? null : upcoming.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .62)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upcoming.isEmpty
                      ? 'No upcoming gatherings'
                      : '${upcoming.length} upcoming ${upcoming.length == 1 ? 'gathering' : 'gatherings'}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Next: ${next.event.title} · ${next.event.date}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinedEventList extends StatelessWidget {
  const _JoinedEventList({
    required this.status,
    required this.entries,
    this.onLeave,
  });

  final TicketStatus status;
  final List<MyEventTicket> entries;
  final ValueChanged<MyEventTicket>? onLeave;

  @override
  Widget build(BuildContext context) {
    final visible = entries
        .where((entry) => entry.status == status)
        .toList(growable: false);
    if (visible.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          EventsEmptyState(
            title: status == TicketStatus.upcoming
                ? 'You haven’t joined an event yet'
                : 'No ${_statusLabel(status).toLowerCase()} events',
            description: status == TicketStatus.upcoming
                ? 'Explore curated gatherings and find one that feels right.'
                : 'Your ${_statusLabel(status).toLowerCase()} gatherings will '
                      'appear here.',
            onShowAll: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 430,
            ),
            itemBuilder: (context, index) {
              final entry = visible[index];
              return _JoinedEventCard(
                key: ValueKey(
                  'joined-event-${entry.event.id}-${entry.status.name}',
                ),
                entry: entry,
                onLeave: onLeave,
              );
            },
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final entry = visible[index];
            return _JoinedEventCard(
              key: ValueKey(
                'joined-event-${entry.event.id}-${entry.status.name}',
              ),
              entry: entry,
              onLeave: onLeave,
            );
          },
        );
      },
    );
  }
}

class _JoinedEventCard extends StatelessWidget {
  const _JoinedEventCard({super.key, required this.entry, this.onLeave});

  final MyEventTicket entry;
  final ValueChanged<MyEventTicket>? onLeave;

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventImagePanel(
            event: event,
            height: 170,
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: EventStatusBadge(status: entry.status),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            event.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          EventMetadataRow(
            icon: Icons.calendar_month_rounded,
            text: '${event.date} · ${event.time}',
          ),
          const SizedBox(height: 7),
          EventMetadataRow(icon: Icons.place_rounded, text: event.venue),
          if (entry.status == TicketStatus.waitlisted) ...[
            const SizedBox(height: 10),
            Text(
              'Position ${entry.position} · ${entry.estimatedEntry}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (entry.status == TicketStatus.cancelled) ...[
            const SizedBox(height: 10),
            const Text(
              'This event is no longer in your upcoming plans.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _EventActions(entry: entry, onLeave: onLeave),
        ],
      ),
    );
  }
}

class _EventActions extends StatelessWidget {
  const _EventActions({required this.entry, this.onLeave});

  final MyEventTicket entry;
  final ValueChanged<MyEventTicket>? onLeave;

  @override
  Widget build(BuildContext context) {
    final event = entry.event;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (entry.status != TicketStatus.cancelled)
          _ActionButton(
            icon: Icons.arrow_forward_rounded,
            label: 'View Details',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(EventDetailScreen.routeName, arguments: event),
          ),
        if (entry.status == TicketStatus.upcoming) ...[
          _ActionButton(
            icon: Icons.logout_rounded,
            label: 'Leave Event',
            onPressed: () => onLeave?.call(entry),
          ),
        ],
        if (entry.status == TicketStatus.waitlisted)
          _ActionButton(
            icon: Icons.hourglass_top_rounded,
            label: 'View Waitlist',
            onPressed: () =>
                Navigator.of(context).pushNamed(EventWaitlistScreen.routeName),
          ),
        if (entry.status == TicketStatus.attended)
          _ActionButton(
            icon: Icons.rate_review_rounded,
            label: 'Share Feedback',
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(PostEventFeedbackScreen.routeName),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
      ),
    );
  }
}

String _statusLabel(TicketStatus status) => switch (status) {
  TicketStatus.upcoming => 'Upcoming',
  TicketStatus.attended => 'Past',
  TicketStatus.waitlisted => 'Waitlist',
  TicketStatus.cancelled => 'Cancelled',
};
