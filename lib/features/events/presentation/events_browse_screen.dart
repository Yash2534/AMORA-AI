import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class EventsBrowseScreen extends StatelessWidget {
  const EventsBrowseScreen({super.key, this.showNavigation = true});

  static const routeName = '/events';

  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: showNavigation
          ? const FloatingBottomNav(activeTab: AmoraNavTab.events)
          : null,
      body: SafeArea(
        bottom: !showNavigation,
        child: ResponsiveMobileFrame(
          maxWidth: 1120,
          child: hasPremiumEventsAccess
              ? const EventsMemberExperience()
              : EventsLockedState(
                  onUpgrade: () => Navigator.of(
                    context,
                  ).pushNamed(SubscriptionScreen.routeName),
                  onManageMembership: () => Navigator.of(
                    context,
                  ).pushNamed(SubscriptionScreen.routeName),
                ),
        ),
      ),
    );
  }
}

class EventsLockedState extends StatelessWidget {
  const EventsLockedState({
    super.key,
    required this.onUpgrade,
    required this.onManageMembership,
  });

  final VoidCallback onUpgrade;
  final VoidCallback onManageMembership;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: FadeUp(
            duration: AmoraMotion.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Events',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    EventsMemberBadge(),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.tertiary.withValues(alpha: .7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .08),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tertiary),
                        ),
                        child: const Icon(
                          Icons.groups_2_rounded,
                          size: 42,
                          color: AppColors.primary,
                          semanticLabel: 'Members-only gatherings',
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Events are for Amora members',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 26,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Join curated gatherings designed for meaningful, '
                        'real-world connections.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _MemberBenefit(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Curated singles experiences',
                      ),
                      const _MemberBenefit(
                        icon: Icons.people_alt_rounded,
                        label: 'Smaller, intentional gatherings',
                      ),
                      const _MemberBenefit(
                        icon: Icons.interests_rounded,
                        label: 'Events shaped around shared interests',
                      ),
                      const SizedBox(height: 24),
                      AppPrimaryButton(
                        label: 'Explore Membership',
                        icon: Icons.workspace_premium_rounded,
                        onPressed: onUpgrade,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onManageMembership,
                        child: const Text('Restore or manage membership'),
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
}

class _MemberBenefit extends StatelessWidget {
  const _MemberBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The paid-member presentation is kept public for focused widget testing.
/// Route access remains controlled exclusively by [EventsBrowseScreen].
class EventsMemberExperience extends StatefulWidget {
  const EventsMemberExperience({super.key});

  @override
  State<EventsMemberExperience> createState() => _EventsMemberExperienceState();
}

class _EventsMemberExperienceState extends State<EventsMemberExperience> {
  static const _allCategory = 'For You';

  Timer? _loadingTimer;
  var _loading = true;
  var _selectedCategory = _allCategory;
  late final Map<String, TicketStatus> _participation = {
    for (final entry in myEventTickets) entry.event.id: entry.status,
  };

  List<String> get _categories => [
    _allCategory,
    ...{for (final event in events) event.category},
  ];

  List<EventModel> get _filteredEvents {
    if (_selectedCategory == _allCategory) {
      return events;
    }
    return events
        .where((event) => event.category == _selectedCategory)
        .toList(growable: false);
  }

  List<MyEventTicket> get _joinedEntries => myEventTickets
      .where(
        (entry) =>
            _participation[entry.event.id] == TicketStatus.upcoming ||
            _participation[entry.event.id] == TicketStatus.waitlisted,
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _loadingTimer = Timer(const Duration(milliseconds: 480), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 22, 20, 32),
        child: EventsSkeleton(),
      );
    }

