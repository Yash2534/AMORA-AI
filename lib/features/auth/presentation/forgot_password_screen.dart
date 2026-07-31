import 'dart:async';

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/reset_password_screen.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';

typedef RecoveryCodeRequester = Future<void> Function(String destination);
typedef RecoveryCodeVerifier =
    Future<String> Function(String destination, String code);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.requestCode, this.verifyCode});

  static const routeName = '/forgot-password';

  final RecoveryCodeRequester? requestCode;
  final RecoveryCodeVerifier? verifyCode;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _RecoveryStep { destination, code }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _codeLength = 6;
  static const _resendSeconds = 45;

  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _codeControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final _codeNodes = List.generate(_codeLength, (_) => FocusNode());
  _RecoveryStep _step = _RecoveryStep.destination;
  bool _loading = false;
  int _secondsLeft = 0;
  String? _error;
  Timer? _timer;

  String get _code =>
      _codeControllers.map((controller) => controller.text).join();

  String get _maskedDestination {
    final email = _destinationController.text.trim();
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email.substring(0, 1)}••••${email.substring(at)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _destinationController.dispose();
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final node in _codeNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enteringCode = _step == _RecoveryStep.code;
    return AmoraAuthShell(
      title: enteringCode ? 'Enter verification code' : 'Reset your password',
      subtitle: enteringCode
          ? 'We sent a code to $_maskedDestination.'
          : 'Enter your registered email and we’ll send a verification code.',
      stepLabel: enteringCode ? 'Step 2 of 3' : 'Step 1 of 3',
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        child: enteringCode ? _buildCodeStep() : _buildDestinationStep(),
      ),
    );
  }

  Widget _buildDestinationStep() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('recovery-destination-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmoraAuthField(
            key: const ValueKey('recovery-email-field'),
            controller: _destinationController,
            label: 'Registered email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            enabled: !_loading,
            validator: _validateEmail,
            onSubmitted: (_) => _requestCode(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AmoraSpacing.space12),
            AuthInlineAlert(message: _error!),
          ],
          const SizedBox(height: AmoraSpacing.space20),
          AuthPrimaryButton(
            key: const ValueKey('send-recovery-code'),
            label: _loading ? 'Sending code…' : 'Send verification code',
            icon: Icons.arrow_forward_rounded,
            isLoading: _loading,
            onPressed: _loading ? null : _requestCode,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          const AuthTrustNote(
            text:
                'For your security, the code must be verified before a password can be changed.',
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      key: const ValueKey('recovery-code-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmoraOtpInput(
          key: const ValueKey('recovery-otp-input'),
          controllers: _codeControllers,
          nodes: _codeNodes,
          enabled: !_loading,
          hasError: _error != null,
          onChanged: () {
            if (_error != null) setState(() => _error = null);
          },
          onPaste: _applyPastedCode,
        ),
        if (_error != null) ...[
          const SizedBox(height: AmoraSpacing.space12),
          AuthInlineAlert(message: _error!),
        ],
        const SizedBox(height: AmoraSpacing.space20),
        AuthPrimaryButton(
          key: const ValueKey('verify-recovery-code'),
          label: _loading ? 'Verifying…' : 'Verify code',
          icon: Icons.verified_user_outlined,
          isLoading: _loading,
          onPressed: _code.length == _codeLength && !_loading
              ? _verifyCode
              : null,
        ),
        const SizedBox(height: AmoraSpacing.space12),
        Center(
          child: _secondsLeft > 0
              ? Semantics(
                  liveRegion: true,
                  child: Text(
                    'Resend code in 00:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.text.withValues(alpha: .68),
                    ),
                  ),
                )
              : AppPrimaryButton(
                  label: 'Resend code',
                  variant: AppPrimaryButtonVariant.text,
                  size: AmoraButtonSize.compact,
                  fullWidth: false,
                  onPressed: _loading ? null : _requestCode,
                ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        AppPrimaryButton(
          label: 'Change email',
          variant: AppPrimaryButtonVariant.text,
          size: AmoraButtonSize.compact,
          fullWidth: false,
          onPressed: _loading ? null : _changeDestination,
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _requestCode() async {
    FocusScope.of(context).unfocus();
    if (_step == _RecoveryStep.destination &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final request = widget.requestCode;
    if (request == null) {
      setState(() {
        _error = 'Password recovery is unavailable right now. Try again later.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await request(_destinationController.text.trim());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = _RecoveryStep.code;
      });
      _startCountdown();
      _codeNodes.first.requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'We could not send a code. Check your connection and retry.';
      });
    }
  }

  Future<void> _verifyCode() async {
    final verify = widget.verifyCode;
    if (verify == null) {
      setState(() {
        _error = 'Code verification is unavailable right now. Try again later.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await verify(_destinationController.text.trim(), _code);
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        ResetPasswordScreen.routeName,
        arguments: ResetPasswordArgs(
          destination: _destinationController.text.trim(),
          recoveryToken: token,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'That code is invalid or expired. Request a new code.';
      });
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _applyPastedCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _codeLength) return;
    for (var index = 0; index < _codeLength; index++) {
      _codeControllers[index].text = digits[index];
    }
    setState(() => _error = null);
  }

  void _changeDestination() {
    _timer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _step = _RecoveryStep.destination;
      _secondsLeft = 0;
      _error = null;
      for (final controller in _codeControllers) {
        controller.clear();
      }
    });
  }
}
