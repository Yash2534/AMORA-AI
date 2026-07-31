import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef PhoneOtpRequester =
    Future<void> Function(String countryCode, String phoneNumber);
typedef PhoneOtpVerifier =
    Future<void> Function(String countryCode, String phoneNumber, String code);

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key, this.requestOtp, this.verifyOtp});

  static const routeName = '/phone-login';

  final PhoneOtpRequester? requestOtp;
  final PhoneOtpVerifier? verifyOtp;

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  static const _otpLength = 6;

  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _otpNodes = List.generate(_otpLength, (_) => FocusNode());
  String _countryCode = '+91';
  bool _codeRequested = false;
  String? _phoneError;
  String? _otpError;
  int _secondsLeft = 0;
  bool _loading = false;
  Timer? _timer;

  bool get _canVerify =>
      _codeRequested &&
      _otpControllers.every((controller) => controller.text.length == 1) &&
      !_loading;

  String get _maskedPhone {
    final phone = _phoneController.text.trim();
    final suffix = phone.length >= 3
        ? phone.substring(phone.length - 3)
        : phone;
    return '$_countryCode ••••• ••$suffix';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verifying = _codeRequested;
    return AmoraAuthShell(
      title: verifying ? 'Enter verification code' : 'Continue with your phone',
      subtitle: verifying
          ? 'We sent a $_otpLength-digit code to $_maskedPhone.'
          : 'We’ll send a one-time verification code.',
      statement: 'A secure first step into Amora.',
      showComposition: false,
      stepLabel: verifying ? 'Step 2 of 2' : 'Step 1 of 2',
      onBack: verifying
          ? _changeNumber
          : () => Navigator.of(context).maybePop(),
      footer: const _PhonePrivacyFooter(),
      child: AnimatedSwitcher(
        duration: AmoraMotion.standard,
        switchInCurve: AmoraMotion.entranceCurve,
        switchOutCurve: AmoraMotion.exitCurve,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: verifying ? _buildOtpView(context) : _buildPhoneView(context),
      ),
    );
  }

  Widget _buildPhoneView(BuildContext context) {
    return Column(
      key: const ValueKey('phone-entry-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SecurityIdentity(),
        const SizedBox(height: AmoraSpacing.space20),
        _PhoneNumberField(
          controller: _phoneController,
          countryCode: _countryCode,
          onCountryChanged: (value) {
            if (value != null) setState(() => _countryCode = value);
          },
          onSubmitted: (_) => _sendOtp(),
        ),
        if (_phoneError != null) ...[
          const SizedBox(height: AmoraSpacing.space12),
          AuthInlineAlert(message: _phoneError!),
        ],
        const SizedBox(height: AmoraSpacing.space20),
        AuthPrimaryButton(
          label: _loading ? 'Sending code…' : 'Send verification code',
          icon: Icons.sms_outlined,
          isLoading: _loading,
          onPressed: _loading ? null : _sendOtp,
        ),
        const SizedBox(height: AmoraSpacing.space16),
        const AuthTrustNote(
          text: 'Your phone number is used for account security.',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }

  Widget _buildOtpView(BuildContext context) {
    return Column(
      key: const ValueKey('otp-verification-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                Icons.dialpad_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code sent', style: AmoraTextStyles.titleMedium),
                  Text(
                    _maskedPhone,
                    style: AmoraTextStyles.bodySmall.copyWith(
                      color: AppColors.textNeutral.withValues(alpha: .68),
                    ),
                  ),
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'Change',
              variant: AppPrimaryButtonVariant.text,
              size: AmoraButtonSize.compact,
              fullWidth: false,
              onPressed: _loading ? null : _changeNumber,
            ),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space20),
        AmoraOtpInput(
          key: const ValueKey('responsive-otp-input'),
          controllers: _otpControllers,
          nodes: _otpNodes,
          hasError: _otpError != null,
          enabled: !_loading,
          onChanged: () {
            setState(() => _otpError = null);
          },
          onPaste: _applyPastedOtp,
        ),
        if (_otpError != null) ...[
          const SizedBox(height: AmoraSpacing.space12),
          AuthInlineAlert(message: _otpError!),
        ],
        const SizedBox(height: AmoraSpacing.space20),
        AuthPrimaryButton(
          label: _loading ? 'Verifying…' : 'Verify and continue',
          icon: Icons.verified_user_outlined,
          isLoading: _loading,
          onPressed: _canVerify ? _verifyOtp : null,
        ),
        const SizedBox(height: AmoraSpacing.space16),
        Center(child: _buildResendAction()),
      ],
    );
  }

  Widget _buildResendAction() {
    if (_secondsLeft > 0) {
      final seconds = _secondsLeft.toString().padLeft(2, '0');
      return Semantics(
        liveRegion: true,
        child: Text(
          'Resend code in 00:$seconds',
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.textNeutral.withValues(alpha: .68),
          ),
        ),
      );
    }
    return AppPrimaryButton(
      label: 'Resend code',
      icon: Icons.refresh_rounded,
      variant: AppPrimaryButtonVariant.text,
      size: AmoraButtonSize.compact,
      fullWidth: false,
      onPressed: _loading ? null : _sendOtp,
    );
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!_validPhone(phone)) {
      setState(() {
        _phoneError = _countryCode == '+91'
            ? 'Enter a valid Indian mobile number'
            : 'Enter a valid phone number';
      });
      return;
    }
    final request = widget.requestOtp;
    if (request == null) {
      setState(() {
        _phoneError =
            'Phone verification is not connected to an authentication service in this build.';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      await request(_countryCode, phone);
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _phoneError = null;
        _otpError = null;
        _secondsLeft = 45;
        _loading = false;
        for (final controller in _otpControllers) {
          controller.clear();
        }
      });
      _otpNodes.first.requestFocus();
      _startResendTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _phoneError =
            'We could not send a code. Check your connection and retry.';
      });
    }
  }

  bool _validPhone(String phone) {
    return switch (_countryCode) {
      '+91' => RegExp(r'^[6-9]\d{9}$').hasMatch(phone),
      '+61' => RegExp(r'^\d{9}$').hasMatch(phone),
      '+1' || '+44' => RegExp(r'^\d{10}$').hasMatch(phone),
      _ => RegExp(r'^\d{7,10}$').hasMatch(phone),
    };
  }

  Future<void> _verifyOtp() async {
    final entered = _otpControllers.map((controller) => controller.text).join();
    final verify = widget.verifyOtp;
    if (verify == null) {
      setState(() {
        _otpError =
            'Code verification is not connected to an authentication service in this build.';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      await verify(_countryCode, _phoneController.text.trim(), entered);
      if (!mounted) return;
      await AmoraSession.completeAuthentication(context);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _otpError = 'That code is invalid or expired. Request a new code.';
      });
    }
  }

  void _applyPastedOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _otpControllers.length) return;
    for (var index = 0; index < _otpControllers.length; index++) {
      _otpControllers[index].text = digits[index];
    }
    _otpNodes.first.requestFocus();
    setState(() => _otpError = null);
  }

  void _changeNumber() {
    _timer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _codeRequested = false;
      _otpError = null;
      _phoneError = null;
      _secondsLeft = 0;
      for (final controller in _otpControllers) {
        controller.clear();
      }
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
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

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({
    required this.controller,
    required this.countryCode,
    required this.onCountryChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Phone number including country code',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AmoraSpacing.space4),
            child: Text(
              'Phone number',
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .72),
              ),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          Container(
            constraints: const BoxConstraints(minHeight: 56),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AmoraRadius.input,
              border: Border.all(color: AppColors.tertiary),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AmoraSpacing.space12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const ValueKey('phone-country-selector'),
                      value: countryCode,
                      borderRadius: AmoraRadius.button,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: const ['+91', '+1', '+44', '+61']
                          .map(
                            (code) => DropdownMenuItem(
                              value: code,
                              child: Text(code),
                            ),
                          )
                          .toList(),
                      onChanged: onCountryChanged,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AmoraSpacing.space8,
                  ),
                  color: AppColors.tertiary,
                ),
                Expanded(
                  child: TextField(
                    key: const ValueKey('phone-number-field'),
                    controller: controller,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: '98765 43210',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AmoraSpacing.space16,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, child) {
                          return value.text.isEmpty
                              ? const Icon(Icons.phone_iphone_rounded)
                              : IconButton(
                                  tooltip: 'Clear phone number',
                                  onPressed: controller.clear,
                                  icon: const Icon(Icons.close_rounded),
                                );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityIdentity extends StatelessWidget {
  const _SecurityIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.tertiary),
              ),
              child: const Icon(
                Icons.phone_iphone_rounded,
                color: AppColors.primary,
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AmoraSpacing.space16),
        Expanded(
          child: Text(
            'One quick check helps keep every Amora account connected to a real number.',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textNeutral.withValues(alpha: .72),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhonePrivacyFooter extends StatelessWidget {
  const _PhonePrivacyFooter();

  @override
  Widget build(BuildContext context) {
    return Text(
      'We never display your phone number on your public profile.',
      textAlign: TextAlign.center,
      style: AmoraTextStyles.bodySmall.copyWith(
        color: AppColors.textNeutral.withValues(alpha: .68),
      ),
    );
  }
}
