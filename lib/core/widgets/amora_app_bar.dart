import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
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
      titleSpacing: leading == null ? AmoraSpacing.x5 : 0,
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
            style: AmoraTextStyles.titleMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AmoraSpacing.x1),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
