import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    this.event,
    this.controller,
    this.repository,
  });

  static const routeName = '/event-detail';

  final EventModel? event;
  final EventParticipationController? controller;
  final EventRepository? repository;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = true;
  bool _actionBusy = false;
  bool _celebrateJoin = false;
  TicketStatus? _status;
  String? _eventId;
  EventModel? _event;
  Object? _loadError;
  bool _startedLoad = false;
  Timer? _celebrationTimer;

  EventParticipationController get _controller =>
      widget.controller ?? EventParticipationController.instance;
  EventRepository get _repository =>
      widget.repository ?? EventRepository.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedLoad) return;
    _startedLoad = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final seed = widget.event ?? (args is EventModel ? args : null);
    if (seed == null) {
      setState(() {
        _loading = false;
        _loadError = StateError('Event identifier is required.');
      });
      return;
    }
    _event = seed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller != null) {
        Future<void>.delayed(const Duration(milliseconds: 260), () {
          if (mounted) setState(() => _loading = false);
        });
      } else {
        _loadDetail(seed.id);
      }
    });
  }

  @override
  void dispose() {
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
    final event = _event;
    final textScaleDelta = (MediaQuery.textScalerOf(context).scale(1) - 1)
        .clamp(0.0, .3);
    final heroTextAllowance = textScaleDelta * 104;
    final attendeeTextAllowance = textScaleDelta * 44;
    if (event != null && _eventId != event.id) {
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
    if (event == null || _loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: EventsErrorState(
              onRetry: event == null
                  ? () => Navigator.of(context).maybePop()
                  : () => _loadDetail(event.id),
            ),
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
                  builder: (context, constraints) {
                    final baseHeight = (constraints.maxWidth * 9 / 16).clamp(
                      260.0,
                      460.0,
                    );
                    return EventDetailHero(
                      event: event,
                      status: _status,
                      height: (baseHeight + heroTextAllowance).clamp(
                        260.0,
                        492.0,
                      ),
                      onBack: () => Navigator.of(context).maybePop(),
                      onShare: () => showEventSnack(
                        context,
                        'Event sharing is not connected yet. Nothing was shared.',
                      ),
                    );
                  },
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
                        child: EventOrganizerSection(
                          organizer: event.organizer,
                        ),
                      ),
                      const SizedBox(height: 28),
                      EventDetailSection(
                        title: 'About this gathering',
                        delay: const Duration(milliseconds: 55),
                        child: ExpandableEventDescription(
                          description: event.description,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (event.agenda.isNotEmpty) ...[
                        EventDetailSection(
                          title: 'What to expect',
                          subtitle:
                              'The available event schedule, presented at a glance',
                          delay: const Duration(milliseconds: 80),
                          child: _AgendaList(items: event.agenda),
                        ),
                        const SizedBox(height: 28),
                      ],
                      EventDetailSection(
                        title: 'Good to know',
                        subtitle: 'Details already provided for this event',
                        delay: const Duration(milliseconds: 105),
                        child: _Requirements(event: event),
                      ),
                      const SizedBox(height: 28),
                      if (event.compatibility > 0) ...[
                        EventDetailSection(
                          title: 'Why this event may suit you',
                          subtitle: 'Based on your available event preferences',
                          delay: const Duration(milliseconds: 130),
                          child: _SuitabilityCard(event: event),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (event.attendees.isNotEmpty)
                        EventDetailSection(
                          title: 'Who’s joining',
                          subtitle:
                              'Members currently visible for this gathering',
                          delay: const Duration(milliseconds: 155),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              EventAttendeePreview(attendees: event.attendees),
                              const SizedBox(height: 18),
                              SizedBox(
                                height: 116 + attendeeTextAllowance,
                                child: ListView.separated(
                                  key: const ValueKey('event-detail-attendees'),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: event.attendees.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (_, index) => EventReveal(
                                    delay: Duration(milliseconds: 25 * index),
                                    offset: 6,
                                    child: _AttendeeCard(
                                      attendee: event.attendees[index],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 28),
                      EventReveal(
                        delay: const Duration(milliseconds: 180),
                        child: EventSafetySection(
                          onGuidelines: () => Navigator.of(
                            context,
                          ).pushNamed(SafetyPrivacyScreen.routeName),
                          onReport: () => Navigator.of(context).pushNamed(
                            ReportFlowScreen.routeName,
                            arguments: ReportFlowArgs(
                              targetType: 'event',
                              targetId: event.id,
                              title: event.title,
                              imageUrl: event.image.imageUrl,
                              fallbackAsset: event.image.assetPath,
                            ),
                          ),
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

  Future<void> _loadDetail(String eventId) async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final minimumSkeleton = Future<void>.delayed(
        const Duration(milliseconds: 260),
      );
      final event = await _repository.detail(eventId);
      await minimumSkeleton;
      _controller.syncCatalog([event]);
      if (!mounted) return;
      setState(() {
        _event = event;
        _status = event.participationStatus;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  TicketStatus? _existingStatus(EventModel event) {
    return event.participationStatus ?? _controller.statusFor(event.id);
  }

  void _handlePrimaryAction(EventModel event) {
    if (_actionBusy) return;
    if (_status == TicketStatus.upcoming) {
      _confirmLeave(event);
      return;
    }
    if (_status == TicketStatus.waitlisted) return;
    if (_status == TicketStatus.cancelled) return;

    final joiningWaitlist = event.waitlistEnabled;
    if (membershipTestMode && !joiningWaitlist) {
      _startJoinMotion();
      MembershipTestFlowController.instance.joinEvent(event.id);
      _controller.registerEvent(event);
      showEventSnack(context, 'You joined ${event.title}');
      return;
    }
    AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () async {
        if (!mounted) return;
        setState(() {
          _actionBusy = true;
        });
        try {
          if (joiningWaitlist) {
            await _controller.joinWaitlistRemote(event);
            if (mounted) showEventSnack(context, 'You joined the waitlist');
          } else {
            await _controller.registerRemote(event);
            if (mounted) {
              setState(() => _celebrateJoin = true);
              showEventSnack(context, 'You joined ${event.title}');
            }
          }
        } catch (error) {
          if (mounted) showEventSnack(context, error.toString());
        } finally {
          _scheduleJoinMotionEnd();
        }
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(sheetContext);
                if (membershipTestMode) {
                  MembershipTestFlowController.instance.leaveEvent(event.id);
                }
                try {
                  await _controller.cancelRemote(event);
                } catch (error) {
                  messenger.showSnackBar(SnackBar(content: Text('$error')));
                  return;
                }
                if (!mounted) return;
                setState(() {
                  _actionBusy = false;
                  _celebrateJoin = false;
                });
                messenger.showSnackBar(
                  SnackBar(content: Text('You left ${event.title}')),
                );
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
          if (event.hasNumericDistance) ...[
            const SizedBox(height: 16),
            EventInfoTile(
              icon: Icons.near_me_rounded,
              label: 'Distance',
              value: event.distance,
            ),
          ],
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
    final hasParticipation = status != null;
    final statusLabel = switch (status) {
      TicketStatus.upcoming => 'Leave Event',
      TicketStatus.waitlisted => 'Waitlisted',
      TicketStatus.cancelled => 'Event Cancelled',
      null =>
        event.waitlistEnabled
            ? 'Join Waitlist'
            : event.registrationOpen
            ? 'Join Event'
            : 'Event Full',
    };
    final label = busy ? 'Joining…' : statusLabel;
    final icon = switch (status) {
      TicketStatus.upcoming => Icons.logout_rounded,
      TicketStatus.waitlisted => Icons.hourglass_top_rounded,
      TicketStatus.cancelled => Icons.event_busy_rounded,
      null =>
        event.waitlistEnabled
            ? Icons.hourglass_top_rounded
            : event.registrationOpen
            ? Icons.event_available_rounded
            : Icons.event_busy_rounded,
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
                variant: hasParticipation
                    ? AppPrimaryButtonVariant.outlined
                    : AppPrimaryButtonVariant.primary,
                onPressed:
                    status == TicketStatus.cancelled ||
                        status == TicketStatus.waitlisted ||
                        busy ||
                        (status == null &&
                            !event.registrationOpen &&
                            !event.waitlistEnabled)
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
