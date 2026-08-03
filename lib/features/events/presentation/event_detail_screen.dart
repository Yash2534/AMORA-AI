import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/event_group_chat_screen.dart';
import 'package:amora_ai/features/events/presentation/event_waitlist_screen.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, this.event, this.controller});

  static const routeName = '/event-detail';

  final EventModel? event;
  final EventParticipationController? controller;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  bool _actionBusy = false;
  bool _celebrateJoin = false;
  TicketStatus? _status;
  String? _eventId;
  Timer? _loadingTimer;
  Timer? _celebrationTimer;

  EventParticipationController get _controller =>
      widget.controller ?? EventParticipationController.instance;

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _loading = false);
    });
    _controller.addListener(_syncStatus);
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _celebrationTimer?.cancel();
    _controller.removeListener(_syncStatus);
    super.dispose();
  }

  void _syncStatus() {
    if (!mounted || _eventId == null) return;
    setState(() {
      _status = _controller.statusFor(_eventId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final event = widget.event ?? (args is EventModel ? args : events.first);
    if (_eventId != event.id) {
      _eventId = event.id;
      _status = _existingStatus(event);
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: _DetailActionSkeleton(),
        body: SafeArea(
          bottom: false,
          child: ResponsiveMobileFrame(
            maxWidth: 940,
            child: EventDetailSkeleton(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _DetailActionBar(
        event: event,
        status: _status,
        busy: _actionBusy,
        celebrate: _celebrateJoin,
        onPressed: () => _handlePrimaryAction(event),
      ),
      body: SafeArea(
        bottom: false,
        child: ResponsiveMobileFrame(
          maxWidth: 940,
          child: CustomScrollView(
            key: ValueKey('event-detail-${event.id}'),
            slivers: [
              SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) => EventDetailHero(
                    event: event,
                    status: _status,
                    height: (constraints.maxWidth * 9 / 16).clamp(260.0, 460.0),
                    onBack: () => Navigator.of(context).maybePop(),
                    onShare: () =>
                        showEventSnack(context, 'Share link prepared'),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 38),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EventReveal(child: _DetailMetadata(event: event)),
                      const SizedBox(height: 20),
                      EventReveal(
                        delay: const Duration(milliseconds: 30),
                        child: EventHostSection(host: event.host),
                      ),
                      const SizedBox(height: 28),
                      EventDetailSection(
                        title: 'About this gathering',
                        delay: const Duration(milliseconds: 55),
                        child: ExpandableEventDescription(
                          description: _eventDescription(event),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const EventDetailSection(
                        title: 'What to expect',
                        subtitle:
                            'The available event schedule, presented at a glance',
                        delay: Duration(milliseconds: 80),
                        child: _AgendaList(items: eventAgenda),
                      ),
                      const SizedBox(height: 28),
                      EventDetailSection(
                        title: 'Good to know',
                        subtitle: 'Details already provided for this event',
                        delay: const Duration(milliseconds: 105),
                        child: _Requirements(event: event),
                      ),
                      const SizedBox(height: 28),
                      EventDetailSection(
                        title: 'Why this event may suit you',
                        subtitle:
                            'Based on the compatibility and interests already available',
                        delay: const Duration(milliseconds: 130),
                        child: _SuitabilityCard(event: event),
                      ),
                      const SizedBox(height: 28),
                      EventDetailSection(
                        title: 'Who’s joining',
                        subtitle:
                            'Members currently visible for this gathering',
                        delay: const Duration(milliseconds: 155),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EventAttendeePreview(attendees: eventAttendees),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 116,
                              child: ListView.separated(
                                key: const ValueKey('event-detail-attendees'),
                                scrollDirection: Axis.horizontal,
                                itemCount: eventAttendees.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (_, index) => EventReveal(
                                  delay: Duration(milliseconds: 25 * index),
                                  offset: 6,
                                  child: _AttendeeCard(
                                    attendee: eventAttendees[index],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_status == TicketStatus.upcoming) ...[
                        const SizedBox(height: 28),
                        EventDetailSection(
                          title: 'Joined event tools',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ActionChip(
                                avatar: const Icon(
                                  Icons.forum_rounded,
                                  size: 18,
                                ),
                                label: const Text('Group Chat'),
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(EventGroupChatScreen.routeName),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_status == TicketStatus.attended) ...[
                        const SizedBox(height: 28),
                        EventDetailSection(
                          title: 'Your experience',
                          child: AppPrimaryButton(
                            label: 'Share feedback',
                            icon: Icons.rate_review_rounded,
                            variant: AppPrimaryButtonVariant.outlined,
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(PostEventFeedbackScreen.routeName),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      EventReveal(
                        delay: const Duration(milliseconds: 180),
                        child: EventSafetySection(
                          onGuidelines: () => Navigator.of(
                            context,
                          ).pushNamed(SafetyPrivacyScreen.routeName),
                          onReport: () => Navigator.of(
                            context,
                          ).pushNamed(ReportFlowScreen.routeName),
                        ),
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
    return _controller.statusFor(event.id);
  }

  void _handlePrimaryAction(EventModel event) {
    if (_actionBusy) return;
    if (_status == TicketStatus.waitlisted) {
      Navigator.of(
        context,
      ).pushNamed(EventWaitlistScreen.routeName, arguments: event);
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

    if (membershipTestMode) {
      _startJoinMotion();
      MembershipTestFlowController.instance.joinEvent(event.id);
      _controller.registerEvent(event);
      showEventSnack(context, 'You joined ${event.title}');
      return;
    }
    AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () {
        if (!mounted) return;
        _controller.registerEvent(event);
        setState(() {
          _actionBusy = true;
          _celebrateJoin = true;
        });
        _scheduleJoinMotionEnd();
        showEventSnack(context, 'You joined ${event.title}');
      },
    );
  }

  void _startJoinMotion() {
    if (!mounted) return;
    setState(() {
      _actionBusy = true;
      _celebrateJoin = true;
    });
    _scheduleJoinMotionEnd();
  }

  void _scheduleJoinMotionEnd() {
    _celebrationTimer?.cancel();
    _celebrationTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _actionBusy = false;
        _celebrateJoin = false;
      });
    });
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
                if (membershipTestMode) {
                  MembershipTestFlowController.instance.leaveEvent(event.id);
                }
                _controller.cancelEvent(event);
                setState(() {
                  _actionBusy = false;
                  _celebrateJoin = false;
                });
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

String _eventDescription(EventModel event) =>
    '${event.title} is a curated ${event.category.toLowerCase()} in '
    '${event.city}, hosted by ${event.host.name}. It brings together people '
    'who value ${event.intent.toLowerCase()} through shared interests in '
    '${event.interests.join(', ').toLowerCase()}. The gathering is planned '
    'around the existing ${event.language.toLowerCase()} language setting and '
    '${event.dressCode.toLowerCase()} dress guidance.';

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
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .62)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
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

class _SuitabilityCard extends StatelessWidget {
  const _SuitabilityCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${event.compatibility}% compatibility with this experience',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${event.intent} · ${event.interests.join(' · ')}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
      constraints: const BoxConstraints(maxWidth: 300),
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
          Flexible(
            child: Text(
              label,
              softWrap: true,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
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
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumAvatar(
                radius: 18,
                imageUrl: attendee.photoAsset,
                fallbackAsset: attendee.photoAsset,
                initials: attendee.name.characters.first,
                semanticLabel: '${attendee.name} attendee photo',
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

class _DetailActionBar extends StatelessWidget {
  const _DetailActionBar({
    required this.event,
    required this.status,
    required this.busy,
    required this.celebrate,
    required this.onPressed,
  });

  final EventModel event;
  final TicketStatus? status;
  final bool busy;
  final bool celebrate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isJoined = status == TicketStatus.upcoming;
    final statusLabel = switch (status) {
      TicketStatus.upcoming => 'Leave Event',
      TicketStatus.attended => 'Share feedback',
      TicketStatus.waitlisted => 'View Waitlist',
      TicketStatus.cancelled => 'Event Cancelled',
      null => 'Join Event',
    };
    final label = busy ? 'Joining…' : statusLabel;
    final icon = switch (status) {
      TicketStatus.upcoming => Icons.logout_rounded,
      TicketStatus.attended => Icons.rate_review_rounded,
      TicketStatus.waitlisted => Icons.hourglass_top_rounded,
      TicketStatus.cancelled => Icons.event_busy_rounded,
      null => Icons.event_available_rounded,
    };
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: celebrate
                ? AppColors.secondary
                : AppColors.tertiary.withValues(alpha: .62),
          ),
          boxShadow: [
            BoxShadow(
              color: (celebrate ? AppColors.secondary : AppColors.primary)
                  .withValues(alpha: celebrate ? .22 : .1),
              blurRadius: celebrate ? 32 : 26,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: TweenAnimationBuilder<double>(
            key: ValueKey(celebrate),
            tween: Tween(begin: celebrate ? .96 : 1, end: 1),
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .96, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: AppPrimaryButton(
                key: ValueKey(label),
                label: label,
                icon: busy ? Icons.hourglass_top_rounded : icon,
                isLoading: busy,
                variant: isJoined
                    ? AppPrimaryButtonVariant.outlined
                    : AppPrimaryButtonVariant.primary,
                onPressed: status == TicketStatus.cancelled || busy
                    ? null
                    : onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailActionSkeleton extends StatelessWidget {
  const _DetailActionSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.tertiary),
        ),
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: .58),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
