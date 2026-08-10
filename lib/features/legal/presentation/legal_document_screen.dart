import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const routeName = '/terms';
  static const legacyRouteName = '/terms-and-conditions';

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Terms & Conditions',
      updated: 'Effective 31 July 2026',
      introduction:
          'These terms explain the rules for using AMORAA and the standards '
          'that help keep every interaction respectful, intentional, and safe.',
      sections: _termsSections,
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const routeName = '/privacy-policy';

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Privacy Policy',
      updated: 'Effective 31 July 2026',
      introduction:
          'This policy describes how AMORAA handles profile, account, '
          'verification, and interaction information when you use the app.',
      sections: _privacySections,
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.updated,
    required this.introduction,
    required this.sections,
  });

  final String title;
  final String updated;
  final String introduction;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
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
                toolbarHeight: AmoraHeaderTokens.singleLineHeight,
                leadingWidth: AmoraSpacing.space56,
                leading: Padding(
                  padding: const EdgeInsets.only(left: AmoraSpacing.space4),
                  child: AmoraHeaderBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                titleSpacing: AmoraHeaderTokens.backTitleGap,
                title: Text(title, maxLines: 1),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space16,
                  AmoraSpacing.space20,
                  AmoraSpacing.space32 +
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
                sliver: SliverList.list(
                  children: [
                    PremiumCard(
                      radius: AmoraRadius.extraLarge,
                      padding: const EdgeInsets.all(AmoraSpacing.space24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                AmoraBrandAssets.icon,
                                width: 40,
                                height: 40,
                                semanticLabel: 'AMORAA',
                              ),
                              const SizedBox(width: AmoraSpacing.space12),
                              Expanded(
                                child: Image.asset(
                                  AmoraBrandAssets.wordmark,
                                  height: 20,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AmoraSpacing.space20),
                          Text(title, style: AmoraTextStyles.headlineLarge),
                          const SizedBox(height: AmoraSpacing.space8),
                          Text(
                            updated,
                            style: AmoraTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space16),
                          Text(
                            introduction,
                            style: AmoraTextStyles.bodyLarge.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space16),
                    for (var index = 0; index < sections.length; index++) ...[
                      _LegalSectionCard(
                        index: index + 1,
                        section: sections[index],
                      ),
                      if (index != sections.length - 1)
                        const SizedBox(height: AmoraSpacing.space12),
                    ],
                    const SizedBox(height: AmoraSpacing.space20),
                    Text(
                      'Questions about these documents can be sent to '
                      'support@amora.ai.',
                      textAlign: TextAlign.center,
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
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

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.index, required this.section});

  final int index;
  final LegalSection section;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.large,
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${section.heading}',
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            section.body,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}

const _termsSections = <LegalSection>[
  LegalSection(
    'Eligibility and account responsibility',
    'You must be at least 18 years old and legally able to enter an agreement. '
        'Keep your account details accurate, protect your sign-in credentials, '
        'and tell us promptly if you believe your account has been misused.',
  ),
  LegalSection(
    'Respectful and authentic participation',
    'Use current, authentic information and photos. Harassment, impersonation, '
        'hate, coercion, scams, unsolicited commercial activity, and content '
        'that exploits or endangers another person are not permitted.',
  ),
  LegalSection(
    'Matches and recommendations',
    'Compatibility scores and AI-assisted recommendations are guidance based '
        'on available profile signals. They do not guarantee attraction, '
        'compatibility, identity, conduct, or relationship outcomes.',
  ),
  LegalSection(
    'Subscriptions and purchases',
    'Paid features, prices, billing periods, renewal terms, and cancellation '
        'options are shown before purchase. Store-provider and applicable '
        'refund rules continue to apply.',
  ),
  LegalSection(
    'Safety and enforcement',
    'You remain responsible for decisions about meeting and communicating. '
        'AMORAA may review reports and restrict or remove access when necessary '
        'to protect members, comply with law, or enforce these terms.',
  ),
  LegalSection(
    'Service availability and changes',
    'Features may evolve, be interrupted, or become unavailable. We aim to '
        'provide a reliable experience but cannot promise uninterrupted access '
        'or that every error will be corrected immediately.',
  ),
  LegalSection(
    'Ending your account',
    'You may stop using the service or request account deletion through the '
        'available account controls. Certain records may be retained where '
        'required for safety, fraud prevention, dispute resolution, or law.',
  ),
];

const _privacySections = <LegalSection>[
  LegalSection(
    'Information you provide',
    'This can include account details, profile answers, photos, preferences, '
        'verification submissions, support requests, and content you choose to '
        'share in conversations or events.',
  ),
  LegalSection(
    'Information created through use',
    'We may process app interactions, device and diagnostic information, '
        'approximate location where enabled, safety reports, purchase status, '
        'and recommendation signals needed to operate the experience.',
  ),
  LegalSection(
    'How information is used',
    'Information is used to provide profiles and messaging, personalize '
        'recommendations, support verification and safety, prevent abuse, '
        'deliver requested communications, maintain the app, and meet legal '
        'obligations.',
  ),
  LegalSection(
    'Sharing and visibility',
    'Profile information is visible according to your settings. Information '
        'may also be processed by vetted service providers or disclosed when '
        'required for safety, legal compliance, or a corporate transaction.',
  ),
  LegalSection(
    'Your choices',
    'You can edit profile information, manage notification and visibility '
        'preferences, block profiles, and use available controls to request '
        'access, correction, export, or deletion of personal information.',
  ),
  LegalSection(
    'Security and retention',
    'We use administrative and technical safeguards appropriate to the '
        'information handled. Data is retained only as long as needed for the '
        'purposes described, including safety, fraud, billing, and legal needs.',
  ),
  LegalSection(
    'Updates and contact',
    'Material policy changes will be communicated through an appropriate '
        'in-app or account channel. Contact support@amora.ai with privacy '
        'questions or requests.',
  ),
];
