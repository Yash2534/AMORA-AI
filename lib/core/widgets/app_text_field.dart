import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.autofillHints,
    this.inputFormatters,
    this.prefixText,
    this.prefix,
    this.maxLength,
    this.maxLengthEnforcement,
    this.counterText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final Widget? prefix;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final String? counterText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      enabled: enabled,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      style: AmoraTextStyles.body.copyWith(
        color: AppColors.text,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        counterText: counterText,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.x5,
          vertical: AmoraSpacing.x4,
        ),
        prefixIcon:
            prefix ??
            (icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: AmoraSpacing.x1),
                    child: Icon(
                      icon,
                      color: AppColors.primary.withValues(alpha: .78),
                      size: 20,
                    ),
                  )),
      ),
    );
  }
}
