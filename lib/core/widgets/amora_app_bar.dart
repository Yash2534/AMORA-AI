import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AmoraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AmoraAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onBack,
    this.actions = const [],
    this.centerTitle = false,
  }) : assert(
         leading == null || onBack == null,
         'Provide either leading or onBack, not both.',
       );

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle == null
        ? AmoraHeaderTokens.singleLineHeight
        : AmoraHeaderTokens.titleSubtitleHeight,
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          leading ??
          (onBack == null ? null : AmoraHeaderBackButton(onPressed: onBack)),
      centerTitle: centerTitle,
      actions: actions,
      toolbarHeight: preferredSize.height,
      titleSpacing: leading == null && onBack == null
          ? AmoraHeaderTokens.contentHorizontalInset
          : AmoraHeaderTokens.backTitleGap,
      title: Column(
        crossAxisAlignment: centerTitle
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraHeaderTokens.titleStyle,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AmoraHeaderTokens.titleSubtitleGap),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraHeaderTokens.subtitleStyle,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shared secondary-header leading control. Its 48 dp box keeps the visual
/// arrow, focus ring, semantics, and pointer target consistent everywhere.
class AmoraHeaderBackButton extends StatelessWidget {
  const AmoraHeaderBackButton({
    super.key,
    required this.onPressed,
    this.tooltip = 'Back',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Semantics(
        button: true,
        label: 'Back',
        child: ExcludeSemantics(
          child: Tooltip(
            message: tooltip,
            child: SizedBox.square(
              dimension: AmoraHeaderTokens.touchTarget,
              child: IconButton(
                onPressed: onPressed,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  hoverColor: AppColors.tertiary.withValues(alpha: .24),
                  focusColor: AppColors.tertiary.withValues(alpha: .28),
                  highlightColor: AppColors.tertiary.withValues(alpha: .2),
                ),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: AmoraHeaderTokens.iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared secondary-header action with a 48 dp target and restrained weight.
class AmoraHeaderActionButton extends StatelessWidget {
  const AmoraHeaderActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final String tooltip;
  final String? semanticLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? tooltip,
      child: ExcludeSemantics(
        child: Tooltip(
          message: tooltip,
          child: SizedBox.square(
            dimension: AmoraHeaderTokens.touchTarget,
            child: IconButton(
              onPressed: onPressed,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.primary,
                hoverColor: AppColors.tertiary.withValues(alpha: .24),
                focusColor: AppColors.tertiary.withValues(alpha: .28),
                highlightColor: AppColors.tertiary.withValues(alpha: .2),
              ),
              icon: Icon(icon, size: AmoraHeaderTokens.iconSize),
            ),
          ),
        ),
      ),
    );
  }
}
