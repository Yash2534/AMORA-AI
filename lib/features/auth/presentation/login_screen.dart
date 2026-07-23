import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/amora_inputs.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/features/auth/presentation/phone_otp_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _loading = false;
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_syncButtonState);
    _passwordController.addListener(_syncButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: 'Welcome back',
      subtitle: 'Continue where your connections left off.',
      statement: 'Designed for real connections.',
      showComposition: false,
      onBack: () => Navigator.of(context).maybePop(),
      footer: const _LoginFooter(),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _CompactLoginIdentity(),
              const SizedBox(height: AmoraSpacing.space20),
              AppTextField(
                key: const ValueKey('login-email-field'),
                controller: _emailController,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: _validateEmail,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AppTextField(
                key: const ValueKey('login-password-field'),
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: !_showPassword,
                validator: _validatePassword,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.done,
                suffix: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AmoraCheckboxTile(
                    value: _rememberMe,
                    label: 'Remember me',
                    onChanged: (value) => setState(() => _rememberMe = value),
                  ),
                  AppPrimaryButton(
                    label: 'Forgot password?',
                    variant: AppPrimaryButtonVariant.text,
                    size: AmoraButtonSize.compact,
                    fullWidth: false,
                    onPressed: _showForgotPassword,
                  ),
                ],
              ),
              const SizedBox(height: AmoraSpacing.space12),
              AuthPrimaryButton(
                label: _loading ? 'Logging in…' : 'Log in',
                icon: Icons.arrow_forward_rounded,
                isLoading: _loading,
                onPressed: _canSubmit && !_loading ? _submit : null,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              const AuthDivider(label: 'or'),
              const SizedBox(height: AmoraSpacing.space16),
              AppPrimaryButton(
                label: 'Continue with phone',
                icon: Icons.phone_iphone_rounded,
                variant: AppPrimaryButtonVariant.outlined,
                onPressed: () =>
                    Navigator.of(context).pushNamed(PhoneOtpScreen.routeName),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              const AuthTrustNote(
                text:
                    'Your sign-in details are used to access your Amora account.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncButtonState() {
    final next =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 6;
    if (next != _canSubmit) setState(() => _canSubmit = next);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _loading = false);
    await AmoraSession.completeAuthentication(context);
  }

  void _showForgotPassword() {
    showAmoraDialog<void>(
      context: context,
      icon: Icons.lock_reset_rounded,
      title: 'Reset your password',
      message:
          'Enter your email on this screen and AMORA AI will prepare a secure reset link for the production backend.',
      primaryLabel: 'Send reset link',
      secondaryLabel: 'Cancel',
      onPrimary: () {
        Navigator.of(context).maybePop();
        _snack('Password reset link prepared');
      },
    );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 6) return 'Use at least 6 characters';
    return null;
  }

  void _snack(String message) {
    showAmoraSnackBar(context, message: message);
  }
}

class _CompactLoginIdentity extends StatelessWidget {
  const _CompactLoginIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tertiary),
          ),
          child: const Icon(
            Icons.favorite_border_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AMORA', style: AmoraTextStyles.titleMedium),
              Text(
                'Your account, right where you left it.',
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('New to AMORA AI?', style: AmoraTextStyles.bodyMedium),
            AppPrimaryButton(
              label: 'Create account',
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: () => Navigator.of(
                context,
              ).pushReplacementNamed(SignupScreen.routeName),
            ),
          ],
        ),
        Text(
          'By continuing, you agree to AMORA AI Terms and Privacy Policy.',
          textAlign: TextAlign.center,
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.textNeutral.withValues(alpha: .68),
          ),
        ),
      ],
    );
  }
}
