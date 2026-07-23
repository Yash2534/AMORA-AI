import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
<<<<<<< HEAD
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/amora_inputs.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
=======
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_inputs.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
>>>>>>> main
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
  bool _marketing = true;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

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

  int get _passwordScore {
    final password = _passwordController.text;
    var score = 0;
    if (password.length >= 8) score++;
    if (RegExp('[A-Z]').hasMatch(password)) score++;
    if (RegExp('[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
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
      title: 'Create your Amora account',
      subtitle:
          'Start with the essentials. You can personalize your profile next.',
      statement: 'Your story starts with a few essentials.',
      showComposition: false,
      stepLabel: 'Account setup',
      onBack: () => Navigator.of(context).maybePop(),
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
              AppTextField(
                key: const ValueKey('signup-name-field'),
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: _requiredName,
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AppTextField(
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
              AppTextField(
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
              AppTextField(
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
<<<<<<< HEAD
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BackHeader(
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(height: AmoraSpacing.space24),
                        const _SignupVisual(),
                        const SizedBox(height: AmoraSpacing.space24),
                        Text(
                          'Create your AMORA profile',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Text(
                          'The essentials help AMORA AI prepare better compatibility questions.',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space20),
                        _ProgressCard(progress: _progress),
                        const SizedBox(height: AmoraSpacing.space16),
                        PremiumCard(
                          radius: AmoraRadius.extraLarge,
                          padding: const EdgeInsets.all(AmoraSpacing.space20),
                          child: Column(
                            children: [
                              AppTextField(
                                controller: _nameController,
                                label: 'Name',
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: _requiredName,
                              ),
                              const SizedBox(height: AmoraSpacing.space16),
                              AppTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: AmoraSpacing.space16),
                              AppTextField(
                                controller: _phoneController,
                                label: 'Phone',
                                icon: Icons.phone_iphone_rounded,
                                prefixText: '+91 ',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: AmoraSpacing.space16),
                              AppTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                suffix: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              _PasswordStrength(score: _passwordScore),
                              const SizedBox(height: AmoraSpacing.space16),
                              AppTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_reset_rounded,
                                obscureText: _obscureConfirmation,
                                validator: _validateConfirmPassword,
                                suffix: IconButton(
                                  tooltip: _obscureConfirmation
                                      ? 'Show password confirmation'
                                      : 'Hide password confirmation',
                                  onPressed: () => setState(
                                    () => _obscureConfirmation =
                                        !_obscureConfirmation,
                                  ),
                                  icon: Icon(
                                    _obscureConfirmation
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AmoraSpacing.space16),
                              _ConsentTile(
                                value: _terms,
                                label: 'I accept the Terms of Service.',
                                onChanged: (value) =>
                                    setState(() => _terms = value),
                              ),
                              _ConsentTile(
                                value: _privacy,
                                label: 'I accept the Privacy Policy.',
                                onChanged: (value) =>
                                    setState(() => _privacy = value),
                              ),
                              _ConsentTile(
                                value: _marketing,
                                label:
                                    'Send me premium events and dating tips.',
                                onChanged: (value) =>
                                    setState(() => _marketing = value),
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              AppPrimaryButton(
                                label: 'Continue',
                                icon: Icons.arrow_forward_rounded,
                                isLoading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Already have an account?',
                              style: AmoraTextStyles.bodyMedium.copyWith(
                                color: AppColors.textGray,
                              ),
                            ),
                            AppPrimaryButton(
                              label: 'Log in',
                              variant: AppPrimaryButtonVariant.text,
                              size: AmoraButtonSize.compact,
                              fullWidth: false,
                              onPressed: () => Navigator.of(
                                context,
                              ).pushReplacementNamed(LoginScreen.routeName),
                            ),
                          ],
                        ),
                      ],
                    ),
=======
                ),
              ),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: AmoraSpacing.space12),
                _PasswordGuidance(score: _passwordScore),
              ],
              const SizedBox(height: AmoraSpacing.space16),
              AppTextField(
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
>>>>>>> main
                  ),
                  icon: Icon(
                    _obscureConfirmation
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space20),
              _ConsentTile(
                value: _terms,
                label: 'I accept the Terms of Service.',
                onChanged: (value) => setState(() => _terms = value),
              ),
              _ConsentTile(
                value: _privacy,
                label: 'I accept the Privacy Policy.',
                onChanged: (value) => setState(() => _privacy = value),
              ),
              _ConsentTile(
                value: _marketing,
                label: 'Send me premium events and dating tips.',
                onChanged: (value) => setState(() => _marketing = value),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              AuthPrimaryButton(
                label: _loading ? 'Creating account…' : 'Create account',
                icon: Icons.arrow_forward_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: AmoraSpacing.space12),
              Text(
                'By creating an account, you agree to Amora’s Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: AmoraTextStyles.bodySmall.copyWith(
                  color: AppColors.textNeutral.withValues(alpha: .68),
                ),
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
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    LocalOnboardingRepository.instance.resetForNewAccount();
    LocalProfileRepository.instance.startNewProfile(
      _nameController.text.trim(),
    );
    Navigator.of(context).pushReplacementNamed(ProfileOnboardingFlow.routeName);
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

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.length < 8) return 'Use at least 8 characters';
    if (_passwordScore < 2) return 'Add numbers or symbols for strength';
    return null;
  }

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

class _PasswordGuidance extends StatelessWidget {
  const _PasswordGuidance({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final label = switch (score) {
      0 || 1 => 'Keep going',
      2 || 3 => 'Good password',
      _ => 'Strong password',
    };
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var index = 0; index < 4; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 6,
                    decoration: BoxDecoration(
                      color: index < score
                          ? AppColors.primary
                          : AppColors.tertiary.withValues(alpha: .55),
                      borderRadius: AmoraRadius.pillBorder,
                    ),
                  ),
                ),
                if (index != 3) const SizedBox(width: AmoraSpacing.space4),
              ],
            ],
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Text(
            '$label · Use 8+ characters and add numbers or symbols.',
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.textNeutral.withValues(alpha: .68),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AmoraCheckboxTile(value: value, label: label, onChanged: onChanged);
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
