import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:flutter/material.dart';

/// The compact, transparent header for AMORAA's five primary destinations.
class AmoraaMainPageHeader extends StatelessWidget {
  const AmoraaMainPageHeader({
    super.key,
    required this.actions,
    this.title,
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
  static const double compactHeight = AmoraHeaderTokens.mainToolbarHeight;
  static const double scaledHeight = AmoraHeaderTokens.scaledMainHeight;
  static const double verticalPadding = 0;
  static const double actionSize = AmoraHeaderTokens.touchTarget;
  static const double actionIconSize = AmoraHeaderTokens.iconSize;
  static const double actionSpacing = AmoraHeaderTokens.actionGap;
  static const double textActionSpacing = AmoraHeaderTokens.titleActionGap;
  static const TextStyle titleStyle = AmoraHeaderTokens.titleStyle;

  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;

  static double toolbarHeightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale > 1.15) return scaledHeight;
    return compactHeight;
  }

  static double extentFor(BuildContext context) =>
      toolbarHeightFor(context) + safeTopSpacing;

  static double heightFor(BuildContext context) => toolbarHeightFor(context);

  static double sliverExtentFor(BuildContext context) => extentFor(context);

  @override
  Widget build(BuildContext context) {
    return AmoraaMainPageHeaderFrame(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleWidget ?? _HeaderText(title!)),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: textActionSpacing),
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: actionSpacing),
              actions[index],
            ],
          ],
        ],
      ),
    );
  }
}

/// Owns the complete main-header geometry so individual pages cannot add
/// competing top or horizontal padding.
class AmoraaMainPageHeaderFrame extends StatelessWidget {
  const AmoraaMainPageHeaderFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AmoraaMainPageHeader.extentFor(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AmoraaMainPageHeader.contentHorizontalInset,
          AmoraaMainPageHeader.safeTopSpacing,
          AmoraaMainPageHeader.contentHorizontalInset,
          0,
        ),
        child: SizedBox(
          height: AmoraaMainPageHeader.toolbarHeightFor(context),
          child: child,
        ),
      ),
    );
  }
}

/// Shared pinned adapter for main destinations built with slivers.
class AmoraaPinnedMainPageHeader extends StatelessWidget {
  const AmoraaPinnedMainPageHeader({
    super.key,
    required this.child,
    this.pinned = true,
  });

  final Widget child;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: _AmoraaMainPageHeaderDelegate(
        extent: AmoraaMainPageHeader.extentFor(context),
        child: child,
      ),
    );
  }
}

class _AmoraaMainPageHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _AmoraaMainPageHeaderDelegate({
    required this.extent,
    required this.child,
  });

  final double extent;
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: AppColors.background, child: child);
  }

  @override
  bool shouldRebuild(covariant _AmoraaMainPageHeaderDelegate oldDelegate) =>
      oldDelegate.extent != extent || oldDelegate.child != child;
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AmoraaMainPageHeader.titleStyle,
      ),
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
