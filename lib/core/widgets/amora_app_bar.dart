import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
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
    this.maxContentWidth = 460,
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
  final double maxContentWidth;

  @override
  Size get preferredSize => Size.fromHeight(
    subtitle == null
        ? AmoraHeaderTokens.singleLineHeight
        : AmoraHeaderTokens.titleSubtitleHeight,
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraHeaderTokens.contentHorizontalInset,
            ),
            child: AmoraInlinePageHeader(
              title: title,
              subtitle: subtitle,
              onBack: onBack,
              leading: leading,
              actions: actions,
              centerTitle: centerTitle,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pinned counterpart to [AmoraAppBar] for secondary pages built with slivers.
class AmoraSliverAppBar extends StatelessWidget {
  const AmoraSliverAppBar({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.actions = const [],
    this.pinned = true,
    this.maxContentWidth = 460,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<Widget> actions;
  final bool pinned;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: pinned,
      backgroundColor: AppColors.background.withValues(alpha: .96),
      foregroundColor: AppColors.primary,
      surfaceTintColor: AppColors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: subtitle == null
          ? AmoraHeaderTokens.singleLineHeight
          : AmoraHeaderTokens.titleSubtitleHeight,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraHeaderTokens.contentHorizontalInset,
            ),
            child: AmoraInlinePageHeader(
              title: title,
              subtitle: subtitle,
              onBack: onBack,
              actions: actions,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared geometry for the few page headers that must remain inside the body.
/// The parent supplies the standard 20 dp page inset; this widget owns all
/// internal alignment, typography, control sizing, and responsive truncation.
class AmoraInlinePageHeader extends StatelessWidget {
  const AmoraInlinePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.leading,
    this.actions = const [],
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? leading;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AmoraHeaderTokens.touchTarget,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (onBack != null) ...[
            AmoraHeaderBackButton(onPressed: onBack),
            const SizedBox(width: AmoraHeaderTokens.backTitleGap),
          ],
          if (leading != null) ...[
            SizedBox.square(
              dimension: AmoraHeaderTokens.touchTarget,
              child: leading,
            ),
            const SizedBox(width: AmoraHeaderTokens.titleActionGap),
          ],
          Expanded(
            child: Align(
              alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
              child: AmoraScreenTitle(title: title, subtitle: subtitle),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: AmoraHeaderTokens.titleActionGap),
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: AmoraHeaderTokens.actionGap),
              actions[index],
            ],
          ],
        ],
      ),
    );
  }
}

/// Standard non-interactive feature mark used by inline specialty headers.
class AmoraHeaderBadge extends StatelessWidget {
  const AmoraHeaderBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
        ),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Center(
        child: Icon(
          icon,
          color: AppColors.surface,
          size: AmoraHeaderTokens.iconSize,
        ),
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
