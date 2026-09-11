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
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
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
  List<SignupLegalDocument>? _legalDocuments;
  bool _legalLoading = true;
  bool _legalLoadFailed = false;

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

  Future<void> _loadLegalDocuments() async {
    setState(() {
      _legalLoading = true;
      _legalLoadFailed = false;
    });
    try {
      final documents = await AuthService.instance
          .requiredSignupLegalDocuments();
      final keys = documents.map((item) => item.documentKey).toSet();
      if (!keys.contains('TERMS_OF_SERVICE') ||
          !keys.contains('PRIVACY_POLICY')) {
        throw const AuthException('Required legal documents are unavailable.');
      }
      if (mounted)
        setState(() {
          _legalDocuments = documents;
          _legalLoading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _legalDocuments = null;
          _legalLoading = false;
          _legalLoadFailed = true;
        });
    }
  }

  SignupLegalDocument? _document(String key) =>
      _legalDocuments?.where((item) => item.documentKey == key).firstOrNull;

  @override
  void initState() {
    super.initState();
    _loadLegalDocuments();
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
                enabled: !_legalLoading && !_legalLoadFailed,
                onTerms: () {
                  final item = _document('TERMS_OF_SERVICE');
                  if (item != null) _openLegalDocument(item);
                },
                onPrivacy: () {
                  final item = _document('PRIVACY_POLICY');
                  if (item != null) _openLegalDocument(item);
                },
                onChanged: (value) => setState(() {
                  _terms = value;
                  _privacy = value;
                }),
              ),
              if (_legalLoading)
                const Padding(
                  padding: EdgeInsets.only(top: AmoraSpacing.space8),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: AmoraSpacing.space8),
                      Text('Loading Terms & Privacy Policy…'),
                    ],
                  ),
                ),
              if (_legalLoadFailed)
                Padding(
                  padding: const EdgeInsets.only(top: AmoraSpacing.space8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'We couldn’t load the Terms & Privacy Policy. Please try again.',
                        ),
                      ),
                      TextButton(
                        onPressed: _loadLegalDocuments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
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
                onPressed: _loading || _legalLoading || _legalLoadFailed
                    ? null
                    : _submit,
              ),
              const SizedBox(height: AmoraSpacing.space20),
              const AuthDivider(),
              const SizedBox(height: AmoraSpacing.space20),
              AmoraGoogleButton(
                label: 'Sign up with Google',
                isLoading: _googleLoading,
                onPressed: _googleLoading || _legalLoading || _legalLoadFailed
                    ? null
                    : _continueWithGoogle,
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
      final acceptedLegalDocuments = _legalDocuments!
          .map((item) => item.acceptance)
          .toList();
      await AuthService.instance.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        acceptedLegalDocuments: acceptedLegalDocuments,
        platform: _consentPlatform,
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
          _error = error.code == 'LEGAL_DOCUMENT_VERSION_OUTDATED'
              ? 'The Terms or Privacy Policy was updated. Please review and accept the latest version.'
              : error.userMessage;
        });
        if (error.code == 'LEGAL_DOCUMENT_VERSION_OUTDATED') {
          _terms = false;
          _privacy = false;
          _loadLegalDocuments();
        }
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
    if (!_terms || !_privacy) {
      _snack('Please accept Terms and Privacy');
      return;
    }
    setState(() => _googleLoading = true);
    try {
      final acceptedLegalDocuments = _legalDocuments!
          .map((item) => item.acceptance)
          .toList();
      await AuthService.instance.googleSignIn(
        acceptedLegalDocuments: acceptedLegalDocuments,
        platform: _consentPlatform,
      );
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

  void _openLegalDocument(SignupLegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VersionedLegalDocumentScreen(document: document),
      ),
    );
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

  String get _consentPlatform {
    if (kIsWeb) return 'WEB';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'IOS',
      _ => 'ANDROID',
    };
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
  const _LegalConsentTile({
    required this.accepted,
    required this.enabled,
    required this.onChanged,
    required this.onTerms,
    required this.onPrivacy,
  });

  final bool accepted;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: accepted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            onChanged: enabled ? (value) => onChanged(value ?? false) : null,
          ),
          const SizedBox(width: AmoraSpacing.space4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AmoraSpacing.space12),
              child: _LegalConsentText(onTerms: onTerms, onPrivacy: onPrivacy),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalConsentText extends StatefulWidget {
  const _LegalConsentText({required this.onTerms, required this.onPrivacy});
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  State<_LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<_LegalConsentText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacy;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = AmoraTextStyles.bodyMedium.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      key: const ValueKey('signup-legal-consent-text'),
      TextSpan(
        style: AmoraTextStyles.bodyMedium,
        children: [
          const TextSpan(text: 'I accept the '),
          TextSpan(
            text: 'Terms & Conditions',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      softWrap: true,
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