    final filtered = _filteredEvents;
    final featured = filtered.isEmpty ? null : filtered.first;
    final upcoming = featured == null
        ? const <EventModel>[]
        : filtered.skip(1).take(8).toList(growable: false);
    final nearby = filtered
        .where((event) => event.city == 'Ahmedabad')
        .take(6)
        .toList(growable: false);
    final interestBased = filtered
        .where(
          (event) => event.interests.any(
            (interest) =>
                interest == 'Coffee' ||
                interest == 'Music' ||
                interest == 'Culture',
          ),
        )
        .take(6)
        .toList(growable: false);

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverList.list(
            children: [
              EventsAppBar(
                onCalendar: () =>
                    Navigator.of(context).pushNamed(MyEventsScreen.routeName),
                onFilter: _showFilters,
              ),
              const SizedBox(height: 18),
              EventsSummary(
                eventCount: events
                    .where((event) => event.city == 'Ahmedabad')
                    .length,
                city: 'Ahmedabad',
                joinedCount: _joinedEntries.length,
              ),
              const SizedBox(height: 16),
              EventCategoryBar(
                categories: _categories,
                selected: _selectedCategory,
                onSelected: (category) =>
                    setState(() => _selectedCategory = category),
              ),
              const SizedBox(height: 24),
              if (featured != null) ...[
                const _SectionHeading(
                  title: 'Featured for you',
                  subtitle: 'A standout gathering from this week’s curation',
                ),
                const SizedBox(height: 12),
                FeaturedEventCard(
                  event: featured,
                  status: _participation[featured.id],
                  onOpen: () => _openDetail(featured),
                  onJoin: () => _handleParticipation(featured),
                ),
                const SizedBox(height: 28),
              ],
              if (filtered.isEmpty)
                EventsEmptyState(onShowAll: _showAll)
              else ...[
                const _SectionHeading(
                  title: 'Upcoming events',
                  subtitle: 'Make space for a meaningful plan',
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (upcoming.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                if (constraints.crossAxisExtent >= 760) {
                  return SliverGrid.builder(
                    itemCount: upcoming.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 356,
                        ),
                    itemBuilder: (_, index) {
                      final event = upcoming[index];
                      return FadeUp(
                        delay: Duration(milliseconds: 35 * index),
                        child: EventCard(
                          event: event,
                          status: _participation[event.id],
                          onOpen: () => _openDetail(event),
                          onJoin: () => _handleParticipation(event),
                        ),
                      );
                    },
                  );
                }
                return SliverList.separated(
                  itemCount: upcoming.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final event = upcoming[index];
                    return FadeUp(
                      delay: Duration(milliseconds: 30 * index),
                      child: EventCard(
                        event: event,
                        horizontal: true,
                        status: _participation[event.id],
                        onOpen: () => _openDetail(event),
                        onJoin: () => _handleParticipation(event),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        if (nearby.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverList.list(
              children: [
                const _SectionHeading(
                  title: 'Near you',
                  subtitle: 'Curated around Ahmedabad',
                ),
                const SizedBox(height: 12),
                _EventRail(
                  events: nearby,
                  participation: _participation,
                  onOpen: _openDetail,
                  onJoin: _handleParticipation,
                ),
              ],
            ),
          ),
        if (interestBased.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverList.list(
              children: [
                const _SectionHeading(
                  title: 'Shared interests',
                  subtitle: 'Coffee, culture, music, and easy conversation',
                ),
                const SizedBox(height: 12),
                _EventRail(
                  events: interestBased,
                  participation: _participation,
                  onOpen: _openDetail,
                  onJoin: _handleParticipation,
                ),
              ],
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 38),
          sliver: SliverList.list(
            children: [
              _SectionHeading(
                title: 'My Events',
                subtitle: _joinedEntries.isEmpty
                    ? 'Your joined gatherings will appear here'
                    : '${_joinedEntries.length} gathering'
                          '${_joinedEntries.length == 1 ? '' : 's'} ahead',
                actionLabel: 'View all',
                onAction: () =>
                    Navigator.of(context).pushNamed(MyEventsScreen.routeName),
              ),
              const SizedBox(height: 12),
              if (_joinedEntries.isEmpty)
                EventsEmptyState(
                  title: 'You haven’t joined an event yet',
                  description:
                      'Explore curated gatherings and find one that feels right.',
                  onShowAll: _showAll,
                )
              else
                for (final entry in _joinedEntries) ...[
                  EventCard(
                    event: entry.event,
                    horizontal: true,
                    status: _participation[entry.event.id],
                    onOpen: () => _openDetail(entry.event),
                    onJoin: () => _handleParticipation(entry.event),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }

  void _showAll() => setState(() => _selectedCategory = _allCategory);

  void _openDetail(EventModel event) {
    Navigator.of(
      context,
    ).pushNamed(EventDetailScreen.routeName, arguments: event);
  }

  void _handleParticipation(EventModel event) {
    final status = _participation[event.id];
    if (status == TicketStatus.waitlisted) {
      _openDetail(event);
      return;
    }
    if (status != null) {
      _openDetail(event);
      return;
    }
    AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () {
        if (!mounted) return;
        setState(() => _participation[event.id] = TicketStatus.upcoming);
        showEventSnack(context, 'You joined ${event.title}');
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Discover events',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a category from the discovery row.',
              style: TextStyle(color: AppColors.text, fontSize: 14),
            ),
            const SizedBox(height: 18),
            EventCategoryBar(
              categories: _categories,
              selected: _selectedCategory,
              onSelected: (category) {
                setState(() => _selectedCategory = category);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EventRail extends StatelessWidget {
  const _EventRail({
    required this.events,
    required this.participation,
    required this.onOpen,
    required this.onJoin,
  });

  final List<EventModel> events;
  final Map<String, TicketStatus> participation;
  final ValueChanged<EventModel> onOpen;
  final ValueChanged<EventModel> onJoin;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final itemWidth = width >= 700 ? 330.0 : (width - 64).clamp(260.0, 328.0);
    return SizedBox(
      height: 354,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final event = events[index];
          return SizedBox(
            width: itemWidth,
            child: EventCard(
              event: event,
              status: participation[event.id],
              onOpen: () => onOpen(event),
              onJoin: () => onJoin(event),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
