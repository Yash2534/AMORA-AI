import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/api/phase_two_api_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class DeleteAccountReason {
  const DeleteAccountReason({
    required this.code,
    required this.label,
    required this.icon,
  });

  final String code;
  final String label;
  final IconData icon;
}

const deleteAccountReasons = <DeleteAccountReason>[
  DeleteAccountReason(
    code: 'found_someone',
    label: 'I found someone',
    icon: Icons.favorite_rounded,
  ),
  DeleteAccountReason(
    code: 'taking_a_break',
    label: 'I\u2019m taking a break',
    icon: Icons.pause_circle_rounded,
  ),
  DeleteAccountReason(
    code: 'not_finding_matches',
    label: 'I\u2019m not finding the right matches',
    icon: Icons.person_search_rounded,
  ),
  DeleteAccountReason(
    code: 'privacy_concerns',
    label: 'Privacy concerns',
    icon: Icons.shield_rounded,
  ),
  DeleteAccountReason(
    code: 'too_many_notifications',
    label: 'Too many notifications',
    icon: Icons.notifications_off_rounded,
  ),
  DeleteAccountReason(
    code: 'app_experience_issues',
    label: 'App experience issues',
    icon: Icons.sentiment_dissatisfied_rounded,
  ),
  DeleteAccountReason(
    code: 'other',
    label: 'Other',
    icon: Icons.more_horiz_rounded,
  ),
];

@immutable
class DeleteAccountSelection {
  const DeleteAccountSelection({required this.reason, this.details});

  final DeleteAccountReason reason;
  final String? details;

  String get backendValue => reason.code;
}

typedef DeleteAccountConfirmed =
    Future<AccountDeletionResult> Function(
      DeleteAccountSelection selection,
      String deletionConfirmation,
    );

enum _DeleteAccountStep {
  reason,
  reauthentication,
  confirmation,
  processing,
  completed,
  pendingReview,
  failure,
  unknown,
}

class AmoraaDeleteAccountFlow extends StatefulWidget {
  const AmoraaDeleteAccountFlow({
    super.key,
    required this.onDeleteConfirmed,
    required this.onCancel,
    this.reauthenticateWithPassword,
  });

  final DeleteAccountConfirmed onDeleteConfirmed;
  final VoidCallback onCancel;
  final Future<String> Function(String password)? reauthenticateWithPassword;

  @override
  State<AmoraaDeleteAccountFlow> createState() =>
      _AmoraaDeleteAccountFlowState();
}

class _AmoraaDeleteAccountFlowState extends State<AmoraaDeleteAccountFlow> {
  static const _maximumOtherReasonLength = 240;

  final _otherController = TextEditingController();
  final _passwordController = TextEditingController();
  DeleteAccountReason? _selectedReason;
  _DeleteAccountStep _step = _DeleteAccountStep.reason;
  bool _submitting = false;
  String? _reauthenticationError;
  String? _deletionConfirmation;
  bool _canRetry = false;

  bool get _isOther => _selectedReason?.code == 'other';
  bool get _otherIsValid =>
      !_isOther || _otherController.text.trim().isNotEmpty;
  bool get _canContinue => _selectedReason != null && _otherIsValid;

  @override
  void initState() {
    super.initState();
    _otherController.addListener(_refresh);
  }

