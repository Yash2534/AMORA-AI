import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/safety/presentation/report_flow_screen.dart';
import 'package:amora_ai/features/safety/presentation/sos_checkin_screen.dart';
import 'package:amora_ai/features/settings/presentation/widgets/profile_settings_hub_widgets.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

class SafetyPrivacyScreen extends StatelessWidget {
  const SafetyPrivacyScreen({super.key});

  static const routeName = '/safety-center';
  static const legacyRouteName = '/safety-privacy';

  @override
  Widget build(BuildContext context) {
    void open(String route) => Navigator.of(context).pushNamed(route);
    void openPage(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));

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
                title: const Text('Safety Center'),
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
                    PremiumCard(
                      radius: AmoraRadius.extraLarge,
                      padding: const EdgeInsets.all(AmoraSpacing.space20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.tertiary),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AmoraSpacing.space16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date with greater confidence',
                                  style: AmoraTextStyles.titleLarge,
                                ),
                                const SizedBox(height: AmoraSpacing.space4),
                                Text(
                                  'Verification, check-ins, reporting, and '
                                  'guidance are available in one private place.',
                                  style: AmoraTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Verification',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey('safety-verified-profile'),
                          icon: Icons.verified_user_outlined,
                          title: 'Verified Profile',
                          subtitle: 'Review your identity verification status.',
                          onTap: () =>
                              openPage(const VerificationStatusScreen()),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('safety-photo-verification'),
                          icon: Icons.add_a_photo_outlined,
                          title: 'Photo Verification',
                          subtitle: 'Manage clear, current profile photos.',
                          onTap: () => open(PhotoManagerScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('safety-face-verification'),
                          icon: Icons.face_retouching_natural_rounded,
                          title: 'Face Verification',
                          subtitle: 'Use the secure selfie verification flow.',
                          onTap: () => openPage(
                            const SelfieVerificationOverviewScreen(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    ProfileSettingsGroup(
                      label: 'Personal Safety',
                      children: [
                        ProfileSettingsHubRow(
                          key: const ValueKey('safety-emergency-contact'),
                          icon: Icons.emergency_outlined,
                          title: 'Emergency Contact & Check-in',
                          subtitle:
                              'Prepare a timed check-in for an upcoming date.',
                          onTap: () => open(SosCheckinScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('safety-tips'),
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'Safety Tips',
                          subtitle:
                              'Read practical guidance for safer connections.',
                          onTap: () => open(FaqSupportScreen.routeName),
                        ),
                        ProfileSettingsHubRow(
                          key: const ValueKey('safety-report'),
                          icon: Icons.flag_outlined,
                          title: 'Report a Problem',
                          subtitle:
                              'Share a profile, message, or safety concern.',
                          onTap: () => open(ReportFlowScreen.routeName),
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

class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _VerificationOverviewScaffold(
      title: 'Verification Status',
      icon: Icons.verified_user_rounded,
      heading: 'Your verification status',
      description:
          'Review the identity checks available for your profile. AMORAA only marks a profile verified after the existing secure flow is completed.',
      actionLabel: 'Review Verification Steps',
      onAction: () =>
          Navigator.of(context).pushNamed(KycVerificationScreen.routeName),
    );
  }
}

class SelfieVerificationOverviewScreen extends StatelessWidget {
  const SelfieVerificationOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _VerificationOverviewScaffold(
      title: 'Selfie Verification',
      icon: Icons.face_retouching_natural_rounded,
      heading: 'Prepare for your selfie check',
      description:
          'Use even lighting, remove face coverings, and look directly at the camera. The secure identity flow will guide you through the required checks.',
      actionLabel: 'Start Selfie Verification',
      onAction: () =>
          Navigator.of(context).pushNamed(KycVerificationScreen.routeName),
    );
  }
}

class _VerificationOverviewScaffold extends StatelessWidget {
  const _VerificationOverviewScaffold({
    required this.title,
    required this.icon,
    required this.heading,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final String heading;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 640,
          child: Padding(
            padding: const EdgeInsets.all(AmoraSpacing.space20),
            child: PremiumCard(
              radius: AmoraRadius.extraLarge,
              padding: const EdgeInsets.all(AmoraSpacing.space20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space16),
                  Text(heading, style: AmoraTextStyles.sectionTitle),
                  const SizedBox(height: AmoraSpacing.space8),
                  Text(
                    description,
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space20),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
