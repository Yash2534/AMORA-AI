import 'dart:math' as math;

import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraOtpInput extends StatefulWidget {
  const AmoraOtpInput({
    super.key,
    required this.controllers,
    required this.nodes,
    required this.onChanged,
    required this.onPaste,
    this.hasError = false,
    this.enabled = true,
  }) : assert(controllers.length > 0),
       assert(controllers.length == nodes.length);

  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;
  final VoidCallback onChanged;
  final ValueChanged<String> onPaste;
  final bool hasError;
  final bool enabled;

  @override
  State<AmoraOtpInput> createState() => _AmoraOtpInputState();
}

class ResponsiveOtpInput extends AmoraOtpInput {
  const ResponsiveOtpInput({
    super.key,
    required super.controllers,
    required super.nodes,
    required super.onChanged,
    required super.onPaste,
    super.hasError,
    super.enabled,
  });
}

class _AmoraOtpInputState extends State<AmoraOtpInput> {
  late final TextEditingController _inputController;
  String _previousValue = '';

  int get _length => widget.controllers.length;
  FocusNode get _focusNode => widget.nodes.first;

  @override
  void initState() {
    super.initState();
    final initial = _externalValue();
    _previousValue = initial;
    _inputController = TextEditingController(text: initial);
    _focusNode.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AmoraOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes.first != widget.nodes.first) {
      oldWidget.nodes.first.removeListener(_refresh);
      _focusNode.addListener(_refresh);
    }
    final external = _externalValue();
    if (external != _inputController.text) {
      _inputController.value = TextEditingValue(
        text: external,
        selection: TextSelection.collapsed(offset: external.length),
      );
      _previousValue = external;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_refresh);
    _inputController.dispose();
    super.dispose();
  }

  String _externalValue() =>
      widget.controllers.map((controller) => controller.text).join();

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleChanged(String value) {
    for (var index = 0; index < _length; index++) {
      final digit = index < value.length ? value[index] : '';
      if (widget.controllers[index].text != digit) {
        widget.controllers[index].value = TextEditingValue(
          text: digit,
          selection: TextSelection.collapsed(offset: digit.length),
        );
      }
    }
    final pasted = value.length - _previousValue.length > 1;
    _previousValue = value;
    if (pasted) widget.onPaste(value);
    widget.onChanged();
    _refresh();
  }

  void _focusAt(int index) {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
    final length = _inputController.text.length;
    final offset = math.min(index, length);
    _inputController.selection = index < length
        ? TextSelection(baseOffset: index, extentOffset: index + 1)
        : TextSelection.collapsed(offset: offset);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final value = _inputController.text;
    final selectionOffset = _inputController.selection.isValid
        ? _inputController.selection.baseOffset
        : value.length;
    final activeIndex = math.min(math.max(selectionOffset, 0), _length - 1);
    return Semantics(
      textField: true,
      label: '$_length digit verification code',
      value: value.isEmpty
          ? 'No digits entered'
          : '${value.length} digits entered',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = constraints.maxWidth < 300 ? 4.0 : 8.0;
          final available = constraints.maxWidth - gap * (_length - 1);
          final cellSize = math.min(56.0, available / _length);
          return SizedBox(
            height: math.max(52, cellSize),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: .01,
                    child: TextField(
                      key: const ValueKey('otp-native-input'),
                      controller: _inputController,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableSuggestions: false,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(_length),
                      ],
                      onChanged: _handleChanged,
                    ),
                  ),
                ),
                Align(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 0; index < _length; index++) ...[
                          _OtpCell(
                            key: ValueKey('otp-cell-$index'),
                            size: cellSize,
                            digit: index < value.length ? value[index] : '',
                            focused:
                                _focusNode.hasFocus && index == activeIndex,
                            hasError: widget.hasError,
                            onTap: () => _focusAt(index),
                          ),
                          if (index != _length - 1) SizedBox(width: gap),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    super.key,
    required this.size,
    required this.digit,
    required this.focused,
    required this.hasError,
    required this.onTap,
  });

  final double size;
  final String digit;
  final bool focused;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = hasError
        ? AppColors.primary
        : focused
        ? AppColors.secondary
        : digit.isNotEmpty
        ? AppColors.primary.withValues(alpha: .5)
        : AppColors.tertiary;
    return Semantics(
      button: true,
      label: 'Verification digit',
      value: digit.isEmpty ? 'Empty' : 'Entered',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: math.max(48, size),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: focused ? 2 : 1.25),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: .12),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            digit,
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
