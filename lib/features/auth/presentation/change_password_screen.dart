import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/domain/amora_password_policy.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';

typedef PasswordChangeSubmitter =
    Future<void> Function(String currentPassword, String newPassword);

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.onChangePassword});

  static const routeName = '/change-password';
  static const samePasswordMessage =
      'New password cannot be the same as the current password.';

  final PasswordChangeSubmitter? onChangePassword;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirmation = true;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AmoraAppBar(
        title: 'Change Password',
        subtitle: 'Keep your AMORAA account secure.',
        onBack: () => Navigator.of(context).maybePop(),
        maxContentWidth: 720,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AmoraSpacing.space20),
            child: _success ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmoraAuthField(
              key: const ValueKey('change-current-password-field'),
              controller: _currentController,
              label: 'Current password',
              hint: 'Enter your current password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureCurrent,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              validator: AmoraPasswordPolicy.validateLoginPassword,
              onChanged: (_) => setState(() => _error = null),
              suffix: _visibilityButton(
                obscured: _obscureCurrent,
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            AmoraAuthField(
              key: const ValueKey('change-new-password-field'),
              controller: _newController,
              label: 'New password',
              hint: 'Use at least 8 characters',
              icon: Icons.password_rounded,
              obscureText: _obscureNew,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateNewPassword,
              onChanged: (_) => setState(() => _error = null),
              suffix: _visibilityButton(
                obscured: _obscureNew,
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            AmoraPasswordRules(
              password: _newController.text,
              requirement: AmoraPasswordPolicy.requirement,
            ),
            const SizedBox(height: AmoraSpacing.space16),
            AmoraAuthField(
              key: const ValueKey('change-confirm-password-field'),
              controller: _confirmationController,
              label: 'Confirm new password',
              hint: 'Enter the new password again',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirmation,
              enabled: !_loading,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateConfirmation,
              onSubmitted: (_) => _submit(),
              suffix: _visibilityButton(
                obscured: _obscureConfirmation,
                onPressed: () => setState(
                  () => _obscureConfirmation = !_obscureConfirmation,
                ),
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: AmoraSpacing.space12),
              AuthInlineAlert(message: error),
            ],
            const SizedBox(height: AmoraSpacing.space20),
            AuthPrimaryButton(
              key: const ValueKey('change-password-submit'),
              label: _loading ? 'Updating password…' : 'Update password',
              icon: Icons.check_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return const AuthTrustNote(
      key: ValueKey('change-password-success'),
      text: 'Your password has been updated.',
      icon: Icons.check_circle_outline_rounded,
    );
  }

  Widget _visibilityButton({
    required bool obscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      onPressed: _loading ? null : onPressed,
      icon: Icon(
        obscured ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      ),
    );
  }

  String? _validateNewPassword(String? value) {
    final policy = AmoraPasswordPolicy.validateNewPassword(value);
    if (policy != null) return policy;
    if (value == _currentController.text) {
      return ChangePasswordScreen.samePasswordMessage;
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password';
    if (value != _newController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await (widget.onChangePassword ?? AuthService.instance.changePassword)(
        _currentController.text,
        _newController.text,
      );
      if (!mounted) return;
      _currentController.clear();
      _newController.clear();
      _confirmationController.clear();
      setState(() {
        _loading = false;
        _success = true;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.code == 'NEW_PASSWORD_SAME_AS_CURRENT'
            ? ChangePasswordScreen.samePasswordMessage
            : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Password could not be updated. Please try again.';
      });
    }
  }
}
