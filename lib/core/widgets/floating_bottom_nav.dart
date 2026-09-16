import 'dart:ui';

import 'package:amora_ai/core/config/app_feature_flags.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';

enum AmoraNavTab { discover, chats, matches, events, profile }

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.activeTab,
    this.isCollapsed = false,
    this.onTabSelected,
  });

  final AmoraNavTab activeTab;
  final bool isCollapsed;
  final ValueChanged<AmoraNavTab>? onTabSelected;

  static const double barHeight = 68;
  static const double compactBarHeight = 52;
  static const double contentSpacing = 8;
  static const double contentBottomPadding =
      barHeight + minimumBottomSpacing + contentSpacing;
  static const double assistantBottomPadding = 86;
  static const double maxBarWidth = 480;
  static const double itemHeight = 60;
  static const double iconSize = 22;
  static const double selectedIconSize = 22;
  static const double iconContainerWidth = 40;
  static const double iconContainerHeight = 29;
  static const double labelSize = 11;
  static const double horizontalMargin = 16;
  static const double minimumBottomSpacing = 6;

  static double navigationHeightFor(BuildContext context) =>
      barHeight +
      MediaQuery.viewPaddingOf(
        context,
      ).bottom.clamp(minimumBottomSpacing, double.infinity);

  static double contentBottomPaddingFor(BuildContext context) =>
      navigationHeightFor(context) + contentSpacing;

  static const items = <AmoraNavigationDestination>[
    AmoraNavigationDestination(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore_rounded,
      label: 'Discover',
      tab: AmoraNavTab.discover,
      routeName: '/discover',
    ),
    AmoraNavigationDestination(
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
      label: 'Chats',
      tab: AmoraNavTab.chats,
      routeName: '/chats',
    ),
    AmoraNavigationDestination(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
      label: 'AI Matches',
      tab: AmoraNavTab.matches,
      routeName: '/matches',
    ),
    if (AppFeatureFlags.eventsEnabled)
      AmoraNavigationDestination(
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month_rounded,
        label: 'Events',
        tab: AmoraNavTab.events,
        routeName: '/events',
      ),
    AmoraNavigationDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
      tab: AmoraNavTab.profile,
      routeName: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color surfaceColor = isDark
        ? AppColors.plumBlack.withValues(alpha: 0.52)
        : AppColors.white.withValues(alpha: 0.32);

    final Color borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.22)
        : AppColors.white.withValues(alpha: 0.45);

    final List<BoxShadow> shadows = [
      BoxShadow(
        color: isDark
            ? AppColors.plumBlack.withValues(alpha: 0.35)
            : AppColors.glassShadow.withValues(alpha: 0.12),
        blurRadius: 22,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
    ];

    return Material(
      key: const ValueKey('floating-bottom-nav-transparent-outer'),
      type: MaterialType.transparency,
      color: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        key: const ValueKey('floating-bottom-nav-safe-area'),
        top: false,
        minimum: const EdgeInsets.only(bottom: minimumBottomSpacing),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxBarWidth),
              child: AnimatedContainer(
                key: const ValueKey('floating-bottom-nav-bar'),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                height: isCollapsed ? compactBarHeight : barHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: shadows,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: DecoratedBox(
                        key: const ValueKey('floating-bottom-nav-container-surface'),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: borderColor,
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AmoraSpacing.space2,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final item in items)
                                Expanded(
                                  child: _BottomNavButton(
                                    item: item,
                                    selected: item.tab == activeTab,
                                    isCollapsed: isCollapsed,
                                    onTap: () => _handleTap(context, item),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, AmoraNavigationDestination item) {
    if (item.tab == activeTab) return;
    if (onTabSelected case final callback?) {
      callback(item.tab);
      return;
    }
    Navigator.of(context).pushReplacementNamed(item.routeName);
  }
}

class _BottomNavButton extends StatefulWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.isCollapsed,
    required this.onTap,
  });

  final AmoraNavigationDestination item;
  final bool selected;
  final bool isCollapsed;
  final VoidCallback onTap;

  @override
  State<_BottomNavButton> createState() => _BottomNavButtonState();
}

class _BottomNavButtonState extends State<_BottomNavButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final selected = widget.selected;
    final item = widget.item;

    final Color selectedIndicatorColor = isDark
        ? AppColors.primary.withValues(alpha: 0.35)
        : AppColors.softLavender;

    final Color activeColor = isDark
        ? AppColors.white
        : AppColors.primary;

    final Color inactiveColor = isDark
        ? AppColors.white.withValues(alpha: 0.65)
        : AppColors.secondaryText;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.label,
        child: SizedBox(
          height: FloatingBottomNav.itemHeight,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('bottom-nav-${item.label}'),
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onHover: (value) => setState(() => _hovered = value),
              onFocusChange: (value) => setState(() => _focused = value),
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: AppColors.accentSoft.withValues(alpha: .3),
              splashColor: AppColors.accentSoft.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    scale: _pressed ? .96 : 1,
                    child: AnimatedContainer(
                      key: ValueKey('bottom-nav-indicator-${item.label}'),
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: FloatingBottomNav.iconContainerWidth,
                      height: FloatingBottomNav.iconContainerHeight,
                      decoration: BoxDecoration(
                        color: selected
                            ? selectedIndicatorColor
                            : AppColors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _focused
                              ? AppColors.primaryLight
                              : AppColors.transparent,
                          width: _focused ? 1.5 : 1,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: duration,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        child: Icon(
                          selected ? item.selectedIcon : item.icon,
                          key: ValueKey('$selected-${item.label}'),
                          color: selected ? activeColor : inactiveColor,
                          size: selected
                              ? FloatingBottomNav.selectedIconSize
                              : FloatingBottomNav.iconSize,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    height: widget.isCollapsed ? 0 : AmoraSpacing.space4,
                  ),
                  ClipRect(
                    child: AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      height: widget.isCollapsed ? 0 : 16,
                      child: AnimatedOpacity(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        opacity: widget.isCollapsed ? 0 : 1,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.08,
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            curve: Curves.easeOutCubic,
                            style: AmoraTextStyles.labelSmall.copyWith(
                              color: selected ? activeColor : inactiveColor,
                              fontSize: FloatingBottomNav.labelSize,
                              fontFamily: AmoraTextStyles.fontFamily,
                              height: 1,
                              letterSpacing: -.35,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            child: Text(
                              item.label,
                              key: ValueKey('bottom-nav-label-${item.label}'),
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AmoraNavigationDestination {
  const AmoraNavigationDestination({
    required this.tab,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.routeName,
  });

  final AmoraNavTab tab;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String routeName;
}
