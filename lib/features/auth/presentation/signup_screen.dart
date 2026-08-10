import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/auth/presentation/account_verification_screen.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/domain/amora_password_policy.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/legal/presentation/legal_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const routeName = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _terms = false;
  bool _privacy = false;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _error;

  double get _progress {
    var completed = 0;
    if (_nameController.text.trim().isNotEmpty) completed++;
    if (_emailController.text.trim().isNotEmpty) completed++;
    if (_phoneController.text.trim().isNotEmpty) completed++;
    if (_passwordController.text.isNotEmpty) completed++;
    if (_confirmPasswordController.text.isNotEmpty) completed++;
    if (_terms && _privacy) completed++;
    return completed / 6;
  }

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _emailController,
      _phoneController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_refreshPresentation);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _emailController,
      _phoneController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_refreshPresentation);
      controller.dispose();
    }
    super.dispose();
  }

  void _refreshPresentation() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: 'Create your AMORAA account',
      subtitle:
          'A few details, then we’ll help you build a profile that feels like you.',
      statement: 'Your story starts with a few essentials.',
      showComposition: false,
      stepLabel: 'Account setup',
      alignStepLabelRight: true,
      stepLabelKey: const ValueKey('signup-account-setup-chip'),
      footer: const _SignupFooter(),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignupProgress(progress: _progress),
              const SizedBox(height: AmoraSpacing.space20),
              AmoraAuthField(
                key: const ValueKey('signup-name-field'),
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: _requiredName,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AmoraAuthField(
                key: const ValueKey('signup-email-field'),
                controller: _emailController,
                label: 'Email address',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AmoraAuthField(
                key: const ValueKey('signup-phone-field'),
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_iphone_rounded,
                prefixText: '+91 ',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validatePhone,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AmoraAuthField(
                key: const ValueKey('signup-password-field'),
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: _validatePassword,
                suffix: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: AmoraSpacing.space12),
                AmoraPasswordRules(
                  password: _passwordController.text,
                  requirement: AmoraPasswordPolicy.requirement,
                ),
              ],
              const SizedBox(height: AmoraSpacing.space16),
              AmoraAuthField(
                key: const ValueKey('signup-confirm-password-field'),
                controller: _confirmPasswordController,
                label: 'Confirm password',
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmation,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: _validateConfirmPassword,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  tooltip: _obscureConfirmation
                      ? 'Show password confirmation'
                      : 'Hide password confirmation',
                  onPressed: () => setState(
                    () => _obscureConfirmation = !_obscureConfirmation,
                  ),
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space20),
              _LegalConsentTile(
                accepted: _terms && _privacy,
                onChanged: (value) => setState(() {
                  _terms = value;
                  _privacy = value;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: AmoraSpacing.space12),
                AuthInlineAlert(message: _error!),
              ],
              const SizedBox(height: AmoraSpacing.space16),
              AuthPrimaryButton(
                label: _loading ? 'Creating account…' : 'Create account',
                icon: Icons.arrow_forward_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: AmoraSpacing.space20),
              const AuthDivider(),
              const SizedBox(height: AmoraSpacing.space20),
              AmoraGoogleButton(
                label: 'Sign up with Google',
                isLoading: _googleLoading,
                onPressed: _googleLoading ? null : _continueWithGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_terms || !_privacy) {
      _snack('Please accept Terms and Privacy');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      if (!mounted) return;
      LocalOnboardingRepository.instance.resetForNewAccount();
      LocalProfileRepository.instance.startNewProfile(
        _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: '+91 ${_phoneController.text.trim()}',
      );
      Navigator.of(context).pushReplacementNamed(
        AccountVerificationScreen.routeName,
        arguments: MobileVerificationArguments(
          phoneNumber: _phoneController.text.trim(),
        ),
      );
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Account creation is unavailable right now. Please try again.';
        });
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await AuthService.instance.googleSignIn();
      if (!mounted) return;
      await AmoraSession.completeAuthentication(context);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _googleLoading = false;
          _error = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _googleLoading = false;
          _error = 'Google sign-in could not be completed. Please try again.';
        });
      }
    }
  }

  String? _requiredName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Enter your name';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value ?? '';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(text)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  String? _validatePassword(String? value) =>
      AmoraPasswordPolicy.validateNewPassword(value);

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  void _snack(String message) {
    showAmoraSnackBar(context, message: message);
  }
}

class _SignupProgress extends StatelessWidget {
  const _SignupProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: AmoraSpacing.space8),
            Expanded(
              child: Text(
                '${(progress * 100).round()}% of account essentials complete',
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space8),
        ClipRRect(
          borderRadius: AmoraRadius.pillBorder,
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 6,
            color: AppColors.primary,
            backgroundColor: AppColors.tertiary.withValues(alpha: .5),
          ),
        ),
      ],
    );
  }
}

class _LegalConsentTile extends StatelessWidget {
  const _LegalConsentTile({required this.accepted, required this.onChanged});

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: accepted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            onChanged: (value) => onChanged(value ?? false),
          ),
          const SizedBox(width: AmoraSpacing.space4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AmoraSpacing.space12),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('I accept the ', style: AmoraTextStyles.bodyMedium),
                  const _LegalLink(
                    label: 'Terms & Conditions',
                    routeName: TermsConditionsScreen.routeName,
                  ),
                  Text(' and ', style: AmoraTextStyles.bodyMedium),
                  const _LegalLink(
                    label: 'Privacy Policy',
                    routeName: PrivacyPolicyScreen.routeName,
                  ),
                  Text('.', style: AmoraTextStyles.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.routeName});

  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).pushNamed(routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AmoraSpacing.space4),
        child: Text(
          label,
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _SignupFooter extends StatelessWidget {
  const _SignupFooter();

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
              Navigator.of(context).pushReplacementNamed(LoginScreen.routeName),
        ),
      ],
    );
  }
}
