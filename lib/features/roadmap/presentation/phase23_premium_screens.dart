import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/section_header.dart';
import 'package:flutter/material.dart';

class RelationshipEcosystemHubScreen extends StatelessWidget {
  const RelationshipEcosystemHubScreen({super.key});

  static const routeName = '/relationship-ecosystem';

  @override
  Widget build(BuildContext context) {
    return _PremiumScaffold(
      title: 'Relationship Ecosystem',
      subtitle: 'Phase 2 and Phase 3 AI modules for deeper connection.',
      icon: Icons.favorite_rounded,
      children: [
        const _SearchAndFilters(
          hint: 'Search AI modules',
          filters: ['AI', 'Events', 'Travel', 'Trust', 'Premium'],
        ),
        const SizedBox(height: 16),
        const _StateStrip(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hubModules.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth < 390 ? .92 : 1.08,
              ),
              itemBuilder: (context, index) {
                final module = _hubModules[index];
                return _ModuleTile(module: module);
              },
            );
          },
        ),
      ],
    );
  }
}

class AiLearningDashboardScreen extends StatelessWidget {
  const AiLearningDashboardScreen({super.key});

  static const routeName = '/ai-learning-dashboard';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'AI Learning Mode',
        subtitle:
            'Recommendation intelligence shaped by likes, chats, visits, interests, and events.',
        icon: Icons.psychology_alt_rounded,
        heroMetric: '92%',
        heroLabel: 'Learning confidence',
        filters: ['Likes', 'Swipes', 'Chats', 'Events'],
        metrics: [
          _Metric(
            'Recommendation Quality',
            '88%',
            .88,
            Icons.recommend_rounded,
          ),
          _Metric('Profile Visit Signal', '74%', .74, Icons.visibility_rounded),
          _Metric('Shared Interest Fit', '81%', .81, Icons.interests_rounded),
        ],
        insights: [
          'Recently learned: live music, thoughtful food dates, slow travel.',
          'You respond better to profiles with complete prompts and clear intent.',
          'Event participation is improving local recommendations.',
        ],
        timeline: [
          'Today - weighted meaningful replies higher than fast replies',
          'Yesterday - reduced low-intent nightlife recommendations',
          'This week - detected stronger fit with travel lovers',
        ],
      ),
    );
  }
}

class CameraRollScanScreen extends StatelessWidget {
  const CameraRollScanScreen({super.key});

  static const routeName = '/camera-roll-scan';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Camera Roll Scan',
        subtitle:
            'Premium Photo Studio ranking your best, most natural, highest-quality photos.',
        icon: Icons.photo_camera_back_rounded,
        heroMetric: '94',
        heroLabel: 'Best photo score',
        filters: ['Best First', 'Smile', 'Natural', 'Professional'],
        metrics: [
          _Metric('Best First Photo', '94', .94, Icons.looks_one_rounded),
          _Metric('Best Smile', '91', .91, Icons.sentiment_satisfied_rounded),
          _Metric('Highest Quality', '89', .89, Icons.high_quality_rounded),
          _Metric('Most Natural', '86', .86, Icons.eco_rounded),
        ],
        insights: [
          'Use the outdoor portrait as your first photo.',
          'Replace one low-light selfie with a clearer social photo.',
          'Add one full-frame photo to improve trust and context.',
        ],
        timeline: [
          'Rank 1 - outdoor portrait, warm smile, strong clarity',
          'Rank 2 - coffee candid, natural expression',
          'Rank 3 - event photo, good social proof',
        ],
      ),
    );
  }
}

class AiDeepfakeDetectionScreen extends StatelessWidget {
  const AiDeepfakeDetectionScreen({super.key});

