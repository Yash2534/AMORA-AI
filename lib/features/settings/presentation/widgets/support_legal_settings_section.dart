import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/features/legal/presentation/community_guidelines_screen.dart';
import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/profile_settings_hub_widgets.dart';
import 'package:amora_ai/features/support/data/support_faq_data.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

class SupportLegalSettingsSection extends StatelessWidget {
  const SupportLegalSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    void open(String route) => Navigator.of(context).pushNamed(route);

    return Column(
      children: [
        ProfileSettingsGroup(
          label: 'Support',
          children: [
            ProfileSettingsHubRow(
              key: const ValueKey('settings-email-support'),
              icon: Icons.mail_outline_rounded,
              title: 'Email Support',
              subtitle: SupportContact.email,
              trailingLabel: 'Contact',
              onTap: () => open(FaqSupportScreen.routeName),
            ),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space24),
        ProfileSettingsGroup(
          label: 'Legal',
          children: [
            ProfileSettingsHubRow(
              key: const ValueKey('settings-terms'),
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Review the terms for using AMORAA.',
              onTap: () => open(TermsConditionsScreen.routeName),
            ),
            ProfileSettingsHubRow(
              key: const ValueKey('settings-privacy-policy'),
              icon: Icons.policy_outlined,
              title: 'Privacy Policy',
              subtitle: 'Understand how your information is used.',
              onTap: () => open(PrivacyPolicyScreen.routeName),
            ),
            ProfileSettingsHubRow(
              key: const ValueKey('settings-guidelines'),
              icon: Icons.groups_2_outlined,
              title: 'Community Guidelines',
              subtitle: 'The standards for a respectful community.',
              onTap: () => open(CommunityGuidelinesScreen.routeName),
            ),
            ProfileSettingsHubRow(
              key: const ValueKey('settings-safety-center'),
              icon: Icons.health_and_safety_outlined,
              title: 'Safety Center',
              subtitle: 'Verification, check-ins, and safer dating.',
              onTap: () => open(SafetyPrivacyScreen.routeName),
            ),
          ],
        ),
      ],
    );
  }
}
