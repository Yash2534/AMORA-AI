import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/settings_support_widgets.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

class SafetyPrivacyScreen extends StatelessWidget {
  const SafetyPrivacyScreen({super.key});

  static const routeName = '/safety-privacy';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset +
                  MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              SettingsHeader(
                title: 'Safety & Privacy',
                subtitle: 'Help, account details, and supported controls.',
                icon: Icons.verified_user_rounded,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              PremiumCard(
                padding: const EdgeInsets.all(AmoraSpacing.space16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: colors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need help with a safety concern?',
                            style: AmoraTextStyles.titleMedium.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space4),
                          Text(
                            'Open AMORAA Support for safety guidance and the '
                            'available contact channel.',
                            style: AmoraTextStyles.bodyMedium.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              SettingsSectionCard(
                title: 'Available now',
                children: [
                  SettingsTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Safety help and support',
                    subtitle: 'Read guidance or contact AMORAA Support.',
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(FaqSupportScreen.routeName),
                  ),
                  SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Correct profile details',
                    subtitle:
                        'Update the profile information stored by AMORAA.',
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(ProfileBasicDetailsScreen.routeName),
                  ),
                ],
              ),
              const SizedBox(height: AmoraSpacing.space16),
              Semantics(
                label:
                    'Unavailable account and data actions are hidden until '
                    'secure server support is connected.',
                child: PremiumCard(
                  padding: const EdgeInsets.all(AmoraSpacing.space16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colors.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Text(
                          'Account deletion and personal-data requests are not '
                          'shown here until AMORAA can submit and track them '
                          'through a secure service.',
                          style: AmoraTextStyles.bodySmall.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
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
