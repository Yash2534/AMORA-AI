import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/amoraa_adaptive_image.dart';
import 'package:amora_ai/core/widgets/amoraa_main_page_header.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:flutter/material.dart';

void showEventSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

Route<T> premiumEventRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => screen,
    transitionDuration: AmoraMotion.page,
    reverseTransitionDuration: AmoraMotion.selection,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: AmoraMotion.curve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.025, .015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class EventReveal extends StatelessWidget {
  const EventReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 12,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeUp(delay: delay, offset: offset, child: child);
  }
}

class EventsAppBar extends StatelessWidget {
  const EventsAppBar({
    super.key,
    required this.onSearch,
    required this.onCalendar,
  });

  final VoidCallback onSearch;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return AmoraaMainPageHeader(
      title: 'Events',
      actions: [
        AmoraaMainPageHeaderAction(
          key: const ValueKey('events-search-button'),
          tooltip: 'Search events',
          semanticLabel: 'Search events',
          icon: Icons.search_rounded,
          onPressed: onSearch,
        ),
        AmoraaMainPageHeaderAction(
          key: const ValueKey('events-my-events-button'),
          tooltip: 'My Events',
          semanticLabel: 'Open My Events',
          icon: Icons.calendar_month_rounded,
          onPressed: onCalendar,
        ),
      ],
    );
  }
}

class EventsMemberBadge extends StatelessWidget {
  const EventsMemberBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Curated by AMORAA',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: AppColors.primary,
            ),
            if (!compact) ...[
              const SizedBox(width: 5),
              const Flexible(
                child: Text(
                  'Curated by AMORAA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EventsContextBar extends StatelessWidget {
  const EventsContextBar({
    super.key,
    required this.eventCount,
    required this.city,
    required this.joinedCount,
  });

  final int eventCount;
  final String city;
  final int joinedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final contextText =
              '$eventCount curated ${eventCount == 1 ? 'experience' : 'experiences'} in $city';
          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const _ContextPill(
                icon: Icons.date_range_rounded,
                label: 'This week',
              ),
              _ContextPill(
                icon: Icons.event_available_rounded,
                label: '$joinedCount joined',
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ContextLocation(text: contextText),
                    const SizedBox(height: 12),
                    chips,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _ContextLocation(text: contextText)),
                    const SizedBox(width: 12),
                    chips,
                  ],
                );
        },
      ),
    );
  }
}

class EventsSummary extends EventsContextBar {
  const EventsSummary({
    super.key,
    required super.eventCount,
    required super.city,
    required super.joinedCount,
  });
}

class _ContextLocation extends StatelessWidget {
  const _ContextLocation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.place_rounded, color: AppColors.secondary),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .72)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.secondary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EventCategoryBar extends StatelessWidget {
  const EventCategoryBar({
    super.key,
    required this.categories,
    required this.selectedValues,
    required this.onChanged,
  });

  final List<String> categories;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return AmoraaHorizontalFilterBar<String>(
      key: const ValueKey('event-category-selector'),
      options: categories,
      selectedValues: selectedValues,
      multiSelect: true,
      labelBuilder: (category) => category,
      optionKeyPrefix: 'event-category',
      showCheckmark: true,
      onChanged: onChanged,
    );
  }
}

class EventImagePanel extends StatelessWidget {
  const EventImagePanel({
    super.key,
    required this.event,
    required this.height,
    this.hero = false,
    this.child,
    this.radius = 26,
    this.borderRadius,
  });

