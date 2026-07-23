import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AmoraTextAction extends StatelessWidget {
  const AmoraTextAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AmoraSpacing.minimumTouchTarget, 48),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.active),
          textStyle: const WidgetStatePropertyAll(AmoraTextStyles.labelLarge),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AmoraRadius.button,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
    return Tooltip(message: tooltip ?? label, child: button);
  }
}
