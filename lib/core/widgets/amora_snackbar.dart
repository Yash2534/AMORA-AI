import 'package:amora_ai/core/widgets/amora_top_notification.dart';
import 'package:flutter/material.dart';

enum AmoraSnackBarTone { neutral, success, warning, error, info }

void showAmoraSnackBar(
  BuildContext context, {
  required String message,
  AmoraSnackBarTone tone = AmoraSnackBarTone.neutral,
  String? actionLabel,
  VoidCallback? onAction,
  String? title,
}) {
  final notifType = switch (tone) {
    AmoraSnackBarTone.neutral => AmoraTopNotificationType.system,
    AmoraSnackBarTone.success => AmoraTopNotificationType.verification,
    AmoraSnackBarTone.warning => AmoraTopNotificationType.system,
    AmoraSnackBarTone.error => AmoraTopNotificationType.system,
    AmoraSnackBarTone.info => AmoraTopNotificationType.system,
  };

  AmoraTopNotificationManager.show(
    context,
    message: message,
    title: title,
    type: notifType,
    onTap: onAction,
  );
}
