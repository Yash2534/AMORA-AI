import 'dart:async';

import 'package:amora_ai/core/widgets/amoraa_confirm_action_sheet.dart';
import 'package:flutter/material.dart';

Future<bool?> showBlockConfirmationDialog({
  required BuildContext context,
  required String userName,
  required FutureOr<void> Function() onConfirm,
}) {
  return showAmoraaProfileActionConfirmation(
    context: context,
    action: AmoraaProfileAction.block,
    profileName: userName,
    onConfirm: onConfirm,
  );
}
