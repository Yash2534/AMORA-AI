import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/event_repository.dart';
import 'package:amora_ai/features/events/data/event_asset_catalog.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
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
  const EventsMemberExperience({super.key, this.controller, this.repository});

  final EventParticipationController? controller;
  final EventRepository? repository;

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

  var _loading = true;
  var _loadError = false;
  var _loadingMore = false;
  var _hasMore = false;
  int? _nextPage;
  List<EventModel> _events = const [];
  final ScrollController _scrollController = ScrollController();
  String? _activeCategory;
  String? _activeCity;
  DateTime? _activeDateTo;
  Set<String> _selectedCategories = <String>{};
  var _didPrecache = false;

  EventParticipationController get _controller =>
      widget.controller ?? EventParticipationController.instance;
  EventRepository get _repository =>
      widget.repository ?? EventRepository.instance;

  Map<String, TicketStatus> get _participation => _controller.statuses;

  List<String> get _categories => _categoryOptions;

  String get _city => _events.isEmpty ? '' : _events.first.city;

  List<EventModel> get _filteredEvents {
    if (_selectedCategories.isEmpty ||
        _selectedCategories.contains(_allCategory)) {
      return _events;
    }
    return _events
        .where(
          (event) => _selectedCategories.any(
            (category) => _matchesCategory(event, category),
          ),
        )
        .toList(growable: false);
  }

  List<EventModel> get _joinedEvents => _controller.registrations
      .where((registration) => registration.status == TicketStatus.upcoming)
      .map((registration) => registration.event)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleParticipationChanged);
    _scrollController.addListener(_handleScroll);
    _loadEvents();
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
    _controller.removeListener(_handleParticipationChanged);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleParticipationChanged() {
    if (!mounted) return;
    final updatedById = {
      for (final registration in _controller.registrations)
        registration.event.id: registration.event,
    };
    setState(() {
      _events = [for (final event in _events) updatedById[event.id] ?? event];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        EventsAppBar(
          onSearch: _showSearch,
          onCalendar: () =>
              Navigator.of(context).pushNamed(MyEventsScreen.routeName),
        ),
        Expanded(child: _buildMemberFeed(context)),
      ],
    );
  }

  Widget _buildMemberFeed(BuildContext context) {
    if (_loading) {
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AmoraaMainPageHeader.contentHorizontalInset,
          AmoraaMainPageHeader.contentSpacing,
          AmoraaMainPageHeader.contentHorizontalInset,
          32,
        ),
        child: EventsSkeleton(),
      );
    }
    if (_loadError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AmoraaMainPageHeader.contentHorizontalInset,
          AmoraaMainPageHeader.contentSpacing,
          AmoraaMainPageHeader.contentHorizontalInset,
          0,
        ),
        child: Center(child: EventsErrorState(onRetry: _loadEvents)),
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
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AmoraaMainPageHeader.contentHorizontalInset,
            AmoraaMainPageHeader.contentSpacing,
            AmoraaMainPageHeader.contentHorizontalInset,
            0,
          ),
          sliver: SliverList.list(
            children: [
              EventsContextBar(
                eventCount: _events
                    .where((event) => event.city == _city)
                    .length,
                city: _city,
                joinedCount: _joinedEvents.length,
              ),
              const SizedBox(height: 16),
              EventCategoryBar(
                categories: _categories,
                selectedValues: _selectedCategories,
                onChanged: _applyCategories,
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
                  attendees: featured.attendees,
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
                  key: const ValueKey('recommended-event-rail'),
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
          padding: const EdgeInsets.fromLTRB(
            20,
            28,
            20,
            FloatingBottomNav.contentSpacing,
          ),
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

  void _showAll() {
    _selectedCategories.clear();
    _loadEvents();
  }

  void _showSearch() {
    showSearch<EventModel?>(
      context: context,
      delegate: _EventSearchDelegate(
        repository: _repository,
        onOpen: _openDetail,
      ),
    );
  }

  void _openDetail(EventModel event) {
    Navigator.of(
      context,
    ).pushNamed(EventDetailScreen.routeName, arguments: event);
  }

  void _handleParticipation(EventModel event) {
    final status = _participation[event.id];
    if (status != null) {
      _openDetail(event);
      return;
    }
    if (membershipTestMode) {
      MembershipTestFlowController.instance.joinEvent(event.id);
      _controller.registerEvent(event);
      showEventSnack(context, 'You joined ${event.title}');
      return;
    }
    AmoraSession.requireAuth(
      context: context,
      onAuthenticated: () async {
        if (!mounted) return;
        try {
          await _controller.registerRemote(event);
          if (mounted) showEventSnack(context, 'You joined ${event.title}');
        } catch (error) {
          if (mounted) {
            showEventSnack(
              context,
              userFacingErrorMessage(
                error,
                fallback: 'Could not join this event. Please try again.',
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _loadEvents({
    String? category,
    String? city,
    DateTime? dateTo,
  }) async {
    _activeCategory = category;
    _activeCity = city;
    _activeDateTo = dateTo;
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final page = await _repository.browse(
        category: category,
        city: city,
        dateTo: dateTo,
      );
      _controller.syncCatalog(page.events);
      if (!mounted) return;
      setState(() {
        _events = page.events;
        _hasMore = page.hasMore;
        _nextPage = page.nextPage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 500) _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final nextPage = _nextPage;
    if (!_hasMore || _loadingMore || nextPage == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.browse(
        page: nextPage,
        category: _activeCategory,
        city: _activeCity,
        dateTo: _activeDateTo,
      );
      final known = _events.map((event) => event.id).toSet();
      final additions = page.events
          .where((event) => known.add(event.id))
          .toList(growable: false);
      _controller.syncCatalog(additions);
      if (!mounted) return;
      setState(() {
        _events = [..._events, ...additions];
        _hasMore = page.hasMore;
        _nextPage = page.nextPage;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _applyCategories(Set<String> categories) {
    _selectedCategories = Set<String>.of(categories);
    final selected = categories.isEmpty ? null : categories.last;
    if (selected == null || selected == _allCategory) {
      _loadEvents();
      return;
    }
    if (selected == 'This Week') {
      _loadEvents(dateTo: DateTime.now().add(const Duration(days: 7)));
      return;
    }
    if (selected == 'Near You') {
      _loadEvents(city: _city);
      return;
    }
    const categoryMap = {'Coffee': 'Coffee Meetup', 'Outdoors': 'Travel'};
    _loadEvents(category: categoryMap[selected] ?? selected);
  }
}

class _EventSearchDelegate extends SearchDelegate<EventModel?> {
  _EventSearchDelegate({required this.repository, required this.onOpen});

  final EventRepository repository;
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
    return FutureBuilder<EventPage>(
      future: repository.browse(search: query.trim(), limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EventsErrorState(onRetry: () => showResults(context));
        }
        final matches = snapshot.data?.events ?? const <EventModel>[];
        if (matches.isEmpty) return const EventsEmptyState();
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
      },
    );
  }
}

class _EventRail extends StatelessWidget {
  const _EventRail({
    super.key,
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
    if (!showDistance) {
      final railHeight = events
          .map(
            (event) => AmoraaRecommendedEventCard.requiredHeight(
              context,
              event,
              itemWidth,
            ),
          )
          .reduce(math.max);
      return SizedBox(
        height: railHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, index) => SizedBox(
            width: itemWidth,
            child: AmoraaRecommendedEventCard(
              event: events[index],
              status: participation[events[index].id],
              onOpen: () => onOpen(events[index]),
              onJoin: () => onJoin(events[index]),
            ),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      key: const ValueKey('nearby-event-rail'),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < events.length; index++) ...[
            if (index > 0) const SizedBox(width: 12),
            SizedBox(
              width: itemWidth,
              child: CompactEventCard(
                event: events[index],
                status: participation[events[index].id],
                onOpen: () => onOpen(events[index]),
                onJoin: () => onJoin(events[index]),
                showDistance: true,
              ),
            ),
          ],
        ],
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
    return SingleChildScrollView(
      key: const ValueKey('amora-circles-rail'),
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < events.length; index++) ...[
              if (index > 0) const SizedBox(width: 12),
              SizedBox(
                width: itemWidth,
                child: AmoraCircleCard(
                  event: events[index],
                  attendees: events[index].attendees,
                  status: participation[events[index].id],
                  onOpen: () => onOpen(events[index]),
                  onJoin: () => onJoin(events[index]),
                ),
              ),
            ],
          ],
        ),
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
