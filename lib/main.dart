import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_theme.dart';
import 'package:amora_ai/core/theme/amora_theme_controller.dart';
import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/features/auth/presentation/compatibility_onboarding_screen.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:amora_ai/features/ai_coach/presentation/ai_icebreakers_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/chat/presentation/chat_list_screen.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
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
import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
import 'package:amora_ai/features/legal/presentation/community_guidelines_screen.dart';
import 'package:amora_ai/features/matches/presentation/matches_screen.dart';
import 'package:amora_ai/features/messaging/presentation/match_screen.dart';
import 'package:amora_ai/features/notifications/presentation/notifications_hub_screen.dart';
import 'package:amora_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/payment/presentation/payment_screen.dart';
import 'package:amora_ai/features/preferences/presentation/dealbreakers_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/bio_builder_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_setup_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/referral/presentation/referral_leaderboard_screen.dart';
import 'package:amora_ai/features/match/presentation/why_we_matched_screen.dart';
import 'package:amora_ai/features/monetization/presentation/liked_you_paywall_screen.dart';
import 'package:amora_ai/features/monetization/presentation/profile_boost_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/safety/presentation/sos_checkin_screen.dart';
import 'package:amora_ai/features/settings/presentation/account_action_screens.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/settings/presentation/settings_screen.dart';
import 'package:amora_ai/features/social_proof/presentation/success_stories_screen.dart';
import 'package:amora_ai/features/splash/presentation/amora_splash_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:amora_ai/features/theme/presentation/dark_mode_settings_screen.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalProfileRepository.instance.initialize();
  await LocalOnboardingRepository.instance.initialize();
  LocalOnboardingRepository.instance.hydrateFromUserProfile();
  await LocalChatRepository.instance.initialize();
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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AmoraThemeController.instance.mode,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'AMORAA',
        debugShowCheckedModeBanner: false,
        theme: AmoraTheme.light(),
        themeMode: themeMode,
        initialRoute: AmoraSplashScreen.routeName,
        routes: {
          AmoraSplashScreen.routeName: (_) => AmoraSplashScreen(
            resolveInitialRoute: () => AmoraSession.isLoggedIn.value
                ? MainShell.routeName
                : LoginScreen.routeName,
          ),
          OnboardingScreen.routeName: (_) => const OnboardingScreen(),
          LoginScreen.routeName: (_) => const LoginScreen(),
          SignupScreen.routeName: (_) => const SignupScreen(),
          ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
          ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
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
          ChatListScreen.routeName: (_) =>
              const MainShell(initialTab: AmoraNavTab.chats),
          ChatDetailScreen.routeName: (_) => const ChatDetailScreen(),
          NotificationsHubScreen.routeName: (_) =>
              const NotificationsHubScreen(),
          EventsScreen.routeName: (_) =>
              const MainShell(initialTab: AmoraNavTab.events),
          EventDetailScreen.routeName: (_) => const EventDetailScreen(),
          MyEventsScreen.routeName: (_) => const MyEventsScreen(),
          AiIcebreakersScreen.routeName: (_) => const AiIcebreakersScreen(),
          SubscriptionScreen.routeName: (_) => const SubscriptionScreen(),
          SubscriptionScreen.membershipRoute: (_) => const SubscriptionScreen(),
          SubscriptionScreen.manageRoute: (_) => const SubscriptionScreen(),
          PaymentScreen.routeName: (_) => const PaymentScreen(),
          ProfileSettingsScreen.routeName: (_) => const ProfileSettingsScreen(),
          SavedProfilesScreen.routeName: (_) => const SavedProfilesScreen(),
          BlockedProfilesScreen.routeName: (_) => const BlockedProfilesScreen(),
          SafetyPrivacyScreen.routeName: (_) => const SafetyPrivacyScreen(),
          SafetyPrivacyScreen.legacyRouteName: (_) =>
              const SafetyPrivacyScreen(),
          FaqSupportScreen.routeName: (_) => const FaqSupportScreen(),
          FaqSupportScreen.legacyRouteName: (_) => const FaqSupportScreen(),
          SettingsScreen.routeName: (_) => const SettingsScreen(),
          ReportFlowScreen.routeName: (_) => const ReportFlowScreen(),
          SosCheckinScreen.routeName: (_) => const SosCheckinScreen(),
          PhotoManagerScreen.routeName: (_) => const PhotoManagerScreen(),
          ProfileEditScreen.routeName: (_) => const ProfileEditScreen(),
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
          DarkModeSettingsScreen.routeName: (_) =>
              const DarkModeSettingsScreen(),
          ReferralLeaderboardScreen.routeName: (_) =>
              const ReferralLeaderboardScreen(),
          TermsConditionsScreen.routeName: (_) => const TermsConditionsScreen(),
          TermsConditionsScreen.legacyRouteName: (_) =>
              const TermsConditionsScreen(),
          PrivacyPolicyScreen.routeName: (_) => const PrivacyPolicyScreen(),
          CommunityGuidelinesScreen.routeName: (_) =>
              const CommunityGuidelinesScreen(),
          LogoutAccountScreen.routeName: (_) => const LogoutAccountScreen(),
          DeleteAccountInformationScreen.routeName: (_) =>
              const DeleteAccountInformationScreen(),
        },
        onUnknownRoute: (_) {
          return MaterialPageRoute<void>(
            builder: (_) => const BrowseGridScreen(),
            settings: const RouteSettings(name: BrowseGridScreen.routeName),
          );
        },
      ),
    );
  }
}
