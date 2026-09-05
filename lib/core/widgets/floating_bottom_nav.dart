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
    this.onTabSelected,
  });

  final AmoraNavTab activeTab;
  final ValueChanged<AmoraNavTab>? onTabSelected;

  static const double barHeight = 68;
  static const double contentSpacing = 8;
  static const double contentBottomPadding =
      barHeight + minimumBottomSpacing + contentSpacing;
  static const double assistantBottomPadding = 86;
  static const double maxBarWidth = 480;
  static const double itemHeight = 60;
  static const double iconSize = 23;
  static const double selectedIconSize = 23;
  static const double iconContainerWidth = 36;
  static const double iconContainerHeight = 28;
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
      label: 'Chat',
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
    return Material(
      key: const ValueKey('floating-bottom-nav-transparent-outer'),
      type: MaterialType.transparency,
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
              child: SizedBox(
                key: const ValueKey('floating-bottom-nav-bar'),
                height: barHeight,
                child: DecoratedBox(
                  key: const ValueKey('floating-bottom-nav-container-surface'),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: .96),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: .14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: .1),
                        blurRadius: 20,
                        spreadRadius: -7,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AmoraSpacing.space4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in items)
                          Expanded(
                            child: _BottomNavButton(
                              item: item,
                              selected: item.tab == activeTab,
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
    required this.onTap,
  });

  final AmoraNavigationDestination item;
  final bool selected;
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final selected = widget.selected;
    final item = widget.item;
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
            color: _hovered ? AppColors.background : AppColors.transparent,
            borderRadius: AmoraRadius.pillBorder,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey('bottom-nav-${item.label}'),
              onTap: widget.onTap,
              onHighlightChanged: (value) => setState(() => _pressed = value),
              onHover: (value) => setState(() => _hovered = value),
              onFocusChange: (value) => setState(() => _focused = value),
              focusColor: AppColors.background,
              hoverColor: AppColors.background,
              highlightColor: AppColors.tertiary.withValues(alpha: .28),
              splashColor: AppColors.secondary.withValues(alpha: .18),
              borderRadius: AmoraRadius.pillBorder,
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
                            ? AppColors.tertiary.withValues(alpha: .42)
                            : AppColors.transparent,
                        borderRadius: AmoraRadius.pillBorder,
                        border: Border.all(
                          color: _focused
                              ? AppColors.secondary
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
                          color: selected
                              ? AppColors.primary
                              : AppColors.text.withValues(alpha: .68),
                          size: selected
                              ? FloatingBottomNav.selectedIconSize
                              : FloatingBottomNav.iconSize,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space4),
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.08,
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      style: AmoraTextStyles.labelSmall.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.text.withValues(alpha: .68),
                        fontSize: FloatingBottomNav.labelSize,
                        fontFamily: AmoraTextStyles.fontFamily,
                        height: 1,
                        letterSpacing: -.35,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      child: Text(
                        item.label,
                        key: ValueKey('bottom-nav-label-${item.label}'),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.fade,
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
