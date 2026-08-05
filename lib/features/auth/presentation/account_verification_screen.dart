import 'dart:async';

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

typedef EmailVerificationCodeRequester = Future<void> Function(String email);
typedef EmailVerificationCodeVerifier =
    Future<void> Function(String email, String code);

enum VerificationPurpose { signup }

enum EmailVerificationFailure {
  incorrectCode,
  expiredCode,
  tooManyAttempts,
  network,
  unavailable,
}

class EmailVerificationException implements Exception {
  const EmailVerificationException(this.failure);

  final EmailVerificationFailure failure;
}

@immutable
class EmailVerificationArguments {
  const EmailVerificationArguments({
    required this.email,
    this.verificationPurpose = VerificationPurpose.signup,
  });

  final String email;
  final VerificationPurpose verificationPurpose;
}

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({
    super.key,
    this.arguments,
    this.requestCode,
    this.verifyCode,
    this.resendSeconds = 30,
  });

  static const routeName = '/account-verification';

  final EmailVerificationArguments? arguments;
  final EmailVerificationCodeRequester? requestCode;
  final EmailVerificationCodeVerifier? verifyCode;
  final int resendSeconds;

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  static const _codeLength = 6;
  final _controllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final _nodes = List.generate(_codeLength, (_) => FocusNode());

  EmailVerificationArguments? _arguments;
  Timer? _timer;
  String? _error;
  String? _confirmation;
  bool _loading = false;
  bool _sending = false;
  bool _initialRequestStarted = false;
  bool _codeSent = false;
  int _secondsLeft = 0;

  String get _code => _controllers.map((controller) => controller.text).join();
  String get _email => _arguments?.email.trim() ?? '';
  bool get _completeCode => RegExp(r'^\d{6}$').hasMatch(_code);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _arguments ??=
        widget.arguments ?? _routeArguments() ?? _recoveryArguments();
    if (_initialRequestStarted) return;
    _initialRequestStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_requestCode(initial: true));
    });
  }

  EmailVerificationArguments? _routeArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    return arguments is EmailVerificationArguments ? arguments : null;
  }

  EmailVerificationArguments _recoveryArguments() {
    return EmailVerificationArguments(
      email: LocalProfileRepository.instance.profile.email.trim(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destination = _email.isEmpty ? 'your registered email' : _email;
    return AmoraAuthShell(
      title: 'Verify your email',
      subtitle: _codeSent
          ? 'We sent a 6-digit verification code to:'
          : 'Email verification is required before profile setup.',
      stepLabel: 'Email verification',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Verification email destination: $destination',
            child: Text(
              destination,
              key: const ValueKey('verification-email'),
              textAlign: TextAlign.center,
              style: AmoraTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AmoraOtpInput(
            key: const ValueKey('account-verification-otp'),
            controllers: _controllers,
            nodes: _nodes,
            hasError: _error != null,
            enabled: !_loading,
            onChanged: () => setState(() {
              _error = null;
              _confirmation = null;
            }),
            onPaste: _paste,
          ),
          if (_error != null) ...[
            const SizedBox(height: AmoraSpacing.space12),
            Semantics(
              liveRegion: true,
              child: AuthInlineAlert(message: _error!),
            ),
          ],
          if (_confirmation != null) ...[
            const SizedBox(height: AmoraSpacing.space12),
            Semantics(
              liveRegion: true,
              child: AuthInlineAlert(message: _confirmation!),
            ),
          ],
          const SizedBox(height: AmoraSpacing.space16),
          const AuthTrustNote(
            text:
                'Only enter a code requested by you. AMORAA support will never ask for it.',
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AuthPrimaryButton(
            key: const ValueKey('verify-account-button'),
            label: _loading ? 'Verifyingâ€¦' : 'Verify Email',
            icon: Icons.verified_user_outlined,
            isLoading: _loading,
            onPressed: _completeCode && !_loading ? _verify : null,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          Text(
            'Didnâ€™t receive the code?',
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium,
          ),
          const SizedBox(height: AmoraSpacing.space4),
          Center(child: _buildResendAction()),
          const SizedBox(height: AmoraSpacing.space8),
          AppPrimaryButton(
            key: const ValueKey('verification-change-email'),
            label: 'Change email',
            variant: AppPrimaryButtonVariant.text,
            size: AmoraButtonSize.compact,
            fullWidth: false,
            onPressed: _loading || _sending
                ? null
                : () => Navigator.of(context).pushReplacementNamed('/signup'),
          ),
        ],
      ),
    );
  }

  Widget _buildResendAction() {
    if (_sending) {
      return Semantics(
        liveRegion: true,
        label: 'Sending verification code',
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (_secondsLeft > 0) {
      return Semantics(
        liveRegion: true,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              'Resend code in ${_secondsLeft}s',
              key: const ValueKey('verification-resend-countdown'),
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.text.withValues(alpha: .68),
              ),
            ),
          ),
        ),
      );
    }
    return AppPrimaryButton(
      key: const ValueKey('verification-resend'),
      label: 'Resend code',
      variant: AppPrimaryButtonVariant.text,
      size: AmoraButtonSize.compact,
      fullWidth: false,
      onPressed: _loading ? null : _requestCode,
    );
  }

  void _paste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != _codeLength) return;
    for (var index = 0; index < _codeLength; index++) {
      _controllers[index].text = digits[index];
    }
    setState(() {
      _error = null;
      _confirmation = null;
    });
  }

  Future<void> _requestCode({bool initial = false}) async {
    if (_sending || _loading || (!initial && _secondsLeft > 0)) return;
    final request = widget.requestCode;
    if (_email.isEmpty || request == null) {
      setState(() {
        _error =
            'Email verification is unavailable right now. Please try again later.';
        _confirmation = null;
      });
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _confirmation = null;
    });
    try {
      await request(_email);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _codeSent = true;
        _confirmation = initial
            ? null
            : 'A new verification code has been sent.';
      });
      _startCountdown();
      _nodes.first.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = _messageFor(error, sending: true);
      });
    }
  }

  Future<void> _verify() async {
    if (_loading || !_completeCode) return;
    final verify = widget.verifyCode;
    if (verify == null) {
      setState(() {
        _error =
            'Verification is unavailable right now. Please try again later.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _confirmation = null;
    });
    try {
      await verify(_email, _code);
      if (!mounted) return;
      LocalOnboardingRepository.instance.update(
        LocalOnboardingRepository.instance.state.copyWith(
          accountVerified: true,
          stage: OnboardingStage.age,
        ),
      );
      setState(() {
        _loading = false;
        _confirmation = 'Email verified';
      });
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        ProfileOnboardingFlow.routeName,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _messageFor(error);
      });
    }
  }

  String _messageFor(Object error, {bool sending = false}) {
    if (error is EmailVerificationException) {
      return switch (error.failure) {
        EmailVerificationFailure.incorrectCode =>
          'That code doesnâ€™t match. Please try again.',
        EmailVerificationFailure.expiredCode =>
          'This code has expired. Request a new one.',
        EmailVerificationFailure.tooManyAttempts =>
          'Too many attempts. Please request a new code.',
        EmailVerificationFailure.network =>
          sending
              ? 'We couldnâ€™t send a code. Check your connection and retry.'
              : 'We couldnâ€™t verify your email. Please try again.',
        EmailVerificationFailure.unavailable =>
          sending
              ? 'Email verification is unavailable right now. Please try again later.'
              : 'Verification is unavailable right now. Please try again later.',
      };
    }
    return sending
        ? 'We couldnâ€™t send a code. Please try again.'
        : 'We couldnâ€™t verify your email. Please try again.';
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.resendSeconds);
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
}
