<<<<<<< HEAD
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
=======
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
>>>>>>> main
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

<<<<<<< HEAD
enum AmoraNavTab {
  discover,
  likes,
  messages,
  profile,

  // Compatibility values for secondary legacy screens. They are deliberately
  // not rendered as primary navigation destinations.
  home,
  events,
  matches,
  chats,
}
=======
enum AmoraNavTab { discover, chats, matches, events, profile }
>>>>>>> main

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.activeTab,
    this.onTabSelected,
  });

  final AmoraNavTab activeTab;
  final ValueChanged<AmoraNavTab>? onTabSelected;

<<<<<<< HEAD
  static const double barHeight = 68;
  static const double bottomMargin = AmoraSpacing.space0;
  static const double contentBottomPadding = AmoraSpacing.space24;
  static const double assistantBottomPadding = barHeight + AmoraSpacing.space16;

  static const items = <AmoraNavigationDestination>[
    AmoraNavigationDestination(
=======
  static const double barHeight = 72;
  static const double bottomMargin = 0;
  static const double contentBottomPadding = 96;
  static const double assistantBottomPadding = 88;

  static const _items = <_NavItem>[
    _NavItem(
      icon: Icons.explore_outlined,
      label: 'Discover',
>>>>>>> main
      tab: AmoraNavTab.discover,
      label: 'Discover',
      inactiveIcon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      routeName: '/browse',
    ),
<<<<<<< HEAD
    AmoraNavigationDestination(
      tab: AmoraNavTab.likes,
      label: 'Likes',
      inactiveIcon: Icons.favorite_border_rounded,
      activeIcon: Icons.favorite_rounded,
      routeName: '/matches',
    ),
    AmoraNavigationDestination(
      tab: AmoraNavTab.messages,
      label: 'Messages',
      inactiveIcon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      routeName: '/chats',
    ),
    AmoraNavigationDestination(
=======
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Chats',
      tab: AmoraNavTab.chats,
      routeName: '/chats',
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      label: 'AI Matches',
      tab: AmoraNavTab.matches,
      routeName: '/matches',
    ),
    _NavItem(
      icon: Icons.calendar_month_outlined,
      label: 'Events',
      tab: AmoraNavTab.events,
      routeName: '/events',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      label: 'Profile',
>>>>>>> main
      tab: AmoraNavTab.profile,
      label: 'Profile',
      inactiveIcon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      routeName: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _NavigationButton(
                    item: item,
                    selected: _normalized(activeTab) == item.tab,
                    onTap: () => _select(context, item),
                  ),
                ),
            ],
          ),
=======
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AmoraSpacing.space8),
      child: SizedBox(
        height: barHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: AppColors.tertiary),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .14),
                blurRadius: 26,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space4,
              vertical: AmoraSpacing.space4,
            ),
            child: Row(
              children: [
                for (final item in _items)
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
>>>>>>> main
        ),
      ),
    );
  }

<<<<<<< HEAD
  void _select(BuildContext context, AmoraNavigationDestination item) {
    if (_normalized(activeTab) == item.tab) return;
    if (onTabSelected case final callback?) {
      callback(item.tab);
      return;
    }
=======
  void _handleTap(BuildContext context, _NavItem item) {
    if (item.tab == activeTab) return;
>>>>>>> main
    Navigator.of(context).pushReplacementNamed(item.routeName);
  }

  static AmoraNavTab _normalized(AmoraNavTab tab) => switch (tab) {
    AmoraNavTab.matches => AmoraNavTab.likes,
    AmoraNavTab.chats => AmoraNavTab.messages,
    _ => tab,
  };
}

<<<<<<< HEAD
class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
=======
class _BottomNavButton extends StatefulWidget {
  const _BottomNavButton({
>>>>>>> main
    required this.item,
    required this.selected,
    required this.onTap,
  });

<<<<<<< HEAD
  final AmoraNavigationDestination item;
=======
  final _NavItem item;
>>>>>>> main
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_BottomNavButton> createState() => _BottomNavButtonState();
}

class _BottomNavButtonState extends State<_BottomNavButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _scale = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  void _animateTo(double target, {double velocity = 0}) {
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .8, stiffness: 520, damping: 30),
        _scale.value,
        target,
        velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Semantics(
      button: true,
      selected: selected,
      label: '${item.label} tab',
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          focusColor: AppColors.hover,
          hoverColor: AppColors.hover,
          splashColor: AppColors.pressed,
          child: Center(
            child: AnimatedContainer(
              duration: AmoraMotion.selection,
              curve: AmoraMotion.curve,
              constraints: const BoxConstraints(
                minWidth: AmoraSpacing.minimumTouchTarget,
                minHeight: AmoraSpacing.minimumTouchTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space12,
                vertical: AmoraSpacing.space4,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.activeContainer
                    : AppColors.transparent,
                borderRadius: AmoraRadius.pillBorder,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? item.activeIcon : item.inactiveIcon,
                    size: AmoraIconSizes.standard,
                    color: selected ? AppColors.active : AppColors.primary,
=======
    return Tooltip(
      message: widget.item.label,
      child: MouseRegion(
        onEnter: (_) {
          _hovered = true;
          _animateTo(1.035);
        },
        onExit: (_) {
          _hovered = false;
          _animateTo(1);
        },
        child: Listener(
          onPointerDown: (_) => _animateTo(.94, velocity: -1),
          onPointerUp: (_) => _animateTo(_hovered ? 1.035 : 1, velocity: 1),
          onPointerCancel: (_) => _animateTo(_hovered ? 1.035 : 1),
          child: ScaleTransition(
            scale: _scale,
            child: Material(
              color: AppColors.surface,
              borderRadius: AmoraRadius.pillBorder,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: ValueKey('bottom-nav-${widget.item.label}'),
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AmoraSpacing.space4,
                    vertical: AmoraSpacing.space4,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSlide(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        offset: widget.selected
                            ? const Offset(0, -.08)
                            : Offset.zero,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutBack,
                          width: widget.selected ? 38 : 34,
                          height: widget.selected ? 38 : 34,
                          decoration: BoxDecoration(
                            color: widget.selected
                                ? AppColors.primary
                                : AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              widget.item.icon,
                              key: ValueKey(widget.selected),
                              color: widget.selected
                                  ? AppColors.surface
                                  : AppColors.textNeutral,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Flexible(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOut,
                          style: AmoraTextStyles.labelSmall.copyWith(
                            color: widget.selected
                                ? AppColors.primary
                                : AppColors.textNeutral,
                            fontSize: 10,
                            height: 1,
                            letterSpacing: -.2,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          child: Text(
                            widget.item.label,
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ],
>>>>>>> main
                  ),
                  const SizedBox(height: AmoraSpacing.space4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.navigation.copyWith(
                      color: selected
                          ? AppColors.active
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
<<<<<<< HEAD
    required this.label,
    required this.inactiveIcon,
    required this.activeIcon,
=======
>>>>>>> main
    required this.routeName,
  });

  final AmoraNavTab tab;
<<<<<<< HEAD
  final String label;
  final IconData inactiveIcon;
  final IconData activeIcon;
=======
>>>>>>> main
  final String routeName;
}
