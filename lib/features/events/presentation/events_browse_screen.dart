import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/data/event_asset_catalog.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:amora_ai/features/subscription/presentation/testing/membership_test_flow.dart';
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
          child: const EventsMemberExperience(),
        ),
      ),
    );
  }
}

/// Public for focused widget tests and rendered directly by the Events route.
class EventsMemberExperience extends StatefulWidget {
  const EventsMemberExperience({super.key});

  @override
  State<EventsMemberExperience> createState() => _EventsMemberExperienceState();
}

class _EventsMemberExperienceState extends State<EventsMemberExperience> {
  static const _allCategory = 'For You';
  static const _categoryOptions = <String>[
    _allCategory,
    'This Week',
    'Near You',
    'Coffee',
    'Dinner',
    'Music',
    'Wellness',
    'Culture',
    'Outdoors',
    'Speed Dating',
    'AMORAA Circles',
  ];

  Timer? _loadingTimer;
  var _loading = true;
  var _selectedCategory = _allCategory;
  var _didPrecache = false;
  late final Map<String, TicketStatus> _participation;

  List<String> get _categories => _categoryOptions;

  String get _city => events.isEmpty ? '' : events.first.city;

  List<EventModel> get _filteredEvents {
    if (_selectedCategory == _allCategory) {
      return events;
    }
    return events
        .where((event) => _matchesCategory(event, _selectedCategory))
        .toList(growable: false);
  }

