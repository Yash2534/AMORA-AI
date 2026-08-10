import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:flutter/material.dart';

/// The compact, transparent header for AMORAA's five primary destinations.
class AmoraaMainPageHeader extends StatelessWidget {
  const AmoraaMainPageHeader({
    super.key,
    required this.actions,
    this.title,
    this.subtitle,
    this.titleWidget,
  }) : assert(
         (title == null) != (titleWidget == null),
         'Provide either title or titleWidget.',
       );

  static const double pageHorizontalInset =
      AmoraHeaderTokens.pageHorizontalInset;
  static const double contentHorizontalInset =
      AmoraHeaderTokens.contentHorizontalInset;
  static const double safeTopSpacing = AmoraHeaderTokens.safeTopSpacing;
  static const double contentSpacing = AmoraHeaderTokens.mainBodyGap;
  static const double compactHeight = AmoraHeaderTokens.singleLineHeight;
  static const double scaledHeight = AmoraHeaderTokens.scaledMainHeight;
  static const double verticalPadding = 0;
  static const double actionSize = AmoraHeaderTokens.touchTarget;
  static const double actionIconSize = AmoraHeaderTokens.iconSize;
  static const double actionSpacing = AmoraHeaderTokens.actionGap;
  static const double textActionSpacing = AmoraHeaderTokens.actionGap;
  static const TextStyle titleStyle = AmoraHeaderTokens.titleStyle;
  static const TextStyle subtitleStyle = AmoraHeaderTokens.subtitleStyle;

  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final List<Widget> actions;

  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale > 1.15) return scaledHeight;
    if (scale > 1) return 64;
    return compactHeight;
  }

  static double sliverExtentFor(BuildContext context) =>
      heightFor(context) + safeTopSpacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heightFor(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: contentHorizontalInset - pageHorizontalInset,
          vertical: verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleWidget ?? _HeaderText(title!, subtitle)),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: textActionSpacing),
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: actionSpacing),
                actions[index],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.title, this.subtitle);

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraaMainPageHeader.titleStyle,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AmoraHeaderTokens.titleSubtitleGap),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AmoraaMainPageHeader.subtitleStyle,
          ),
        ],
      ],
    );
  }
}

/// A visually light action with an accessible 48 dp hit target.
class AmoraaMainPageHeaderAction extends StatelessWidget {
  const AmoraaMainPageHeaderAction({
    super.key,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Tooltip(
          message: tooltip,
          child: SizedBox.square(
            dimension: AmoraaMainPageHeader.actionSize,
            child: IconButton(
              onPressed: onPressed,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.transparent,
                hoverColor: AppColors.tertiary.withValues(alpha: .24),
                focusColor: AppColors.tertiary.withValues(alpha: .28),
                highlightColor: AppColors.tertiary.withValues(alpha: .2),
              ),
              icon: Icon(icon, size: AmoraaMainPageHeader.actionIconSize),
            ),
          ),
        ),
      ),
    );
  }
}
