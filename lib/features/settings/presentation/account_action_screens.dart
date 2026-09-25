import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/chat/data/chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/settings/presentation/widgets/amoraa_delete_account_flow.dart';
import 'package:flutter/material.dart';

class LogoutAccountScreen extends StatelessWidget {
  const LogoutAccountScreen({super.key});

  static const routeName = '/logout';

  @override
  Widget build(BuildContext context) {
    return _AccountActionScaffold(
      title: 'Logout',
      icon: Icons.logout_rounded,
      heading: 'Sign out of this device?',
      description:
          'Your AMORAA profile and preferences remain saved. You can sign '
          'back in whenever you are ready.',
      action: AppPrimaryButton(
        key: const ValueKey('confirm-profile-settings-logout'),
        label: 'Logout securely',
        icon: Icons.logout_rounded,
        onPressed: () {
          AmoraSession.logOut();
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
        },
      ),
    );
  }
}

typedef AccountDeactivationCallback = Future<bool> Function(String password);

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key, this.onDeactivate});

  static const routeName = '/deactivate-account';

  final AccountDeactivationCallback? onDeactivate;

  @override
  State<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  final _passwordController = TextEditingController();
  bool _passwordStep = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeactivation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Are you sure you want to deactivate your account?'),
        content: const Text(
          'Your profile will be hidden until you choose to activate your account again.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('deactivate-confirmation-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('deactivate-confirmation-continue'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _passwordStep = true;
        _error = null;
      });
    }
  }

  Future<void> _deactivate() async {
    if (_submitting) return;
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Password is required.');
      return;
    }
    final callback = widget.onDeactivate;
    if (callback == null) {
      setState(() {
        _error =
            'Couldn’t deactivate your account. No account-deactivation service is connected.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    var deactivated = false;
    try {
      deactivated = await callback(_passwordController.text);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.code == 'CURRENT_PASSWORD_INCORRECT'
            ? 'Incorrect password. Please try again.'
            : error.userMessage;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Couldn’t deactivate your account. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    if (!deactivated) {
      setState(() {
        _submitting = false;
        _error = 'Couldn’t deactivate your account. Please try again.';
      });
      return;
    }
    AmoraSession.logOut();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return _AccountActionScaffold(
      title: 'Deactivate Account',
      icon: Icons.pause_circle_outline_rounded,
      heading: 'Deactivate your account?',
      description: 'Your profile will be hidden and you will be signed out.',
      supporting: const [
        'Your account data remains stored.',
        'Matches, chats, profile information, and membership data are not permanently deleted.',
        'Signing in again will let you explicitly reactivate your profile.',
      ],
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_passwordStep) ...[
            Text(
              'Confirm your password',
              style: AmoraTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              'Enter your password to deactivate your account.',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            TextField(
              key: const ValueKey('deactivate-password-field'),
              controller: _passwordController,
              obscureText: true,
              enabled: !_submitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _deactivate(),
              decoration: const InputDecoration(
                labelText: 'Current password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
          if (_error != null) _AccountActionError(message: _error!),
          const SizedBox(height: AmoraSpacing.space12),
          Semantics(
            button: true,
            label: 'Deactivate AMORAA account',
            child: AppPrimaryButton(
              key: const ValueKey('confirm-deactivate-account'),
              label: 'Deactivate Account',
              icon: Icons.pause_circle_outline_rounded,
              isLoading: _submitting,
              variant: AppPrimaryButtonVariant.outlined,
              onPressed: _submitting
                  ? null
                  : _passwordStep
                  ? _deactivate
                  : _confirmDeactivation,
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          AppPrimaryButton(
            label: 'Keep My Account',
            variant: AppPrimaryButtonVariant.text,
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      showBackAction: false,
    );
  }
}

class DeleteAccountInformationScreen extends StatefulWidget {
  const DeleteAccountInformationScreen({
    super.key,
    this.loadMethods,
    this.sendOtp,
    this.confirmDeletion,
    this.resendCooldown = const Duration(seconds: 45),
  });

  static const routeName = '/delete-account';

  final AccountDeletionMethodsLoader? loadMethods;
  final AccountDeletionOtpSender? sendOtp;
  final AccountDeletionConfirmer? confirmDeletion;
  final Duration resendCooldown;

  @override
  State<DeleteAccountInformationScreen> createState() =>
      _DeleteAccountInformationScreenState();
}

class _DeleteAccountInformationScreenState
    extends State<DeleteAccountInformationScreen> {
  Future<void> _completeDeletion() async {
    await _clearDeletedAccountState();
    if (!mounted) return;
    AmoraSession.logOut();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  Future<void> _clearDeletedAccountState() async {
    for (final clear in <Future<void> Function()>[
      ChatRepository.instance.clearForAccountDeletion,
      LocalProfileRepository.instance.clearForAccountDeletion,
      LocalOnboardingRepository.instance.clearForAccountDeletion,
    ]) {
      try {
        await clear();
      } catch (_) {
        // A server-confirmed deletion still requires the local session to end.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AccountActionScaffold(
      title: 'Delete Account',
      icon: Icons.delete_forever_rounded,
      heading: 'Permanent account deletion',
      description:
          'Deleting your account is permanent. Continue only when you are ready to verify your identity with a one-time code.',
      supporting: const [
        'Your account will be removed from the active-user experience immediately after successful verification.',
        'Billing managed by an app store must be cancelled through that store.',
        'AMORAA will never treat a local logout or an unverified code as successful deletion.',
      ],
      action: AmoraaDeleteAccountFlow(
        onDeleted: _completeDeletion,
        onCancel: () => Navigator.of(context).maybePop(),
        loadMethods: widget.loadMethods,
        sendOtp: widget.sendOtp,
        confirmDeletion: widget.confirmDeletion,
        resendCooldown: widget.resendCooldown,
      ),
      showBackAction: false,
    );
  }
}

class _AccountActionError extends StatelessWidget {
  const _AccountActionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AmoraSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: .38)),
        ),
        child: Text(
          message,
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.text,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AccountActionScaffold extends StatelessWidget {
  const _AccountActionScaffold({
    required this.title,
    required this.icon,
    required this.heading,
    required this.description,
    required this.action,
    this.supporting = const [],
    this.showBackAction = true,
  });

  final String title;
  final IconData icon;
  final String heading;
  final String description;
  final List<String> supporting;
  final bool showBackAction;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AmoraAppBar(
        title: title,
        onBack: () => Navigator.of(context).maybePop(),
        maxContentWidth: 560,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: ListView(
            padding: const EdgeInsets.all(AmoraSpacing.space20),
            children: [
              PremiumCard(
                radius: AmoraRadius.extraLarge,
                padding: const EdgeInsets.all(AmoraSpacing.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.tertiary),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 30),
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space20),
                    Text(heading, style: AmoraTextStyles.headlineSmall),
                    const SizedBox(height: AmoraSpacing.space8),
                    Text(
                      description,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    if (supporting.isNotEmpty) ...[
                      const SizedBox(height: AmoraSpacing.space16),
                      for (final item in supporting)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AmoraSpacing.space12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppColors.primary,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: AmoraSpacing.space8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: AmoraTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: AmoraSpacing.space20),
                    action,
                    if (showBackAction) ...[
                      const SizedBox(height: AmoraSpacing.space8),
                      AppPrimaryButton(
                        label: 'Go back',
                        variant: AppPrimaryButtonVariant.text,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
