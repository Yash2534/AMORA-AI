import 'dart:async';

import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/widgets/amora_otp_input.dart';
import 'package:flutter/material.dart';

typedef AccountDeletionMethodsLoader =
    Future<List<AccountDeletionMethod>> Function();
typedef AccountDeletionOtpSender = Future<void> Function(String channel);
typedef AccountDeletionConfirmer =
    Future<void> Function(String channel, String otp);

enum _DeleteAccountStep { warning, method, otp }

class AmoraaDeleteAccountFlow extends StatefulWidget {
  const AmoraaDeleteAccountFlow({
    super.key,
    required this.onDeleted,
    required this.onCancel,
    this.loadMethods,
    this.sendOtp,
    this.confirmDeletion,
    this.resendCooldown = const Duration(seconds: 45),
  });

  final Future<void> Function() onDeleted;
  final VoidCallback onCancel;
  final AccountDeletionMethodsLoader? loadMethods;
  final AccountDeletionOtpSender? sendOtp;
  final AccountDeletionConfirmer? confirmDeletion;
  final Duration resendCooldown;

  @override
  State<AmoraaDeleteAccountFlow> createState() =>
      _AmoraaDeleteAccountFlowState();
}

class _AmoraaDeleteAccountFlowState extends State<AmoraaDeleteAccountFlow> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpNodes = List.generate(6, (_) => FocusNode());
  _DeleteAccountStep _step = _DeleteAccountStep.warning;
  List<AccountDeletionMethod> _methods = const [];
  AccountDeletionMethod? _selected;
  bool _busy = false;
  String? _error;
  Timer? _timer;
  int _cooldownSeconds = 0;

  String get _otp =>
      _otpControllers.map((controller) => controller.text).join();
  bool get _otpComplete => RegExp(r'^\d{6}$').hasMatch(_otp);

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    child: switch (_step) {
      _DeleteAccountStep.warning => _warningStep(),
      _DeleteAccountStep.method => _methodStep(),
      _DeleteAccountStep.otp => _otpStep(),
    },
  );

  Widget _warningStep() => Column(
    key: const ValueKey('delete-account-warning-step'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('This action is permanent', style: AmoraTextStyles.titleLarge),
      const SizedBox(height: AmoraSpacing.space8),
      Text(
        'Your active AMORAA account, profile, matches, and private account data will no longer be available. This cannot be undone.',
        style: AmoraTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      const SizedBox(height: AmoraSpacing.space20),
      AppPrimaryButton(
        key: const ValueKey('settings-delete-permanently'),
        label: 'Delete Account',
        icon: Icons.delete_forever_rounded,
        variant: AppPrimaryButtonVariant.destructive,
        onPressed: _busy ? null : _confirmIntent,
      ),
      const SizedBox(height: AmoraSpacing.space8),
      AppPrimaryButton(
        key: const ValueKey('delete-keep-account'),
        label: 'Keep My Account',
        variant: AppPrimaryButtonVariant.text,
        onPressed: _busy ? null : widget.onCancel,
      ),
    ],
  );

  Widget _methodStep() => Column(
    key: const ValueKey('delete-account-method-step'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Verify your identity', style: AmoraTextStyles.titleLarge),
      const SizedBox(height: AmoraSpacing.space8),
      Text(
        'Send a verification code to a registered destination:',
        style: AmoraTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AmoraSpacing.space16),
      RadioGroup<AccountDeletionMethod>(
        groupValue: _selected,
        onChanged: _busy
            ? (_) {}
            : (value) => setState(() => _selected = value),
        child: Column(
          children: [
            for (final method in _methods)
              RadioListTile<AccountDeletionMethod>(
                key: ValueKey('delete-method-${method.channel.toLowerCase()}'),
                value: method,
                enabled: !_busy,
                activeColor: AppColors.primary,
                title: Text(method.channel == 'EMAIL' ? 'Email' : 'Phone'),
                subtitle: Text(method.maskedDestination),
              ),
          ],
        ),
      ),
      if (_error != null) _errorText(),
      const SizedBox(height: AmoraSpacing.space16),
      AppPrimaryButton(
        key: const ValueKey('delete-account-send-otp'),
        label: 'Send OTP',
        icon: Icons.mark_email_read_outlined,
        isLoading: _busy,
        onPressed: _selected == null || _busy ? null : _sendOtp,
      ),
      AppPrimaryButton(
        label: 'Go back',
        variant: AppPrimaryButtonVariant.text,
        onPressed: _busy
            ? null
            : () => setState(() => _step = _DeleteAccountStep.warning),
      ),
    ],
  );

  Widget _otpStep() => Column(
    key: const ValueKey('delete-account-otp-step'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Enter verification code', style: AmoraTextStyles.titleLarge),
      const SizedBox(height: AmoraSpacing.space8),
      Text(
        'We sent a six-digit code to ${_selected?.maskedDestination ?? 'your registered destination'}.',
        style: AmoraTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AmoraSpacing.space20),
      AmoraOtpInput(
        key: const ValueKey('delete-account-otp-input'),
        controllers: _otpControllers,
        nodes: _otpNodes,
        enabled: !_busy,
        hasError: _error != null,
        onChanged: () => setState(() => _error = null),
        onPaste: (_) {},
      ),
      if (_error != null) _errorText(),
      const SizedBox(height: AmoraSpacing.space20),
      AppPrimaryButton(
        key: const ValueKey('delete-account-verify-delete'),
        label: 'Verify & Delete Account',
        icon: Icons.delete_forever_rounded,
        variant: AppPrimaryButtonVariant.destructive,
        isLoading: _busy,
        onPressed: _otpComplete && !_busy ? _verifyAndDelete : null,
      ),
      const SizedBox(height: AmoraSpacing.space8),
      AppPrimaryButton(
        key: const ValueKey('delete-account-resend-otp'),
        label: _cooldownSeconds > 0
            ? 'Resend in ${_cooldownSeconds}s'
            : 'Resend code',
        variant: AppPrimaryButtonVariant.text,
        onPressed: _busy || _cooldownSeconds > 0 ? null : _sendOtp,
      ),
    ],
  );

  Widget _errorText() => Padding(
    padding: const EdgeInsets.only(top: AmoraSpacing.space12),
    child: Text(
      _error!,
      key: const ValueKey('delete-account-error'),
      style: AmoraTextStyles.bodySmall.copyWith(color: AppColors.error),
    ),
  );

  Future<void> _confirmIntent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Are you sure you want to permanently delete your account?',
        ),
        content: const Text('This action is permanent and cannot be undone.'),
        actions: [
          TextButton(
            key: const ValueKey('delete-confirmation-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('delete-confirmation-continue'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final methods =
          await (widget.loadMethods ??
              PhaseTwoApiService.instance.accountDeletionMethods)();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _methods = methods;
        _selected = methods.length == 1 ? methods.first : null;
        _step = _DeleteAccountStep.method;
        if (methods.isEmpty) {
          _error =
              'No verified email or phone number is available. Please use an approved account recovery path.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageFor(error);
      });
    }
  }

  Future<void> _sendOtp() async {
    final selected = _selected;
    if (selected == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.sendOtp ??
          PhaseTwoApiService.instance.sendAccountDeletionOtp)(selected.channel);
      if (!mounted) return;
      _clearOtp();
      setState(() {
        _busy = false;
        _step = _DeleteAccountStep.otp;
      });
      _startCooldown();
      _otpNodes.first.requestFocus();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageFor(error);
      });
    }
  }

  Future<void> _verifyAndDelete() async {
    final selected = _selected;
    if (selected == null || !_otpComplete || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await (widget.confirmDeletion ??
          ((channel, otp) => PhaseTwoApiService.instance.confirmAccountDeletion(
            channel: channel,
            otp: otp,
          )))(selected.channel, _otp);
      await widget.onDeleted();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _messageFor(error);
      });
    }
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldownSeconds = widget.resendCooldown.inSeconds;
    if (_cooldownSeconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
        return;
      }
      setState(() => _cooldownSeconds -= 1);
    });
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  String _messageFor(Object error) {
    if (error is AuthException) {
      return switch (error.code) {
        'OTP_INVALID' => 'Invalid verification code.',
        'OTP_EXPIRED' =>
          'This verification code has expired. Please request a new code.',
        'OTP_MAX_ATTEMPTS' ||
        'RATE_LIMITED' => 'Too many attempts. Please try again later.',
        'DELETION_VERIFICATION_UNAVAILABLE' || 'DELETION_CHANNEL_UNAVAILABLE' =>
          'No verified email or phone number is available. Please use an approved account recovery path.',
        _ => error.userMessage,
      };
    }
    return 'Unable to complete account deletion. Please try again.';
  }
}
