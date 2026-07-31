import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

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
  static const double bottomMargin = 0;
  static const double contentBottomPadding = 96;
  static const double assistantBottomPadding = 88;

  static const items = <AmoraNavigationDestination>[
    AmoraNavigationDestination(
      icon: Icons.explore_outlined,
      label: 'Discover',
      tab: AmoraNavTab.discover,
      routeName: '/discover',
    ),
    AmoraNavigationDestination(
      icon: Icons.chat_bubble_outline_rounded,
      label: 'Chats',
      tab: AmoraNavTab.chats,
      routeName: '/chats',
    ),
    AmoraNavigationDestination(
      icon: Icons.auto_awesome_outlined,
      label: 'AI Matches',
      tab: AmoraNavTab.matches,
      routeName: '/matches',
    ),
    AmoraNavigationDestination(
      icon: Icons.calendar_month_outlined,
      label: 'Events',
      tab: AmoraNavTab.events,
      routeName: '/events',
    ),
    AmoraNavigationDestination(
      icon: Icons.person_outline_rounded,
      label: 'Profile',
      tab: AmoraNavTab.profile,
      routeName: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AmoraSpacing.space8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                        child: Text(
                          widget.item.label,
                          maxLines: 2,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.fade,
                          style: AmoraTextStyles.labelSmall.copyWith(
                            color: widget.selected
                                ? AppColors.active
                                : AppColors.textNeutral,
                            fontSize: 10,
                            height: 1,
                            letterSpacing: -.2,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
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
    );
  }
}

class AmoraNavigationDestination {
  const AmoraNavigationDestination({
    required this.tab,
    required this.icon,
    required this.label,
    required this.routeName,
  });

  final AmoraNavTab tab;
  final IconData icon;
  final String label;
  final String routeName;
}
