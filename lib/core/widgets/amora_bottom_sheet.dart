import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;

class AmoraBottomSheet extends StatelessWidget {
  const AmoraBottomSheet({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: AmoraRadius.sheet,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1428).withValues(alpha: 0.82)
                  : Colors.white.withValues(alpha: 0.82),
              borderRadius: AmoraRadius.sheet,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.2,
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
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : AppColors.borderGray,
                        borderRadius: AmoraRadius.pillBorder,
                      ),
                    ),
                    child,
                  ],
                ),
              ),
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
