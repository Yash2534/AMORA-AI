import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/events/data/events_dummy_data.dart';
import 'package:amora_ai/features/events/domain/event_models.dart';
import 'package:amora_ai/features/events/presentation/event_group_chat_screen.dart';
import 'package:amora_ai/features/events/presentation/event_waitlist_screen.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/events/presentation/ticket_booking_screen.dart';
import 'package:amora_ai/features/events/presentation/widgets/events_widgets.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, this.event});

  static const routeName = '/event-detail';

  final EventModel? event;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final selectedEvent = event ?? (args is EventModel ? args : events.first);
    var saved = false;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: StatefulBuilder(
                      builder: (context, setLocalState) => Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AmoraSpacing.space20,
                          AmoraSpacing.space20,
                          AmoraSpacing.space20,
                          AmoraSpacing.navigationContentInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                EventImagePanel(
                                  event: selectedEvent,
                                  hero: true,
                                  height: 330,
                                  child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton.filledTonal(
                                              tooltip: 'Back',
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).maybePop(),
                                              icon: const Icon(AmoraIcons.back),
                                            ),
                                            const Spacer(),
                                            IconButton.filledTonal(
                                              tooltip: 'Save event',
                                              onPressed: () {
                                                AmoraSession.requireAuth(
                                                  context: context,
                                                  onAuthenticated: () {
                                                    setLocalState(
                                                      () => saved = !saved,
                                                    );
                                                    showEventSnack(
                                                      context,
                                                      saved
                                                          ? 'Event saved'
                                                          : 'Event removed from saved',
                                                    );
                                                  },
                                                );
                                              },
                                              icon: Icon(
                                                saved
                                                    ? AmoraIcons.heartFill
                                                    : AmoraIcons.heart,
                                              ),
                                            ),
                                            IconButton.filledTonal(
                                              tooltip: 'Share event',
                                              onPressed: () => showEventSnack(
                                                context,
                                                'Share link prepared',
                                              ),
                                              icon: const Icon(
                                                AmoraIcons.share,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        Text(
                                          selectedEvent.category,
                                          style: const TextStyle(
                                            color: AppColors.surface,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          selectedEvent.title,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AmoraTextStyles.displaySmall
                                              .copyWith(
                                                color: AppColors.surface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            HostCard(host: selectedEvent.host),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ActionChip(
                                  avatar: const Icon(Icons.rate_review_rounded),
                                  label: const Text('Feedback'),
                                  onPressed: () => AmoraSession.requireAuth(
                                    context: context,
                                    onAuthenticated: () =>
                                        Navigator.of(context).pushNamed(
                                          PostEventFeedbackScreen.routeName,
                                        ),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.hourglass_top_rounded,
                                  ),
                                  label: const Text('Waitlist'),
                                  onPressed: () => AmoraSession.requireAuth(
                                    context: context,
                                    onAuthenticated: () => Navigator.of(
                                      context,
                                    ).pushNamed(EventWaitlistScreen.routeName),
                                  ),
                                ),
                                ActionChip(
                                  avatar: const Icon(Icons.groups_rounded),
                                  label: const Text('Group Chat'),
                                  onPressed: () => AmoraSession.requireAuth(
                                    context: context,
                                    onAuthenticated: () => Navigator.of(
                                      context,
                                    ).pushNamed(EventGroupChatScreen.routeName),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const SectionTitle(title: 'Event Information'),
                            const SizedBox(height: 12),
                            EventInfoTile(
                              icon: Icons.calendar_month_rounded,
                              label: 'Date',
                              value: selectedEvent.date,
                            ),
                            const SizedBox(height: 10),
                            EventInfoTile(
                              icon: Icons.schedule_rounded,
                              label: 'Time',
                              value: selectedEvent.time,
                            ),
                            const SizedBox(height: 10),
                            EventInfoTile(
                              icon: Icons.place_rounded,
                              label: 'Venue',
                              value: selectedEvent.venue,
                            ),
                            const SizedBox(height: 10),
                            _VenueMapPreview(event: selectedEvent),
                            const SizedBox(height: 10),
                            EventInfoTile(
                              icon: Icons.route_rounded,
                              label: 'Distance',
                              value: selectedEvent.distance,
                            ),
                            const SizedBox(height: 10),
                            EventInfoTile(
                              icon: Icons.checkroom_rounded,
                              label: 'Dress Code',
                              value: selectedEvent.dressCode,
                            ),
                            const SizedBox(height: 10),
                            EventInfoTile(
                              icon: Icons.groups_rounded,
                              label: 'Age Range',
                              value: selectedEvent.ageRange,
                            ),
                            const SizedBox(height: 10),
                            EventInfoTile(
                              icon: Icons.translate_rounded,
                              label: 'Language',
                              value: selectedEvent.language,
                            ),
                            const SizedBox(height: 22),
                            _CompatibilityCard(event: selectedEvent),
                            const SizedBox(height: 22),
                            const SectionTitle(
                              title: 'Attendees Preview',
                              subtitle: 'Verified people with clear intentions',
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: eventAttendees.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) => AttendeeAvatar(
                                  attendee: eventAttendees[index],
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            const SectionTitle(title: 'Agenda Timeline'),
                            const SizedBox(height: 14),
                            AgendaTimeline(items: eventAgenda),
                            const SizedBox(height: 8),
                            const SectionTitle(title: 'Facilities'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final item in eventFacilities)
                                  Chip(
                                    avatar: Icon(
                                      item.$1,
                                      size: 17,
                                      color: AppColors.primaryPurple,
                                    ),
                                    label: Text(item.$2),
                                    backgroundColor: AppColors.surface,
                                    side: const BorderSide(
                                      color: AppColors.borderGray,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const SectionTitle(title: 'Reviews'),
                            const SizedBox(height: 12),
                            for (final review in eventReviews)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReviewCard(review: review),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 16,
                child: PremiumEventButton(
                  label: 'Book Ticket',
                  icon: Icons.confirmation_number_rounded,
                  onPressed: () => AmoraSession.requireAuth(
                    context: context,
                    onAuthenticated: () => Navigator.of(context).push(
                      premiumEventRoute(
                        TicketBookingScreen(event: selectedEvent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueMapPreview extends StatelessWidget {
  const _VenueMapPreview({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            event.palette.first.withValues(alpha: .16),
            event.palette.last.withValues(alpha: .22),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surface),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 20,
            top: 18,
            child: Icon(
              Icons.map_rounded,
              color: AppColors.primaryPurple.withValues(alpha: .18),
              size: 82,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Venue Preview',
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.venue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 124,
                  child: PremiumEventButton(
                    label: 'Directions',
                    compact: true,
                    outlined: true,
                    icon: Icons.near_me_rounded,
                    onPressed: () => showEventSnack(
                      context,
                      'Route preview saved for this venue',
                    ),
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

class _CompatibilityCard extends StatelessWidget {
  const _CompatibilityCard({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: event.palette),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'AI says\nYou have\n${event.compatibility}%\ncompatibility with attendees.',
              style: const TextStyle(
                color: AppColors.surface,
                height: 1.18,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: AppColors.deepWine,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.deepWine),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.surface,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final EventReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.name,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Icon(Icons.star_rounded, color: AppColors.premiumGold),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              color: AppColors.textGray,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
