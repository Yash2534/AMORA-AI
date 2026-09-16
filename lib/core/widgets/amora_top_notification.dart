import 'dart:async';
import 'dart:ui';

import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Notification categories supported by the AMORA top glass notification system.
enum AmoraTopNotificationType {
  match,
  message,
  like,
  superLike,
  aiMatch,
  verification,
  system,
}

/// Data model for a top notification banner.
class AmoraNotificationData {
  const AmoraNotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.timestamp,
    this.avatarUrl,
    this.onTap,
    this.duration = const Duration(seconds: 4),
  });

  final String id;
  final AmoraTopNotificationType type;
  final String title;
  final String message;
  final String? timestamp;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final Duration duration;
}

/// Global manager for presenting top-positioned glassmorphic notifications.
class AmoraTopNotificationManager {
  AmoraTopNotificationManager._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static BuildContext? get globalContext => navigatorKey.currentContext;

  static final List<_NotificationOverlayEntry> _activeEntries = [];

  /// Show a notification using the global navigator key context or passed context.
  static void showGlobal({
    required String message,
    String? title,
    AmoraTopNotificationType type = AmoraTopNotificationType.system,
    String? timestamp,
    String? avatarUrl,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final ctx = globalContext;
    if (ctx != null) {
      show(
        ctx,
        message: message,
        title: title,
        type: type,
        timestamp: timestamp,
        avatarUrl: avatarUrl,
        onTap: onTap,
        duration: duration,
      );
    }
  }

  /// Show a top animated glass notification banner over the active Overlay.
  static void show(
    BuildContext? context, {
    required String message,
    String? title,
    AmoraTopNotificationType type = AmoraTopNotificationType.system,
    String? timestamp,
    String? avatarUrl,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final effectiveContext = context ?? globalContext;
    if (effectiveContext == null) return;

    final String defaultTitle = switch (type) {
      AmoraTopNotificationType.match => 'New Match!',
      AmoraTopNotificationType.message => 'New Message',
      AmoraTopNotificationType.like => 'Someone liked you ❤️',
      AmoraTopNotificationType.superLike => 'You received a Super Like ⭐',
      AmoraTopNotificationType.aiMatch => 'New AI Match',
      AmoraTopNotificationType.verification => 'Profile Verified',
      AmoraTopNotificationType.system => 'Notification',
    };

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final data = AmoraNotificationData(
      id: id,
      type: type,
      title: (title == null || title.trim().isEmpty) ? defaultTitle : title,
      message: message,
      timestamp: timestamp ?? 'Just now',
      avatarUrl: avatarUrl,
      onTap: onTap,
      duration: duration,
    );

    final entryHolder = _NotificationOverlayEntry(
      data: data,
      onDismiss: () => dismiss(data.id),
    );

    _activeEntries
      ..clear()
      ..add(entryHolder);
    _updateGlobalOverlay(effectiveContext);
  }

  /// Dismiss a specific notification by ID.
  static void dismiss(String id) {
    _activeEntries.removeWhere((e) => e.data.id == id);
    _notifyStackListeners();
  }

  /// Dismiss all active top notifications.
  static void dismissAll() {
    _activeEntries.clear();
    _notifyStackListeners();
  }

  static OverlayEntry? _globalOverlayEntry;
  static final StreamController<void> _updateStreamController =
      StreamController<void>.broadcast();

  static void _notifyStackListeners() {
    if (!_updateStreamController.isClosed) {
      _updateStreamController.add(null);
    }
  }

  static void _updateGlobalOverlay(BuildContext context) {
    try {
      if (_globalOverlayEntry == null || !_globalOverlayEntry!.mounted) {
        _globalOverlayEntry?.remove();
        _globalOverlayEntry = null;
        final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
            Overlay.maybeOf(context, rootOverlay: false);
        if (overlay != null) {
          _globalOverlayEntry = OverlayEntry(
            builder: (context) => const _TopNotificationStackOverlay(),
          );
          overlay.insert(_globalOverlayEntry!);
        }
      }
    } catch (_) {
      // Fallback safely if overlay context is invalid
    }
    _notifyStackListeners();
  }
}

class _NotificationOverlayEntry {
  _NotificationOverlayEntry({
    required this.data,
    required this.onDismiss,
  });

  final AmoraNotificationData data;
  final VoidCallback onDismiss;
}

class _TopNotificationStackOverlay extends StatefulWidget {
  const _TopNotificationStackOverlay({super.key});

  @override
  State<_TopNotificationStackOverlay> createState() =>
      _TopNotificationStackOverlayState();
}

class _TopNotificationStackOverlayState
    extends State<_TopNotificationStackOverlay> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = AmoraTopNotificationManager._updateStreamController.stream
        .listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = AmoraTopNotificationManager._activeEntries;
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final topPadding = MediaQuery.viewPaddingOf(context).top;
    final topEntry = entries.first;

    return Positioned(
      top: topPadding + AmoraSpacing.space8,
      left: AmoraSpacing.space16,
      right: AmoraSpacing.space16,
      child: Material(
        type: MaterialType.transparency,
        child: _AnimatedTopNotificationBanner(
          key: ValueKey('top-notif-${topEntry.data.id}'),
          data: topEntry.data,
          onDismiss: topEntry.onDismiss,
        ),
      ),
    );
  }
}