  static const routeName = '/ai-deepfake-detection';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'AI Verification Dashboard',
        subtitle:
            'Authenticity, AI image detection, face matching, and verification timeline.',
        icon: Icons.verified_user_rounded,
        heroMetric: '97%',
        heroLabel: 'Authenticity score',
        filters: ['Images', 'Face Match', 'Alerts', 'Timeline'],
        metrics: [
          _Metric(
            'AI Image Detection',
            'Low Risk',
            .93,
            Icons.image_search_rounded,
          ),
          _Metric('Face Matching', '96%', .96, Icons.face_rounded),
          _Metric('Trust Badge', 'Active', 1, Icons.workspace_premium_rounded),
        ],
        insights: [
          'No suspicious image patterns detected across profile photos.',
          'Face match confidence is high between gallery and verification selfie.',
          'Trust badge is ready for profile display.',
        ],
        timeline: [
          'Photo verification completed',
          'Face matching completed',
          'Authenticity review passed',
        ],
      ),
    );
  }
}

class FirstDateQuestionDeckScreen extends StatefulWidget {
  const FirstDateQuestionDeckScreen({super.key});

  static const routeName = '/first-date-question-deck';

  @override
  State<FirstDateQuestionDeckScreen> createState() =>
      _FirstDateQuestionDeckScreenState();
}

class _FirstDateQuestionDeckScreenState
    extends State<FirstDateQuestionDeckScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final card = _questionCards[_index % _questionCards.length];
    return _PremiumScaffold(
      title: 'First-Date Question Deck',
      subtitle: 'AI-generated conversation cards for natural chemistry.',
      icon: Icons.style_rounded,
      children: [
        const _SearchAndFilters(
          hint: 'Search categories',
          filters: ['Travel', 'Food', 'Dreams', 'Music', 'Relationship'],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 210),
          child: PremiumCard(
            key: ValueKey(card.category),
            radius: 30,
            padding: const EdgeInsets.all(20),
            color: AppColors.lightPinkBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TinyLabel(icon: card.icon, label: card.category),
                const SizedBox(height: 18),
                Text(
                  card.question,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 26,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                _InsightBlock(title: 'AI reason', body: card.reason),
                const SizedBox(height: 12),
                _InsightBlock(title: 'Conversation tip', body: card.tip),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Save',
                        icon: Icons.bookmark_border_rounded,
                        onPressed: () => _snack(context, 'Question saved'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Shuffle',
                        icon: Icons.shuffle_rounded,
                        variant: AppPrimaryButtonVariant.outlined,
                        onPressed: () => setState(() => _index++),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppPrimaryButton(
                  label: 'Copy',
                  icon: Icons.copy_rounded,
                  variant: AppPrimaryButtonVariant.dark,
                  onPressed: () => _snack(context, 'Question copied'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _StateStrip(),
      ],
    );
  }
}

class RelationshipPredictionScreen extends StatelessWidget {
  const RelationshipPredictionScreen({super.key});

  static const routeName = '/relationship-prediction';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Relationship Prediction',
        subtitle:
            'Health, compatibility timeline, response patterns, and future potential.',
        icon: Icons.timeline_rounded,
        heroMetric: '86%',
        heroLabel: 'Future potential',
        filters: ['Weekly', 'Monthly', 'Advice', 'Timeline'],
        metrics: [
          _Metric('Relationship Health', '82%', .82, Icons.favorite_rounded),
          _Metric('Communication Score', '88%', .88, Icons.forum_rounded),
          _Metric('Longevity Signal', '79%', .79, Icons.trending_up_rounded),
        ],
        insights: [
          'Your response rhythm is consistent and emotionally warm.',
          'Shared long-term goals are stronger than average for this match.',
          'Weekly insight: ask one values-based question before planning.',
        ],
        timeline: [
          'Week 1 - strong curiosity and question balance',
          'Week 2 - improved response depth',
          'Monthly report - high future potential with steady pacing',
        ],
      ),
    );
  }
}

class VirtualSpeedDatingScreen extends StatelessWidget {
  const VirtualSpeedDatingScreen({super.key});

