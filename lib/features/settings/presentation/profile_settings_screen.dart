import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/settings/presentation/account_action_screens.dart';
import 'package:amora_ai/features/settings/presentation/managed_profiles_screen.dart';
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
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background.withValues(alpha: .96),
                surfaceTintColor: AppColors.background,
                toolbarHeight: 80,
                leadingWidth: 64,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AmoraSpacing.space12),
                  child: IconButton.filledTonal(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                titleSpacing: AmoraSpacing.space8,
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profile Settings',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Manage your AMORAA account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                      label: 'Account Actions',
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
                        ProfileSettingsHubRow(
                          key: const ValueKey('settings-delete-account'),
                          icon: Icons.person_remove_outlined,
                          title: 'Delete Account',
                          subtitle:
                              'Review permanent account deletion options.',
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
