import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/domain/my_event_category.dart';
import 'package:amora_ai/features/events/presentation/controllers/event_participation_controller.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/events_browse_screen.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:flutter/material.dart';

class MyEventsScreen extends StatefulWidget {
  const MyEventsScreen({super.key, this.controller});

  static const routeName = '/my-events';

  final EventParticipationController? controller;

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  EventParticipationController get _controller =>
      widget.controller ?? EventParticipationController.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: MyEventCategory.values.length,
      vsync: this,
    );
    _controller.addListener(_handleStateChanged);
    if (widget.controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.loadMyEvents();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 920,
          child: Column(
            children: [
              const _MyEventsHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: _CategoryTabs(
                  controller: _tabController,
                  participation: _controller,
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return Center(
        child: Semantics(
          label: 'Loading your events',
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_controller.hasLoadError) {
      return _MyEventsError(
        onRetry: widget.controller == null
            ? _controller.loadMyEvents
            : _controller.retry,
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        for (final category in MyEventCategory.values)
          _MyEventList(
            category: category,
            entries: _controller.registrationsFor(category),
            onCancel: _confirmCancellation,
            onLeaveWaitlist: _leaveWaitlist,
          ),
      ],
    );
  }

  void _confirmCancellation(UserEventRegistration registration) {
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
              'Cancel this booking?',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${registration.event.title} will move to Cancelled.',
              style: const TextStyle(color: AppColors.text, fontSize: 15),
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Cancel booking',
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(sheetContext);
                if (widget.controller != null) {
                  _controller.cancelEvent(registration.event);
                } else {
                  try {
                    await _controller.cancelRemote(registration.event);
                  } catch (error) {
                    messenger.showSnackBar(SnackBar(content: Text('$error')));
                    return;
                  }
                }
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${registration.event.title} booking cancelled',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Keep booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveWaitlist(UserEventRegistration registration) async {
    if (widget.controller != null) {
      _controller.leaveWaitlist(registration.event.id);
    } else {
      try {
        await _controller.leaveWaitlistRemote(registration.event);
      } catch (error) {
        if (mounted) showEventSnack(context, error.toString());
        return;
      }
    }
    if (mounted) {
      showEventSnack(context, 'You left ${registration.event.title} waitlist');
    }
  }
}

class _MyEventsHeader extends StatelessWidget {
  const _MyEventsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 20, 0),
      child: Row(
        children: [
          AmoraHeaderBackButton(
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: AmoraScreenTitle(
              title: 'My Events',
              subtitle: 'Your plans, bookings, and event history.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.controller, required this.participation});

  final TabController controller;
  final EventParticipationController participation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .68)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: AppColors.surface.withValues(alpha: 0),
        labelColor: AppColors.surface,
        unselectedLabelColor: AppColors.text,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 14),
        tabs: [
          for (final category in MyEventCategory.values)
            Tab(
              key: ValueKey('my-events-tab-${category.name}'),
              height: 48,
              text:
                  '${_categoryLabel(category)} (${participation.countFor(category)})',
            ),
        ],
      ),
    );
  }
}

class _MyEventList extends StatelessWidget {
  const _MyEventList({
    required this.category,
    required this.entries,
    required this.onCancel,
    required this.onLeaveWaitlist,
  });

  final MyEventCategory category;
  final List<UserEventRegistration> entries;
  final ValueChanged<UserEventRegistration> onCancel;
  final ValueChanged<UserEventRegistration> onLeaveWaitlist;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final empty = _emptyCopy(category);
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          EventsEmptyState(
            title: empty.$1,
            description: empty.$2,
            actionLabel: category == MyEventCategory.upcoming
                ? 'Explore events'
                : 'Show All Events',
            onShowAll: category == MyEventCategory.upcoming
                ? () => Navigator.of(
                    context,
                  ).pushNamed(EventsBrowseScreen.routeName)
                : null,
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
            itemCount: entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 450,
            ),
            itemBuilder: (context, index) => _MyEventCard(
              registration: entries[index],
              category: category,
              onCancel: onCancel,
              onLeaveWaitlist: onLeaveWaitlist,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, index) => _MyEventCard(
            registration: entries[index],
            category: category,
            onCancel: onCancel,
            onLeaveWaitlist: onLeaveWaitlist,
          ),
        );
      },
    );
  }
}

