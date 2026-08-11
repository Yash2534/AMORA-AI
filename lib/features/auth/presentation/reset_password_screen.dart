import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/auth/domain/amora_password_policy.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';

typedef PasswordResetSubmitter =
    Future<void> Function(
      String email,
      String recoveryToken,
      String newPassword,
    );

class ResetPasswordArgs {
  const ResetPasswordArgs({required this.email, required this.recoveryToken});

  final String email;
  final String recoveryToken;
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.onReset});

  static const routeName = '/reset-password';

  final PasswordResetSubmitter? onReset;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _loading = false;
  bool _success = false;
  String? _error;
  ResetPasswordArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is ResetPasswordArgs) _args = arguments;
  }

  @override
  void dispose() {
    _passwordController.clear();
    _confirmationController.clear();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmoraAuthShell(
      title: _success ? 'Password updated' : 'Create a new password',
      subtitle: _success
          ? 'You can now sign in with your new password.'
          : 'Use a secure password you have not used for AMORAA before.',
      stepLabel: _success ? null : 'Step 3 of 3',
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          key: const ValueKey('reset-password-form'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmoraAuthField(
              key: const ValueKey('new-password-field'),
              controller: _passwordController,
              label: 'New password',
              hint: 'Use at least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AmoraPasswordPolicy.validateNewPassword,
              onChanged: (_) => setState(() => _error = null),
              suffix: IconButton(
                tooltip: _obscurePassword
                    ? 'Show new password'
                    : 'Hide new password',
                onPressed: _loading
                    ? null
                    : () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            AmoraPasswordRules(
              password: _passwordController.text,
              requirement: AmoraPasswordPolicy.requirement,
            ),
            const SizedBox(height: AmoraSpacing.space16),
            AmoraAuthField(
              key: const ValueKey('confirm-new-password-field'),
              controller: _confirmationController,
              label: 'Confirm new password',
              hint: 'Enter the password again',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmation,
              enabled: !_loading,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateConfirmation,
              onSubmitted: (_) => _submit(),
              suffix: IconButton(
                tooltip: _obscureConfirmation
                    ? 'Show password confirmation'
                    : 'Hide password confirmation',
                onPressed: _loading
                    ? null
                    : () => setState(
                        () => _obscureConfirmation = !_obscureConfirmation,
                      ),
                icon: Icon(
                  _obscureConfirmation
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AmoraSpacing.space12),
              AuthInlineAlert(message: _error!),
            ],
            const SizedBox(height: AmoraSpacing.space20),
            AuthPrimaryButton(
              key: const ValueKey('reset-password-submit'),
              label: _loading ? 'Updating password…' : 'Update password',
              icon: Icons.arrow_forward_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('reset-password-success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.verified_user_outlined, size: 48),
        const SizedBox(height: AmoraSpacing.space16),
        const AuthTrustNote(
          text:
              'Your password was updated by the connected authentication service.',
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: AmoraSpacing.space20),
        AuthPrimaryButton(
          label: 'Return to sign in',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false),
        ),
      ],
    );
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final submit = widget.onReset;
    final args = _args;
    if (submit == null || args == null) {
      setState(() {
        _error = 'Password reset is unavailable right now. Start again later.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await submit(args.email, args.recoveryToken, _passwordController.text);
      if (!mounted) return;
      _passwordController.clear();
      _confirmationController.clear();
      setState(() {
        _loading = false;
        _success = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'The reset session expired or the service is unavailable. Start again.';
        });
      }
    }
  }
}
