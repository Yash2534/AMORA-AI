import 'dart:async';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_card.dart';
import 'package:amora_ai/core/widgets/amora_empty_state.dart';
import 'package:amora_ai/core/widgets/amora_loading.dart';
import 'package:amora_ai/core/widgets/amora_search_bar.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_editorial_panel.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:flutter/material.dart';

class EventsBrowseScreen extends StatefulWidget {
  const EventsBrowseScreen({super.key, this.showNavigation = true});

  static const routeName = '/events';
  final bool showNavigation;

  @override
  State<EventsBrowseScreen> createState() => _EventsBrowseScreenState();
}

class _EventsBrowseScreenState extends State<EventsBrowseScreen> {
  final _searchController = TextEditingController();
  final _pageController = PageController(viewportFraction: .92);
  var _selectedCity = 'Ahmedabad';
  var _selectedCategory = 'Premium';
  var _search = '';
  var _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  List<EventModel> get _filteredEvents {
    return events.where((event) {
      final matchesCity = event.city == _selectedCity;
      final matchesCategory =
          _selectedCategory == 'Premium' || event.category == _selectedCategory;
      final query = _search.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.city.toLowerCase().contains(query) ||
          event.category.toLowerCase().contains(query);
      return matchesCity && matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;
    return Scaffold(
      bottomNavigationBar: widget.showNavigation
          ? const FloatingBottomNav(activeTab: AmoraNavTab.events)
          : null,
      body: SafeArea(
        bottom: !widget.showNavigation,
        child: ResponsiveMobileFrame(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  22,
                  18,
                  widget.showNavigation ? 24 : 18,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    _PremiumAppBar(
                      onNotifications: () =>
                          showEventSnack(context, 'Notifications synced'),
                      onSearch: () => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: AmoraSpacing.x4),
                    PremiumEditorialPanel(
                      title: 'Premium socials for serious connections',
                      subtitle:
                          'Coffee meets, rooftop evenings, Garba nights and curated mixers with verified hosts.',
                      badge: 'AMORA Experiences',
                      cta: 'Browse',
                      assetPath: AppImages.eventRooftop,
                      icon: AmoraIcons.events,
                      aspectRatio: 1.82,
                      onTap: () => showEventSnack(
                        context,
                        'Showing curated events near $_selectedCity',
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.x4),
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _search = value),
                    ),
                    const SizedBox(height: AmoraSpacing.x4),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final city in eventCities)
                            CityChip(
                              city: city,
                              selected: city == _selectedCity,
                              onTap: () => setState(() => _selectedCity = city),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.x4),
                    Wrap(
                      children: [
                        for (final category in eventCategories)
                          CategoryChip(
                            label: category,
                            selected: category == _selectedCategory,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                          ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.x3),
                    SizedBox(
                      height:
                          MediaQuery.textScalerOf(context).scale(16) / 16 > 1.2
                          ? 256
                          : 220,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: heroEvents.length,
                        itemBuilder: (context, index) {
                          final event = heroEvents[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: EventBanner(
                              event: event,
                              onBook: () => _openBooking(event),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.x6),
                    const SectionTitle(
                      title: 'Featured Events',
                      subtitle: 'Curated dating moments near you',
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      const Row(
                        children: [
                          Expanded(child: AmoraCardSkeleton(height: 260)),
                          SizedBox(width: AmoraSpacing.space12),
                          Expanded(child: AmoraCardSkeleton(height: 260)),
                        ],
                      )
                    else if (filtered.isEmpty)
                      AmoraEmptyState(
                        icon: AmoraIcons.events,
                        title: 'No events match these filters',
                        message:
                            'Try another city, category, or search phrase.',
                        actionLabel: 'Reset filters',
                        onAction: _resetFilters,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textScale =
                              MediaQuery.textScalerOf(context).scale(16) / 16;
                          final railHeight = textScale > 1.2
                              ? 390.0
                              : constraints.maxWidth < 340
                              ? 370.0
                              : 352.0;
                          return SizedBox(
                            height: railHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(bottom: 2),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, index) {
                                final event = filtered[index];
                                return EventCard(
                                  event: event,
                                  onOpen: () => _openDetail(event),
                                  onBook: () => _openBooking(event),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 26),
                    _MapPreview(city: _selectedCity),
                    const SizedBox(height: 26),
                    const SectionTitle(
                      title: 'Popular This Week',
                      subtitle: 'Fast-filling premium socials',
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final columns = width >= 760
                            ? 4
                            : width >= 560
                            ? 3
                            : 2;
                        final tileWidth =
                            (width - ((columns - 1) * 12)) / columns;
                        final tileHeight = tileWidth < 180 ? 332.0 : 344.0;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: tileWidth / tileHeight,
                              ),
                          itemCount: popularEvents.length,
                          itemBuilder: (context, index) {
                            final event = popularEvents[index];
                            return EventCard(
                              event: event,
                              compact: true,
                              fillHeight: true,
                              onOpen: () => _openDetail(event),
                              onBook: () => _openBooking(event),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    const SectionTitle(
                      title: 'Recommended For You',
                      subtitle: 'AI picks based on intentions and interests',
                    ),
                    const SizedBox(height: 14),
                    for (final event in recommendedEvents)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _RecommendationCard(
                          event: event,
                          onOpen: () => _openDetail(event),
                          onBook: () => _openBooking(event),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = 'Ahmedabad';
      _selectedCategory = 'Premium';
      _search = '';
      _searchController.clear();
    });
  }

  void _openDetail(EventModel event) {
    Navigator.of(context).pushNamed('/event-detail', arguments: event);
  }

  void _openBooking(EventModel event) {
    Navigator.of(context).pushNamed('/ticket-booking', arguments: event);
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return AmoraCard(
      variant: AmoraCardVariant.event,
      padding: AmoraSpacing.compactCard,
      semanticLabel: '$city event map',
      child: SizedBox(
        height: 158,
        child: Row(
          children: [
            Container(
              width: 92,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.primaryRose],
                ),
                borderRadius: AmoraRadius.card,
              ),
              child: const Icon(
                AmoraIcons.location,
                color: AppColors.surface,
                size: AmoraIconSizes.large,
              ),
            ),
            const SizedBox(width: AmoraSpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$city event map',
                    style: AmoraTextStyles.titleLarge.copyWith(
                      color: AppColors.deepWine,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space8),
                  Text(
                    'Venue pins and distance filters are ready for maps integration.',
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumAppBar extends StatelessWidget {
  const _PremiumAppBar({required this.onNotifications, required this.onSearch});

  final VoidCallback onNotifications;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Events',
                style: AmoraTextStyles.headlineLarge.copyWith(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AmoraSpacing.space8),
              Text(
                'Meet people beyond swiping',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _CircleIconButton(
          tooltip: 'Notifications',
          icon: AmoraIcons.notifications,
          onPressed: onNotifications,
        ),
        const SizedBox(width: AmoraSpacing.space8),
        _CircleIconButton(
          tooltip: 'Search',
          icon: AmoraIcons.search,
          onPressed: onSearch,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.deepWine,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AmoraSearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Search events...',
      onClear: controller.text.isEmpty
          ? null
          : () {
              controller.clear();
              onChanged('');
            },
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.event,
    required this.onOpen,
    required this.onBook,
  });

  final EventModel event;
  final VoidCallback onOpen;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return AmoraCard(
      variant: AmoraCardVariant.event,
      padding: AmoraSpacing.compactCard,
      onTap: onOpen,
      semanticLabel: event.title,
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: event.palette),
              borderRadius: AmoraRadius.card,
            ),
            child: Icon(
              event.image.icon,
              color: AppColors.surface,
              size: AmoraIconSizes.large,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.titleMedium.copyWith(
                    color: AppColors.deepWine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space4),
                Text(
                  '${event.intent} • ${event.compatibility}% match',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space8),
                Text(
                  event.interests.join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.labelMedium.copyWith(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AmoraSpacing.space8),
          Semantics(
            button: true,
            label: 'Book ${event.title}',
            child: IconButton.filled(
              tooltip: 'Book event',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.deepWine,
                foregroundColor: AppColors.surface,
              ),
              onPressed: onBook,
              icon: const Icon(AmoraIcons.ticket),
            ),
          ),
        ],
      ),
    );
  }
}
