import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_bottom_sheet.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef RoseGiftSender = Future<bool> Function(String note);

Future<bool> showAmoraaRoseGiftSheet({
  required BuildContext context,
  required String recipientName,
  required RoseGiftSender onSend,
}) async {
  return await showAmoraBottomSheet<bool>(
        context: context,
        child: AmoraaRoseGiftSheet(
          recipientName: recipientName,
          onSend: onSend,
        ),
      ) ??
      false;
}

class AmoraaRoseGiftSheet extends StatefulWidget {
  const AmoraaRoseGiftSheet({
    super.key,
    required this.recipientName,
    required this.onSend,
  });

  static const int maximumNoteLength = 160;

  final String recipientName;
  final RoseGiftSender onSend;

  @override
  State<AmoraaRoseGiftSheet> createState() => _AmoraaRoseGiftSheetState();
}

class _AmoraaRoseGiftSheetState extends State<AmoraaRoseGiftSheet>
    with SingleTickerProviderStateMixin {
  final _noteController = TextEditingController();
  late final AnimationController _roseController;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _roseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _roseController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _sent) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final sent = await widget.onSend(_noteController.text.trim());
    if (!mounted) return;
    if (!sent) {
      setState(() {
        _sending = false;
        _error = 'Couldn’t send the Rose';
      });
      return;
    }
    setState(() {
      _sending = false;
      _sent = true;
    });
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _roseController.forward(from: 0);
    }
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final firstName = widget.recipientName.trim().split(' ').first;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send a Rose',
                textAlign: TextAlign.center,
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                'A thoughtful way to show genuine interest.',
                textAlign: TextAlign.center,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.text.withValues(alpha: .68),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space20),
              Semantics(
                liveRegion: _sent,
                label: _sent ? 'Rose sent to $firstName' : 'Rose gift preview',
                child: AnimatedBuilder(
                  animation: _roseController,
                  builder: (context, child) {
                    final progress = Curves.easeOutCubic.transform(
                      _roseController.value,
                    );
                    return Opacity(
                      opacity: _sent ? 1 - (progress * .12) : 1,
                      child: Transform.translate(
                        offset: Offset(0, _sent ? -14 * progress : 0),
                        child: Transform.scale(
                          scale: _sent ? .92 + (.08 * progress) : 1,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: .30),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: .46),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_florist_rounded,
                        size: 48,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space16),
              Text(
                _sent ? 'Rose sent to $firstName' : 'For $firstName',
                textAlign: TextAlign.center,
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space20),
              TextField(
                key: const ValueKey('rose-note-field'),
                controller: _noteController,
                enabled: !_sending && !_sent,
                minLines: 2,
                maxLines: 4,
                maxLength: AmoraaRoseGiftSheet.maximumNoteLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Optional note',
                  hintText: 'Add a personal message',
                  alignLabelWithHint: true,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AmoraSpacing.space8),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.secondary,
                        size: 19,
                      ),
                      const SizedBox(width: AmoraSpacing.space8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AmoraTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AmoraSpacing.space16),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Cancel',
                      variant: AppPrimaryButtonVariant.outlined,
                      onPressed: _sending || _sent
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Send Rose to ${widget.recipientName}',
                      child: AppPrimaryButton(
                        key: const ValueKey('send-rose-button'),
                        label: _error == null ? 'Send Rose' : 'Try again',
                        icon: Icons.local_florist_rounded,
                        isLoading: _sending,
                        onPressed: _sending || _sent ? null : _send,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
