import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/chat/presentation/chat_detail_screen.dart';
import 'package:amora_ai/features/events/presentation/event_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/settings/presentation/notification_preferences_screen.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class NotificationsHubScreen extends StatefulWidget {
  const NotificationsHubScreen({super.key});

  static const routeName = '/notifications';

  @override
  State<NotificationsHubScreen> createState() => _NotificationsHubScreenState();
}

class _NotificationsHubScreenState extends State<NotificationsHubScreen> {
  final List<_NotificationItem> _notifications = _buildSeedNotifications();
  final Set<String> _selectedIds = <String>{};
  String _filter = 'All';

  bool get _selectionMode => _selectedIds.isNotEmpty;

  List<_NotificationItem> get _filteredNotifications {
    if (_filter == 'All') return _notifications;
    if (_filter == 'Unread') {
      return _notifications
          .where((item) => item.unread)
          .toList(growable: false);
    }
    return _notifications
        .where((item) => item.category == _filter)
        .toList(growable: false);
  }

  List<Object> get _feedEntries {
    final entries = <Object>[];
    final visible = _filteredNotifications;
    for (final group in _notificationGroups) {
      final groupItems = visible
          .where((item) => item.group == group)
          .toList(growable: false);
      if (groupItems.isEmpty) continue;
      entries
        ..add(group)
        ..addAll(groupItems);
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _feedEntries;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 680,
          child: Column(
            children: [
              _NotificationsAppBar(
                onBack: _goBack,
                onSettings: () => Navigator.of(
                  context,
                ).pushNamed(NotificationPreferencesScreen.routeName),
              ),
              const SizedBox(height: AmoraSpacing.space8),
              _NotificationFilterRail(
                selected: _filter,
                onSelected: (filter) {
                  setState(() {
                    _filter = filter;
                    _selectedIds.clear();
                  });
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                child: _selectionMode
                    ? _SelectionToolbar(
                        key: const ValueKey('notification-selection-toolbar'),
                        count: _selectedIds.length,
                        onMarkRead: _markSelectedRead,
                        onDelete: _deleteSelected,
                        onClose: () => setState(_selectedIds.clear),
                      )
                    : const SizedBox(
                        key: ValueKey('notification-selection-empty'),
                        height: AmoraSpacing.space12,
                      ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? _NotificationEmptyState(onDiscover: _openDiscover)
                    : ListView.builder(
                        key: const ValueKey('notification-feed'),
                        padding: const EdgeInsets.fromLTRB(
                          AmoraSpacing.space16,
                          AmoraSpacing.space4,
                          AmoraSpacing.space16,
                          AmoraSpacing.space24,
                        ),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          if (entry is String) {
                            return _NotificationSectionHeader(label: entry);
                          }
                          final item = entry as _NotificationItem;
                          return _AnimatedNotificationEntry(
                            key: ValueKey('notification-entry-${item.id}'),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AmoraSpacing.space12,
                              ),
                              child: _NotificationTile(
                                item: item,
                                selected: _selectedIds.contains(item.id),
                                selectionMode: _selectionMode,
                                onTap: () => _handleTap(item),
                                onLongPress: () => _toggleSelection(item),
                                onMarkRead: () => _markRead(item),
                                onDelete: () => _delete(item),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goBack() async {
    if (await Navigator.of(context).maybePop()) return;
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/browse');
  }

  void _handleTap(_NotificationItem item) {
    if (_selectionMode) {
      _toggleSelection(item);
      return;
    }
    _markRead(item, announce: false);
    if (item.route == null) {
      _showMessage(item.title);
      return;
    }
    Navigator.of(context).pushNamed(item.route!, arguments: item.arguments);
  }

  void _toggleSelection(_NotificationItem item) {
    setState(() {
      if (!_selectedIds.add(item.id)) _selectedIds.remove(item.id);
    });
  }

  void _markRead(_NotificationItem item, {bool announce = true}) {
    if (!item.unread) return;
    setState(() => item.unread = false);
    if (announce) _showMessage('Marked as read');
  }

  void _delete(_NotificationItem item) {
    setState(() {
      _notifications.remove(item);
      _selectedIds.remove(item.id);
    });
    _showMessage('Notification deleted');
  }

  void _markSelectedRead() {
    setState(() {
      for (final item in _notifications) {
        if (_selectedIds.contains(item.id)) item.unread = false;
      }
      _selectedIds.clear();
    });
    _showMessage('Selected notifications marked as read');
  }

  void _deleteSelected() {
    setState(() {
      _notifications.removeWhere((item) => _selectedIds.contains(item.id));
      _selectedIds.clear();
    });
    _showMessage('Selected notifications deleted');
  }

  void _openDiscover() {
    Navigator.of(context).pushReplacementNamed('/browse');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            message,
            style: const TextStyle(color: AppColors.surface),
          ),
        ),
      );
  }
}

class _NotificationsAppBar extends StatelessWidget {
  const _NotificationsAppBar({required this.onBack, required this.onSettings});

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AmoraSpacing.space16,
        AmoraSpacing.space8,
        AmoraSpacing.space16,
        0,
      ),
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .10),
                blurRadius: 24,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('notifications-back-button'),
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: Text(
                    'Back',
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 76),
                child: Text(
                  'Notifications',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AmoraTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _AppBarButton(
                  key: const ValueKey('notifications-settings-button'),
                  tooltip: 'Notification preferences',
                  icon: Icons.settings_rounded,
                  onTap: onSettings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.primary, size: 23),
      ),
    );
  }
}

class _NotificationFilterRail extends StatelessWidget {
  const _NotificationFilterRail({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('notification-filter-rail'),
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _notificationFilters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AmoraSpacing.space8),
        itemBuilder: (context, index) {
          final filter = _notificationFilters[index];
          return _NotificationFilterChip(
            key: ValueKey('notification-filter-$filter'),
            label: filter,
            selected: selected == filter,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _NotificationFilterChip extends StatefulWidget {
  const _NotificationFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NotificationFilterChip> createState() =>
      _NotificationFilterChipState();
}

class _NotificationFilterChipState extends State<_NotificationFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale;

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

  void _animate(double target) {
    _scale.animateWith(
      SpringSimulation(
        const SpringDescription(mass: .8, stiffness: 500, damping: 30),
        _scale.value,
        target,
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _animate(.95),
      onPointerUp: (_) => _animate(1),
      onPointerCancel: (_) => _animate(1),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: ShapeDecoration(
            color: widget.selected ? AppColors.primary : AppColors.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: widget.selected
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
            ),
            shadows: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .06),
                blurRadius: 12,
                spreadRadius: -6,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: widget.selected ? AppColors.primary : AppColors.surface,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space16,
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: widget.selected
                          ? AppColors.surface
                          : AppColors.textNeutral,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    super.key,
    required this.count,
    required this.onMarkRead,
    required this.onDelete,
    required this.onClose,
  });

  final int count;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AmoraSpacing.space16,
        AmoraSpacing.space12,
        AmoraSpacing.space16,
        AmoraSpacing.space4,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.tertiary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AmoraSpacing.space8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$count selected',
                  style: AmoraTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mark selected as read',
                onPressed: onMarkRead,
                icon: const Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                tooltip: 'Delete selected',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.secondary,
                ),
              ),
              IconButton(
                tooltip: 'Exit selection',
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textNeutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSectionHeader extends StatelessWidget {
  const _NotificationSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AmoraSpacing.space4,
        AmoraSpacing.space16,
        AmoraSpacing.space4,
        AmoraSpacing.space12,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AmoraTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AmoraSpacing.space12),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.tertiary.withValues(alpha: .72),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNotificationEntry extends StatefulWidget {
  const _AnimatedNotificationEntry({super.key, required this.child});

  final Widget child;

  @override
  State<_AnimatedNotificationEntry> createState() =>
      _AnimatedNotificationEntryState();
}

class _AnimatedNotificationEntryState extends State<_AnimatedNotificationEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _slide = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _NotificationTile extends StatefulWidget {
  const _NotificationTile({
    required this.item,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onMarkRead,
    required this.onDelete,
  });

  final _NotificationItem item;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('notification-tile-${widget.item.id}'),
      direction: widget.selectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      background: const _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppColors.primary,
        icon: Icons.mark_email_read_rounded,
        label: 'Mark as read',
      ),
      secondaryBackground: const _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.secondary,
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          widget.onMarkRead();
          return false;
        }
        return true;
      },
      onDismissed: (direction) => widget.onDelete(),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? .985 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.tertiary.withValues(alpha: .38)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.selected
                    ? AppColors.secondary
                    : AppColors.tertiary.withValues(alpha: .52),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .08),
                  blurRadius: 22,
                  spreadRadius: -10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: widget.selected
                  ? AppColors.tertiary.withValues(alpha: .38)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                child: Padding(
                  padding: const EdgeInsets.all(AmoraSpacing.space16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotificationAvatar(item: widget.item),
                      const SizedBox(width: AmoraSpacing.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AmoraTextStyles.titleSmall.copyWith(
                                      color: AppColors.textNeutral,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AmoraSpacing.space8),
                                if (widget.selected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.secondary,
                                    size: 20,
                                  )
                                else if (widget.item.unread)
                                  _NotificationBadge(
                                    key: ValueKey(
                                      'notification-unread-${widget.item.id}',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AmoraTextStyles.bodyMedium.copyWith(
                                color: AppColors.textNeutral.withValues(
                                  alpha: .72,
                                ),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.item.relativeTime,
                              style: AmoraTextStyles.labelSmall.copyWith(
                                color: AppColors.textNeutral.withValues(
                                  alpha: .52,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PremiumAssetImage(
            imageUrl: item.imageUrl,
            fallbackAsset: item.fallbackAsset,
            initials: item.initials,
            width: 54,
            height: 54,
            borderRadius: BorderRadius.circular(20),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Icon(item.icon, color: AppColors.surface, size: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  const _NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Unread',
      child: Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(top: AmoraSpacing.space4),
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final alignLeft = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: EdgeInsets.only(
        left: alignLeft ? AmoraSpacing.space20 : 0,
        right: alignLeft ? 0 : AmoraSpacing.space20,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.surface, size: 24),
          const SizedBox(height: AmoraSpacing.space4),
          Text(
            label,
            style: AmoraTextStyles.labelSmall.copyWith(
              color: AppColors.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ready for a future real loading state without introducing a fake delay now.
class NotificationSkeletonLoader extends StatelessWidget {
  const NotificationSkeletonLoader({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AmoraSpacing.space12),
          child: Container(
            height: 112,
            padding: const EdgeInsets.all(AmoraSpacing.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.tertiary.withValues(alpha: .48),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: .34),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: .62,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: .46),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                      FractionallySizedBox(
                        widthFactor: .88,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.tertiary.withValues(alpha: .28),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AmoraSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .36),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 104,
                height: 104,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space24),
            Text(
              "You're all caught up",
              textAlign: TextAlign.center,
              style: AmoraTextStyles.headlineSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space8),
            Text(
              "We'll notify you when something important happens.",
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textNeutral.withValues(alpha: .66),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space24),
            FilledButton.icon(
              key: const ValueKey('notifications-discover-button'),
              onPressed: onDiscover,
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Discover People'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                minimumSize: const Size(200, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.relativeTime,
    required this.group,
    required this.category,
    required this.icon,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.initials,
    required this.route,
    this.arguments,
    this.unread = true,
  });

  final String id;
  final String title;
  final String description;
  final String relativeTime;
  final String group;
  final String category;
  final IconData icon;
  final String imageUrl;
  final String fallbackAsset;
  final String initials;
  final String? route;
  final Object? arguments;
  bool unread;
}

const _notificationFilters = <String>[
  'All',
  'Unread',
  'Matches',
  'Messages',
  'Likes',
  'Super Likes',
  'Events',
  'Profile Views',
  'Verification',
  'Security',
  'Payments',
  'Offers',
];

const _notificationGroups = <String>[
  'Today',
  'Yesterday',
  'This Week',
  'Earlier',
];

List<_NotificationItem> _buildSeedNotifications() => <_NotificationItem>[
  _profileNotification(
    id: 'like-kavya',
    profileName: 'Kavya',
    title: 'Kavya liked your profile',
    description: 'Your travel prompt caught her attention.',
    relativeTime: '2 min ago',
    group: 'Today',
    category: 'Likes',
    icon: Icons.favorite_rounded,
  ),
  _profileNotification(
    id: 'message-riya',
    profileName: 'Riya',
    title: 'Riya sent you a new message',
    description: '“That coffee place looks perfect. Saturday?”',
    relativeTime: '12 min ago',
    group: 'Today',
    category: 'Messages',
    icon: Icons.chat_bubble_rounded,
    route: ChatDetailScreen.routeName,
  ),
  _profileNotification(
    id: 'match-aadhya',
    profileName: 'Aadhya',
    title: 'You have a new AI Match',
    description: 'Aadhya is 96% compatible with your relationship goals.',
    relativeTime: '28 min ago',
    group: 'Today',
    category: 'Matches',
    icon: Icons.auto_awesome_rounded,
  ),
  _profileNotification(
    id: 'super-like-meera',
    profileName: 'Meera',
    title: 'Meera Super Liked you',
    description: 'She thinks your shared love of live music is a strong start.',
    relativeTime: '1 hr ago',
    group: 'Today',
    category: 'Super Likes',
    icon: Icons.star_rounded,
  ),
  _eventNotification(),
  _profileNotification(
    id: 'view-nisha',
    profileName: 'Nisha',
    title: 'Nisha viewed your profile',
    description: 'Your profile made an impression yesterday.',
    relativeTime: 'Yesterday, 8:42 PM',
    group: 'Yesterday',
    category: 'Profile Views',
    icon: Icons.visibility_rounded,
    unread: false,
  ),
  _systemNotification(
    id: 'verification-approved',
    title: 'Identity verification approved',
    description: 'Your verified badge is now visible across Amora.',
    relativeTime: 'Yesterday, 3:18 PM',
    group: 'Yesterday',
    category: 'Verification',
    icon: Icons.verified_user_rounded,
    route: KycVerificationScreen.routeName,
  ),
  _profileNotification(
    id: 'nearby-matches',
    profileName: 'Ishita',
    title: 'New nearby matches found',
    description: 'Five compatible people joined near Ahmedabad this week.',
    relativeTime: 'Monday',
    group: 'This Week',
    category: 'Matches',
    icon: Icons.location_on_rounded,
    unread: false,
  ),
  _profileNotification(
    id: 'coffee-accepted',
    profileName: 'Sneha',
    title: 'Coffee Date request accepted',
    description: 'Sneha accepted your plan for Sunday at 4 PM.',
    relativeTime: 'Sunday',
    group: 'This Week',
    category: 'Messages',
    icon: Icons.coffee_rounded,
    unread: false,
  ),
  _offerNotification(),
  _systemNotification(
    id: 'security-login',
    title: 'New security login detected',
    description: 'Chrome on Windows signed in from Ahmedabad.',
    relativeTime: 'Jun 18',
    group: 'Earlier',
    category: 'Security',
    icon: Icons.lock_rounded,
    route: null,
    unread: false,
  ),
  _systemNotification(
    id: 'subscription-renewed',
    title: 'Subscription renewed',
    description: 'Your Amora Gold membership renewed successfully.',
    relativeTime: 'Jun 12',
    group: 'Earlier',
    category: 'Payments',
    icon: Icons.credit_card_rounded,
    route: SubscriptionScreen.routeName,
    unread: false,
  ),
];

_NotificationItem _profileNotification({
  required String id,
  required String profileName,
  required String title,
  required String description,
  required String relativeTime,
  required String group,
  required String category,
  required IconData icon,
  String route = ProfileDetailScreen.routeName,
  bool unread = true,
}) {
  final profile = ImageRepository.profileByName(profileName);
  return _NotificationItem(
    id: id,
    title: title,
    description: description,
    relativeTime: relativeTime,
    group: group,
    category: category,
    icon: icon,
    imageUrl: profile.imageUrl,
    fallbackAsset: profile.fallbackAsset,
    initials: profile.initials,
    route: route,
    arguments: profile,
    unread: unread,
  );
}

_NotificationItem _systemNotification({
  required String id,
  required String title,
  required String description,
  required String relativeTime,
  required String group,
  required String category,
  required IconData icon,
  required String? route,
  bool unread = true,
}) {
  final profile = ImageRepository.profileByName('Yash');
  return _NotificationItem(
    id: id,
    title: title,
    description: description,
    relativeTime: relativeTime,
    group: group,
    category: category,
    icon: icon,
    imageUrl: profile.imageUrl,
    fallbackAsset: profile.fallbackAsset,
    initials: profile.initials,
    route: route,
    unread: unread,
  );
}

_NotificationItem _eventNotification() {
  final event = ImageRepository.eventByName('Coffee Meetup');
  return _NotificationItem(
    id: 'event-reminder',
    title: 'Coffee Match Meetup is tomorrow',
    description: 'Your event starts at 6 PM. Check in opens 30 minutes early.',
    relativeTime: 'Yesterday, 9:10 PM',
    group: 'Yesterday',
    category: 'Events',
    icon: Icons.event_available_rounded,
    imageUrl: event.imageUrl,
    fallbackAsset: event.fallbackAsset,
    initials: 'EV',
    route: EventDetailScreen.routeName,
    arguments: event,
  );
}

_NotificationItem _offerNotification() {
  final venue = ImageRepository.venueByName('Skyline Social Lounge');
  return _NotificationItem(
    id: 'premium-offer',
    title: 'A premium offer is available',
    description: 'Save on Amora Gold when you upgrade before Friday.',
    relativeTime: 'Saturday',
    group: 'This Week',
    category: 'Offers',
    icon: Icons.local_offer_rounded,
    imageUrl: venue.imageUrl,
    fallbackAsset: venue.fallbackAsset,
    initials: 'GO',
    route: SubscriptionScreen.routeName,
  );
}