class _AnimatedTopNotificationBanner extends StatefulWidget {
  const _AnimatedTopNotificationBanner({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  final AmoraNotificationData data;
  final VoidCallback onDismiss;

  @override
  State<_AnimatedTopNotificationBanner> createState() =>
      _AnimatedTopNotificationBannerState();
}

class _AnimatedTopNotificationBannerState
    extends State<_AnimatedTopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();

    _autoDismissTimer = Timer(widget.data.duration, () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (!mounted) return;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dismissible(
            key: ValueKey('dismiss-${widget.data.id}'),
            direction: DismissDirection.up,
            onDismissed: (_) {
              _autoDismissTimer?.cancel();
              widget.onDismiss();
            },
            child: AmoraTopNotificationBanner(
              data: widget.data,
              onDismiss: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating glassmorphic top notification banner widget.
class AmoraTopNotificationBanner extends StatelessWidget {
  const AmoraTopNotificationBanner({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  final AmoraNotificationData data;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(data.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shadowColor = style.isSuperLike
        ? AppColors.superLike.withValues(alpha: 0.25)
        : (isDark
            ? Colors.black.withValues(alpha: 0.40)
            : const Color(0xFF6B4E71).withValues(alpha: 0.16));

    final glassColor = isDark
        ? const Color(0xFF1F1B24).withValues(alpha: 0.88)
        : const Color(0xFFFCFAFD).withValues(alpha: 0.85);

    final borderColor = style.isSuperLike
        ? AppColors.superLike.withValues(alpha: 0.50)
        : (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.75));

    final primaryTextColor = style.isSuperLike
        ? (isDark ? AppColors.superLikeContainer : AppColors.onSuperLikeContainer)
        : (isDark ? AppColors.surface : AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            spreadRadius: style.isSuperLike ? 1 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: borderColor,
                width: style.isSuperLike ? 1.5 : 1.2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () {
                  onDismiss();
                  data.onTap?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AmoraSpacing.space16,
                    vertical: AmoraSpacing.space12,
                  ),
                  child: Row(
                    children: [
                      // Circular Icon / Avatar
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: style.isSuperLike
                              ? LinearGradient(
                                  colors: [
                                    AppColors.superLikeContainer,
                                    AppColors.superLike,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: style.isSuperLike ? null : style.bgColor,
                          boxShadow: style.isSuperLike
                              ? [
                                  BoxShadow(
                                    color: AppColors.superLike
                                        .withValues(alpha: 0.45),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                          border: Border.all(
                            color: style.isSuperLike
                                ? AppColors.superLikeContainer
                                : style.iconColor.withValues(alpha: 0.20),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            style.icon,
                            color: style.isSuperLike ? AppColors.onSuperLikeContainer : style.iconColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space12),
                      // Text content
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data.title,
                                    style: AmoraTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (data.timestamp case final ts?) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    ts,
                                    style: AmoraTextStyles.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.textMuted
                                          : AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data.message,
                              style: AmoraTextStyles.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.surface.withValues(alpha: 0.85)
                                    : AppColors.textSecondary,
                                fontSize: 12.5,
                                height: 1.25,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AmoraSpacing.space8),
                      // Dismiss Close Icon
                      InkWell(
                        onTap: onDismiss,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : AppColors.textMuted.withValues(alpha: 0.8),
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

  _NotificationStyle _styleFor(AmoraTopNotificationType type) {
    return switch (type) {
      AmoraTopNotificationType.match => const _NotificationStyle(
          icon: Icons.favorite_rounded,
          iconColor: Color(0xFFE91E63),
          bgColor: Color(0xFFFDE8F3),
        ),
      AmoraTopNotificationType.message => const _NotificationStyle(
          icon: Icons.chat_bubble_rounded,
          iconColor: Color(0xFF713F62),
          bgColor: Color(0xFFF3E8F0),
        ),
      AmoraTopNotificationType.like => const _NotificationStyle(
          icon: Icons.favorite_rounded,
          iconColor: AppColors.primary,
          bgColor: AppColors.accentSoft,
        ),
      AmoraTopNotificationType.superLike => const _NotificationStyle(
          icon: Icons.star_rounded,
          iconColor: AppColors.superLike,
          bgColor: AppColors.superLikeContainer,
          isSuperLike: true,
        ),
      AmoraTopNotificationType.aiMatch => const _NotificationStyle(
          icon: Icons.auto_awesome_rounded,
          iconColor: Color(0xFF8E24AA),
          bgColor: Color(0xFFF5EBFB),
        ),
      AmoraTopNotificationType.verification => const _NotificationStyle(
          icon: Icons.verified_rounded,
          iconColor: Color(0xFF2E7D32),
          bgColor: Color(0xFFE8F5E9),
        ),
      AmoraTopNotificationType.system => const _NotificationStyle(
          icon: Icons.notifications_active_rounded,
          iconColor: Color(0xFF713F62),
          bgColor: Color(0xFFF3E5F5),
        ),
    };
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isSuperLike = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isSuperLike;
}
