import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

class LogoutAccountScreen extends StatelessWidget {
  const LogoutAccountScreen({super.key});

  static const routeName = '/logout';

  @override
  Widget build(BuildContext context) {
    return _AccountActionScaffold(
      title: 'Logout',
      icon: Icons.logout_rounded,
      heading: 'Sign out of this device?',
      description:
          'Your AMORAA profile and preferences remain saved. You can sign '
          'back in whenever you are ready.',
      action: AppPrimaryButton(
        key: const ValueKey('confirm-profile-settings-logout'),
        label: 'Logout securely',
        icon: Icons.logout_rounded,
        onPressed: () {
          AmoraSession.logOut();
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
        },
      ),
    );
  }
}

class DeleteAccountInformationScreen extends StatelessWidget {
  const DeleteAccountInformationScreen({super.key});

  static const routeName = '/delete-account';

  @override
  Widget build(BuildContext context) {
    return _AccountActionScaffold(
      title: 'Delete Account',
      icon: Icons.person_remove_outlined,
      heading: 'Permanent account deletion',
      description:
          'Account deletion requires a secure server-confirmed request. That '
          'endpoint is not connected to this frontend, so AMORAA will never '
          'simulate deletion or erase only part of your account.',
      supporting: const [
        'Your profile, conversations, purchases, and safety records may be affected.',
        'Billing managed by an app store must be cancelled through that store.',
        'Support can explain the currently available account options.',
      ],
      action: AppPrimaryButton(
        label: 'Contact AMORAA Support',
        icon: Icons.support_agent_rounded,
        onPressed: () =>
            Navigator.of(context).pushNamed(FaqSupportScreen.routeName),
      ),
    );
  }
}

class _AccountActionScaffold extends StatelessWidget {
  const _AccountActionScaffold({
    required this.title,
    required this.icon,
    required this.heading,
    required this.description,
    required this.action,
    this.supporting = const [],
  });

  final String title;
  final IconData icon;
  final String heading;
  final String description;
  final List<String> supporting;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.all(AmoraSpacing.space20),
            children: [
              PremiumCard(
                radius: AmoraRadius.extraLarge,
                padding: const EdgeInsets.all(AmoraSpacing.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.tertiary),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 30),
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space20),
                    Text(heading, style: AmoraTextStyles.headlineSmall),
                    const SizedBox(height: AmoraSpacing.space8),
                    Text(
                      description,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    if (supporting.isNotEmpty) ...[
                      const SizedBox(height: AmoraSpacing.space16),
                      for (final item in supporting)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AmoraSpacing.space12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppColors.secondary,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: AmoraSpacing.space8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AmoraTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: AmoraSpacing.space20),
                    action,
                    const SizedBox(height: AmoraSpacing.space8),
                    AppPrimaryButton(
                      label: 'Go back',
                      variant: AppPrimaryButtonVariant.text,
                      onPressed: () => Navigator.of(context).maybePop(),
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
