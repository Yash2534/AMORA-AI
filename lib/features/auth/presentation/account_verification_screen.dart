import 'dart:async';

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef MobileOtpRequester = Future<void> Function(String phoneNumber);
typedef MobileOtpVerifier =
    Future<void> Function(String phoneNumber, String code);

enum MobileVerificationStep { phoneEntry, otpEntry, success }

/// Route arguments deliberately contain only phone data. Email verification is
/// handled by its own backend flow and is not part of this screen anymore.
@immutable
class MobileVerificationArguments {
  const MobileVerificationArguments({
    this.phoneNumber,
    this.country = const MobileCountry(
      code: 'IN',
      name: 'India',
      dialCode: '+91',
    ),
  });

  final String? phoneNumber;
  final MobileCountry country;
}

class MobileVerificationException implements Exception {
  const MobileVerificationException(this.code);

  final String code;
}

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({
    super.key,
    this.arguments,
    this.requestOtp,
    this.verifyOtp,
    this.resendSeconds = 30,
  });

  static const routeName = '/account-verification';

  final MobileVerificationArguments? arguments;
  final MobileOtpRequester? requestOtp;
  final MobileOtpVerifier? verifyOtp;
  final int resendSeconds;

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  static const _codeLength = 6;
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final _otpNodes = List.generate(_codeLength, (_) => FocusNode());
  Timer? _timer;
  late MobileCountry _country;
  MobileVerificationStep _step = MobileVerificationStep.phoneEntry;
  String? _error;
  String? _confirmation;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isResendingOtp = false;
  int _secondsLeft = 0;
  bool _initialized = false;

  String get _localNumber =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');
  String get _normalizedPhone => '${_country.dialCode}$_localNumber';
  String get _otp =>
      _otpControllers.map((controller) => controller.text).join();
  bool get _isCompleteOtp => RegExp(r'^\d{6}$').hasMatch(_otp);
  bool get _isBusy => _isSendingOtp || _isVerifyingOtp || _isResendingOtp;
  bool get _isValidPhone =>
      _country.code == 'IN' && RegExp(r'^[6-9]\d{9}$').hasMatch(_localNumber);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final routeArguments = ModalRoute.of(context)?.settings.arguments;
    final arguments =
        widget.arguments ??
        (routeArguments is MobileVerificationArguments ? routeArguments : null);
    _country =
        arguments?.country ??
        const MobileCountry(code: 'IN', name: 'India', dialCode: '+91');
    _phoneController.text = _nationalNumber(
      arguments?.phoneNumber ??
          LocalProfileRepository.instance.profile.phoneNumber,
    );
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController
      ..removeListener(_onPhoneChanged)
      ..dispose();
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: switch (_step) {
          MobileVerificationStep.phoneEntry => _phoneEntry(context),
          MobileVerificationStep.otpEntry => _otpEntry(context),
          MobileVerificationStep.success => _success(context),
        },
      ),
    );
  }

  Widget _phoneEntry(BuildContext context) {
    return AmoraAuthShell(
      key: const ValueKey('mobile-verification-phone-step'),
      title: 'Verify your mobile number',
      subtitle:
          "We'll send a 6-digit verification code to confirm your number.",
      stepLabel: 'Mobile verification',
      alignStepLabelRight: true,
      compactLayout: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UnifiedMobileNumberField(
            controller: _phoneController,
            country: _country,
            enabled: !_isBusy,
            hasError: _error != null,
            onCountryTap: _showCountrySelector,
            onSubmitted: (_) => _sendOtp(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AmoraSpacing.space12),
            Semantics(
              liveRegion: true,
              child: AuthInlineAlert(message: _error!),
            ),
          ],
          const SizedBox(height: AmoraSpacing.space16),
          AuthPrimaryButton(
            key: const ValueKey('send-otp-button'),
            label: _isSendingOtp ? 'Sending OTP…' : 'Send OTP',
            icon: Icons.sms_outlined,
            isLoading: _isSendingOtp,
            onPressed: _isValidPhone && !_isBusy ? _sendOtp : null,
          ),
          const SizedBox(height: AmoraSpacing.space12),
          const AuthTrustNote(
            text: 'Standard SMS charges may apply.',
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _otpEntry(BuildContext context) {
    return AmoraAuthShell(
      key: const ValueKey('mobile-verification-otp-step'),
      title: 'Enter verification code',
      subtitle: 'We sent a 6-digit code to ${_maskedPhone()}',
      stepLabel: 'Mobile verification',
      alignStepLabelRight: true,
      compactLayout: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmoraOtpInput(
            key: const ValueKey('account-verification-otp'),
            controllers: _otpControllers,
            nodes: _otpNodes,
            hasError: _error != null,
            enabled: !_isBusy,
            onChanged: () => setState(() {
              _error = null;
              _confirmation = null;
            }),
            onPaste: _pasteOtp,
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
          Text(
            "Didn't receive the code?",
            textAlign: TextAlign.center,
            style: AmoraTextStyles.bodyMedium,
          ),
          const SizedBox(height: AmoraSpacing.space4),
          Center(child: _resendAction()),
          const SizedBox(height: AmoraSpacing.space4),
          AppPrimaryButton(
            key: const ValueKey('verification-change-mobile'),
            label: 'Change mobile number',
            variant: AppPrimaryButtonVariant.text,
            size: AmoraButtonSize.compact,
            fullWidth: false,
            onPressed: _isBusy ? null : _changeMobileNumber,
          ),
          const SizedBox(height: AmoraSpacing.space16),
          AuthPrimaryButton(
            key: const ValueKey('verify-mobile-button'),
            label: _isVerifyingOtp ? 'Verifying…' : 'Verify Mobile Number',
            icon: Icons.verified_user_outlined,
            isLoading: _isVerifyingOtp,
            onPressed: _isCompleteOtp && !_isBusy ? _verifyOtp : null,
          ),
        ],
      ),
    );
  }

  Widget _success(BuildContext context) {
    return AmoraAuthShell(
      key: const ValueKey('mobile-verification-success-step'),
      title: 'Verification complete',
      subtitle: 'Your mobile number has been verified successfully.',
      stepLabel: 'Mobile verification',
      alignStepLabelRight: true,
      compactLayout: true,
      child: Semantics(
        liveRegion: true,
        label: 'Mobile number verification complete',
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: .86, end: 1),
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: const Icon(
                Icons.verified_rounded,
                size: 56,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text(
              _maskedPhone(),
              style: AmoraTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resendAction() {
    if (_isResendingOtp) {
      return Semantics(
        liveRegion: true,
        label: 'Resending verification code',
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
      onPressed: _isVerifyingOtp ? null : () => _sendOtp(resend: true),
    );
  }

  void _onPhoneChanged() {
    if (mounted) {
      setState(() => _error = null);
    }
  }

  void _pasteOtp(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != _codeLength) return;
    for (var index = 0; index < _codeLength; index++) {
      _otpControllers[index].text = digits[index];
    }
  }

  Future<void> _showCountrySelector() async {
    // The current signup API accepts Indian national mobile numbers only.
    final country = await showModalBottomSheet<MobileCountry>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: AmoraSpacing.bottomSheet,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select country code', style: AmoraTextStyles.titleMedium),
            const SizedBox(height: AmoraSpacing.space12),
            Semantics(
              selected: true,
              label: 'India, +91, selected',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: AmoraSpacing.space8,
                leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                title: const Text('India'),
                trailing: const Text('+91'),
                onTap: () => Navigator.pop(
                  context,
                  const MobileCountry(
                    code: 'IN',
                    name: 'India',
                    dialCode: '+91',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (country != null && mounted) {
      setState(() => _country = country);
    }
  }

  Future<void> _sendOtp({bool resend = false}) async {
    if (_isBusy || (resend && _secondsLeft > 0) || !resend && !_isValidPhone) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final request =
        widget.requestOtp ?? AuthService.instance.resendVerification;
    setState(() {
      if (resend) {
        _isResendingOtp = true;
      } else {
        _isSendingOtp = true;
      }
      _error = null;
      _confirmation = null;
    });
    try {
      await request(_normalizedPhone);
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _isResendingOtp = false;
        _step = MobileVerificationStep.otpEntry;
        _confirmation = resend
            ? 'A new verification code has been sent.'
            : null;
      });
      _startCountdown();
      _otpNodes.first.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _isResendingOtp = false;
        _error = _messageFor(error, sending: true, resend: resend);
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_isBusy || !_isCompleteOtp) {
      return;
    }
    final verify = widget.verifyOtp ?? AuthService.instance.verifyAccount;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isVerifyingOtp = true;
      _error = null;
      _confirmation = null;
    });
    try {
      await verify(_normalizedPhone, _otp);
      if (!mounted) return;
      _timer?.cancel();
      AmoraSession.logIn();
      LocalOnboardingRepository.instance.update(
        LocalOnboardingRepository.instance.state.copyWith(
          accountVerified: true,
          stage: OnboardingStage.age,
        ),
      );
      setState(() {
        _isVerifyingOtp = false;
        _step = MobileVerificationStep.success;
      });
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        ProfileOnboardingFlow.routeName,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isVerifyingOtp = false;
        _error = _messageFor(error);
      });
    }
  }

  void _changeMobileNumber() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _step = MobileVerificationStep.phoneEntry;
      _secondsLeft = 0;
      _error = null;
      _confirmation = null;
    });
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

  String _maskedPhone() {
    final number = _localNumber;
    if (number.length < 4) {
      return _normalizedPhone;
    }
    return '${_country.dialCode} ${number.substring(0, 2)}••• ••${number.substring(number.length - 3)}';
  }

  String _nationalNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length > 10) {
      return digits.substring(2);
    }
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  String _messageFor(
    Object error, {
    bool sending = false,
    bool resend = false,
  }) {
    final code = error is AuthException
        ? error.code
        : error is MobileVerificationException
        ? error.code
        : null;
    return switch (code) {
      'INVALID_PHONE_NUMBER' =>
        'Invalid mobile number. Check the number and try again.',
      'OTP_INVALID' => "Incorrect code. That code doesn't match. Try again.",
      'OTP_EXPIRED' => 'Code expired. Request a new verification code.',
      'OTP_ATTEMPTS_EXCEEDED' ||
      'OTP_MAX_ATTEMPTS' => 'Too many attempts. Please request a new code.',
      'RATE_LIMITED' => 'Too many requests. Please try again shortly.',
      'NETWORK_ERROR' =>
        resend
            ? "Couldn't resend the code. Please try again."
            : 'Check your connection and try again.',
      'SERVICE_UNAVAILABLE' =>
        'Verification unavailable. Please try again shortly.',
      _ =>
        sending
            ? (resend
                  ? "Couldn't resend the code. Please try again."
                  : "Couldn't send the code. Please try again.")
            : 'Verification unavailable. Please try again shortly.',
    };
  }
}