  final EventModel event;
  final double height;
  final bool hero;
  final Widget? child;
  final double radius;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(radius);
    Widget panel = Semantics(
      image: true,
      label: '${event.title} event image',
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: effectiveRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => PremiumImage(
                  imageUrl: event.image.imageUrl,
                  assetPath: event.image.assetPath,
                  fallbackAsset: event.image.assetPath,
                  initials: event.image.label.characters.first,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  aspectMode: AmoraaImageAspectMode.event,
                  fit: BoxFit.cover,
                  borderRadius: effectiveRadius,
                  cacheWidth:
                      (constraints.maxWidth *
                              MediaQuery.devicePixelRatioOf(context))
                          .round(),
                  cacheHeight:
                      (constraints.maxHeight *
                              MediaQuery.devicePixelRatioOf(context))
                          .round(),
                  semanticLabel: '${event.title} event image',
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .38),
                ),
              ),
              ?child,
            ],
          ),
        ),
      ),
    );
    if (hero) {
      panel = Hero(tag: 'event-hero-${event.id}', child: panel);
    }
    return panel;
  }
}

class EventImage extends EventImagePanel {
  const EventImage({
    super.key,
    required super.event,
    required super.height,
    super.hero,
    super.child,
    super.radius,
    super.borderRadius,
  });
}

class EventDetailHero extends StatelessWidget {
  const EventDetailHero({
    super.key,
    required this.event,
    required this.status,
    required this.height,
    required this.onBack,
    required this.onShare,
  });

