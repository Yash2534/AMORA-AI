import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

class AmoraBottomSheet extends StatelessWidget {
  const AmoraBottomSheet({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AmoraRadius.sheet,
          border: Border(
            top: BorderSide(color: AppColors.borderGray.withValues(alpha: .7)),
          ),
          boxShadow: AmoraShadows.bottomSheet,
        ),
        child: Material(
          color: AppColors.transparent,
          child: Padding(
            padding: padding ?? AmoraSpacing.bottomSheet,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AmoraSpacing.space32,
                  height: AmoraSpacing.space4,
                  margin: const EdgeInsets.only(bottom: AmoraSpacing.x4),
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: AmoraRadius.pillBorder,
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAmoraBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppColors.transparent,
    showDragHandle: false,
    sheetAnimationStyle: const AnimationStyle(
      duration: AmoraMotion.standard,
      reverseDuration: AmoraMotion.fast,
      curve: AmoraMotion.curve,
      reverseCurve: AmoraMotion.curve,
    ),
    builder: (_) => AmoraBottomSheet(child: child),
  );
}