@immutable
class MobileCountry {
  const MobileCountry({
    required this.code,
    required this.name,
    required this.dialCode,
  });

  final String code;
  final String name;
  final String dialCode;
}

class _UnifiedMobileNumberField extends StatefulWidget {
  const _UnifiedMobileNumberField({
    required this.controller,
    required this.country,
    required this.enabled,
    required this.hasError,
    required this.onCountryTap,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final MobileCountry country;
  final bool enabled;
  final bool hasError;
  final VoidCallback onCountryTap;
  final ValueChanged<String> onSubmitted;

  @override
  State<_UnifiedMobileNumberField> createState() =>
      _UnifiedMobileNumberFieldState();
}

class _UnifiedMobileNumberFieldState extends State<_UnifiedMobileNumberField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant _UnifiedMobileNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final filled = widget.controller.text.isNotEmpty;
    final borderColor = widget.hasError
        ? AppColors.primary
        : focused
        ? AppColors.secondary
        : filled
        ? AppColors.primary.withValues(alpha: .42)
        : AppColors.tertiary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mobile number',
          style: AmoraTextStyles.labelLarge.copyWith(
            color: focused ? AppColors.primary : AppColors.text,
            fontSize: 13,
            letterSpacing: .1,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final narrow = availableWidth < 260;
            final countryWidth = (availableWidth * .36).clamp(84.0, 108.0);
            final phoneIconWidth = (availableWidth * .14).clamp(34.0, 42.0);
            return AnimatedContainer(
              key: const ValueKey('unified-mobile-number-field'),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: AmoraSpacing.controlHeight,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.surface
                    : AppColors.tertiary.withValues(alpha: .26),
                borderRadius: AmoraRadius.input,
                border: Border.all(
                  color: borderColor,
                  width: focused ? 1.5 : 1,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: .10),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    button: true,
                    enabled: widget.enabled,
                    label:
                        'Select country code. ${widget.country.name}, ${widget.country.dialCode}',
                    child: InkWell(
                      key: const ValueKey('country-code-selector'),
                      onTap: widget.enabled ? widget.onCountryTap : null,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(15),
                      ),
                      child: SizedBox(
                        width: countryWidth,
                        child: SizedBox(
                          height: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AmoraSpacing.space8,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Text(
                                        '🇮🇳',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    widget.country.dialCode,
                                    style: AmoraTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 1,
                      height: 28,
                      child: ColoredBox(
                        color: borderColor.withValues(
                          alpha: focused ? .72 : .82,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      textField: true,
                      label: 'Mobile number',
                      child: TextFormField(
                        key: const ValueKey('mobile-number-field'),
                        controller: widget.controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [
                          AutofillHints.telephoneNumberNational,
                        ],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onFieldSubmitted: widget.onSubmitted,
                        style: AmoraTextStyles.bodyLarge.copyWith(
                          fontSize: narrow ? 15 : 16,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlignVertical: TextAlignVertical.center,
                        cursorColor: AppColors.secondary,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: '9723653140',
                          hintStyle: AmoraTextStyles.bodyLarge.copyWith(
                            color: AppColors.text.withValues(alpha: .48),
                          ),
                          prefixIcon: const Center(
                            child: Icon(
                              Icons.phone_iphone_rounded,
                              color: AppColors.primary,
                              size: 19,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints.tightFor(
                            width: phoneIconWidth,
                            height: AmoraSpacing.controlHeight,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            right: AmoraSpacing.space8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