  static const routeName = '/virtual-speed-dating';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Virtual Speed Dating',
        subtitle:
            'Live rooms, waiting area, 3-minute timer, AI moderation, and feedback.',
        icon: Icons.video_camera_front_rounded,
        heroMetric: '03:00',
        heroLabel: 'Room timer',
        filters: ['Upcoming', 'Live', 'Joined', 'Premium'],
        metrics: [
          _Metric('Live Rooms', '4', .66, Icons.sensors_rounded),
          _Metric('Upcoming Rooms', '12', .72, Icons.schedule_rounded),
          _Metric('AI Moderation', 'Active', 1, Icons.shield_rounded),
        ],
        insights: [
          'Tonight: Intentional Dating Ahmedabad room has 18 participants.',
          'Premium members can join the priority waiting area.',
          'Room summaries and post-date feedback unlock after each session.',
        ],
        timeline: [
          '7:30 PM - Coffee chat room',
          '8:00 PM - Founder dating room',
          '8:30 PM - Music lovers room',
        ],
      ),
    );
  }
}

class GroupMeetupsScreen extends StatelessWidget {
  const GroupMeetupsScreen({super.key});

  static const routeName = '/group-meetups';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Group Meetups',
        subtitle:
            'Coffee, movies, hiking, music, food walks, sports, games, and book clubs.',
        icon: Icons.groups_rounded,
        heroMetric: '24',
        heroLabel: 'Nearby meetups',
        filters: ['Coffee', 'Movies', 'Food', 'Sports'],
        metrics: [
          _Metric('Coffee Meetups', '8', .72, Icons.local_cafe_rounded),
          _Metric('Movie Nights', '5', .58, Icons.movie_rounded),
          _Metric('Weekend Trips', '3', .42, Icons.luggage_rounded),
        ],
        insights: [
          'AI suggests a food walk with 6 verified members within 4 km.',
          'Average group budget: Rs 700-1500.',
          'Hosts with high trust scores are prioritized.',
        ],
        timeline: [
          'Tonight - Game night hosted by Riya',
          'Saturday - Food walk with 12 participants',
          'Sunday - Book club and coffee',
        ],
      ),
    );
  }
}

class EventPlanningDashboardScreen extends StatelessWidget {
  const EventPlanningDashboardScreen({super.key});

  static const routeName = '/event-planning-dashboard';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Event Planning',
        subtitle:
            'Upcoming, interested, joined, host event, AI suggestions, reminders, map, and chat.',
        icon: Icons.event_available_rounded,
        heroMetric: '9',
        heroLabel: 'AI suggested events',
        filters: ['Upcoming', 'Joined', 'Nearby', 'Calendar'],
        metrics: [
          _Metric('Joined', '3', .45, Icons.check_circle_rounded),
          _Metric('Interested', '11', .66, Icons.star_border_rounded),
          _Metric('Reminder Health', 'On', 1, Icons.notifications_rounded),
        ],
        insights: [
          'AI recommends one small-format event before larger festivals.',
          'Map view prioritizes venues with safe arrival and parking signals.',
          'Event chat is available for joined experiences.',
        ],
        timeline: [
          'Tomorrow - rooftop coffee mixer',
          'Friday - music social',
          'Sunday - heritage food walk',
        ],
      ),
    );
  }
}

class HumanMatchmakerScreen extends StatelessWidget {
  const HumanMatchmakerScreen({super.key});

  static const routeName = '/human-matchmaker';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Human Matchmaker',
        subtitle:
            'Luxury concierge for consultations, expert reviews, coaching, and booking.',
        icon: Icons.support_agent_rounded,
        heroMetric: 'Gold',
        heroLabel: 'Concierge access',
        filters: ['Experts', 'Video', 'Booking', 'Payment'],
        metrics: [
          _Metric('Available Experts', '6', .75, Icons.badge_rounded),
          _Metric('Profile Review', 'Ready', 1, Icons.rate_review_rounded),
          _Metric(
            'Booking Timeline',
            '2 days',
            .62,
            Icons.calendar_month_rounded,
          ),
        ],
        insights: [
          'Recommended expert: relationship coach focused on intentional dating.',
          'Payment summary is prepared for a 45-minute video consultation.',
          'Profile review includes photo order, prompts, and match strategy.',
        ],
        timeline: [
          'Select expert',
          'Book consultation',
          'Receive concierge match plan',
        ],
      ),
    );
  }
}

