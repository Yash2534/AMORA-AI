import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/phone_otp_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/settings/presentation/safety_privacy_screen.dart';
import 'package:amora_ai/features/support/presentation/faq_support_screen.dart';
import 'package:flutter/material.dart';

class AmoraAuthScreen extends StatefulWidget {
  const AmoraAuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AmoraAuthScreen> createState() => _AmoraAuthScreenState();
}

class _AmoraAuthScreenState extends State<AmoraAuthScreen> {
  bool _googleLoading = false;

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: 'Meaningful connections start here.',
      subtitle: 'Sign in or create your Amora account to continue.',
      onBack: _goBack,
      footer: const _AuthFooter(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmoraGoogleButton(
            key: const ValueKey('auth-google'),
            isLoading: _googleLoading,
            onPressed: _googleLoading ? null : _continueWithGoogle,
          ),
          const SizedBox(height: AmoraSpacing.space12),
          AuthPrimaryButton(
            key: const ValueKey('auth-phone'),
            label: 'Continue with phone',
            icon: Icons.phone_iphone_rounded,
            style: AuthButtonStyle.soft,
            onPressed: () =>
                Navigator.of(context).pushNamed(PhoneOtpScreen.routeName),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          const AuthDivider(),
          const SizedBox(height: AmoraSpacing.space20),
          AuthPrimaryButton(
            key: const ValueKey('auth-email'),
            label: 'Continue with email',
            icon: Icons.mail_outline_rounded,
            onPressed: () =>
                Navigator.of(context).pushNamed(LoginScreen.routeName),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('New to Amora?', style: AmoraTextStyles.bodyMedium),
              AppPrimaryButton(
                key: const ValueKey('auth-create-account'),
                label: 'Create account',
                variant: AppPrimaryButtonVariant.text,
                size: AmoraButtonSize.compact,
                fullWidth: false,
                onPressed: () =>
                    Navigator.of(context).pushNamed(SignupScreen.routeName),
              ),
            ],
          ),
          const SizedBox(height: AmoraSpacing.space12),
          const AuthTrustNote(
            text:
                'Your account details are kept private and never shown on your profile.',
            icon: Icons.verified_user_outlined,
          ),
        ],
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    navigator.canPop()
        ? navigator.pop()
        : navigator.pushReplacementNamed('/landing');
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      // Preserve the project’s existing authentication/session callback.
      await AmoraSession.completeAuthentication(context);
    } catch (_) {
      if (mounted) setState(() => _googleLoading = false);
    }
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'By continuing, you agree to Amora’s Terms and Privacy Policy.',
          textAlign: TextAlign.center,
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.text.withValues(alpha: .68),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AmoraSpacing.space4,
          children: [
            AppPrimaryButton(
              label: 'Terms',
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(SafetyPrivacyScreen.routeName),
            ),
            AppPrimaryButton(
              label: 'Privacy',
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(SafetyPrivacyScreen.routeName),
            ),
            AppPrimaryButton(
              label: 'Help',
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: () =>
                  Navigator.of(context).pushNamed(FaqSupportScreen.routeName),
            ),
          ],
        ),
      ],
    );
  }
}
