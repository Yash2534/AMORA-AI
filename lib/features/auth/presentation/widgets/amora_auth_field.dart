import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraAuthField extends StatefulWidget {
  const AmoraAuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.autofillHints,
    this.inputFormatters,
    this.prefixText,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final int? maxLength;

  @override
  State<AmoraAuthField> createState() => _AmoraAuthFieldState();
}

class _AmoraAuthFieldState extends State<AmoraAuthField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AmoraAuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _focusNode
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final filled = widget.controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AmoraSpacing.space4),
          child: Text(
            widget.label,
            style: AmoraTextStyles.labelMedium.copyWith(
              color: focused ? AppColors.primary : AppColors.text,
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surface
                : AppColors.tertiary.withValues(alpha: .26),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused
                  ? AppColors.secondary
                  : filled
                  ? AppColors.primary.withValues(alpha: .42)
                  : AppColors.tertiary,
              width: focused ? 1.5 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: .10),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            style: AmoraTextStyles.bodyLarge,
            cursorColor: AppColors.secondary,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixText: widget.prefixText,
              prefixIcon: widget.icon == null
                  ? null
                  : Icon(widget.icon, color: AppColors.primary, size: 21),
              suffixIcon: widget.suffix,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space16,
                vertical: 17,
              ),
              errorStyle: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
