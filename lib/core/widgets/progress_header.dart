import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:flutter/material.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.deepWine,
              )
            else
              const SizedBox(width: AmoraSpacing.minimumTouchTarget),
            Expanded(
              child: ClipRRect(
                borderRadius: AmoraRadius.pillBorder,
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: AmoraSpacing.space8,
                  backgroundColor: AppColors.borderGray,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(width: AmoraSpacing.minimumTouchTarget),
          ],
        ),
        const SizedBox(height: AmoraSpacing.space20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
