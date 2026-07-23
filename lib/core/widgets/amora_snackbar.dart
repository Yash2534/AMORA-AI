import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum AmoraSnackBarTone { neutral, success, warning, error, info }

void showAmoraSnackBar(
  BuildContext context, {
  required String message,
  AmoraSnackBarTone tone = AmoraSnackBarTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final color = switch (tone) {
    AmoraSnackBarTone.neutral => AppColors.onSurface,
    AmoraSnackBarTone.success => AppColors.success,
    AmoraSnackBarTone.warning => AppColors.warning,
    AmoraSnackBarTone.error => AppColors.error,
    AmoraSnackBarTone.info => AppColors.info,
  };
  final icon = switch (tone) {
    AmoraSnackBarTone.neutral => AmoraIcons.message,
    AmoraSnackBarTone.success => AmoraIcons.check,
    AmoraSnackBarTone.warning => Icons.warning_amber_rounded,
    AmoraSnackBarTone.error => Icons.error_outline_rounded,
    AmoraSnackBarTone.info => Icons.info_outline_rounded,
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Row(
          children: [
            Icon(icon, color: AppColors.surface),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}
