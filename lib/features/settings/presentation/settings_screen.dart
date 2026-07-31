import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/floating_bottom_nav.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/core/widgets/section_header.dart';
import 'package:amora_ai/features/events/presentation/events_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/settings_support_widgets.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/settings/presentation/profile_settings_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:amora_ai/features/theme/presentation/dark_mode_settings_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [AppColors.background, AppColors.surface],
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 380 ? 18.0 : 24.0;
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        22,
                        padding,
                        FloatingBottomNav.contentBottomPadding,
                      ),
                      child: Column(
                        children: [
                          const SectionHeader(
                            title: 'Settings',
                            subtitle: 'Manage premium, safety, and events.',
                          ),
                          const SizedBox(height: 18),
                          for (final group in _settingsGroups) ...[
                            _SettingsGroupCard(group: group),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: const FloatingBottomNav(
                          activeTab: AmoraNavTab.profile,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.group});

  final _SettingsGroup group;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.deepWine,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            group.subtitle,
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space12),
          for (final item in group.items) _SettingsTile(item: item),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final _SettingsItem item;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: item.icon,
      title: item.title,
      subtitle: item.subtitle,
      onTap: () => Navigator.of(context).pushNamed(item.route),
    );
  }
}

class _SettingsGroup {
  const _SettingsGroup(this.title, this.subtitle, this.items);

  final String title;
  final String subtitle;
  final List<_SettingsItem> items;
}

class _SettingsItem {
  const _SettingsItem(this.title, this.subtitle, this.route, this.icon);

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
}

const _settingsGroups = [
  _SettingsGroup('Account', 'Identity and profile controls.', [
    _SettingsItem(
      'Profile Settings',
      'Account details and visibility',
      ProfileSettingsScreen.routeName,
      Icons.manage_accounts_rounded,
    ),
  ]),
  _SettingsGroup('Safety', 'Privacy and verification controls.', [
    _SettingsItem(
      'Safety & Privacy',
      'Verification and privacy controls',
      SafetyPrivacyScreen.routeName,
      Icons.verified_user_rounded,
    ),
  ]),
  _SettingsGroup('Experience', 'Notifications and events.', [
    _SettingsItem(
      'Appearance',
      'Light, dark, or system theme',
      DarkModeSettingsScreen.routeName,
      Icons.dark_mode_rounded,
    ),
    _SettingsItem(
      'Notification Preferences',
      'Matches, messages, and events',
      NotificationPreferencesScreen.routeName,
      Icons.notifications_active_rounded,
    ),
    _SettingsItem(
      'Events',
      'Curated social experiences',
      EventsScreen.routeName,
      Icons.celebration_rounded,
    ),
  ]),
  _SettingsGroup('Support', 'Help and account guidance.', [
    _SettingsItem(
      'FAQ & Support',
      'Help center and email support',
      FaqSupportScreen.routeName,
      Icons.help_outline_rounded,
    ),
  ]),
];
