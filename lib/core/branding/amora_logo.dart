import 'dart:ui' as ui;

import 'package:amora_ai/core/branding/amora_brand_assets.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Centralized Amoraa Logo component adhering strictly to the brand design system.
///
/// Features a subtle premium glassy touch-up:
/// - Primary: Deep Amoraa Plum (`AppColors.logoPrimary`) with tonal glass gradient
/// - Secondary: Soft Lavender / Dusty Rose (`AppColors.logoSecondary`) with specular sheen
/// - Soft Ambient Depth: Micro drop shadow following logo silhouette
class AmoraLogo extends StatelessWidget {
  const AmoraLogo({
    super.key,
    this.width,
    this.height,
    this.iconSize = 32.0,
    this.wordmarkHeight = 18.0,
    this.showWordmark = true,
    this.alignment = Alignment.centerLeft,
    this.primaryColor = AppColors.logoPrimary,
    this.secondaryColor = AppColors.logoSecondary,
    this.glassy = true,
  });

  /// Render only the wordmark portion of the logo.
  const AmoraLogo.wordmark({
    super.key,
    this.width,
    this.height = 20.0,
    this.alignment = Alignment.centerLeft,
    this.primaryColor = AppColors.logoPrimary,
    this.secondaryColor = AppColors.logoSecondary,
    this.glassy = true,
  })  : iconSize = 0,
        wordmarkHeight = height ?? 20.0,
        showWordmark = true;

  /// Render only the icon mark portion of the logo.
  const AmoraLogo.icon({
    super.key,
    this.iconSize = 32.0,
    this.alignment = Alignment.center,
    this.primaryColor = AppColors.logoPrimary,
    this.secondaryColor = AppColors.logoSecondary,
    this.glassy = true,
  })  : width = iconSize,
        height = iconSize,
        wordmarkHeight = 0,
        showWordmark = false;

  final double? width;
  final double? height;
  final double iconSize;
  final double wordmarkHeight;
  final bool showWordmark;
  final Alignment alignment;
  final Color primaryColor;
  final Color secondaryColor;
  final bool glassy;

  @override
  Widget build(BuildContext context) {
    if (!showWordmark) {
      final iconWidget = Image.asset(
        AmoraBrandAssets.icon,
        width: width ?? iconSize,
        height: height ?? iconSize,
        fit: BoxFit.contain,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        semanticLabel: 'AMORAA icon',
      );

      if (!glassy) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
          child: iconWidget,
        );
      }

      return _GlassyLogoElement(
        baseColor: secondaryColor,
        child: iconWidget,
      );
    }

    if (iconSize <= 0) {
      final wordmarkWidget = Image.asset(
        AmoraBrandAssets.wordmark,
        width: width,
        height: wordmarkHeight,
        fit: BoxFit.contain,
        alignment: alignment,
        filterQuality: FilterQuality.high,
        semanticLabel: 'AMORAA',
      );

      if (!glassy) {
        return ColorFiltered(
          colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
          child: wordmarkWidget,
        );
      }

      return _GlassyLogoElement(
        baseColor: primaryColor,
        child: wordmarkWidget,
      );
    }

    final iconWidget = Image.asset(
      AmoraBrandAssets.icon,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      semanticLabel: 'AMORAA icon',
    );

    final wordmarkWidget = Image.asset(
      AmoraBrandAssets.wordmark,
      height: wordmarkHeight,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      filterQuality: FilterQuality.high,
      semanticLabel: 'AMORAA',
    );

    if (!glassy) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(secondaryColor, BlendMode.srcIn),
            child: iconWidget,
          ),
          const SizedBox(width: 8),
          ColorFiltered(
            colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
            child: wordmarkWidget,
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _GlassyLogoElement(
          baseColor: secondaryColor,
          child: iconWidget,
        ),
        const SizedBox(width: 8),
        _GlassyLogoElement(
          baseColor: primaryColor,
          child: wordmarkWidget,
        ),
      ],
    );
  }
}

/// Applies subtle glassy finish, specular highlight sheen, and soft ambient shadow
/// to logo shapes without changing dimensions or adding a background card.
class _GlassyLogoElement extends StatelessWidget {
  const _GlassyLogoElement({
    required this.child,
    required this.baseColor,
  });

  final Widget child;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final highlightColor = Color.alphaBlend(
      AppColors.logoHighlight.withValues(alpha: 0.28),
      baseColor,
    );
    final shadowColor = AppColors.logoGlow.withValues(
      alpha: (baseColor.a * 0.18).clamp(0.0, 1.0),
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Soft Ambient Depth Shadow following logo shape
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5),
          child: Transform.translate(
            offset: const Offset(0, 1.2),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(shadowColor, BlendMode.srcIn),
              child: child,
            ),
          ),
        ),

        // 2. Main Logo Base with Tonal Glass Gradient
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                highlightColor,
                baseColor,
                baseColor.withValues(alpha: 0.94),
              ],
              stops: const [0.0, 0.55, 1.0],
            ).createShader(bounds);
          },
          child: child,
        ),

        // 3. Specular Glass Light Reflection Overlay
        ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-0.8, -1.0),
              end: const Alignment(0.8, 1.0),
              colors: [
                AppColors.logoHighlight.withValues(alpha: 0.22),
                AppColors.logoHighlight.withValues(alpha: 0.0),
                AppColors.logoHighlight.withValues(alpha: 0.10),
              ],
              stops: const [0.0, 0.45, 0.85],
            ).createShader(bounds);
          },
          child: child,
        ),
      ],
    );
  }
}
