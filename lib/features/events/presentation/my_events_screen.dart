import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/amora_empty_state.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:flutter/material.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key});

  static const routeName = '/my-events';

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  late final List<MyEventTicket> _tickets = List<MyEventTicket>.from(
    myEventTickets,
  );

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveMobileFrame(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AmoraSpacing.space20,
                    AmoraSpacing.space20,
                    AmoraSpacing.space20,
                    AmoraSpacing.space0,
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(AmoraIcons.back),
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Text(
                          'My Events',
                          style: AmoraTextStyles.headlineMedium.copyWith(
                            color: AppColors.deepWine,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                  child: TabBar(
                    tabs: [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Attended'),
                      Tab(text: 'Waitlisted'),
                      Tab(text: 'Cancelled'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TicketList(
                        status: TicketStatus.upcoming,
                        tickets: _tickets,
                        onCancel: _cancelTicket,
                      ),
                      _TicketList(
                        status: TicketStatus.attended,
                        tickets: _tickets,
                      ),
                      _TicketList(
                        status: TicketStatus.waitlisted,
                        tickets: _tickets,
                      ),
                      _TicketList(
                        status: TicketStatus.cancelled,
                        tickets: _tickets,
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

  void _cancelTicket(MyEventTicket ticket) {
    showAmoraDialog<void>(
      context: context,
      title: 'Cancel ticket?',
      message: 'Cancel your pass for ${ticket.event.title}?',
      icon: AmoraIcons.ticket,
      primaryLabel: 'Cancel ticket',
      secondaryLabel: 'Keep ticket',
      onPrimary: () {
        Navigator.pop(context);
        setState(() {
          _tickets
            ..remove(ticket)
            ..add(
              MyEventTicket(
                event: ticket.event,
                ticketNumber: ticket.ticketNumber,
                seat: 'Cancelled',
                status: TicketStatus.cancelled,
                position: 0,
                estimatedEntry: 'Cancellation requested',
              ),
            );
        });
        showEventSnack(context, 'Ticket cancellation requested');
      },
    );
  }
}

class _TicketList extends StatelessWidget {
  const _TicketList({
    required this.status,
    required this.tickets,
    this.onCancel,
  });

  final TicketStatus status;
  final List<MyEventTicket> tickets;
  final ValueChanged<MyEventTicket>? onCancel;

  @override
  Widget build(BuildContext context) {
    final visibleTickets = tickets
        .where((ticket) => ticket.status == status)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        if (visibleTickets.isEmpty)
          AmoraEmptyState(
            icon: AmoraIcons.events,
            title: 'No ${status.name} events',
            message: 'Your ${status.name} event passes will appear here.',
          )
        else
          for (final ticket in visibleTickets) ...[
            _MyEventCard(ticket: ticket, onCancel: onCancel),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _MyEventCard extends StatelessWidget {
  const _MyEventCard({required this.ticket, this.onCancel});

  final MyEventTicket ticket;
  final ValueChanged<MyEventTicket>? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.surface),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepWine.withValues(alpha: .07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventImagePanel(
            event: ticket.event,
            height: 132,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    ticket.event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${ticket.event.date} - ${ticket.event.time}',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            ticket.event.venue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (ticket.status == TicketStatus.upcoming)
            _UpcomingActions(ticket: ticket, onCancel: onCancel),
          if (ticket.status == TicketStatus.attended) _AttendedActions(),
          if (ticket.status == TicketStatus.waitlisted)
            _WaitlistedActions(ticket: ticket),
          if (ticket.status == TicketStatus.cancelled)
            const Text(
              'Cancelled - refund and support workflow placeholder',
              style: TextStyle(
                color: AppColors.textGray,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _UpcomingActions extends StatelessWidget {
  const _UpcomingActions({required this.ticket, this.onCancel});

  final MyEventTicket ticket;
  final ValueChanged<MyEventTicket>? onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionChipButton(
          icon: Icons.qr_code_2_rounded,
          label: 'QR Pass',
          onTap: () => _showQrPass(context, ticket),
        ),
        _ActionChipButton(
          icon: Icons.near_me_rounded,
          label: 'Directions',
          onTap: () => showEventSnack(context, 'Directions opened'),
        ),
        _ActionChipButton(
          icon: Icons.cancel_rounded,
          label: 'Cancel Ticket',
          onTap: () => onCancel?.call(ticket),
        ),
      ],
    );
  }

  void _showQrPass(BuildContext context, MyEventTicket ticket) {
    showAmoraBottomSheet<void>(
      context: context,
      child: QRPassCard(ticket: ticket),
    );
  }
}

class _AttendedActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionChipButton(
          icon: Icons.star_rounded,
          label: 'Rating',
          onTap: () => showEventSnack(context, 'Rating saved'),
        ),
        _ActionChipButton(
          icon: Icons.ios_share_rounded,
          label: 'Share Memory',
          onTap: () => showEventSnack(context, 'Memory shared'),
        ),
        _ActionChipButton(
          icon: Icons.photo_library_rounded,
          label: 'Download Photos',
          onTap: () => showEventSnack(context, 'Photo download queued'),
        ),
      ],
    );
  }
}

class _WaitlistedActions extends StatelessWidget {
  const _WaitlistedActions({required this.ticket});

  final MyEventTicket ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Position ${ticket.position} - ${ticket.estimatedEntry}',
          style: const TextStyle(
            color: AppColors.primaryPurple,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        _ActionChipButton(
          icon: Icons.notifications_active_rounded,
          label: 'Notify Me',
          onTap: () => showEventSnack(context, 'Waitlist alerts enabled'),
        ),
      ],
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: AppColors.primaryPurple),
      label: Text(label),
      labelStyle: const TextStyle(
        color: AppColors.deepWine,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: AppColors.lavenderBackground.withValues(alpha: .55),
      side: BorderSide.none,
      onPressed: onTap,
    );
  }
}