class TravelModeScreen extends StatelessWidget {
  const TravelModeScreen({super.key});

  static const routeName = '/travel-mode';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Travel Mode',
        subtitle:
            'Passport-style discovery for cities, countries, trips, vacation mode, and companions.',
        icon: Icons.flight_takeoff_rounded,
        heroMetric: '18',
        heroLabel: 'Trending cities',
        filters: ['Cities', 'Trips', 'Matches', 'Vacation'],
        metrics: [
          _Metric('Travel Matches', '42', .78, Icons.public_rounded),
          _Metric('Upcoming Trips', '4', .44, Icons.luggage_rounded),
          _Metric('Companion Fit', '83%', .83, Icons.explore_rounded),
        ],
        insights: [
          'Mumbai, Dubai, Singapore, and London are trending for AMORAA members.',
          'Vacation Mode keeps local discovery intentional while you travel.',
          'Travel companion suggestions emphasize safety and shared itinerary style.',
        ],
        timeline: [
          'Ahmedabad - current city',
          'Mumbai - upcoming trip',
          'Dubai - saved destination',
        ],
      ),
    );
  }
}

class AdvancedAiDiscoveryScreen extends StatelessWidget {
  const AdvancedAiDiscoveryScreen({super.key});

  static const routeName = '/advanced-ai-discovery';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Advanced AI Discovery',
        subtitle:
            'Most compatible, AI picks, verified, nearby, new members, interests, and events.',
        icon: Icons.travel_explore_rounded,
        heroMetric: '128',
        heroLabel: 'AI recommended',
        filters: ['Compatible', 'Verified', 'Nearby', 'Interests'],
        metrics: [
          _Metric('Most Compatible', '24', .86, Icons.favorite_rounded),
          _Metric('AI Picks', '18', .74, Icons.auto_awesome_rounded),
          _Metric('Verified Nearby', '39', .81, Icons.verified_rounded),
        ],
        insights: [
          'Professionals and travel lovers are over-indexing in your best matches.',
          'New members with strong profile completion are prioritized.',
          'Event-based recommendations refresh after each RSVP.',
        ],
        timeline: [
          'Food lovers updated',
          'Fitness matches refreshed',
          'Music and events pool expanded',
        ],
      ),
    );
  }
}

class AstrologyMatchingScreen extends StatelessWidget {
  const AstrologyMatchingScreen({super.key});

  static const routeName = '/astrology-matching';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Astrology Matching',
        subtitle:
            'Optional Kundli, Guna Milan, planet compatibility, and AI combined score.',
        icon: Icons.nights_stay_rounded,
        heroMetric: '31/36',
        heroLabel: 'Guna Milan',
        filters: ['Kundli', 'Planets', 'Marriage', 'AI Score'],
        metrics: [
          _Metric('Planet Compatibility', '84%', .84, Icons.public_rounded),
          _Metric('Marriage Score', '82%', .82, Icons.favorite_rounded),
          _Metric('AI + Astrology', '88%', .88, Icons.auto_awesome_rounded),
        ],
        insights: [
          'Astrology matching is optional and never required for discovery.',
          'AI score balances values, behavior, and relationship goals.',
          'Use this as one signal, not a final decision.',
        ],
        timeline: [
          'Birth details optional',
          'Compatibility generated privately',
          'Combined score added to match report',
        ],
      ),
    );
  }
}

class FriendshipModeScreen extends StatelessWidget {
  const FriendshipModeScreen({super.key});