  @override
  void dispose() {
    _otherController
      ..removeListener(_refresh)
      ..dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  DeleteAccountSelection get _selection {
    final reason = _selectedReason!;
    final details = reason.code == 'other' ? _otherController.text.trim() : '';
    return DeleteAccountSelection(
      reason: reason,
      details: details.isEmpty ? null : details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: switch (_step) {
        _DeleteAccountStep.reason => _buildReasonStep(),
        _DeleteAccountStep.reauthentication => _buildReauthenticationStep(),
        _DeleteAccountStep.confirmation => _buildConfirmationStep(),
        _DeleteAccountStep.processing => _buildProcessingStep(),
        _DeleteAccountStep.completed => _buildCompletedStep(),
        _DeleteAccountStep.pendingReview => _buildPendingReviewStep(),
        _DeleteAccountStep.failure => _buildFailureStep(),
        _DeleteAccountStep.unknown => _buildUnknownStep(),
      },
    );
  }

  Widget _buildReasonStep() {
    return Column(
      key: const ValueKey('delete-account-reason-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Why are you deleting your account?',
          style: AmoraTextStyles.titleLarge,
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          'Your feedback helps us improve AMORAA.',
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space16),
        for (final reason in deleteAccountReasons) ...[
          _DeleteReasonRow(
            key: ValueKey('delete-reason-${reason.code}'),
            reason: reason,
            selected: reason == _selectedReason,
            onTap: () => setState(() => _selectedReason = reason),
          ),
          if (reason != deleteAccountReasons.last)
            const SizedBox(height: AmoraSpacing.space8),
        ],
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: _isOther
              ? Padding(
                  padding: const EdgeInsets.only(top: AmoraSpacing.space12),
                  child: TextFormField(
                    key: const ValueKey('delete-other-reason-field'),
                    controller: _otherController,
                    maxLength: _maximumOtherReasonLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        _maximumOtherReasonLength,
                      ),
                    ],
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Tell us more',
                      hintText: 'Enter your reason',
                      counterText: '',
                      errorText:
                          _otherController.text.isNotEmpty && !_otherIsValid
                          ? 'Please enter your reason.'
                          : null,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: AmoraSpacing.space20),
        AppPrimaryButton(
          key: const ValueKey('delete-reason-continue'),
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          variant: AppPrimaryButtonVariant.outlined,
          onPressed: _canContinue
              ? () {
                  FocusScope.of(context).unfocus();
                  setState(() => _step = _DeleteAccountStep.reauthentication);
                }
              : null,
        ),
        const SizedBox(height: AmoraSpacing.space8),
        AppPrimaryButton(
          key: const ValueKey('delete-reason-cancel'),
          label: 'Cancel',
          variant: AppPrimaryButtonVariant.text,
          onPressed: widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildReauthenticationStep() {
    final isGoogle = AuthService.instance.currentUser?.authProvider == 'google';
    return Column(
      key: const ValueKey('delete-account-reauthentication-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Confirm it’s you', style: AmoraTextStyles.titleLarge),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          isGoogle
              ? 'Re-authenticate with the Google account linked to AMORAA before deleting your account.'
              : 'Enter your current password before deleting your account.',
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space20),
        if (isGoogle)
          AppPrimaryButton(
            key: const ValueKey('delete-account-google-reauthenticate'),
            label: 'Continue with Google',
            icon: Icons.login_rounded,
            isLoading: _submitting,
            onPressed: _submitting ? null : _reauthenticateWithGoogle,
          )
        else ...[
          TextFormField(
            key: const ValueKey('delete-account-password-field'),
            controller: _passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _reauthenticateWithPassword(),
            decoration: const InputDecoration(labelText: 'Current Password'),
          ),
          const SizedBox(height: AmoraSpacing.space16),
          AppPrimaryButton(
            key: const ValueKey('delete-account-password-reauthenticate'),
            label: 'Continue',
            icon: Icons.lock_outline_rounded,
            isLoading: _submitting,
            onPressed: _submitting ? null : _reauthenticateWithPassword,
          ),
        ],
        if (_reauthenticationError != null) ...[
          const SizedBox(height: AmoraSpacing.space12),
          Text(
            _reauthenticationError!,
            style: AmoraTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: AmoraSpacing.space8),
        AppPrimaryButton(
          label: 'Go back',
          variant: AppPrimaryButtonVariant.text,
          onPressed: _submitting
              ? null
              : () => setState(() => _step = _DeleteAccountStep.reason),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final selection = _selection;
    return Column(
      key: const ValueKey('delete-account-final-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Delete your account permanently?',
          style: AmoraTextStyles.titleLarge,
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          'After you confirm your identity, we will submit your account deletion request. Deletion may require additional processing or review.',
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space16),
        _SelectedReasonSummary(selection: selection),
        const SizedBox(height: AmoraSpacing.space20),
        Semantics(
          button: true,
          label: 'Delete Permanently, destructive action',
          child: AppPrimaryButton(
            key: const ValueKey('settings-delete-permanently'),
            label: 'Delete Permanently',
            icon: Icons.delete_forever_rounded,
            isLoading: _submitting,
            variant: AppPrimaryButtonVariant.destructive,
            onPressed: _submitting ? null : _submitDeletion,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        AppPrimaryButton(
          key: const ValueKey('delete-keep-account'),
          label: 'Keep My Account',
          variant: AppPrimaryButtonVariant.text,
          onPressed: _submitting ? null : widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildFailureStep() {
    return Column(
      key: const ValueKey('delete-account-failure-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            'Deletion could not be completed',
            style: AmoraTextStyles.titleLarge,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          'We were unable to complete your deletion request. Please try again or contact support if the problem continues.',
          style: AmoraTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space16),
        _SelectedReasonSummary(selection: _selection),
        const SizedBox(height: AmoraSpacing.space20),
        if (_canRetry)
          AppPrimaryButton(
            key: const ValueKey('delete-account-retry'),
            label: 'Try Again',
            icon: Icons.refresh_rounded,
            isLoading: _submitting,
            variant: AppPrimaryButtonVariant.destructive,
            onPressed: _submitting
                ? null
                : () => setState(
                    () => _step = _DeleteAccountStep.reauthentication,
                  ),
          ),
        const SizedBox(height: AmoraSpacing.space8),
        AppPrimaryButton(
          key: const ValueKey('delete-failure-cancel'),
          label: 'Cancel',
          variant: AppPrimaryButtonVariant.text,
          onPressed: _submitting ? null : widget.onCancel,
        ),
      ],
    );
  }

  Widget _buildProcessingStep() => _buildLifecycleState(
    key: 'delete-account-processing-step',
    title: 'Processing deletion',
    message:
        'Your account deletion request is being processed. Some deletion steps may take additional time to complete.',
    icon: Icons.hourglass_top_rounded,
  );

  Widget _buildCompletedStep() => _buildLifecycleState(
    key: 'delete-account-completed-step',
    title: 'Deletion completed',
    message: 'Your account deletion has been completed.',
    icon: Icons.check_circle_outline_rounded,
  );

  Widget _buildPendingReviewStep() => _buildLifecycleState(
    key: 'delete-account-pending-review-step',
    title: 'Deletion request received',
    message:
        'Your account deletion request has been received. Some information may require additional review before the process can be fully completed.',
    icon: Icons.info_outline_rounded,
  );

  Widget _buildUnknownStep() => _buildLifecycleState(
    key: 'delete-account-unknown-step',
    title: 'Unable to confirm deletion status',
    message:
        'We could not confirm the current status of your deletion request. Please contact support if the problem continues.',
    icon: Icons.help_outline_rounded,
  );

  Widget _buildLifecycleState({
    required String key,
    required String title,
    required String message,
    required IconData icon,
  }) => Column(
    key: ValueKey(key),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(liveRegion: true, child: Icon(icon, color: AppColors.primary)),
      const SizedBox(height: AmoraSpacing.space12),
      Text(title, style: AmoraTextStyles.titleLarge),
      const SizedBox(height: AmoraSpacing.space8),
      Text(
        message,
        style: AmoraTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
      const SizedBox(height: AmoraSpacing.space20),
      AppPrimaryButton(
        label: 'Close',
        variant: AppPrimaryButtonVariant.text,
        onPressed: widget.onCancel,
      ),
    ],
  );

  Future<void> _reauthenticateWithPassword() async {
    if (_submitting || _passwordController.text.isEmpty) return;
    await _reauthenticate(
      () =>
          widget.reauthenticateWithPassword?.call(_passwordController.text) ??
          AuthService.instance.reauthenticateForAccountDeletionWithPassword(
            _passwordController.text,
          ),
    );
  }

  Future<void> _reauthenticateWithGoogle() => _reauthenticate(
    AuthService.instance.reauthenticateForAccountDeletionWithGoogle,
  );

  Future<void> _reauthenticate(Future<String> Function() action) async {
    setState(() {
      _submitting = true;
      _reauthenticationError = null;
    });
    try {
      final confirmation = await action();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _deletionConfirmation = confirmation;
        _step = _DeleteAccountStep.confirmation;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _reauthenticationError = error.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _reauthenticationError =
            'Please re-authenticate before deleting your account.';
      });
    } finally {
      _passwordController.clear();
    }
  }

  Future<void> _submitDeletion() async {
    if (_submitting || !_canContinue) return;
    setState(() => _submitting = true);
    AccountDeletionResult? result;
    try {
      final confirmation = _deletionConfirmation;
      if (confirmation == null) {
        throw const AuthException(
          'Please re-authenticate before deleting your account.',
        );
      }
      result = await widget.onDeleteConfirmed(_selection, confirmation);
    } on AuthException catch (error) {
      if (!mounted) return;
      final confirmationExpired =
          error.code == 'DELETION_CONFIRMATION_INVALID' ||
          error.code == 'REAUTHENTICATION_REQUIRED';
      setState(() {
        _submitting = false;
        _deletionConfirmation = null;
        if (confirmationExpired) {
          _reauthenticationError =
              'Your identity confirmation has expired. Please confirm your identity again.';
          _step = _DeleteAccountStep.reauthentication;
        } else {
          _step = _DeleteAccountStep.unknown;
        }
      });
      return;
    } catch (_) {
      result = const AccountDeletionResult(
        status: AccountDeletionStatus.unknown,
        canRetry: false,
      );
    }
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _deletionConfirmation = null;
      _canRetry = result!.canRetry;
      _step = switch (result.status) {
        AccountDeletionStatus.verified ||
        AccountDeletionStatus.processing => _DeleteAccountStep.processing,
        AccountDeletionStatus.completed => _DeleteAccountStep.completed,
        AccountDeletionStatus.pendingReview => _DeleteAccountStep.pendingReview,
        AccountDeletionStatus.failed => _DeleteAccountStep.failure,
        AccountDeletionStatus.unknown => _DeleteAccountStep.unknown,
      };
    });
  }
}

class _DeleteReasonRow extends StatelessWidget {
  const _DeleteReasonRow({
    super.key,
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  final DeleteAccountReason reason;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      label: '${reason.label}, ${selected ? 'selected' : 'unselected'}',
      child: Material(
        color: selected
            ? AppColors.tertiary.withValues(alpha: .28)
            : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? AppColors.secondary : AppColors.tertiary,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space16,
                vertical: AmoraSpacing.space12,
              ),
              child: Row(
                children: [
                  Icon(reason.icon, color: AppColors.primary, size: 21),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: Text(
                      reason.label,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space8),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? AppColors.secondary
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedReasonSummary extends StatelessWidget {
  const _SelectedReasonSummary({required this.selection});

  final DeleteAccountSelection selection;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('delete-selected-reason-summary'),
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected reason', style: AmoraTextStyles.labelMedium),
          const SizedBox(height: AmoraSpacing.space4),
          Text(selection.reason.label, style: AmoraTextStyles.titleMedium),
          if (selection.details case final details?) ...[
            const SizedBox(height: AmoraSpacing.space4),
            Text(details, style: AmoraTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
