import 'dart:math' as math;

import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraChatComposer extends StatefulWidget {
  const AmoraChatComposer({
    super.key,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onDraftChanged,
    this.enabled = true,
    this.disabledReason,
    this.onEmojiPickerVisibilityChanged,
    this.compactHeight,
    this.contextLabel,
    this.contextTitle,
    this.contextDetail,
    this.onRemoveContext,
    this.onAttach,
  });

  static const maximumMessageLength = 2000;

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final ValueChanged<String> onDraftChanged;
  final bool enabled;
  final String? disabledReason;
  final ValueChanged<bool>? onEmojiPickerVisibilityChanged;
  final bool? compactHeight;
  final String? contextLabel;
  final String? contextTitle;
  final String? contextDetail;
  final VoidCallback? onRemoveContext;
  final VoidCallback? onAttach;

  @override
  State<AmoraChatComposer> createState() => _AmoraChatComposerState();
}

class _AmoraChatComposerState extends State<AmoraChatComposer> {
  late final FocusNode _focusNode;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AmoraChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      _setEmojiPickerVisible(false);
    } else {
      _refresh();
    }
  }

  void _setEmojiPickerVisible(bool visible) {
    if (_showEmojiPicker == visible) return;
    setState(() => _showEmojiPicker = visible);
    widget.onEmojiPickerVisibilityChanged?.call(visible);
  }

  Future<void> _toggleEmojiPicker() async {
    if (!widget.enabled) return;
    if (_showEmojiPicker) {
      _setEmojiPickerVisible(false);
      _focusNode.requestFocus();
      return;
    }
    _focusNode.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    if (!mounted) return;
    _setEmojiPickerVisible(true);
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final hasText = widget.controller.text.trim().isNotEmpty;
    final canSend = widget.enabled && hasText && !widget.sending;
    final mediaSize = MediaQuery.sizeOf(context);
    final compactHeight = widget.compactHeight ?? mediaSize.height < 500;
    final pickerHeight = compactHeight
        ? 72.0
        : math.min(330.0, math.max(240.0, mediaSize.height * .34));
    final width = mediaSize.width;
    final columns = width < 360
        ? 7
        : width < 600
        ? 8
        : 10;

    return Material(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.enabled &&
              (widget.disabledReason?.trim().isNotEmpty ?? false))
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: AppColors.tertiary.withValues(alpha: .42),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.disabledReason!,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.contextTitle?.trim().isNotEmpty == true)
            _ComposerContextPreview(
              label: widget.contextLabel ?? 'Replying to',
              title: widget.contextTitle!,
              detail: widget.contextDetail,
              onRemove: widget.onRemoveContext,
            ),
          Container(
            padding: compactHeight
                ? const EdgeInsets.fromLTRB(8, 4, 10, 4)
                : const EdgeInsets.fromLTRB(8, 8, 10, 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.tertiary.withValues(alpha: .52),
                ),
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.fromLTRB(2, 4, 5, 4),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? AppColors.surface
                    : AppColors.tertiary.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: focused || _showEmojiPicker
                      ? AppColors.secondary
                      : AppColors.tertiary,
                  width: focused || _showEmojiPicker ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.onAttach != null)
                    SizedBox.square(
                      dimension: 44,
                      child: IconButton(
                        key: const ValueKey('chat-attach-button'),
                        tooltip: 'Send photo',
                        onPressed: widget.enabled && !widget.sending
                            ? widget.onAttach
                            : null,
                        icon: const Icon(Icons.image_outlined),
                      ),
                    ),
                  Semantics(
                    button: true,
                    enabled: widget.enabled,
                    label: _showEmojiPicker
                        ? 'Show keyboard'
                        : 'Show emoji picker',
                    child: SizedBox.square(
                      dimension: 48,
                      child: IconButton(
                        tooltip: _showEmojiPicker ? 'Keyboard' : 'Emoji',
                        onPressed: widget.enabled ? _toggleEmojiPicker : null,
                        icon: Icon(
                          _showEmojiPicker
                              ? Icons.keyboard_rounded
                              : AmoraIcons.emoji,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('chat-message-field'),
                      controller: widget.controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: AmoraChatComposer.maximumMessageLength,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          AmoraChatComposer.maximumMessageLength,
                        ),
                      ],
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      onChanged: widget.onDraftChanged,
                      onTap: () {
                        if (_showEmojiPicker) {
                          _setEmojiPickerVisible(false);
                        }
                      },
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.enabled
                            ? widget.contextTitle?.trim().isNotEmpty == true
                                  ? 'Write a reply…'
                                  : 'Write a message…'
                            : 'Messaging unavailable',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        counterText: '',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    enabled: canSend,
                    label: widget.sending ? 'Sending message' : 'Send message',
                    hint: canSend ? null : 'Enter a message before sending',
                    child: SizedBox.square(
                      dimension: 48,
                      child: IconButton.filled(
                        key: const ValueKey('chat-send-button'),
                        tooltip: 'Send',
                        onPressed: canSend ? widget.onSend : null,
                        style: IconButton.styleFrom(
                          backgroundColor: canSend
                              ? AppColors.primary
                              : AppColors.tertiary,
                          foregroundColor: canSend
                              ? AppColors.surface
                              : AppColors.primary.withValues(alpha: .55),
                          disabledBackgroundColor: AppColors.tertiary,
                          disabledForegroundColor: AppColors.primary.withValues(
                            alpha: .55,
                          ),
                        ),
                        icon: widget.sending
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.surface,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: _showEmojiPicker
                ? SizedBox(
                    key: const ValueKey('chat-emoji-picker'),
                    height: pickerHeight,
                    child: compactHeight
                        ? _CompactEmojiTray(
                            controller: widget.controller,
                            onChanged: widget.onDraftChanged,
                          )
                        : EmojiPicker(
                            textEditingController: widget.controller,
                            onEmojiSelected: (_, _) {
                              widget.onDraftChanged(widget.controller.text);
                            },
                            onBackspacePressed: () {
                              widget.onDraftChanged(widget.controller.text);
                            },
                            config: Config(
                              height: pickerHeight,
                              emojiViewConfig: EmojiViewConfig(
                                columns: columns,
                                emojiSizeMax: 30,
                                backgroundColor: AppColors.surface,
                                gridPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                noRecents: const Center(
                                  child: Text(
                                    'Recently used emoji will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.text),
                                  ),
                                ),
                                loadingIndicator: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              categoryViewConfig: CategoryViewConfig(
                                initCategory: Category.SMILEYS,
                                tabBarHeight: compactHeight ? 40 : 46,
                                extraTab: compactHeight
                                    ? CategoryExtraTab.BACKSPACE
                                    : CategoryExtraTab.NONE,
                                backgroundColor: AppColors.surface,
                                indicatorColor: AppColors.secondary,
                                iconColor: AppColors.text,
                                iconColorSelected: AppColors.primary,
                                backspaceColor: AppColors.primary,
                                dividerColor: AppColors.tertiary,
                              ),
                              bottomActionBarConfig: BottomActionBarConfig(
                                enabled: !compactHeight,
                                backgroundColor: AppColors.surface,
                                buttonColor: AppColors.primary,
                                buttonIconColor: AppColors.surface,
                                showBackspaceButton: true,
                                showSearchViewButton: true,
                              ),
                              searchViewConfig: const SearchViewConfig(
                                backgroundColor: AppColors.surface,
                                buttonIconColor: AppColors.primary,
                                inputTextStyle: TextStyle(
                                  color: AppColors.text,
                                ),
                                hintTextStyle: TextStyle(color: AppColors.text),
                              ),
                              skinToneConfig: const SkinToneConfig(
                                dialogBackgroundColor: AppColors.surface,
                                indicatorColor: AppColors.primary,
                                rememberSkinTone: true,
                              ),
                            ),
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ComposerContextPreview extends StatelessWidget {
  const _ComposerContextPreview({
    required this.label,
    required this.title,
    this.detail,
    this.onRemove,
  });

  final String label;
  final String title;
  final String? detail;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label. $title. ${detail ?? ''}',
      child: Container(
        key: const ValueKey('chat-composer-context'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withValues(alpha: .28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withValues(alpha: .36)),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '“$title”',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (detail?.trim().isNotEmpty == true)
                    Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.text.withValues(alpha: .68),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (onRemove != null)
              SizedBox.square(
                dimension: 48,
                child: IconButton(
                  key: const ValueKey('remove-chat-context'),
                  tooltip: 'Remove reply context',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactEmojiTray extends StatelessWidget {
  const _CompactEmojiTray({required this.controller, required this.onChanged});

  static const _emoji = ['😀', '😂', '🥰', '😍', '😊', '😉', '❤️', '👍', '✨'];

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('chat-compact-emoji-tray'),
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          for (final emoji in _emoji)
            SizedBox.square(
              dimension: 52,
              child: IconButton(
                tooltip: 'Insert $emoji',
                onPressed: () => _insert(emoji),
                icon: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
          SizedBox.square(
            dimension: 52,
            child: IconButton(
              tooltip: 'Backspace',
              onPressed: _backspace,
              icon: const Icon(
                Icons.backspace_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _insert(String emoji) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, emoji),
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    onChanged(controller.text);
  }

  void _backspace() {
    final runes = controller.text.runes.toList(growable: true);
    if (runes.isEmpty) return;
    runes.removeLast();
    controller.value = TextEditingValue(
      text: String.fromCharCodes(runes),
      selection: TextSelection.collapsed(
        offset: String.fromCharCodes(runes).length,
      ),
    );
    onChanged(controller.text);
  }
}