  static const routeName = '/friendship-mode';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Friendship Mode',
        subtitle:
            'Separate no-dating discovery for friends, events, groups, and interests.',
        icon: Icons.diversity_1_rounded,
        heroMetric: 'No dating',
        heroLabel: 'Mode active',
        filters: ['Friends', 'Groups', 'Events', 'Interests'],
        metrics: [
          _Metric('Interest Match', '89%', .89, Icons.interests_rounded),
          _Metric('Nearby Groups', '16', .68, Icons.groups_rounded),
          _Metric('Friend Events', '7', .52, Icons.event_rounded),
        ],
        insights: [
          'Dating affordances are hidden in Friendship Mode.',
          'Discovery emphasizes shared hobbies, groups, and social comfort.',
          'Mode switching is explicit and reversible.',
        ],
        timeline: [
          'Choose friendship onboarding',
          'Pick interests',
          'Join groups and local events',
        ],
      ),
    );
  }
}

class ProfessionalNetworkingScreen extends StatelessWidget {
  const ProfessionalNetworkingScreen({super.key});

  static const routeName = '/professional-networking';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Professional Networking',
        subtitle:
            'Premium business mode for founders, technology, mentorship, and networking events.',
        icon: Icons.business_center_rounded,
        heroMetric: '56',
        heroLabel: 'Relevant contacts',
        filters: ['Industry', 'Startup', 'Founder', 'Mentorship'],
        metrics: [
          _Metric('Startup Connect', '21', .78, Icons.rocket_launch_rounded),
          _Metric('Mentorship Fit', '76%', .76, Icons.school_rounded),
          _Metric('Business Events', '9', .62, Icons.event_seat_rounded),
        ],
        insights: [
          'Professional mode separates networking from romantic discovery.',
          'Industry filters help route founders and technology profiles.',
          'Networking feed can highlight events and collaboration intent.',
        ],
        timeline: [
          'Complete professional profile',
          'Select industries',
          'Join curated networking rooms',
        ],
      ),
    );
  }
}

class CommunityFiltersScreen extends StatelessWidget {
  const CommunityFiltersScreen({super.key});

  static const routeName = '/community-filters';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Community Filters',
        subtitle:
            'Optional religion, community, mother tongue, culture, and marriage preferences.',
        icon: Icons.tune_rounded,
        heroMetric: 'Optional',
        heroLabel: 'Privacy-first fields',
        filters: ['Religion', 'Culture', 'Language', 'Marriage'],
        metrics: [
          _Metric('Optional Fields', '100%', 1, Icons.lock_outline_rounded),
          _Metric(
            'Visibility Control',
            'Ready',
            1,
            Icons.visibility_off_rounded,
          ),
          _Metric(
            'Preference Match',
            '72%',
            .72,
            Icons.favorite_border_rounded,
          ),
        ],
        insights: [
          'Community details are never mandatory.',
          'Users control whether these fields influence recommendations.',
          'Filters should support intent without narrowing identity unfairly.',
        ],
        timeline: [
          'Add optional preference',
          'Choose visibility',
          'Adjust recommendation weight',
        ],
      ),
    );
  }
}

class BusinessNetworkingScreen extends StatelessWidget {
  const BusinessNetworkingScreen({super.key});

  static const routeName = '/business-networking';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Business Networking',
        subtitle:
            'Professional profile, company, designation, skills, collaboration, and startup connect.',
        icon: Icons.handshake_rounded,
        heroMetric: '12',
        heroLabel: 'Collaboration fits',
        filters: ['Company', 'Skills', 'Events', 'Startup'],
        metrics: [
          _Metric('Skill Match', '87%', .87, Icons.psychology_rounded),
          _Metric('Business Events', '8', .58, Icons.event_rounded),
          _Metric('Founder Signals', 'Strong', .82, Icons.trending_up_rounded),
        ],
        insights: [
          'Business profile can live beside personal profile without mixing intents.',
          'Skills and collaboration goals power professional matching.',
          'Startup Connect prioritizes verified founders and operators.',
        ],
        timeline: [
          'Add company and designation',
          'Select collaboration goals',
          'Join business events',
        ],
      ),
    );
  }
}

