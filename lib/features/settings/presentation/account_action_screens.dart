import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/auth/presentation/login_screen.dart';
import 'package:amora_ai/features/chat/data/local_chat_repository.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
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

typedef AccountDeactivationCallback = Future<bool> Function();
typedef AccountDeletionCallback = Future<bool> Function();

class DeactivateAccountScreen extends StatefulWidget {
  const DeactivateAccountScreen({super.key, this.onDeactivate});

  static const routeName = '/deactivate-account';

  final AccountDeactivationCallback? onDeactivate;

  @override
  State<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  bool _understood = false;
  bool _submitting = false;
  String? _error;

  Future<void> _deactivate() async {
    if (!_understood || _submitting) return;
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
      deactivated = await callback();
    } catch (_) {
      deactivated = false;
    }
    if (!mounted) return;
    if (!deactivated) {
      setState(() {
        _submitting = false;
        _error = 'Couldn’t deactivate your account. Please try again.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return _AccountActionScaffold(
      title: 'Deactivate Account',
      icon: Icons.pause_circle_outline_rounded,
      heading: 'Deactivate your account?',
      description:
          'Your profile will be hidden and your account will be paused. You can reactivate it later by signing in again.',
      supporting: const [
        'Your account data remains stored.',
        'Matches, chats, profile information, and membership data are not permanently deleted.',
        'Reactivation requires a connected account-status service.',
      ],
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            key: const ValueKey('deactivate-account-understood'),
            contentPadding: EdgeInsets.zero,
            value: _understood,
            onChanged: _submitting
                ? null
                : (value) => setState(() {
                    _understood = value ?? false;
                    _error = null;
                  }),
            title: const Text(
              'I understand that my profile will be hidden temporarily.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
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
              onPressed: _understood && !_submitting ? _deactivate : null,
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
  const DeleteAccountInformationScreen({super.key, this.onDeleteAccount});

  static const routeName = '/delete-account';

  final AccountDeletionCallback? onDeleteAccount;

  @override
  State<DeleteAccountInformationScreen> createState() =>
      _DeleteAccountInformationScreenState();
}

class _DeleteAccountInformationScreenState
    extends State<DeleteAccountInformationScreen> {
  final _confirmationController = TextEditingController();
  bool _confirmationStep = false;
  bool _submitting = false;
  String? _error;

  bool get _confirmed => _confirmationController.text.trim() == 'DELETE';

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(_refresh);
  }

  @override
  void dispose() {
    _confirmationController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() => _error = null);
  }

  Future<void> _deletePermanently() async {
    if (!_confirmed || _submitting) return;
    final callback = widget.onDeleteAccount;
    if (callback == null) {
      setState(() {
        _error =
            'Couldn’t delete your account. Your account has not been deleted because no delete-account service is connected.';
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    var deleted = false;
    try {
      deleted = await callback();
    } catch (_) {
      deleted = false;
    }
    if (!mounted) return;
    if (!deleted) {
      setState(() {
        _submitting = false;
        _error =
            'Couldn’t delete your account. Your account has not been deleted. Please try again.';
      });
      return;
    }
    await _clearDeletedAccountState();
    if (!mounted) return;
    AmoraSession.logOut();
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  Future<void> _clearDeletedAccountState() async {
    for (final clear in <Future<void> Function()>[
      LocalChatRepository.instance.clearForAccountDeletion,
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
      heading: _confirmationStep
          ? 'Type DELETE to continue'
          : 'Delete your account permanently?',
      description: _confirmationStep
          ? 'This deliberate confirmation helps prevent accidental deletion.'
          : 'This action cannot be undone. Profile and account access will be removed only after the account service confirms deletion.',
      supporting: const [
        'Existing matches, chats, and account data may be deleted according to the active backend policy.',
        'Billing managed by an app store must be cancelled through that store.',
        'AMORAA will not treat a local logout as successful deletion.',
      ],
      action: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_confirmationStep) ...[
            TextField(
              key: const ValueKey('settings-delete-confirmation-field'),
              controller: _confirmationController,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Type DELETE',
                hintText: 'DELETE',
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
          ],
          if (_error != null) _AccountActionError(message: _error!),
          if (_error != null) const SizedBox(height: AmoraSpacing.space12),
          Semantics(
            button: true,
            label: 'Permanently delete AMORAA account',
            child: AppPrimaryButton(
              key: ValueKey(
                _confirmationStep
                    ? 'settings-delete-permanently'
                    : 'settings-delete-continue',
              ),
              label: _confirmationStep
                  ? 'Delete Permanently'
                  : 'Continue to confirmation',
              icon: _confirmationStep
                  ? Icons.delete_forever_rounded
                  : Icons.arrow_forward_rounded,
              isLoading: _submitting,
              variant: _confirmationStep
                  ? AppPrimaryButtonVariant.destructive
                  : AppPrimaryButtonVariant.outlined,
              onPressed: _submitting
                  ? null
                  : _confirmationStep
                  ? (_confirmed ? _deletePermanently : null)
                  : () => setState(() => _confirmationStep = true),
            ),
          ),
          const SizedBox(height: AmoraSpacing.space8),
          AppPrimaryButton(
            label: 'Cancel',
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
      appBar: AppBar(title: Text(title)),
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
                                  color: AppColors.secondary,
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
