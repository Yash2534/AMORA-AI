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
  int get _unreadCount => _notifications.where((item) => item.unread).length;

  List<String> get _availableFilters => <String>[
    'All',
    'Unread',
    for (final filter in _notificationFilters)
      if (filter != 'All' &&
          filter != 'Unread' &&
          _notifications.any((item) => item.category == filter))
        filter,
  ];

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
    final unreadCount = _unreadCount;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 680,
          child: Column(
            children: [
              _NotificationsAppBar(
                onBack: _goBack,
                unreadCount: unreadCount,
                onMarkAllRead: unreadCount == 0 ? null : _markAllRead,
                onSettings: () => Navigator.of(
                  context,
                ).pushNamed(NotificationPreferencesScreen.routeName),
              ),
              if (unreadCount > 0)
                _NotificationsSummaryStrip(
                  unreadCount: unreadCount,
                  unreadMatches: _notifications
                      .where(
                        (item) => item.unread && item.category == 'Matches',
                      )
                      .length,
                  unreadMessages: _notifications
                      .where(
                        (item) => item.unread && item.category == 'Messages',
                      )
                      .length,
                ),
              _NotificationFilterRail(
                filters: _availableFilters,
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
                    ? _notifications.isEmpty
                          ? _NotificationEmptyState(onDiscover: _openDiscover)
                          : _NotificationFilteredEmptyState(
                              onShowAll: () {
                                setState(() {
                                  _filter = 'All';
                                  _selectedIds.clear();
                                });
                              },
                            )
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
                            child: _NotificationTile(
                              item: item,
                              selected: _selectedIds.contains(item.id),
                              selectionMode: _selectionMode,
                              onTap: () => _handleTap(item),
                              onLongPress: () => _toggleSelection(item),
                              onMarkRead: () => _markRead(item),
                              onDelete: () => _delete(item),
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

  void _markAllRead() {
    if (_unreadCount == 0) return;
    setState(() {
      for (final item in _notifications) {
        item.unread = false;
      }
      _selectedIds.clear();
    });
    _showMessage('All notifications marked as read');
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
  const _NotificationsAppBar({
    required this.onBack,
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final int unreadCount;
  final VoidCallback? onMarkAllRead;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.tertiary.withValues(alpha: .46)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showMarkAllLabel = constraints.maxWidth >= 520;
            final compact = constraints.maxWidth < 380;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _AppBarButton(
                    key: const ValueKey('notifications-back-button'),
                    tooltip: 'Back',
                    semanticLabel: 'Back from notifications',
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Notifications',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AmoraTextStyles.titleLarge.copyWith(
                              color: AppColors.primary,
                              fontSize: compact ? 21 : 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (unreadCount > 0 && !compact) ...[
                          const SizedBox(width: 8),
                          Semantics(
                            label: '$unreadCount unread notifications',
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(99),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$unreadCount',
                                style: AmoraTextStyles.labelSmall.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showMarkAllLabel)
                    Tooltip(
                      message: 'Mark all as read',
                      child: Semantics(
                        button: true,
                        enabled: onMarkAllRead != null,
                        label: 'Mark all notifications as read',
                        child: TextButton.icon(
                          key: const ValueKey(
                            'notifications-mark-all-read-button',
                          ),
                          onPressed: onMarkAllRead,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 20,
                          ),
                          label: const Text('Mark all'),
                        ),
                      ),
                    )
                  else
                    _AppBarButton(
                      key: const ValueKey('notifications-mark-all-read-button'),
                      tooltip: 'Mark all as read',
                      semanticLabel: 'Mark all notifications as read',
                      icon: Icons.mark_email_read_rounded,
                      onTap: onMarkAllRead,
                    ),
                  _AppBarButton(
                    key: const ValueKey('notifications-settings-button'),
                    tooltip: 'Notification preferences',
                    semanticLabel: 'Open notification preferences',
                    icon: Icons.settings_rounded,
                    onTap: onSettings,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsSummaryStrip extends StatelessWidget {
  const _NotificationsSummaryStrip({
    required this.unreadCount,
    required this.unreadMatches,
    required this.unreadMessages,
  });

  final int unreadCount;
  final int unreadMatches;
  final int unreadMessages;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (unreadMatches > 0)
        '$unreadMatches new ${unreadMatches == 1 ? 'match' : 'matches'}',
      if (unreadMessages > 0)
        '$unreadMessages ${unreadMessages == 1 ? 'message' : 'messages'} waiting',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.secondary.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .28),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unreadCount unread ${unreadCount == 1 ? 'notification' : 'notifications'}',
                    style: AmoraTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.text.withValues(alpha: .66),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    super.key,
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: SizedBox.square(
        dimension: 48,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.primary,
            disabledForegroundColor: AppColors.tertiary,
            hoverColor: AppColors.background,
            focusColor: AppColors.tertiary.withValues(alpha: .24),
            highlightColor: AppColors.tertiary.withValues(alpha: .2),
          ),
          icon: Icon(icon, size: 22),
        ),
      ),
    );
  }
}

class _NotificationFilterRail extends StatelessWidget {
  const _NotificationFilterRail({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('notification-filter-rail'),
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: filters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AmoraSpacing.space8),
        itemBuilder: (context, index) {
          final filter = filters[index];
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _notificationFilterIcon(widget.label),
                        size: 17,
                        color: widget.selected
                            ? AppColors.surface
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        widget.label,
                        style: AmoraTextStyles.labelMedium.copyWith(
                          color: widget.selected
                              ? AppColors.surface
                              : AppColors.text,
                          fontWeight: widget.selected
                              ? FontWeight.w700
                              : FontWeight.w600,
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

IconData _notificationFilterIcon(String label) {
  return switch (label) {
    'Unread' => Icons.mark_email_unread_rounded,
    'Matches' => Icons.auto_awesome_rounded,
    'Messages' => Icons.chat_bubble_rounded,
    'Likes' => Icons.favorite_rounded,
    'Super Likes' => Icons.star_rounded,
    'Events' => Icons.event_rounded,
    'Profile Views' => Icons.visibility_rounded,
    'Verification' => Icons.verified_user_rounded,
    'Security' => Icons.shield_rounded,
    'Payments' => Icons.credit_card_rounded,
    'Offers' => Icons.local_offer_rounded,
    _ => Icons.notifications_rounded,
  };
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
      duration: const Duration(milliseconds: 260),
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
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
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
    final item = widget.item;
    final semanticState = item.unread ? 'Unread' : 'Read';
    return Semantics(
      button: true,
      selected: widget.selected,
      label:
          '${item.title}. ${item.description}. ${item.relativeTime}. $semanticState.',
      child: Dismissible(
        key: ValueKey('notification-tile-${item.id}'),
        direction: widget.selectionMode
            ? DismissDirection.none
            : item.unread
            ? DismissDirection.horizontal
            : DismissDirection.endToStart,
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
            scale: _pressed ? .99 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 88),
              decoration: BoxDecoration(
                color: widget.selected
                    ? AppColors.tertiary.withValues(alpha: .34)
                    : item.unread
                    ? AppColors.background.withValues(alpha: .84)
                    : AppColors.surface,
                borderRadius: widget.selected
                    ? BorderRadius.circular(18)
                    : BorderRadius.zero,
                border: widget.selected
                    ? Border.all(color: AppColors.secondary, width: 1.4)
                    : Border(
                        left: BorderSide(
                          color: item.unread
                              ? AppColors.secondary
                              : AppColors.transparent,
                          width: item.unread ? 3 : 0,
                        ),
                        bottom: BorderSide(
                          color: AppColors.tertiary.withValues(alpha: .38),
                        ),
                      ),
              ),
              child: Material(
                color: AppColors.transparent,
                borderRadius: widget.selected
                    ? BorderRadius.circular(18)
                    : BorderRadius.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  focusColor: AppColors.tertiary.withValues(alpha: .22),
                  hoverColor: AppColors.background.withValues(alpha: .62),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NotificationAvatar(item: item),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AmoraTextStyles.titleSmall
                                          .copyWith(
                                            color: AppColors.text,
                                            fontSize: 15,
                                            fontWeight: item.unread
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            height: 1.24,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 92,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          item.relativeTime,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.right,
                                          style: AmoraTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.text
                                                    .withValues(alpha: .54),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                height: 1.2,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        if (widget.selected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                            size: 19,
                                          )
                                        else if (item.unread)
                                          _NotificationBadge(
                                            key: ValueKey(
                                              'notification-unread-${item.id}',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AmoraTextStyles.bodyMedium.copyWith(
                                  color: AppColors.text.withValues(alpha: .7),
                                  fontSize: 14,
                                  height: 1.35,
                                  fontWeight: item.unread
                                      ? FontWeight.w500
                                      : FontWeight.w400,
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
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  const _NotificationAvatar({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final contextualIcon =
        item.category == 'Verification' ||
        item.category == 'Security' ||
        item.category == 'Payments';
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (contextualIcon)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: .2),
                ),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 24),
            )
          else
            PremiumAssetImage(
              imageUrl: item.imageUrl,
              fallbackAsset: item.fallbackAsset,
              initials: item.initials,
              width: 52,
              height: 52,
              borderRadius: BorderRadius.circular(26),
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
                width: 22,
                height: 22,
                child: Icon(item.icon, color: AppColors.surface, size: 12),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0) ...[
              Container(
                width: 56,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              height: 92,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.tertiary.withValues(alpha: .38),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: .3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: .7,
                                child: Container(
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: AppColors.tertiary.withValues(
                                      alpha: .44,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 42,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withValues(
                                  alpha: .26,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        FractionallySizedBox(
                          widthFactor: .88,
                          child: Container(
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withValues(alpha: .26),
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
          ],
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
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: .22),
                ),
              ),
              child: SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: .26),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const Positioned(
                      right: 13,
                      top: 14,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: AppColors.secondary,
                        size: 17,
                      ),
                    ),
                  ],
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
              'Matches, messages, events, and important updates will appear here.',
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

class _NotificationFilteredEmptyState extends StatelessWidget {
  const _NotificationFilteredEmptyState({required this.onShowAll});

  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .24),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.filter_alt_off_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No notifications here',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.titleLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Try another category.',
              textAlign: TextAlign.center,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.text.withValues(alpha: .66),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onShowAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.secondary.withValues(alpha: .42),
                ),
                minimumSize: const Size(160, 48),
              ),
              icon: const Icon(Icons.notifications_rounded, size: 19),
              label: const Text('Show All'),
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
