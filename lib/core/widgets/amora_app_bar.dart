import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AmoraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AmoraAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle == null
        ? AmoraSpacing.appBarHeight
        : AmoraSpacing.appBarWithSubtitleHeight,
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      centerTitle: centerTitle,
      actions: actions,
      toolbarHeight: preferredSize.height,
      titleSpacing: leading == null ? AmoraSpacing.x5 : AmoraSpacing.x2,
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
            style: AmoraTextStyles.pageHeaderTitle,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AmoraSpacing.x1),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.pageHeaderSubtitle,
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
              dimension: AmoraSpacing.minimumTouchTarget,
              child: IconButton(
                onPressed: onPressed,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  hoverColor: AppColors.tertiary.withValues(alpha: .24),
                  focusColor: AppColors.tertiary.withValues(alpha: .28),
                  highlightColor: AppColors.tertiary.withValues(alpha: .2),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