  final EventModel event;
  final TicketStatus? status;
  final double height;
  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return EventImage(
      event: event,
      height: height,
      hero: true,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _EventHeroButton(
                  tooltip: 'Back',
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack,
                ),
                const Spacer(),
                _EventHeroButton(
                  tooltip: 'Share event',
                  icon: Icons.ios_share_rounded,
                  onPressed: onShare,
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EventStatusBadge(status: status),
                const EventsMemberBadge(compact: true),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              event.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 29,
                height: 1.08,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(event.image.icon, color: AppColors.surface, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    event.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventHeroButton extends StatelessWidget {
  const _EventHeroButton({
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
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface.withValues(alpha: .94),
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.tertiary.withValues(alpha: .68)),
      ),
      icon: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AmoraMotion.selection,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(icon, key: ValueKey(icon)),
      ),
    );
  }
}

class EventDetailSection extends StatelessWidget {
  const EventDetailSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.delay = Duration.zero,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return EventReveal(
      delay: delay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class ExpandableEventDescription extends StatefulWidget {
  const ExpandableEventDescription({super.key, required this.description});

  final String description;

  @override
  State<ExpandableEventDescription> createState() =>
      _ExpandableEventDescriptionState();
}

class _ExpandableEventDescriptionState
    extends State<ExpandableEventDescription> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AmoraMotion.page;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: duration,
          curve: AmoraMotion.curve,
          alignment: Alignment.topCenter,
          child: Text(
            widget.description,
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
          ),
          label: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

class FeaturedEventCard extends StatelessWidget {
  const FeaturedEventCard({
    super.key,
    required this.event,
    required this.attendees,
    required this.status,
    required this.onOpen,
    required this.onJoin,
  });

  final EventModel event;
  final List<EventAttendee> attendees;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return EventReveal(
      child: Semantics(
        container: true,
        label:
            'Featured member event, ${event.title}, ${event.date} at ${event.time}',
        child: Material(
          color: AppColors.surface,
          elevation: 3,
          shadowColor: AppColors.primary.withValues(alpha: .16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: AppColors.tertiary.withValues(alpha: .58)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => EventImagePanel(
                    event: event,
                    height: (constraints.maxWidth * 9 / 16).clamp(230, 520),
                    radius: 30,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              const EventsMemberBadge(compact: true),
                              EventDateBadge(date: event.date),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            event.category,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 26,
                              height: 1.08,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EventMetadataRow(
                        icon: Icons.calendar_month_rounded,
                        text: '${event.date} · ${event.time}',
                      ),
                      const SizedBox(height: 8),
                      EventMetadataRow(
                        icon: Icons.place_rounded,
                        text: '${event.venue}, ${event.city}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${event.intent}. ${event.interests.join(', ')}.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          PremiumAvatar(
                            imageUrl: event.host.photoAsset,
                            fallbackAsset: event.host.photoAsset,
                            initials: event.host.name.characters.first,
                            radius: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Hosted by ${event.host.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EventAttendeePreview(attendees: attendees),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final join = EventJoinButton(
                            eventTitle: event.title,
                            status: status,
                            onPressed: onJoin,
                          );
                          final details = AppPrimaryButton(
                            label: 'View Details',
                            icon: Icons.arrow_forward_rounded,
                            variant: AppPrimaryButtonVariant.outlined,
                            onPressed: onOpen,
                          );
                          if (constraints.maxWidth < 300) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                join,
                                const SizedBox(height: 9),
                                details,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: join),
                              const SizedBox(width: 10),
                              Expanded(child: details),
                            ],
                          );
                        },
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

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.status,
    required this.onOpen,
    required this.onJoin,
    this.horizontal = false,
    this.showDistance = false,
  });

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final bool horizontal;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    final content = horizontal
        ? _HorizontalEventCard(
            event: event,
            status: status,
            onOpen: onOpen,
            onJoin: onJoin,
            showDistance: showDistance,
          )
        : _VerticalEventCard(
            event: event,
            status: status,
            onOpen: onOpen,
            onJoin: onJoin,
          );
    return KeyedSubtree(
      key: ValueKey('event-card-${event.id}'),
      child: content,
    );
  }
}

class StandardEventCard extends EventCard {
  const StandardEventCard({
    super.key,
    required super.event,
    required super.status,
    required super.onOpen,
    required super.onJoin,
  }) : super(horizontal: false);
}

class AmoraaRecommendedEventCard extends StatelessWidget {
  const AmoraaRecommendedEventCard({
    super.key,
    required this.event,
    required this.status,
    required this.onOpen,
    required this.onJoin,
  });

  static const double imageHeight = 176;
  static const double dateBadgeWidth = 56;
  static const double dateBadgeHeight = 62;
  static const double contentPadding = AmoraSpacing.space16;
  static const double titleGap = AmoraSpacing.space12;
  static const double baseHeight = 456;

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (status) {
      TicketStatus.upcoming => 'Joined',
      TicketStatus.attended => 'Attended',
      TicketStatus.waitlisted => 'Waitlist',
      TicketStatus.cancelled => 'Cancelled',
      null => 'Open to join',
    };
    return Semantics(
      container: true,
      label:
          '${event.title}. ${event.date}. ${event.time}. ${event.venue}. ${event.category}. $statusLabel.',
      child: KeyedSubtree(
        key: ValueKey('event-card-${event.id}'),
        child: Material(
          color: AppColors.surface,
          elevation: 1.5,
          shadowColor: AppColors.primary.withValues(alpha: .12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(color: AppColors.tertiary.withValues(alpha: .5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EventImagePanel(
                    key: ValueKey('recommended-event-image-${event.id}'),
                    event: event,
                    height: imageHeight,
                    radius: 19,
                    child: Padding(
                      padding: const EdgeInsets.all(AmoraSpacing.space12),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: EventStatusBadge(status: status),
                      ),
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EventDateBadge(
                          key: ValueKey('event-date-${event.id}'),
                          date: event.date,
                          width: dateBadgeWidth,
                          height: dateBadgeHeight,
                        ),
                        const SizedBox(width: titleGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                key: ValueKey('event-title-${event.id}'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: AmoraTextStyles.cardTitle.copyWith(
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _RecommendedEventMetadataRow(
                                key: ValueKey('event-time-${event.id}'),
                                icon: Icons.schedule_rounded,
                                text: event.time,
                              ),
                              const SizedBox(height: 10),
                              _RecommendedEventMetadataRow(
                                key: ValueKey('event-venue-${event.id}'),
                                icon: Icons.place_rounded,
                                text: event.venue,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                event.category,
                                key: ValueKey('event-category-${event.id}'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.left,
                                style: AmoraTextStyles.accentText,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  EventJoinButton(
                    key: ValueKey('recommended-event-action-${event.id}'),
                    eventTitle: event.title,
                    status: status,
                    onPressed: onJoin,
                    compact: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedEventMetadataRow extends StatelessWidget {
  const _RecommendedEventMetadataRow({
    super.key,
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: AmoraSpacing.space8),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.metadata.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class CompactEventCard extends EventCard {
  const CompactEventCard({
    super.key,
    required super.event,
    required super.status,
    required super.onOpen,
    required super.onJoin,
    super.showDistance,
  }) : super(horizontal: true);
}

class AmoraCircleCard extends StatelessWidget {
  const AmoraCircleCard({
    super.key,
    required this.event,
    required this.attendees,
    required this.status,
    required this.onOpen,
    required this.onJoin,
  });

  final EventModel event;
  final List<EventAttendee> attendees;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'AMORAA Circle, ${event.title}',
      child: Material(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: .14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppColors.tertiary.withValues(alpha: .62)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventImagePanel(
                  event: event,
                  height: 142,
                  radius: 18,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: .94),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                event.image.icon,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            EventStatusBadge(status: status),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'AMORAA Circle',
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                EventMetadataRow(
                  icon: Icons.calendar_month_rounded,
                  text: '${event.date} · ${event.time}',
                  compact: true,
                ),
                const SizedBox(height: 5),
                EventMetadataRow(
                  icon: Icons.place_rounded,
                  text: event.venue,
                  compact: true,
                ),
                const SizedBox(height: 7),
                Text(
                  'Hosted by ${event.host.name} · ${event.intent}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: EventAttendeePreview(
                        attendees: attendees.take(3).toList(growable: false),
                        maxVisible: 3,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 116,
                      child: EventJoinButton(
                        eventTitle: event.title,
                        status: status,
                        onPressed: onJoin,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyEventsPreview extends StatelessWidget {
  const MyEventsPreview({
    super.key,
    required this.event,
    required this.status,
    required this.onOpen,
    required this.onViewAll,
  });

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.tertiary.withValues(alpha: .6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: compact ? 92 : 116,
                        child: EventImagePanel(
                          event: event,
                          height: 116,
                          radius: 18,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EventStatusBadge(status: status),
                            const SizedBox(height: 8),
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 17,
                                height: 1.15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            EventMetadataRow(
                              icon: Icons.calendar_month_rounded,
                              text: '${event.date} · ${event.time}',
                              compact: true,
                            ),
                            const SizedBox(height: 5),
                            EventMetadataRow(
                              icon: Icons.place_rounded,
                              text: event.venue,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'View Details',
                          size: AmoraButtonSize.compact,
                          onPressed: onOpen,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'View All',
                          size: AmoraButtonSize.compact,
                          variant: AppPrimaryButtonVariant.outlined,
                          onPressed: onViewAll,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class JoinedEventCard extends MyEventsPreview {
  const JoinedEventCard({
    super.key,
    required super.event,
    required super.status,
    required super.onOpen,
    required super.onViewAll,
  });
}

class _HorizontalEventCard extends StatelessWidget {
  const _HorizontalEventCard({
    required this.event,
    required this.status,
    required this.onOpen,
    required this.onJoin,
    required this.showDistance,
  });

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.tertiary.withValues(alpha: .5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: EventImagePanel(event: event, height: 126, radius: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _EventCardDetails(
                  event: event,
                  status: status,
                  showDistance: showDistance,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: status == null ? 'Join ${event.title}' : 'View event',
                onPressed: status == null ? onJoin : onOpen,
                icon: Icon(
                  status == null
                      ? Icons.add_circle_rounded
                      : Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalEventCard extends StatelessWidget {
  const _VerticalEventCard({
    required this.event,
    required this.status,
    required this.onOpen,
    required this.onJoin,
  });

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(color: AppColors.tertiary.withValues(alpha: .5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventImagePanel(
                event: event,
                height: 176,
                radius: 19,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: EventStatusBadge(status: status),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _EventCardDetails(event: event, status: status),
              const SizedBox(height: 14),
              EventJoinButton(
                eventTitle: event.title,
                status: status,
                onPressed: onJoin,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCardDetails extends StatelessWidget {
  const _EventCardDetails({
    required this.event,
    required this.status,
    this.showDistance = false,
  });

  final EventModel event;
  final TicketStatus? status;
  final bool showDistance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventDateBadge(
              key: ValueKey('event-date-${event.id}'),
              date: event.date,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                event.title,
                key: ValueKey('event-title-${event.id}'),
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          key: ValueKey('event-metadata-${event.id}'),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EventMetadataRow(
                key: ValueKey('event-time-${event.id}'),
                icon: Icons.schedule_rounded,
                text: event.time,
                compact: true,
              ),
              const SizedBox(height: 6),
              EventMetadataRow(
                key: ValueKey('event-venue-${event.id}'),
                icon: Icons.place_rounded,
                text: event.venue,
                compact: true,
              ),
              if (showDistance && event.hasNumericDistance) ...[
                const SizedBox(height: 6),
                EventMetadataRow(
                  icon: Icons.near_me_rounded,
                  text: event.distance,
                  compact: true,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                event.category,
                key: ValueKey('event-category-${event.id}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventDateBadge extends StatelessWidget {
  const EventDateBadge({
    super.key,
    required this.date,
    this.width = 46,
    this.height,
  });

  final String date;
  final double width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final parts = date.replaceAll(',', '').split(RegExp(r'\s+'));
    final day = parts.length > 1 ? parts[1] : date;
    final month = parts.length > 2 ? parts[2] : '';
    return Semantics(
      label: date,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              month.toUpperCase(),
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              day,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventMetadataRow extends StatelessWidget {
  const EventMetadataRow({
    super.key,
    required this.icon,
    required this.text,
    this.compact = false,
  });

  final IconData icon;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: compact ? 16 : 18, color: AppColors.secondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class EventJoinButton extends StatelessWidget {
  const EventJoinButton({
    super.key,
    required this.eventTitle,
    required this.status,
    required this.onPressed,
    this.compact = false,
  });

  final String eventTitle;
  final TicketStatus? status;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      TicketStatus.upcoming => ('Joined', Icons.check_circle_rounded),
      TicketStatus.attended => ('View memories', Icons.history_rounded),
      TicketStatus.waitlisted => ('View waitlist', Icons.hourglass_top_rounded),
      TicketStatus.cancelled => ('Cancelled', Icons.event_busy_rounded),
      null => ('Join Event', Icons.add_rounded),
    };
    return AnimatedSwitcher(
      duration: AmoraMotion.selection,
      child: AppPrimaryButton(
        key: ValueKey(label),
        label: label,
        icon: icon,
        size: compact ? AmoraButtonSize.compact : AmoraButtonSize.standard,
        variant: status == null
            ? AppPrimaryButtonVariant.primary
            : AppPrimaryButtonVariant.outlined,
        onPressed: status == TicketStatus.cancelled ? null : onPressed,
      ),
    );
  }
}

class EventStatusBadge extends StatelessWidget {
  const EventStatusBadge({super.key, required this.status});

  final TicketStatus? status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TicketStatus.upcoming => 'Joined',
      TicketStatus.attended => 'Attended',
      TicketStatus.waitlisted => 'Waitlist',
      TicketStatus.cancelled => 'Cancelled',
      null => 'Open to join',
    };
    return Semantics(
      label: 'Event status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: status == null
              ? AppColors.primary
              : AppColors.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: status == null ? AppColors.surface : AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class EventHostSection extends StatelessWidget {
  const EventHostSection({super.key, required this.host});

  final EventHost host;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: host.photoAsset,
            fallbackAsset: host.photoAsset,
            initials: host.name.characters.first,
            radius: 27,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hosted by',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  host.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (host.rating > 0) ...[
            Text(
              host.rating.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.star_rounded,
              size: 18,
              color: AppColors.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class EventAttendeePreview extends StatelessWidget {
  const EventAttendeePreview({
    super.key,
    required this.attendees,
    this.maxVisible = 4,
    this.compact = false,
  });

  final List<EventAttendee> attendees;
  final int maxVisible;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visible = attendees.take(maxVisible).toList();
    return Semantics(
      label: '${attendees.length} attendees visible',
      child: Row(
        children: [
          SizedBox(
            width: 34 + (visible.length - 1).clamp(0, maxVisible) * 23,
            height: 38,
            child: Stack(
              children: [
                for (var index = 0; index < visible.length; index++)
                  Positioned(
                    left: index * 23,
                    child: EventReveal(
                      delay: Duration(milliseconds: 25 * index),
                      offset: 4,
                      child: PremiumAvatar(
                        imageUrl: visible[index].photoAsset,
                        fallbackAsset: visible[index].photoAsset,
                        initials: visible[index].name.characters.first,
                        radius: 19,
                        verified: visible[index].verified,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${attendees.length} members attending',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EventInfoTile extends StatelessWidget {
  const EventInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventSafetySection extends StatelessWidget {
  const EventSafetySection({
    super.key,
    required this.onGuidelines,
    required this.onReport,
  });

  final VoidCallback onGuidelines;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.primary),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Safety & community',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Meet thoughtfully, respect boundaries, and use AMORAA existing '
            'safety tools whenever you need support.',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onGuidelines,
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Guidelines'),
              ),
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report event'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EventsSkeleton extends StatelessWidget {
  const EventsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SkeletonBlock(height: 76),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) =>
                _SkeletonBlock(height: 38, width: index == 0 ? 92 : 74),
          ),
        ),
        const SizedBox(height: 22),
        const _SkeletonBlock(height: 390),
        const SizedBox(height: 24),
        const _SkeletonBlock(height: 24, width: 180),
        const SizedBox(height: 14),
        for (var index = 0; index < 3; index++) ...[
          const _SkeletonBlock(height: 180),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class EventDetailSkeleton extends StatelessWidget {
  const EventDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (viewportHeight * .42).clamp(300.0, 450.0);
    return SingleChildScrollView(
      key: const ValueKey('event-detail-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBlock(height: heroHeight),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SkeletonBlock(height: 96),
                const SizedBox(height: 18),
                const _SkeletonBlock(height: 74),
                const SizedBox(height: 28),
                const _SkeletonBlock(height: 24, width: 190),
                const SizedBox(height: 12),
                const _SkeletonBlock(height: 18),
                const SizedBox(height: 9),
                const _SkeletonBlock(height: 18),
                const SizedBox(height: 9),
                const _SkeletonBlock(height: 18, width: 250),
                const SizedBox(height: 28),
                const _SkeletonBlock(height: 130),
                const SizedBox(height: 28),
                const _SkeletonBlock(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .35, end: .8),
      duration: AmoraMotion.skeleton,
      builder: (_, opacity, _) => Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

class EventsEmptyState extends StatelessWidget {
  const EventsEmptyState({
    super.key,
    this.onShowAll,
    this.title = 'No events match your preferences yet',
    this.description =
        'Try another category or check back for new curated experiences.',
    this.actionLabel = 'Show All Events',
  });

  final VoidCallback? onShowAll;
  final String title;
  final String description;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return _EventsStateCard(
      icon: Icons.search_off_rounded,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onShowAll,
    );
  }
}

class EventsErrorState extends StatelessWidget {
  const EventsErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _EventsStateCard(
      icon: Icons.cloud_off_rounded,
      title: 'Couldn’t load Events',
      description: 'Your member gatherings are temporarily unavailable.',
      actionLabel: 'Try Again',
      onAction: onRetry,
    );
  }
}

class _EventsStateCard extends StatelessWidget {
  const _EventsStateCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 38),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 18),
            AppPrimaryButton(
              label: actionLabel,
              onPressed: onAction,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}
