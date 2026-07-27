import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/auth/presentation/phone_otp_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AmoraAuthScreen extends StatefulWidget {
  const AmoraAuthScreen({super.key});

  static const routeName = '/auth';

  @override
  State<AmoraAuthScreen> createState() => _AmoraAuthScreenState();
}

class _AmoraAuthScreenState extends State<AmoraAuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: AmoraMotion.standard)
      ..forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: 'Meaningful connections begin here.',
      subtitle: 'Create an account or return to your private Amora space.',
      statement: 'Meet with intention.',
      showComposition: false,
      onBack: _goBack,
      footer: const _AuthFooter(),
      child: FadeTransition(
        opacity: _intro,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPrimaryButton(
              key: const ValueKey('auth-create-account'),
              label: 'Create account',
              icon: Icons.favorite_rounded,
              onPressed: () =>
                  Navigator.of(context).pushNamed(SignupScreen.routeName),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            AppPrimaryButton(
              key: const ValueKey('auth-sign-in'),
              label: 'Log in',
              icon: Icons.login_rounded,
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: () =>
                  Navigator.of(context).pushNamed(LoginScreen.routeName),
            ),
            const SizedBox(height: AmoraSpacing.space20),
            const AuthDivider(),
            const SizedBox(height: AmoraSpacing.space16),
            AuthPrimaryButton(
              label: 'Continue with phone',
              icon: Icons.phone_iphone_rounded,
              onPressed: () =>
                  Navigator.of(context).pushNamed(PhoneOtpScreen.routeName),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            AppPrimaryButton(
              label: 'Continue with Google',
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: _completeAuth,
            ),
            if (defaultTargetPlatform == TargetPlatform.iOS) ...[
              const SizedBox(height: AmoraSpacing.space12),
              AppPrimaryButton(
                label: 'Continue with Apple',
                icon: Icons.apple_rounded,
                variant: AppPrimaryButtonVariant.dark,
                onPressed: _completeAuth,
              ),
            ],
            const SizedBox(height: AmoraSpacing.space20),
            const AuthTrustNote(
              text: 'Your profile and conversations stay private.',
              icon: Icons.verified_user_outlined,
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    navigator.canPop()
        ? navigator.pop()
        : navigator.pushReplacementNamed('/landing');
  }

  void _completeAuth() {
    AmoraSession.completeAuthentication(context);
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
            color: AppColors.textNeutral.withValues(alpha: .68),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AmoraSpacing.space4,
          children: [
            for (final label in const ['Privacy', 'Terms', 'Help'])
              AppPrimaryButton(
                label: label,
                variant: AppPrimaryButtonVariant.text,
                size: AmoraButtonSize.compact,
                fullWidth: false,
                onPressed: () =>
                    showAmoraSnackBar(context, message: '$label selected'),
              ),
          ],
        ),
      ],
    );
  }
}
