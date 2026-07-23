<<<<<<< HEAD
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
=======
import 'package:amora_ai/core/access/amora_access.dart';
>>>>>>> main
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
<<<<<<< HEAD
=======
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/foundation.dart';
>>>>>>> main
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
<<<<<<< HEAD
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final padding = constraints.maxWidth < 390
                    ? AmoraSpacing.space16
                    : AmoraSpacing.space24;
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AmoraSpacing.space20,
                    padding,
                    AmoraSpacing.space24 +
                        MediaQuery.viewPaddingOf(context).bottom +
                        MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AmoraSpacing.space40,
                    ),
                    child: FadeTransition(
                      opacity: _intro,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthHeader(),
                          const SizedBox(height: AmoraSpacing.space32),
                          const _AuthHero(),
                          const SizedBox(height: AmoraSpacing.space24),
                          PremiumCard(
                            radius: AmoraRadius.extraLarge,
                            padding: AmoraSpacing.card,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppPrimaryButton(
                                  key: const Key('auth-sign-in'),
                                  label: 'Sign in',
                                  icon: Icons.login_rounded,
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(LoginScreen.routeName),
                                ),
                                const SizedBox(height: AmoraSpacing.space12),
                                AppPrimaryButton(
                                  key: const Key('auth-create-account'),
                                  label: 'Create account',
                                  icon: Icons.person_add_alt_1_rounded,
                                  variant: AppPrimaryButtonVariant.outlined,
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(SignupScreen.routeName),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space20),
                          const _FooterLinks(),
                        ],
                      ),
                    ),
                  ),
                );
              },
=======
    return AmoraAuthShell(
      title: 'Welcome to AMORA AI',
      subtitle: 'Choose the quickest way to begin your private Amora journey.',
      statement: 'Meet with intention.',
      onBack: _goBack,
      footer: const _AuthFooter(),
      child: FadeTransition(
        opacity: _intro,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Continue securely',
              style: AmoraTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
>>>>>>> main
            ),
            const SizedBox(height: AmoraSpacing.space12),
            AuthPrimaryButton(
              label: 'Continue with phone',
              icon: Icons.phone_iphone_rounded,
              onPressed: () =>
                  Navigator.of(context).pushNamed(PhoneOtpScreen.routeName),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            AppPrimaryButton(
              label: 'Continue with email',
              icon: Icons.mail_outline_rounded,
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: () =>
                  Navigator.of(context).pushNamed(LoginScreen.routeName),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            const AuthDivider(),
            const SizedBox(height: AmoraSpacing.space16),
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
              text: 'Sign in is required only when you are ready to connect.',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: AmoraSpacing.space16),
            AppPrimaryButton(
              label: 'Explore AMORA AI',
              icon: Icons.explore_outlined,
              variant: AppPrimaryButtonVariant.text,
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(BrowseGridScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AmoraSpacing.minimumTouchTarget),
        const Spacer(),
        const _BrandMark(),
        const Spacer(),
        const SizedBox(width: AmoraSpacing.minimumTouchTarget),
      ],
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero();
=======

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
>>>>>>> main

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Already have an account?', style: AmoraTextStyles.bodyMedium),
            AppPrimaryButton(
              label: 'Log in',
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: () =>
                  Navigator.of(context).pushNamed(LoginScreen.routeName),
            ),
          ],
        ),
        Text(
          'By continuing, you agree to Amora’s Terms and Privacy Policy.',
          textAlign: TextAlign.center,
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.textNeutral.withValues(alpha: .68),
          ),
        ),
<<<<<<< HEAD
        const SizedBox(height: AmoraSpacing.space24),
        Text(
          'Meaningful connections begin with being yourself.',
          textAlign: TextAlign.center,
          style: AmoraTextStyles.headlineMedium,
        ),
        const SizedBox(height: AmoraSpacing.space12),
        Text(
          'A calm, intentional space for meeting people who value the same things you do.',
          textAlign: TextAlign.center,
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
=======
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
        AppPrimaryButton(
          label: 'Create a new account',
          icon: Icons.person_add_alt_1_rounded,
          variant: AppPrimaryButtonVariant.text,
          fullWidth: false,
          onPressed: () =>
              Navigator.of(context).pushNamed(SignupScreen.routeName),
>>>>>>> main
        ),
      ],
    );
  }
}
<<<<<<< HEAD

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Text('AMORA AI', style: AmoraTextStyles.titleMedium);
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AmoraSpacing.space8,
      runSpacing: AmoraSpacing.space4,
      children: [
        _footerLink(context, 'Privacy'),
        _footerLink(context, 'Terms'),
        _footerLink(context, 'Help'),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String label) {
    return AppPrimaryButton(
      label: label,
      variant: AppPrimaryButtonVariant.text,
      size: AmoraButtonSize.compact,
      fullWidth: false,
      onPressed: () => showAmoraSnackBar(context, message: '$label selected'),
    );
  }
}
=======
>>>>>>> main