  List<EventModel> get _joinedEvents => events
      .where(
        (event) =>
            _participation[event.id] == TicketStatus.upcoming ||
            _participation[event.id] == TicketStatus.waitlisted,
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _participation = membershipTestMode
        ? {
            for (final id
                in MembershipTestFlowController.instance.joinedEventIds)
              id: TicketStatus.upcoming,
          }
        : {for (final entry in myEventTickets) entry.event.id: entry.status};
    if (membershipTestMode) {
      MembershipTestFlowController.instance.addListener(_syncTestParticipation);
    }
    _loadingTimer = Timer(const Duration(milliseconds: 480), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    for (final asset in EventAssetCatalog.all.take(3)) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    if (membershipTestMode) {
      MembershipTestFlowController.instance.removeListener(
        _syncTestParticipation,
      );
    }
    super.dispose();
  }

  void _syncTestParticipation() {
    if (!mounted) return;
    final joined = MembershipTestFlowController.instance.joinedEventIds;
    setState(() {
      _participation
        ..removeWhere((_, status) => status == TicketStatus.upcoming)
        ..addEntries(joined.map((id) => MapEntry(id, TicketStatus.upcoming)));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
        child: EventsSkeleton(),
      );
    }

    final filtered = _filteredEvents;
    final featured = filtered.isEmpty ? null : filtered.first;
    final recommended = featured == null
        ? const <EventModel>[]
        : filtered.skip(1).take(5).toList(growable: false);
    final thisWeek = filtered
        .where(_isWithinNextWeek)
        .where((event) => event.id != featured?.id)
        .take(8)
        .toList(growable: false);
    final nearby = filtered
        .where((event) => event.city == _city)
        .where((event) => event.id != featured?.id)
        .take(6)
        .toList(growable: false);
    final circles = filtered
        .where(
          (event) => _matchesAny(
            '${event.title} ${event.category} ${event.interests.join(' ')}',
            const ['coffee', 'book', 'founder', 'heritage', 'mindful', 'music'],
          ),
        )
        .where((event) => event.id != featured?.id)
        .take(5)
        .toList(growable: false);

    return CustomScrollView(
      key: const PageStorageKey('events-member-feed'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _EventsHeaderDelegate(
            child: EventsAppBar(
              onSearch: _showSearch,
              onCalendar: () =>
                  Navigator.of(context).pushNamed(MyEventsScreen.routeName),
              onFilter: _showFilters,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList.list(
            children: [
              EventsContextBar(
                eventCount: events.where((event) => event.city == _city).length,
                city: _city,
                joinedCount: _joinedEvents.length,
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
                  title: 'Featured experience',
                  subtitle: 'A standout gathering from this week’s curation',
                ),
                const SizedBox(height: 12),
                FeaturedEventCard(
                  event: featured,
                  attendees: eventAttendees,
                  status: _participation[featured.id],
                  onOpen: () => _openDetail(featured),
                  onJoin: () => _handleParticipation(featured),
                ),
                const SizedBox(height: 28),
              ],
              if (filtered.isEmpty)
                EventsEmptyState(onShowAll: _showAll)
              else if (recommended.isNotEmpty) ...[
                const _SectionHeading(
                  title: 'Recommended for You',
                  subtitle: 'Curated around shared interests and intent',
                ),
                const SizedBox(height: 12),
                _EventRail(
                  events: recommended,
                  participation: _participation,
                  onOpen: _openDetail,
                  onJoin: _handleParticipation,
                ),
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
        if (thisWeek.isNotEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _SectionHeading(
                title: 'This Week',
                subtitle: 'Plans worth making space for',
              ),
            ),
          ),
        if (thisWeek.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                if (constraints.crossAxisExtent >= 760) {
                  return SliverGrid.builder(
                    itemCount: thisWeek.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 418,
                        ),
                    itemBuilder: (_, index) {
                      final event = thisWeek[index];
                      return RepaintBoundary(
                        child: EventReveal(
                          delay: Duration(milliseconds: 35 * index),
                          child: StandardEventCard(
                            event: event,
                            status: _participation[event.id],
                            onOpen: () => _openDetail(event),
                            onJoin: () => _handleParticipation(event),
                          ),
                        ),
                      );
                    },
                  );
                }
                return SliverList.separated(
                  itemCount: thisWeek.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final event = thisWeek[index];
                    return RepaintBoundary(
                      child: EventReveal(
                        delay: Duration(milliseconds: 30 * index),
                        child: CompactEventCard(
                          event: event,
                          status: _participation[event.id],
                          onOpen: () => _openDetail(event),
                          onJoin: () => _handleParticipation(event),
                        ),
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
                _SectionHeading(
                  title: 'Near You',
                  subtitle: 'Curated around $_city',
                ),
                const SizedBox(height: 12),
                _EventRail(
                  events: nearby,
                  participation: _participation,
                  onOpen: _openDetail,
                  onJoin: _handleParticipation,
                  showDistance: true,
                ),
              ],
            ),
          ),
        if (circles.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverList.list(
              children: [
                const _SectionHeading(
                  title: 'AMORAA Circles',
                  subtitle:
                      'Small interest-led gatherings for easier conversation',
                ),
                const SizedBox(height: 12),
                _CircleRail(
                  events: circles,
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
                subtitle: _joinedEvents.isEmpty
                    ? 'Your joined gatherings will appear here'
                    : '${_joinedEvents.length} gathering'
                          '${_joinedEvents.length == 1 ? '' : 's'} ahead',
                actionLabel: 'View all',
                onAction: () =>
                    Navigator.of(context).pushNamed(MyEventsScreen.routeName),
              ),
              const SizedBox(height: 12),
              if (_joinedEvents.isEmpty)
                EventsEmptyState(
                  title: 'You haven’t joined an event yet',
                  description:
                      'Explore curated gatherings and choose one that feels right.',
                  onShowAll: _showAll,
                )
              else
                JoinedEventCard(
                  event: _joinedEvents.first,
                  status: _participation[_joinedEvents.first.id],
                  onOpen: () => _openDetail(_joinedEvents.first),
                  onViewAll: () =>
                      Navigator.of(context).pushNamed(MyEventsScreen.routeName),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _matchesCategory(EventModel event, String category) {
    final searchable =
        '${event.title} ${event.category} ${event.interests.join(' ')}'
            .toLowerCase();
    return switch (category) {
      'This Week' => _isWithinNextWeek(event),
      'Near You' => event.city == _city,
      'Coffee' => _matchesAny(searchable, const ['coffee', 'book', 'dessert']),
      'Dinner' => _matchesAny(searchable, const ['food', 'thali', 'dinner']),
      'Music' => _matchesAny(searchable, const ['music', 'sufi', 'garba']),
      'Wellness' => _matchesAny(searchable, const [
        'mindful',
        'fitness',
        'cycling',
        'walk',
      ]),
      'Culture' => _matchesAny(searchable, const [
        'culture',
        'museum',
        'heritage',
        'garba',
        'art',
      ]),
      'Outdoors' => _matchesAny(searchable, const [
        'trek',
        'cycling',
        'lake',
        'outdoor',
      ]),
      'Speed Dating' => searchable.contains('speed dating'),
      'AMORAA Circles' => _matchesAny(searchable, const [
        'coffee',
        'book',
        'founder',
        'heritage',
        'mindful',
        'music',
      ]),
      _ => true,
    };
  }

  bool _isWithinNextWeek(EventModel event) {
    final parts = event.date.replaceAll(',', '').split(RegExp(r'\s+'));
    if (parts.length < 3) return true;
    const months = <String, int>{
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final day = int.tryParse(parts[1]);
    final month = months[parts[2]];
    if (day == null || month == null) return true;
    final today = DateUtils.dateOnly(DateTime.now());
    var occurrence = DateTime(today.year, month, day);
    if (occurrence.isBefore(today)) {
      occurrence = DateTime(today.year + 1, month, day);
    }
    final days = occurrence.difference(today).inDays;
    return days >= 0 && days <= 7;
  }

  bool _matchesAny(String source, List<String> terms) {
    final normalized = source.toLowerCase();
    return terms.any(normalized.contains);
  }

  void _showAll() => setState(() => _selectedCategory = _allCategory);

  void _showSearch() {
    showSearch<EventModel?>(
      context: context,
      delegate: _EventSearchDelegate(source: events, onOpen: _openDetail),
    );
  }

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
    if (membershipTestMode) {
      MembershipTestFlowController.instance.joinEvent(event.id);
      showEventSnack(context, 'You joined ${event.title}');
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

class _EventSearchDelegate extends SearchDelegate<EventModel?> {
  _EventSearchDelegate({required this.source, required this.onOpen});

  final List<EventModel> source;
  final ValueChanged<EventModel> onOpen;

  @override
  String get searchFieldLabel => 'Search member events';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear search',
        onPressed: () => query = '',
        icon: const Icon(Icons.close_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final matches = source
        .where(
          (event) =>
              normalized.isEmpty ||
              event.title.toLowerCase().contains(normalized) ||
              event.category.toLowerCase().contains(normalized) ||
              event.city.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final event = matches[index];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Icon(event.image.icon, color: AppColors.secondary),
          title: Text(event.title),
          subtitle: Text('${event.category} · ${event.city}'),
          onTap: () {
            close(context, event);
            onOpen(event);
          },
        );
      },
    );
  }
}

class _EventsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _EventsHeaderDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 76;

  @override
  double get maxExtent => 76;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .98),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: .08)),
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _EventsHeaderDelegate oldDelegate) =>
      oldDelegate.child != child;
}

class _EventRail extends StatelessWidget {
  const _EventRail({
    required this.events,
    required this.participation,
    required this.onOpen,
    required this.onJoin,
    this.showDistance = false,
  });

  final List<EventModel> events;
  final Map<String, TicketStatus> participation;
  final ValueChanged<EventModel> onOpen;
  final ValueChanged<EventModel> onJoin;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final itemWidth = width >= 700 ? 330.0 : (width - 64).clamp(260.0, 328.0);
    return SizedBox(
      height: showDistance ? 174 : 418,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final event = events[index];
          return SizedBox(
            width: itemWidth,
            child: showDistance
                ? CompactEventCard(
                    event: event,
                    status: participation[event.id],
                    onOpen: () => onOpen(event),
                    onJoin: () => onJoin(event),
                    showDistance: true,
                  )
                : StandardEventCard(
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

class _CircleRail extends StatelessWidget {
  const _CircleRail({
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
    final itemWidth = width >= 700 ? 348.0 : (width - 58).clamp(276.0, 340.0);
    return SizedBox(
      height: 356,
      child: ListView.separated(
        key: const ValueKey('amora-circles-rail'),
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final event = events[index];
          return SizedBox(
            width: itemWidth,
            child: AmoraCircleCard(
              event: event,
              attendees: eventAttendees,
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
