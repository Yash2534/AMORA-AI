import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';

/// Geometry and typography shared by AMORAA's existing header variants.
///
/// Heights exclude the status-bar inset. The owning Scaffold/SafeArea applies
/// that inset exactly once.
abstract final class AmoraHeaderTokens {
  static const double pageHorizontalInset = AmoraSpacing.space20;
  static const double contentHorizontalInset = AmoraSpacing.space20;
  static const double safeTopSpacing = AmoraSpacing.space4;
  static const double mainBodyGap = AmoraSpacing.space8;
  static const double secondaryBodyGap = AmoraSpacing.space16;

  static const double mainToolbarHeight = AmoraSpacing.compactControlHeight;
  static const double singleLineHeight = AmoraSpacing.appBarHeight;
  static const double titleSubtitleHeight =
      AmoraSpacing.appBarWithSubtitleHeight;
  static const double scaledMainHeight = AmoraSpacing.controlHeight;
  static const double chatDetailHeight = 72;

  static const double touchTarget = AmoraSpacing.minimumTouchTarget;
  static const double actionVisualSize = 44;
  static const double iconSize = 20;
  static const double chatIconSize = 21;
  static const double backTitleGap = AmoraSpacing.space8;
  static const double actionGap = AmoraSpacing.space0;
  static const double titleActionGap = AmoraSpacing.space8;
  static const double titleSubtitleGap = 2;

  static const double discoverLogoWidth = 112;
  static const double discoverLogoHeight = 22;

  static const TextStyle titleStyle = AmoraTextStyles.pageHeaderTitle;
  static const TextStyle subtitleStyle = AmoraTextStyles.pageHeaderSubtitle;
}
