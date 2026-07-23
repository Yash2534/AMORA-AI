import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_inputs.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
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
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _nodes = List.generate(6, (_) => FocusNode());
  String? _error;
  bool _loading = false;

  String get _code {
    final firstValue = _controllers.first.text.replaceAll(RegExp(r'\D'), '');
    if (firstValue.length >= 6) return firstValue.substring(0, 6);
    return _controllers
        .map((item) => item.text.replaceAll(RegExp(r'\D'), ''))
        .where((value) => value.isNotEmpty)
        .map((value) => value.substring(0, 1))
        .join();
  }

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                constraints.maxWidth < 390 ? 16 : 24,
                12,
                constraints.maxWidth < 390 ? 16 : 24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 36,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton.filledTonal(
                        tooltip: 'Go back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.activeContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify your account',
                      textAlign: TextAlign.center,
                      style: AmoraTextStyles.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This frontend demo uses a local code. No message is sent and no server verification is claimed.',
                      textAlign: TextAlign.center,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PremiumCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Six-digit code',
                            style: AmoraTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          AmoraOtpBoxes(
                            controllers: _controllers,
                            nodes: _nodes,
                            onChanged: () => setState(() => _error = null),
                            onPaste: _paste,
                          ),
                          if (_error case final message?) ...[
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                message,
                                style: AmoraTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(
                                AmoraRadius.medium,
                              ),
                            ),
                            child: const Text(
                              'Local demo code: 246810',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppPrimaryButton(
                            key: const Key('verify-account-button'),
                            label: 'Verify and continue',
                            icon: Icons.verified_rounded,
                            isLoading: _loading,
                            onPressed: _code.length == 6 && !_loading
                                ? _verify
                                : null,
                          ),
                          const SizedBox(height: 8),
                          AppPrimaryButton(
                            label: 'Resend local code',
                            variant: AppPrimaryButtonVariant.text,
                            onPressed: () => setState(() => _error = null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space24),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Change email or phone'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _paste(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return;
    for (var index = 0; index < 6; index++) {
      _controllers[index].text = digits[index];
    }
    _nodes.last.requestFocus();
    setState(() => _error = null);
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final valid = LocalOnboardingRepository.instance.verifyCode(_code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!valid) {
      setState(() => _error = 'That local demo code is not valid.');
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      ProfileOnboardingFlow.routeName,
      (route) => false,
    );
  }
}
