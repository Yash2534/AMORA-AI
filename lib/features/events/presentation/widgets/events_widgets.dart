import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_image.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/monetization/data/monetization_data.dart';
import 'package:flutter/material.dart';

bool get hasPremiumEventsAccess => subscriptionPlans.any(
  (plan) => plan.current && plan.features.contains('Premium events'),
);

void showEventSnack(BuildContext context, String message) {
  showAmoraSnackBar(context, message: message);
}

Route<T> premiumEventRoute<T>(Widget screen) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, _, _) => screen,
    transitionDuration: AmoraMotion.page,
    reverseTransitionDuration: AmoraMotion.selection,
    transitionsBuilder: (_, animation, _, child) {
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

class EventsAppBar extends StatelessWidget {
  const EventsAppBar({
    super.key,
    required this.onCalendar,
    required this.onFilter,
  });

  final VoidCallback onCalendar;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Curated for Amora members',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _ToolbarButton(
            tooltip: 'My Events',
            icon: Icons.calendar_month_rounded,
            onPressed: onCalendar,
          ),
          const SizedBox(width: 6),
          _ToolbarButton(
            tooltip: 'Filter events',
            icon: Icons.tune_rounded,
            onPressed: onFilter,
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
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
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.tertiary.withValues(alpha: .55)),
      ),
      icon: Icon(icon),
    );
  }
}

class EventsMemberBadge extends StatelessWidget {
  const EventsMemberBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Amora member exclusive',
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
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: AppColors.primary,
            ),
            SizedBox(width: 5),
            Flexible(
              child: Text(
                'Member Exclusive',
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
        ),
      ),
    );
  }
}

class EventsSummary extends StatelessWidget {
  const EventsSummary({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$eventCount curated ${eventCount == 1 ? 'event' : 'events'} in '
              '$city',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$joinedCount',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'joined',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final active = category == selected;
          return Semantics(
            button: true,
            selected: active,
            label: 'Show $category events',
            child: ChoiceChip(
              selected: active,
              showCheckmark: false,
              avatar: Icon(
                _categoryIcon(category),
                size: 17,
                color: active ? AppColors.surface : AppColors.secondary,
              ),
              label: Text(category),
              onSelected: (_) => onSelected(category),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: active ? AppColors.primary : AppColors.secondary,
              ),
              labelStyle: TextStyle(
                color: active ? AppColors.surface : AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('coffee')) return Icons.coffee_rounded;
  if (value.contains('music') || value.contains('garba')) {
    return Icons.music_note_rounded;
  }
  if (value.contains('travel') || value.contains('outdoor')) {
    return Icons.landscape_rounded;
  }
  if (value.contains('speed')) return Icons.favorite_rounded;
  if (value.contains('week')) return Icons.date_range_rounded;
  if (value.contains('member') || value.contains('premium')) {
    return Icons.auto_awesome_rounded;
  }
  return Icons.explore_rounded;
}

class EventImagePanel extends StatelessWidget {
  const EventImagePanel({
    super.key,
    required this.event,
    required this.height,
    this.hero = false,
    this.child,
    this.radius = 26,
  });

  final EventModel event;
  final double height;
  final bool hero;
  final Widget? child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget panel = SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumImage(
              imageUrl: event.image.imageUrl,
              assetPath: event.image.assetPath,
              fallbackAsset: event.image.assetPath,
              initials: event.image.label.characters.first,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(radius),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: .04),
                    AppColors.primary.withValues(alpha: .82),
                  ],
                ),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
    if (hero) {
      panel = Hero(tag: 'event-hero-${event.id}', child: panel);
    }
    return panel;
  }
}

class FeaturedEventCard extends StatelessWidget {
  const FeaturedEventCard({
    super.key,
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
    return FadeUp(
      child: Semantics(
        container: true,
        label:
            'Featured member event, ${event.title}, ${event.date} at ${event.time}',
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventImagePanel(
                  event: event,
                  height: 252,
                  radius: 30,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EventsMemberBadge(),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: EventJoinButton(
                              eventTitle: event.title,
                              status: status,
                              onPressed: onJoin,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: onOpen,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                side: const BorderSide(
                                  color: AppColors.tertiary,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
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
  });

  final EventModel event;
  final TicketStatus? status;
  final VoidCallback onOpen;
  final VoidCallback onJoin;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final content = horizontal
        ? _HorizontalEventCard(
            event: event,
            status: status,
            onOpen: onOpen,
            onJoin: onJoin,
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

class _HorizontalEventCard extends StatelessWidget {
  const _HorizontalEventCard({
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
      borderRadius: BorderRadius.circular(24),
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
                child: _EventCardDetails(event: event, status: status),
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
      borderRadius: BorderRadius.circular(26),
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
  const _EventCardDetails({required this.event, required this.status});

  final EventModel event;
  final TicketStatus? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventDateBadge(date: event.date),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
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
            ),
          ],
        ),
        const SizedBox(height: 10),
        EventMetadataRow(
          icon: Icons.schedule_rounded,
          text: event.time,
          compact: true,
        ),
        const SizedBox(height: 6),
        EventMetadataRow(
          icon: Icons.place_rounded,
          text: event.venue,
          compact: true,
        ),
        const SizedBox(height: 8),
        Text(
          event.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class EventDateBadge extends StatelessWidget {
  const EventDateBadge({super.key, required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    final parts = date.replaceAll(',', '').split(RegExp(r'\s+'));
    final day = parts.length > 1 ? parts[1] : date;
    final month = parts.length > 2 ? parts[2] : '';
    return Semantics(
      label: date,
      child: Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
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
      TicketStatus.attended => ('View memories', Icons.favorite_rounded),
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
      null => 'Member Exclusive',
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
          Text(
            host.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 18, color: AppColors.secondary),
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
  });

  final List<EventAttendee> attendees;
  final int maxVisible;

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
                    child: PremiumAvatar(
                      imageUrl: visible[index].photoAsset,
                      fallbackAsset: visible[index].photoAsset,
                      initials: visible[index].name.characters.first,
                      radius: 19,
                      verified: visible[index].verified,
                    ),
                  ),
              ],
            ),
          ),
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
              Text(
                'Safety & community',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Meet thoughtfully, respect boundaries, and use Amora’s existing '
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
        const _SkeletonBlock(height: 44, width: 310),
        const SizedBox(height: 18),
        const _SkeletonBlock(height: 320),
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
    required this.onShowAll,
    this.title = 'No events match your preferences yet',
    this.description =
        'Try another category or check back for new member gatherings.',
  });

  final VoidCallback onShowAll;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _EventsStateCard(
      icon: Icons.search_off_rounded,
      title: title,
      description: description,
      actionLabel: 'Show All Events',
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
      title: 'Couldn’t load events',
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
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

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
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: actionLabel,
            onPressed: onAction,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
