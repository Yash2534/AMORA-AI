import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/settings/presentation/account_action_screens.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
import 'package:amora_ai/features/settings/presentation/likes_super_likes_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/profile_settings_hub_widgets.dart';
import 'package:amora_ai/features/settings/presentation/widgets/support_legal_settings_section.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  static const routeName = '/profile-settings';

  @override
  Widget build(BuildContext context) {
    void open(String route) => Navigator.of(context).pushNamed(route);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 760,
          child: CustomScrollView(
            slivers: [
              AmoraSliverAppBar(
                title: 'Profile Settings',
                subtitle: 'Manage your AMORAA account',
                onBack: () => Navigator.of(context).maybePop(),
                maxContentWidth: 760,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space16,
                  AmoraSpacing.space20,
                  AmoraSpacing.space40 +
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    Text(
                      'Everything important, thoughtfully organized.',
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Account',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-personal-information'),
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Information',
                          subtitle: 'Update your identity and profile details.',
                          onTap: () =>
                              open(ProfileBasicDetailsScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-likes-super-likes'),
                          icon: Icons.favorite_rounded,
                          title: 'Likes & Super Likes',
                          subtitle: 'Review people you liked or Super Liked.',
                          onTap: () => open(LikesSuperLikesScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-saved-profiles'),
                          icon: Icons.bookmark_outline_rounded,
                          title: 'Saved Profiles',
                          subtitle: 'Return to people you saved.',
                          onTap: () => open(SavedProfilesScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-blocked-profiles'),
                          icon: Icons.block_rounded,
                          title: 'Blocked Profiles',
                          subtitle: 'Review profiles you chose not to see.',
                          onTap: () => open(BlockedProfilesScreen.routeName),
                        ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Membership',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-membership'),
                          icon: Icons.workspace_premium_outlined,
                          title: 'Membership',
                          subtitle: 'Explore AMORAA Premium benefits.',
                          onTap: () => open(SubscriptionScreen.membershipRoute),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-manage-subscription'),
                          icon: Icons.credit_card_rounded,
                          title: 'Manage Subscription',
                          subtitle: 'Review your current plan and billing.',
                          onTap: () => open(SubscriptionScreen.manageRoute),
                        ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Notifications',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey(
                            'settings-notification-preferences',
                          ),
                          icon: Icons.notifications_none_rounded,
                          title: 'Notification Preferences',
                          subtitle: 'Choose which AMORAA updates reach you.',
                          onTap: () =>
                              open(NotificationPreferencesScreen.routeName),
                        ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    const SupportLegalSettingsSection(),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Security & Session',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-change-password'),
                          icon: Icons.password_rounded,
                          title: 'Change Password',
                          subtitle: 'Securely reset your password by email.',
                          onTap: () => open(ForgotPasswordScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-logout'),
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          subtitle: 'Sign out safely on this device.',
                          onTap: () => open(LogoutAccountScreen.routeName),
                        ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Account Actions',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-deactivate-account'),
                          icon: Icons.pause_circle_outline_rounded,
                          title: 'Deactivate Account',
                          subtitle:
                              'Temporarily hide your profile and pause your account. You can return later by signing in again.',
                          onTap: () => open(DeactivateAccountScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-delete-account'),
                          icon: Icons.delete_forever_rounded,
                          title: 'Delete Account',
                          subtitle:
                              'Permanently delete your AMORAA account and associated data.',
                          danger: true,
                          onTap: () =>
                              open(DeleteAccountInformationScreen.routeName),
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
    );
  }
}
