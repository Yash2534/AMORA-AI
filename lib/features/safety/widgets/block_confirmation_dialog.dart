import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Future<bool?> showBlockConfirmationDialog({
  required BuildContext context,
  required String userName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => BlockConfirmationDialog(userName: userName),
  );
}

class BlockConfirmationDialog extends StatelessWidget {
  const BlockConfirmationDialog({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: const Icon(Icons.block_rounded, color: AppColors.errorRed),
      title: Text('Block $firstName?'),
      content: const Text(
        "They won't be notified, and you won't see each other again.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Block User'),
        ),
      ],
    );
  }
}
