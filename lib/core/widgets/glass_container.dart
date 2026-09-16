import 'dart:ui';

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Glass intensity levels matching the Amoraa Design System.
enum AmoraGlassLevel {
  /// Level 1 — Search, filter chips, small badges, inline controls.
  subtle,

  /// Level 2 — Floating bottom dock, chat composer, bottom sheets, header action buttons.
  medium,

  /// Level 3 — Major floating action panels & overlays.
  strong,
}

/// Reusable Apple iOS-inspired Glassmorphism container widget.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.level = AmoraGlassLevel.medium,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blur,
    this.opacity,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.onTap,
  });

  final Widget child;
  final AmoraGlassLevel level;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? blur;
  final double? opacity;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  double get _effectiveBlur => switch (level) {
        AmoraGlassLevel.subtle => blur ?? 12.0,
        AmoraGlassLevel.medium => blur ?? 18.0,
        AmoraGlassLevel.strong => blur ?? 24.0,
      };

  double get _effectiveOpacity => switch (level) {
        AmoraGlassLevel.subtle => opacity ?? 0.88,
        AmoraGlassLevel.medium => opacity ?? 0.82,
        AmoraGlassLevel.strong => opacity ?? 0.76,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBlur = _effectiveBlur;
    final effectiveOpacity = _effectiveOpacity;

    final defaultSurfaceColor = isDark
        ? const Color(0xFF1E1428).withValues(alpha: effectiveOpacity)
        : Colors.white.withValues(alpha: effectiveOpacity);

    final effectiveColor = color ?? defaultSurfaceColor;

    final effectiveBorderColor = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.6));

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AmoraSpacing.space16),
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );

    if (effectiveBlur > 0) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