class AiGroupDatingRoomsScreen extends StatelessWidget {
  const AiGroupDatingRoomsScreen({super.key});

  static const routeName = '/ai-group-dating-rooms';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'AI Group Dating Rooms',
        subtitle:
            'Multiple participants, AI moderation, ice breakers, games, suggestions, and analytics.',
        icon: Icons.video_call_rounded,
        heroMetric: 'Live',
        heroLabel: 'Room analytics',
        filters: ['Rooms', 'Games', 'Ice Breakers', 'Analytics'],
        metrics: [
          _Metric('Participants', '8', .72, Icons.groups_rounded),
          _Metric('AI Moderation', 'Active', 1, Icons.shield_rounded),
          _Metric('Match Suggestions', '5', .64, Icons.favorite_rounded),
        ],
        insights: [
          'AI keeps prompts inclusive and detects uncomfortable tone.',
          'Games create low-pressure interaction before direct matching.',
          'Room analytics summarize energy, participation, and suggested matches.',
        ],
        timeline: [
          'Waiting room opens',
          'Ice breaker round',
          'Match suggestions generated',
        ],
      ),
    );
  }
}

class CommunityEventsScreen extends StatelessWidget {
  const CommunityEventsScreen({super.key});

  static const routeName = '/community-events';

  @override
  Widget build(BuildContext context) {
    return const _ModuleDashboardScreen(
      spec: _ModuleSpec(
        title: 'Community Events',
        subtitle:
            'Local festivals, social activities, networking, music, food, sports, volunteer, and travel.',
        icon: Icons.celebration_rounded,
        heroMetric: '34',
        heroLabel: 'Local events',
        filters: ['Festivals', 'Music', 'Food', 'Volunteer'],
        metrics: [
          _Metric('Festivals', '6', .48, Icons.festival_rounded),
          _Metric('Volunteer', '4', .38, Icons.volunteer_activism_rounded),
          _Metric('Travel Socials', '7', .55, Icons.luggage_rounded),
        ],
        insights: [
          'Community events broaden AMORAA beyond swipe-based dating.',
          'Local culture, food, and volunteer events support safer first meetings.',
          'AI suggestions adapt by city, interests, and attendance history.',
        ],
        timeline: [
          'Friday - music social',
          'Saturday - volunteer brunch',
          'Sunday - community food walk',
        ],
      ),
    );
  }
}

class _ModuleDashboardScreen extends StatelessWidget {
  const _ModuleDashboardScreen({required this.spec});

  final _ModuleSpec spec;

  @override
  Widget build(BuildContext context) {
    return _PremiumScaffold(
      title: spec.title,
      subtitle: spec.subtitle,
      icon: spec.icon,
      children: [
        _SearchAndFilters(hint: 'Search ${spec.title}', filters: spec.filters),
        const SizedBox(height: 16),
        _HeroScoreCard(spec: spec),
        const SizedBox(height: 16),
        const _StateStrip(),
        const SizedBox(height: 16),
        _MetricGrid(metrics: spec.metrics),
        const SizedBox(height: 16),
        _InsightList(items: spec.insights),
        const SizedBox(height: 16),
        _TimelineList(items: spec.timeline),
        const SizedBox(height: 16),
        AppPrimaryButton(
          label: 'Open Controls',
          icon: Icons.tune_rounded,
          onPressed: () => _showControls(context, spec),
        ),
      ],
    );
  }
}