class _MyEventCard extends StatelessWidget {
  const _MyEventCard({
    required this.registration,
    required this.category,
    required this.onCancel,
    required this.onLeaveWaitlist,
  });

  final UserEventRegistration registration;
  final MyEventCategory category;
  final ValueChanged<UserEventRegistration> onCancel;
  final ValueChanged<UserEventRegistration> onLeaveWaitlist;

  @override
  Widget build(BuildContext context) {
    final event = registration.event;
    return Semantics(
      container: true,
      label: '${event.title}, ${event.date}, ${_categoryLabel(category)} event',
      child: Container(
        key: ValueKey('my-event-${event.id}-${category.name}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.tertiary.withValues(alpha: .62)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            EventImagePanel(
              event: event,
              height: 142,
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: EventStatusBadge(status: registration.status),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
            EventMetadataRow(
              icon: Icons.calendar_month_rounded,
              text: '${event.date} · ${event.time}',
            ),
            const SizedBox(height: 6),
            EventMetadataRow(
              icon: Icons.place_rounded,
              text: '${event.venue}, ${event.city}',
            ),
            const SizedBox(height: 8),
            Text(
              _statusCopy(category),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CardAction(
                  icon: Icons.arrow_forward_rounded,
                  label: 'Open details',
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(EventDetailScreen.routeName, arguments: event),
                ),
                if (category == MyEventCategory.upcoming)
                  _CardAction(
                    icon: Icons.event_busy_rounded,
                    label: 'Cancel booking',
                    onPressed: () => onCancel(registration),
                  ),
                if (category == MyEventCategory.waitlist)
                  _CardAction(
                    icon: Icons.logout_rounded,
                    label: 'Leave waitlist',
                    onPressed: () => onLeaveWaitlist(registration),
                  ),
                if (category == MyEventCategory.past)
                  _CardAction(
                    icon: Icons.rate_review_rounded,
                    label: 'Share feedback',
                    onPressed: () => Navigator.of(context).pushNamed(
                      PostEventFeedbackScreen.routeName,
                      arguments: registration.event,
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

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _MyEventsError extends StatelessWidget {
  const _MyEventsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              color: AppColors.primary,
              size: 34,
            ),
            const SizedBox(height: 12),
            const Text(
              'We couldn’t load your events',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please try again.',
              style: TextStyle(color: AppColors.text),
            ),
            const SizedBox(height: 14),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _categoryLabel(MyEventCategory category) => switch (category) {
  MyEventCategory.upcoming => 'Upcoming',
  MyEventCategory.past => 'Past',
  MyEventCategory.waitlist => 'Waitlist',
  MyEventCategory.cancelled => 'Cancelled',
};

(String, String) _emptyCopy(MyEventCategory category) => switch (category) {
  MyEventCategory.upcoming => (
    'No upcoming events',
    'Events you book will appear here.',
  ),
  MyEventCategory.past => (
    'No past events',
    'Your completed events will appear here.',
  ),
  MyEventCategory.waitlist => (
    'No waitlisted events',
    'Events you join a waitlist for will appear here.',
  ),
  MyEventCategory.cancelled => (
    'No cancelled events',
    'Cancelled bookings will appear here.',
  ),
};

String _statusCopy(MyEventCategory category) => switch (category) {
  MyEventCategory.upcoming => 'Booking confirmed',
  MyEventCategory.past => 'Event completed',
  MyEventCategory.waitlist => 'You’re on the waitlist',
  MyEventCategory.cancelled => 'Booking cancelled',
};
