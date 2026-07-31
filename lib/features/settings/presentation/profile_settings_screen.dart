import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/settings_support_widgets.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  static const routeName = '/profile-settings';

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  var _newMatches = true;
  var _newMessages = true;
  var _eventReminders = true;
  var _promotions = false;
  var _showDistance = true;
  var _showOnline = true;
  var _incognito = false;
  var _hideContacts = false;

  @override
  Widget build(BuildContext context) {
    final profile = LocalProfileRepository.instance.profile;
    final personalInfo = <String, String>{
      'Full Name': profile.name,
      'Email': profile.email,
      'Phone Number': profile.phoneNumber,
      'City': profile.location,
      'Gender': profile.gender,
      'Date of Birth': profile.birthdate,
      'Relationship Intention': profile.datingIntention,
    };
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsHeader(
                    title: 'Profile Settings',
                    subtitle:
                        'Manage your account, preferences, and visibility.',
                    icon: Icons.manage_accounts_rounded,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  const _UserSummaryCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniNavButton(
                          icon: Icons.verified_user_rounded,
                          label: 'Safety',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(SafetyPrivacyScreen.routeName),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniNavButton(
                          icon: Icons.help_outline_rounded,
                          label: 'Support',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(FaqSupportScreen.routeName),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Personal Info',
                    children: [
                      for (final entry in personalInfo.entries)
                        SettingsTile(
                          icon: _iconFor(entry.key),
                          title: entry.key,
                          subtitle: entry.value.isEmpty
                              ? 'Not provided'
                              : entry.value,
                          onTap:
                              entry.key == 'Email' ||
                                  entry.key == 'Phone Number'
                              ? null
                              : _openProfileEditor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Notification Preferences',
                    children: [
                      PrivacyToggleTile(
                        title: 'New Matches',
                        subtitle: 'Notify when someone compatible matches.',
                        value: _newMatches,
                        icon: Icons.favorite_rounded,
                        onChanged: (value) =>
                            setState(() => _newMatches = value),
                      ),
                      PrivacyToggleTile(
                        title: 'New Messages',
                        subtitle: 'Conversation alerts from your matches.',
                        value: _newMessages,
                        icon: Icons.chat_rounded,
                        onChanged: (value) =>
                            setState(() => _newMessages = value),
                      ),
                      PrivacyToggleTile(
                        title: 'Event Reminders',
                        subtitle: 'Reminders for bookings and singles events.',
                        value: _eventReminders,
                        icon: Icons.event_rounded,
                        onChanged: (value) =>
                            setState(() => _eventReminders = value),
                      ),
                      PrivacyToggleTile(
                        title: 'Promotions',
                        subtitle: 'Plan offers, coins, and event discounts.',
                        value: _promotions,
                        icon: Icons.local_offer_rounded,
                        onChanged: (value) =>
                            setState(() => _promotions = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Privacy Controls',
                    children: [
                      PrivacyToggleTile(
                        title: 'Show distance',
                        subtitle: 'Let matches see approximate distance.',
                        value: _showDistance,
                        onChanged: (value) =>
                            setState(() => _showDistance = value),
                      ),
                      PrivacyToggleTile(
                        title: 'Show online status',
                        subtitle: 'Show when you are active now.',
                        value: _showOnline,
                        onChanged: (value) =>
                            setState(() => _showOnline = value),
                      ),
                      PrivacyToggleTile(
                        title: 'Incognito mode',
                        subtitle: 'Only people you like can see you.',
                        value: _incognito,
                        onChanged: (value) =>
                            setState(() => _incognito = value),
                      ),
                      PrivacyToggleTile(
                        title: 'Hide from contacts',
                        subtitle: 'Reduce visibility to imported contacts.',
                        value: _hideContacts,
                        onChanged: (value) =>
                            setState(() => _hideContacts = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SettingsSectionCard(
                    title: 'Account Actions',
                    children: [
                      SettingsTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notification Preferences',
                        subtitle: 'Matches, messages, events, payments.',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(NotificationPreferencesScreen.routeName),
                      ),
                      SettingsTile(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Manage Subscription',
                        subtitle: 'View and upgrade your plan.',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(SubscriptionScreen.routeName),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String key) {
    return switch (key) {
      'Full Name' => Icons.badge_rounded,
      'Email' => Icons.email_rounded,
      'Phone Number' => Icons.phone_rounded,
      'City' => Icons.location_city_rounded,
      'Gender' => Icons.person_rounded,
      'Date of Birth' => Icons.cake_rounded,
      _ => Icons.favorite_rounded,
    };
  }

  Future<void> _openProfileEditor() async {
    await Navigator.of(context).pushNamed(ProfileEditScreen.routeName);
    if (mounted) setState(() {});
  }
}

class _UserSummaryCard extends StatelessWidget {
  const _UserSummaryCard();

  @override
  Widget build(BuildContext context) {
    final repository = LocalProfileRepository.instance;
    return AnimatedBuilder(
      animation: repository,
      builder: (context, _) {
        final profile = repository.profile;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.secondary,
                AppColors.tertiary,
                AppColors.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepWine.withValues(alpha: .18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PremiumAvatar(
                    imageUrl: profile.primaryPhoto,
                    fallbackAsset: profile.primaryPhoto,
                    initials: 'YA',
                    radius: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.surface,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.location,
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  TrustPill(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Gold Member',
                    color: AppColors.premiumGold,
                  ),
                  TrustPill(icon: Icons.verified_rounded, label: 'Verified'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile completion',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${profile.completionPercent}%',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: profile.completionPercent / 100,
                  minHeight: 9,
                  color: AppColors.active,
                  backgroundColor: AppColors.surface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniNavButton extends StatelessWidget {
  const _MiniNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        radius: 24,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
