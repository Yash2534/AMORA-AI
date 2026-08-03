import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraPasswordField extends StatefulWidget {
  const AmoraPasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hint,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AmoraPasswordField> createState() => _AmoraPasswordFieldState();
}

class _AmoraPasswordFieldState extends State<AmoraPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      icon: AmoraIcons.lock,
      validator: widget.validator,
      obscureText: _obscured,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      autofillHints: const [AutofillHints.password],
      suffix: IconButton(
        tooltip: _obscured ? 'Show password' : 'Hide password',
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(_obscured ? AmoraIcons.eye : Icons.visibility_off_rounded),
      ),
    );
  }
}

class AmoraOtpField extends StatelessWidget {
  const AmoraOtpField({
    super.key,
    required this.controller,
    this.length = 6,
    this.label = 'Verification code',
    this.onChanged,
  });

  final TextEditingController controller;
  final int length;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: '$length digit $label',
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(length),
        ],
        onChanged: onChanged,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class AmoraCheckboxTile extends StatelessWidget {
  const AmoraCheckboxTile({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      button: true,
      label: label,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: AmoraRadius.button,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive six-cell OTP input that preserves paste and focus traversal.
class AmoraOtpBoxes extends StatelessWidget {
  const AmoraOtpBoxes({
    super.key,
    required this.controllers,
    required this.nodes,
    required this.onChanged,
    required this.onPaste,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> nodes;
  final VoidCallback onChanged;
  final ValueChanged<String> onPaste;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 340
            ? AmoraSpacing.space4
            : AmoraSpacing.space8;
        final boxWidth = ((constraints.maxWidth - (gap * 5)) / 6)
            .clamp(32.0, AmoraSpacing.minimumTouchTarget)
            .toDouble();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < 6; index++) ...[
              SizedBox(
                width: boxWidth,
                child: TextField(
                  key: Key('otp-digit-$index'),
                  controller: controllers[index],
                  focusNode: nodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: AmoraTextStyles.titleLarge.copyWith(
                    color: AppColors.deepWine,
                  ),
                  decoration: const InputDecoration(counterText: ''),
                  onChanged: (value) {
                    if (value.length > 1) {
                      onPaste(value);
                      return;
                    }
                    if (value.isNotEmpty && index < nodes.length - 1) {
                      nodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      nodes[index - 1].requestFocus();
                    }
                    onChanged();
                  },
                ),
              ),
              if (index != 5) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }
}
