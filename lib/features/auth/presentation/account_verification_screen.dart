import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/auth/presentation/widgets/auth_presentation.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/presentation/profile_onboarding_flow.dart';
import 'package:flutter/material.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  static const routeName = '/account-verification';

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
  String? _error;
  bool _loading = false;

  String get _code => _controllers.map((controller) => controller.text).join();

  @override
  void dispose() {
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
    return AmoraAuthShell(
      title: 'Enter verification code',
      subtitle: 'Enter the six-digit code for your AMORAA account.',
      stepLabel: 'Account verification',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmoraOtpInput(
            key: const ValueKey('account-verification-otp'),
            controllers: _controllers,
            nodes: _nodes,
            hasError: _error != null,
            enabled: !_loading,
            onChanged: () {
              if (_error != null) setState(() => _error = null);
            },
            onPaste: _paste,
          ),
          if (_error != null) ...[
            const SizedBox(height: AmoraSpacing.space12),
            AuthInlineAlert(message: _error!),
          ],
          const SizedBox(height: AmoraSpacing.space16),
          const AuthInlineAlert(
            message:
                'Use the verification code provided for this account. Codes '
                'are never requested by AMORAA support.',
          ),
          const SizedBox(height: AmoraSpacing.space20),
          AuthPrimaryButton(
            key: const ValueKey('verify-account-button'),
            label: _loading ? 'Verifying…' : 'Verify and continue',
            icon: Icons.verified_user_outlined,
            isLoading: _loading,
            onPressed: _code.length == _codeLength && !_loading
                ? _verify
                : null,
          ),
          const SizedBox(height: AmoraSpacing.space8),
          AppPrimaryButton(
            label: 'Change email',
            variant: AppPrimaryButtonVariant.text,
            onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  void _paste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _codeLength) return;
    for (var index = 0; index < _codeLength; index++) {
      _controllers[index].text = digits[index];
    }
    setState(() => _error = null);
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final valid = LocalOnboardingRepository.instance.verifyCode(_code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!valid) {
      setState(() => _error = 'That code is not valid.');
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      ProfileOnboardingFlow.routeName,
      (route) => false,
    );
  }
}