class _PremiumScaffold extends StatelessWidget {
  const _PremiumScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                  sliver: SliverList.list(
                    children: [
                      _PremiumHeader(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                      ),
                      const SizedBox(height: 18),
                      ...children,
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

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(height: 16),
        PremiumCard(
          radius: 30,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.deepWine,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, color: AppColors.surface, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.deepWine,
                        fontSize: 26,
                        height: 1.06,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        height: 1.34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.hint, required this.filters});

  final String hint;
  final List<String> filters;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 26,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return FilterChip(
                  selected: index == 0,
                  label: Text(filters[index]),
                  onSelected: (_) {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroScoreCard extends StatelessWidget {
  const _HeroScoreCard({required this.spec});

  final _ModuleSpec spec;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 30,
      color: AppColors.deepWine,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 94,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: .86,
                  strokeWidth: 8,
                  color: AppColors.premiumGold,
                  backgroundColor: AppColors.surface.withValues(alpha: .18),
                ),
                Text(
                  spec.heroMetric,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.heroLabel,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Updated from recent behavior, profile quality, trust signals, and intent patterns.',
                  style: TextStyle(
                    color: AppColors.background,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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

class _StateStrip extends StatelessWidget {
  const _StateStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StateCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading',
            label: 'Skeleton ready',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StateCard(
            icon: Icons.error_outline_rounded,
            title: 'Error',
            label: 'Retry state',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StateCard(
            icon: Icons.inbox_rounded,
            title: 'Empty',
            label: 'Guided copy',
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(12),
      radius: 22,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.5 : 1.35,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      radius: 24,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.lavenderBackground,
            child: Icon(metric.icon, color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.deepWine,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                LinearProgressIndicator(
                  value: metric.progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(99),
                  color: AppColors.primaryRose,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            metric.value,
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightList extends StatelessWidget {
  const _InsightList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'AI Insights',
            subtitle: 'Actionable guidance generated from product signals.',
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightBlock(title: 'Recommendation', body: item),
            ),
        ],
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Timeline',
            subtitle: 'Recent progress and upcoming actions.',
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.deepWine,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      items[i],
                      style: const TextStyle(
                        color: AppColors.textDark,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
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

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.premiumGold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
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

class _TinyLabel extends StatelessWidget {
  const _TinyLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.deepWine,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module});

  final _HubModule module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(module.route),
      borderRadius: BorderRadius.circular(24),
      child: PremiumCard(
        radius: 24,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lavenderBackground,
              child: Icon(module.icon, color: AppColors.primaryPurple),
            ),
            const Spacer(),
            Text(
              module.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.deepWine,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.phase,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showControls(BuildContext context, _ModuleSpec spec) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: PremiumCard(
          radius: 30,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${spec.title} Controls',
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Production-ready bottom sheet shell for filters, privacy, reminders, and module settings.',
                style: TextStyle(
                  color: AppColors.textGray,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Personalized AI recommendations'),
              ),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Premium notifications'),
              ),
              const SizedBox(height: 10),
              AppPrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class _ModuleSpec {
  const _ModuleSpec({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.heroMetric,
    required this.heroLabel,
    required this.filters,
    required this.metrics,
    required this.insights,
    required this.timeline,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String heroMetric;
  final String heroLabel;
  final List<String> filters;
  final List<_Metric> metrics;
  final List<String> insights;
  final List<String> timeline;
}

class _Metric {
  const _Metric(this.label, this.value, this.progress, this.icon);

  final String label;
  final String value;
  final double progress;
  final IconData icon;
}

class _QuestionCard {
  const _QuestionCard({
    required this.category,
    required this.question,
    required this.reason,
    required this.tip,
    required this.icon,
  });

  final String category;
  final String question;
  final String reason;
  final String tip;
  final IconData icon;
}

class _HubModule {
  const _HubModule(this.title, this.phase, this.route, this.icon);

  final String title;
  final String phase;
  final String route;
  final IconData icon;
}

const _questionCards = [
  _QuestionCard(
    category: 'Travel',
    question: 'What is one place that changed the way you see life?',
    reason:
        'Travel stories reveal values, independence, curiosity, and emotional memory.',
    tip:
        'Share your own answer after they respond, then ask what made it meaningful.',
    icon: Icons.flight_takeoff_rounded,
  ),
  _QuestionCard(
    category: 'Food',
    question: 'What meal instantly feels like home to you?',
    reason: 'Food is a warm path into family, culture, comfort, and nostalgia.',
    tip: 'Keep it sensory and light. This can naturally lead into a date idea.',
    icon: Icons.restaurant_rounded,
  ),
  _QuestionCard(
    category: 'Dreams',
    question: 'What version of your life are you quietly building toward?',
    reason:
        'Aspirational questions reveal direction without sounding like an interview.',
    tip: 'Listen for energy and ask what support looks like for them.',
    icon: Icons.auto_awesome_rounded,
  ),
  _QuestionCard(
    category: 'Relationship',
    question: 'What makes you feel emotionally safe with someone?',
    reason:
        'This opens a mature conversation about attachment, trust, and communication.',
    tip: 'Answer gently and avoid turning it into a checklist.',
    icon: Icons.favorite_border_rounded,
  ),
  _QuestionCard(
    category: 'Music',
    question: 'What song would be playing during your happiest memory?',
    reason:
        'Music creates vivid emotional recall and easy follow-up questions.',
    tip: 'Ask for the story behind the song, not just the title.',
    icon: Icons.music_note_rounded,
  ),
];

const _hubModules = [
  _HubModule(
    'AI Learning Mode',
    'Phase 2',
    AiLearningDashboardScreen.routeName,
    Icons.psychology_alt_rounded,
  ),
  _HubModule(
    'Camera Roll Scan',
    'Phase 2',
    CameraRollScanScreen.routeName,
    Icons.photo_camera_back_rounded,
  ),
  _HubModule(
    'Deepfake Detection',
    'Phase 2',
    AiDeepfakeDetectionScreen.routeName,
    Icons.verified_user_rounded,
  ),
  _HubModule(
    'Question Deck',
    'Phase 2',
    FirstDateQuestionDeckScreen.routeName,
    Icons.style_rounded,
  ),
  _HubModule(
    'Relationship Prediction',
    'Phase 2',
    RelationshipPredictionScreen.routeName,
    Icons.timeline_rounded,
  ),
  _HubModule(
    'Virtual Speed Dating',
    'Phase 2',
    VirtualSpeedDatingScreen.routeName,
    Icons.video_camera_front_rounded,
  ),
  _HubModule(
    'Group Meetups',
    'Phase 2',
    GroupMeetupsScreen.routeName,
    Icons.groups_rounded,
  ),
  _HubModule(
    'Event Planning',
    'Phase 2',
    EventPlanningDashboardScreen.routeName,
    Icons.event_available_rounded,
  ),
  _HubModule(
    'Human Matchmaker',
    'Phase 2',
    HumanMatchmakerScreen.routeName,
    Icons.support_agent_rounded,
  ),
  _HubModule(
    'Travel Mode',
    'Phase 2',
    TravelModeScreen.routeName,
    Icons.flight_takeoff_rounded,
  ),
  _HubModule(
    'Advanced Discovery',
    'Phase 2',
    AdvancedAiDiscoveryScreen.routeName,
    Icons.travel_explore_rounded,
  ),
  _HubModule(
    'Astrology Matching',
    'Phase 3',
    AstrologyMatchingScreen.routeName,
    Icons.nights_stay_rounded,
  ),
  _HubModule(
    'Friendship Mode',
    'Phase 3',
    FriendshipModeScreen.routeName,
    Icons.diversity_1_rounded,
  ),
  _HubModule(
    'Professional Networking',
    'Phase 3',
    ProfessionalNetworkingScreen.routeName,
    Icons.business_center_rounded,
  ),
  _HubModule(
    'Community Filters',
    'Phase 3',
    CommunityFiltersScreen.routeName,
    Icons.tune_rounded,
  ),
  _HubModule(
    'Business Networking',
    'Phase 3',
    BusinessNetworkingScreen.routeName,
    Icons.handshake_rounded,
  ),
  _HubModule(
    'AI Group Rooms',
    'Phase 3',
    AiGroupDatingRoomsScreen.routeName,
    Icons.video_call_rounded,
  ),
  _HubModule(
    'Community Events',
    'Phase 3',
    CommunityEventsScreen.routeName,
    Icons.celebration_rounded,
  ),
];
