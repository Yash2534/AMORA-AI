import 'dart:async';

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AmoraaProfileAction { unlike, removeSuperLike, unsave, block, unblock }

extension AmoraaProfileActionCopy on AmoraaProfileAction {
  String title(String profileName) => switch (this) {
    AmoraaProfileAction.unlike => 'Unlike $profileName?',
    AmoraaProfileAction.removeSuperLike =>
      'Remove Super Like from $profileName?',
    AmoraaProfileAction.unsave => 'Remove $profileName from Saved Profiles?',
    AmoraaProfileAction.block => 'Block $profileName?',
    AmoraaProfileAction.unblock => 'Unblock $profileName?',
  };

  String get description => switch (this) {
    AmoraaProfileAction.unlike =>
      'This profile will be removed from your Likes list.',
    AmoraaProfileAction.removeSuperLike =>
      'This profile will be removed from your Super Likes list.',
    AmoraaProfileAction.unsave => 'You can save this profile again later.',
    AmoraaProfileAction.block =>
      'You will no longer see each other in discovery, and they may be removed from your active interactions according to AMORAA\u2019s existing block behavior.',
    AmoraaProfileAction.unblock =>
      'This profile may become visible to you again based on your discovery and privacy settings.',
  };

  String get confirmLabel => switch (this) {
    AmoraaProfileAction.unlike => 'Unlike',
    AmoraaProfileAction.removeSuperLike => 'Remove Super Like',
    AmoraaProfileAction.unsave => 'Remove from Saved',
    AmoraaProfileAction.block => 'Block Profile',
    AmoraaProfileAction.unblock => 'Unblock',
  };

  String get cancelLabel => switch (this) {
    AmoraaProfileAction.unlike => 'Keep Like',
    AmoraaProfileAction.removeSuperLike => 'Keep Super Like',
    AmoraaProfileAction.unsave => 'Keep Saved',
    AmoraaProfileAction.block => 'Cancel',
    AmoraaProfileAction.unblock => 'Keep Blocked',
  };

  String errorMessage(String profileName) => switch (this) {
    AmoraaProfileAction.unlike =>
      'Couldn\u2019t remove this Like.\nPlease try again.',
    AmoraaProfileAction.removeSuperLike =>
      'Couldn\u2019t remove this Super Like.\nPlease try again.',
    AmoraaProfileAction.unsave =>
      'Couldn\u2019t remove this saved profile.\nPlease try again.',
    AmoraaProfileAction.block =>
      'Couldn\u2019t block $profileName.\nPlease try again.',
    AmoraaProfileAction.unblock =>
      'Couldn\u2019t unblock this profile.\nPlease try again.',
  };

  String semanticLabel(String profileName) => switch (this) {
    AmoraaProfileAction.unlike => 'Unlike $profileName',
    AmoraaProfileAction.removeSuperLike =>
      'Remove Super Like from $profileName',
    AmoraaProfileAction.unsave => 'Remove $profileName from Saved Profiles',
    AmoraaProfileAction.block => 'Block $profileName',
    AmoraaProfileAction.unblock => 'Unblock $profileName',
  };
}

String amoraaProfileActionName(String? value) {
  final name = value?.trim() ?? '';
  return name.isEmpty ? 'this profile' : name;
}

Future<bool?> showAmoraaProfileActionConfirmation({
  required BuildContext context,
  required AmoraaProfileAction action,
  required String? profileName,
  required FutureOr<void> Function() onConfirm,
}) {
  final safeName = amoraaProfileActionName(profileName);
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => AmoraaConfirmActionSheet(
      title: action.title(safeName),
      description: action.description,
      confirmLabel: action.confirmLabel,
      cancelLabel: action.cancelLabel,
      errorMessage: action.errorMessage(safeName),
      semanticLabel: action.semanticLabel(safeName),
      isDestructive: true,
      onConfirm: onConfirm,
    ),
  );
}

class AmoraaConfirmActionSheet extends StatefulWidget {
  const AmoraaConfirmActionSheet({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.errorMessage,
    required this.semanticLabel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final String errorMessage;
  final String semanticLabel;
  final FutureOr<void> Function() onConfirm;
  final bool isDestructive;

  @override
  State<AmoraaConfirmActionSheet> createState() =>
      _AmoraaConfirmActionSheetState();
}

class _AmoraaConfirmActionSheetState extends State<AmoraaConfirmActionSheet> {
  bool _submitting = false;
  bool _failed = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        key: const ValueKey('amoraa-confirm-action'),
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmoraRadius.extraLarge),
        ),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: widget.isDestructive ? AppColors.errorRed : AppColors.primary,
        ),
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: AmoraTextStyles.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: AmoraSpacing.space12),
              Semantics(
                liveRegion: true,
                child: Text(
                  widget.errorMessage,
                  key: const ValueKey('confirm-action-error'),
                  textAlign: TextAlign.center,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const ValueKey('confirm-action-cancel'),
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space16,
              ),
            ),
            child: Text(widget.cancelLabel),
          ),
          Semantics(
            label: widget.semanticLabel,
            button: true,
            liveRegion: _submitting,
            child: FilledButton(
              key: const ValueKey('confirm-action-confirm'),
              onPressed: _submitting ? null : _confirm,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space16,
                ),
                backgroundColor: widget.isDestructive
                    ? AppColors.errorRed
                    : AppColors.secondary,
              ),
              child: _submitting
                  ? const SizedBox.square(
                      key: ValueKey('confirm-action-progress'),
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.surface,
                      ),
                    )
                  : Text(widget.confirmLabel),
            ),
          ),
        ],
      ),
    );
  }
}
