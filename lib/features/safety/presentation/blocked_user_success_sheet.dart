import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Future<void> showBlockedUserSuccessSheet({
  required BuildContext context,
  required String userName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              color: AppColors.successGreen,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              '${userName.split(' ').first} blocked',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.deepWine,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "They won't be notified, and you won't see each other again.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textGray,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ),
  );
}
