import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/auth/presentation/compatibility_onboarding_screen.dart';
import 'package:amora_ai/features/auth/presentation/amora_auth_screen.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/phone_otp_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/ai_coach/presentation/ai_icebreakers_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/commerce/presentation/gift_catalog_screen.dart';
import 'package:amora_ai/features/commerce/presentation/send_gift_screen.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/events/presentation/event_group_chat_screen.dart';
import 'package:amora_ai/features/events/presentation/event_waitlist_screen.dart';
import 'package:amora_ai/features/events/presentation/my_events_screen.dart';
import 'package:amora_ai/features/events/presentation/post_event_feedback_screen.dart';
import 'package:amora_ai/features/insights/presentation/dating_recap_screen.dart';
import 'package:amora_ai/features/landing/presentation/amora_landing_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/messaging/presentation/match_screen.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:amora_ai/features/preferences/presentation/dealbreakers_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/bio_builder_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_setup_screen.dart';
import 'package:amora_ai/features/referral/presentation/referral_leaderboard_screen.dart';
import 'package:amora_ai/features/roadmap/presentation/phase23_premium_screens.dart';
import 'package:amora_ai/features/roadmap/presentation/roadmap_feature_screens.dart';
import 'package:amora_ai/features/match/presentation/why_we_matched_screen.dart';
import 'package:amora_ai/features/monetization/presentation/liked_you_paywall_screen.dart';
import 'package:amora_ai/features/monetization/presentation/profile_boost_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/settings/presentation/settings_screen.dart';
import 'package:amora_ai/features/social_proof/presentation/success_stories_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:amora_ai/features/theme/presentation/dark_mode_settings_screen.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _didPrecacheImages = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheImages) return;
    _didPrecacheImages = true;
    AppImages.precacheCore(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMORA AI',
      debugShowCheckedModeBanner: false,
      theme: AmoraTheme.light(),
      initialRoute: AmoraSession.isLoggedIn.value
          ? MainShell.routeName
          : AmoraAuthScreen.routeName,
      routes: {
        // First-launch workflow.
        AmoraLandingScreen.routeName: (_) => const AmoraLandingScreen(),
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
        AmoraAuthScreen.routeName: (_) => const AmoraAuthScreen(),
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        PhoneOtpScreen.routeName: (_) => const PhoneOtpScreen(),
        AccountVerificationScreen.routeName: (_) =>
            const AccountVerificationScreen(),
        ProfileOnboardingFlow.routeName: (_) => const ProfileOnboardingFlow(),
        ProfileCompletionScreen.routeName: (_) =>
            const ProfileCompletionScreen(),
        ProfilePreviewScreen.routeName: (_) => const ProfilePreviewScreen(),
        ProfileBasicDetailsScreen.routeName: (_) =>
            const ProfileBasicDetailsScreen(),
        CompatibilityOnboardingScreen.routeName: (_) =>
            const CompatibilityOnboardingScreen(),
        ProfileSetupScreen.routeName: (_) => const ProfileSetupScreen(),
        KycVerificationScreen.routeName: (_) => const KycVerificationScreen(),

        // Primary app tabs and product flows.
        MainShell.routeName: (_) => const MainShell(),
        BrowseGridScreen.routeName: (_) => const BrowseGridScreen(),
        AdvancedFiltersScreen.routeName: (_) => const AdvancedFiltersScreen(),
        DiscoverScreen.routeName: (_) => const MainShell(),
        ProfileScreen.routeName: (_) =>
            const MainShell(initialTab: AmoraNavTab.profile),
        ProfileDetailScreen.routeName: (_) => const ProfileDetailScreen(),
        MatchesScreen.routeName: (_) =>
            const MainShell(initialTab: AmoraNavTab.matches),
        MatchScreen.routeName: (_) => const MatchScreen(),
        SendGiftScreen.routeName: (_) => const SendGiftScreen(),
        ChatListScreen.routeName: (_) =>
            const MainShell(initialTab: AmoraNavTab.chats),
        ChatDetailScreen.routeName: (_) => const ChatDetailScreen(),
        NotificationsHubScreen.routeName: (_) => const NotificationsHubScreen(),
        EventsScreen.routeName: (_) =>
            const MainShell(initialTab: AmoraNavTab.events),
        EventDetailScreen.routeName: (_) => const EventDetailScreen(),
        MyEventsScreen.routeName: (_) => const MyEventsScreen(),
        AiIcebreakersScreen.routeName: (_) => const AiIcebreakersScreen(),
        SubscriptionScreen.routeName: (_) => const SubscriptionScreen(),
        PaymentScreen.routeName: (_) => const PaymentScreen(),
        ProfileSettingsScreen.routeName: (_) => const ProfileSettingsScreen(),
        SafetyPrivacyScreen.routeName: (_) => const SafetyPrivacyScreen(),
        FaqSupportScreen.routeName: (_) => const FaqSupportScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        ReportFlowScreen.routeName: (_) => const ReportFlowScreen(),
        PhotoManagerScreen.routeName: (_) => const PhotoManagerScreen(),
        StoriesScreen.routeName: (_) => const StoriesScreen(),
        TwentyQuestionsScreen.routeName: (_) => const TwentyQuestionsScreen(),
        PostEventFeedbackScreen.routeName: (_) =>
            const PostEventFeedbackScreen(),
        EventGroupChatScreen.routeName: (_) => const EventGroupChatScreen(),
        EventWaitlistScreen.routeName: (_) => const EventWaitlistScreen(),
        WhyWeMatchedScreen.routeName: (_) => const WhyWeMatchedScreen(),
        ProfileBoostScreen.routeName: (_) => const ProfileBoostScreen(),
        LikedYouPaywallScreen.routeName: (_) => const LikedYouPaywallScreen(),
        LikedYouPaywallScreen.aliasRouteName: (_) =>
            const LikedYouPaywallScreen(),
        BioBuilderScreen.routeName: (_) => const BioBuilderScreen(),
        DealbreakersScreen.routeName: (_) => const DealbreakersScreen(),
        DatingRecapScreen.routeName: (_) => const DatingRecapScreen(),
        NotificationPreferencesScreen.routeName: (_) =>
            const NotificationPreferencesScreen(),
        SuccessStoriesScreen.routeName: (_) => const SuccessStoriesScreen(),
        DarkModeSettingsScreen.routeName: (_) => const DarkModeSettingsScreen(),
        VideoSpeedDatingRoomScreen.routeName: (_) =>
            const VideoSpeedDatingRoomScreen(),
        PollPromptsScreen.routeName: (_) => const PollPromptsScreen(),
        '/shared-media-gallery': (_) => const ChatDetailScreen(),
        GiftShopCatalogScreen.routeName: (_) => const GiftShopCatalogScreen(),
        ReferralLeaderboardScreen.routeName: (_) =>
            const ReferralLeaderboardScreen(),
        RelationshipEcosystemHubScreen.routeName: (_) =>
            const RelationshipEcosystemHubScreen(),
        AiLearningDashboardScreen.routeName: (_) =>
            const AiLearningDashboardScreen(),
        CameraRollScanScreen.routeName: (_) => const CameraRollScanScreen(),
        AiDeepfakeDetectionScreen.routeName: (_) =>
            const AiDeepfakeDetectionScreen(),
        FirstDateQuestionDeckScreen.routeName: (_) =>
            const FirstDateQuestionDeckScreen(),
        RelationshipPredictionScreen.routeName: (_) =>
            const RelationshipPredictionScreen(),
        VirtualSpeedDatingScreen.routeName: (_) =>
            const VirtualSpeedDatingScreen(),
        GroupMeetupsScreen.routeName: (_) => const GroupMeetupsScreen(),
        EventPlanningDashboardScreen.routeName: (_) =>
            const EventPlanningDashboardScreen(),
        HumanMatchmakerScreen.routeName: (_) => const HumanMatchmakerScreen(),
        TravelModeScreen.routeName: (_) => const TravelModeScreen(),
        AdvancedAiDiscoveryScreen.routeName: (_) =>
            const AdvancedAiDiscoveryScreen(),
        AstrologyMatchingScreen.routeName: (_) =>
            const AstrologyMatchingScreen(),
        FriendshipModeScreen.routeName: (_) => const FriendshipModeScreen(),
        ProfessionalNetworkingScreen.routeName: (_) =>
            const ProfessionalNetworkingScreen(),
        CommunityFiltersScreen.routeName: (_) => const CommunityFiltersScreen(),
        BusinessNetworkingScreen.routeName: (_) =>
            const BusinessNetworkingScreen(),
        AiGroupDatingRoomsScreen.routeName: (_) =>
            const AiGroupDatingRoomsScreen(),
        CommunityEventsScreen.routeName: (_) => const CommunityEventsScreen(),
      },
      onUnknownRoute: (_) {
        return MaterialPageRoute<void>(
          builder: (_) => const BrowseGridScreen(),
          settings: const RouteSettings(name: BrowseGridScreen.routeName),
        );
      },
    );
  }
}
