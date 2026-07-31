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
                          onTap: () => open(KycVerificationScreen.routeName),
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
                          onTap: () => open(KycVerificationScreen.routeName),
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
