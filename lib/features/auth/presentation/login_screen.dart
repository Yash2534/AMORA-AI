import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/domain/amora_password_policy.dart';
import 'package:amora_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/signup_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _loading = false;
  bool _googleLoading = false;
  bool _canSubmit = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_syncButtonState);
    _passwordController.addListener(_syncButtonState);
  }

  @override
  void dispose() {
    _emailController
      ..removeListener(_syncButtonState)
      ..dispose();
    _passwordController
      ..removeListener(_syncButtonState)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: 'Welcome back',
      subtitle: 'Continue your AMORAA journey.',
      footer: const _LoginFooter(),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmoraAuthField(
                key: const ValueKey('login-email-field'),
                controller: _emailController,
                label: 'Email address',
                hint: 'you@example.com',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: _validateEmail,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AmoraAuthField(
                key: const ValueKey('login-password-field'),
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: !_showPassword,
                validator: AmoraPasswordPolicy.validateLoginPassword,
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
              Align(
                alignment: Alignment.centerRight,
                child: AppPrimaryButton(
                  key: const ValueKey('forgot-password-link'),
                  label: 'Forgot password?',
                  variant: AppPrimaryButtonVariant.text,
                  size: AmoraButtonSize.compact,
                  fullWidth: false,
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(
                          context,
                        ).pushNamed(ForgotPasswordScreen.routeName),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AmoraSpacing.space8),
                AuthInlineAlert(message: _error!),
              ],
              const SizedBox(height: AmoraSpacing.space12),
              AuthPrimaryButton(
                key: const ValueKey('login-submit'),
                label: _loading ? 'Signing in…' : 'Sign in',
                icon: Icons.arrow_forward_rounded,
                isLoading: _loading,
                onPressed: _canSubmit && !_loading ? _submit : null,
              ),
              const SizedBox(height: AmoraSpacing.space20),
              const AuthDivider(),
              const SizedBox(height: AmoraSpacing.space20),
              AmoraGoogleButton(
                isLoading: _googleLoading,
                onPressed: _googleLoading ? null : _continueWithGoogle,
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
        _passwordController.text.isNotEmpty;
    if (mounted && next != _canSubmit) setState(() => _canSubmit = next);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      TextInput.finishAutofillContext();
      await AmoraSession.completeAuthentication(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Sign in is unavailable right now. Please try again.';
      });
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await AmoraSession.completeAuthentication(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _googleLoading = false;
        _error = 'Google sign-in could not be completed. Please try again.';
      });
    }
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('New to AMORAA?', style: AmoraTextStyles.bodyMedium),
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
    );
  }
}
