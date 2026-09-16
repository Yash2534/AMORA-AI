import 'dart:math' as math;
import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/profile_card.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:flutter/material.dart';

class AmoraProfileCardStack extends StatefulWidget {
  const AmoraProfileCardStack({
    super.key,
    required this.profiles,
    required this.currentIndex,
    required this.height,
    required this.onOpen,
    required this.onLike,
    required this.onPass,
    required this.onChat,
    required this.onMatch,
    required this.onUndo,
    this.lastProfile,
  });

  final List<AmoraProfileCardData> profiles;
  final int currentIndex;
  final double height;
  final ValueChanged<AmoraProfileCardData> onOpen;
  final VoidCallback onLike;
  final VoidCallback onPass;
  final VoidCallback onChat;
  final VoidCallback onMatch;
  final VoidCallback onUndo;
  final AmoraProfileCardData? lastProfile;

  @override
  State<AmoraProfileCardStack> createState() => AmoraProfileCardStackState();
}

class AmoraProfileCardStackState extends State<AmoraProfileCardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  double _swipeProgress = 0.0;
  Offset _exitOffset = Offset.zero;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (_isExiting) return;
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isExiting) return;
    setState(() {
      _dragOffset += details.delta;
      _swipeProgress = (_dragOffset.dx / 140.0).clamp(-1.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isExiting) return;
    _isDragging = false;
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final velocityY = details.velocity.pixelsPerSecond.dy;

    if (_dragOffset.dx > 100 || velocityX > 700) {
      _triggerSwipeRight();
    } else if (_dragOffset.dx < -100 || velocityX < -700) {
      _triggerSwipeLeft();
    } else if (_dragOffset.dy < -120 || velocityY < -700) {
      _triggerSwipeUp();
    } else {
      _resetPosition();
    }
  }

  void _resetPosition() {
    final startOffset = _dragOffset;
    _animController.reset();
    final animation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    void listener() {
      setState(() {
        _dragOffset = animation.value;
        _swipeProgress = (_dragOffset.dx / 140.0).clamp(-1.0, 1.0);
      });
    }

    animation.addListener(listener);
    _animController.forward().then((_) {
      animation.removeListener(listener);
    });
  }

  void _triggerSwipeLeft() {
    _animateExit(const Offset(-500, 40), widget.onPass);
  }

  void _triggerSwipeRight() {
    _animateExit(const Offset(500, 40), widget.onLike);
  }

  void _triggerSwipeUp() {
    _animateExit(const Offset(0, -600), widget.onMatch);
  }

  void triggerSwipeLeftFromButton() => _triggerSwipeLeft();
  void triggerSwipeRightFromButton() => _triggerSwipeRight();
  void triggerSwipeUpFromButton() => _triggerSwipeUp();

  void _animateExit(Offset targetOffset, VoidCallback onCompleteAction) {
    if (_isExiting) return;
    _isExiting = true;
    final startOffset = _dragOffset;
    _animController.reset();
    final animation = Tween<Offset>(
      begin: startOffset,
      end: targetOffset,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad),
    );

    void listener() {
      setState(() {
        _dragOffset = animation.value;
      });
    }

    animation.addListener(listener);
    _animController.forward().then((_) {
      animation.removeListener(listener);
      _isExiting = false;
      _dragOffset = Offset.zero;
      _swipeProgress = 0.0;
      onCompleteAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No profiles available',
            style: AmoraTextStyles.bodyLarge.copyWith(color: AppColors.textGray),
          ),
        ),
      );
    }

    final total = widget.profiles.length;
    final frontIndex = widget.currentIndex % total;
    final frontProfile = widget.profiles[frontIndex];

    final hasBack1 = total >= 2;
    final back1Index = (widget.currentIndex + 1) % total;
    final back1Profile = hasBack1 ? widget.profiles[back1Index] : null;

    final hasBack2 = total >= 3;
    final back2Index = (widget.currentIndex + 2) % total;
    final back2Profile = hasBack2 ? widget.profiles[back2Index] : null;

    final progressFraction = (_dragOffset.dx.abs() / 150.0).clamp(0.0, 1.0);

    return SizedBox(
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // BACK CARD #2 (Bottom-most in stack depth)
          if (hasBack2 && back2Profile != null)
            Positioned.fill(
              child: _buildBackCard(
                context: context,
                profile: back2Profile,
                baseScale: 0.93,
                targetScale: 0.965,
                baseOffsetY: -22.0,
                targetOffsetY: -11.0,
                baseRotation: 0.035,
                targetRotation: -0.025,
                baseOpacity: 0.80,
                targetOpacity: 0.92,
                progress: progressFraction,
              ),
            ),

          // BACK CARD #1 (Middle in stack depth)
          if (hasBack1 && back1Profile != null)
            Positioned.fill(
              child: _buildBackCard(
                context: context,
                profile: back1Profile,
                baseScale: 0.965,
                targetScale: 1.0,
                baseOffsetY: -11.0,
                targetOffsetY: 0.0,
                baseRotation: -0.025,
                targetRotation: 0.0,
                baseOpacity: 0.92,
                targetOpacity: 1.0,
                progress: progressFraction,
              ),
            ),

          // FRONT CARD (Top-most in stack depth)
          Positioned.fill(
            child: _buildFrontCard(
              context: context,
              profile: frontProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard({
    required BuildContext context,
    required AmoraProfileCardData profile,
    required double baseScale,
    required double targetScale,
    required double baseOffsetY,
    required double targetOffsetY,
    required double baseRotation,
    required double targetRotation,
    required double baseOpacity,
    required double targetOpacity,
    required double progress,
  }) {
    final scale = baseScale + (targetScale - baseScale) * progress;
    final offsetY = baseOffsetY + (targetOffsetY - baseOffsetY) * progress;
    final rotation = baseRotation + (targetRotation - baseRotation) * progress;
    final opacity = (baseOpacity + (targetOpacity - baseOpacity) * progress).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.primary.withValues(alpha: 0.20),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepWine.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AmoraProfileImage(
                      imageUrl: profile.imageUrl,
                      assetPath: profile.fallbackAsset ?? AppImages.fallbackProfile,
                      initials: profile.initials ?? AppImages.initialsForName(profile.name),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.25),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 18,
                      right: 18,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.50),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.premiumGold,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  style: AmoraTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
    );
  }

  Widget _buildFrontCard({
    required BuildContext context,
    required AmoraProfileCardData profile,
  }) {
    final rotationAngle = _dragOffset.dx * 0.0006;
    final visibleInterests = ProfileInterestPolicy.visible(profile.interests);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotationAngle,
          child: Semantics(
            button: true,
            label: 'Best match ${profile.name}, ${profile.score}% AI match',
            child: InkWell(
              onTap: () => widget.onOpen(profile),
              borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
              child: SizedBox(
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                    boxShadow: AmoraShadows.floating,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AmoraProfileImage(
                          imageUrl: profile.imageUrl,
                          assetPath: profile.fallbackAsset ?? AppImages.fallbackProfile,
                          initials: profile.initials ?? AppImages.initialsForName(profile.name),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.textPrimary.withValues(alpha: .10),
                                AppColors.textPrimary.withValues(alpha: .70),
                                AppColors.textPrimary.withValues(alpha: .88),
                              ],
                              stops: const [0.35, 0.58, 0.82, 1.0],
                            ),
                          ),
                        ),
                        // TOP BADGES
                        Positioned(
                          top: AmoraSpacing.space16,
                          left: AmoraSpacing.space16,
                          right: AmoraSpacing.space16,
                          child: Wrap(
                            spacing: AmoraSpacing.space8,
                            runSpacing: AmoraSpacing.space8,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              _SolidOverlayBadge(
                                icon: Icons.auto_awesome_rounded,
                                label: '${profile.score}% AI Match',
                                strong: true,
                              ),
                              if (profile.isVerified)
                                const _SolidOverlayBadge(
                                  icon: Icons.verified_rounded,
                                  label: 'Verified',
                                ),
                              if (profile.isOnline)
                                const _SolidOverlayBadge(
                                  icon: Icons.circle_rounded,
                                  label: 'Online now',
                                  iconColor: AppColors.successGreen,
                                ),
                            ],
                          ),
                        ),
                        // SWIPE ACTION STAMPS (LIKE / PASS / SUPER LIKE)
                        if (_dragOffset.dx > 25)
                          Positioned(
                            top: 48,
                            left: 24,
                            child: Transform.rotate(
                              angle: -0.25,
                              child: _SwipeStampBadge(
                                text: 'LIKE',
                                color: AppColors.successGreen,
                                icon: Icons.favorite_rounded,
                              ),
                            ),
                          ),
                        if (_dragOffset.dx < -25)
                          Positioned(
                            top: 48,
                            right: 24,
                            child: Transform.rotate(
                              angle: 0.25,
                              child: _SwipeStampBadge(
                                text: 'PASS',
                                color: AppColors.errorRed,
                                icon: Icons.close_rounded,
                              ),
                            ),
                          ),
                        if (_dragOffset.dy < -30 && _dragOffset.dx.abs() < 50)
                          Positioned(
                            top: 60,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _SwipeStampBadge(
                                text: 'SUPER LIKE',
                                color: AppColors.premiumGold,
                                icon: Icons.star_rounded,
                              ),
                            ),
                          ),
                        // PROFILE DETAILS
                        Positioned(
                          left: AmoraSpacing.space20,
                          right: AmoraSpacing.space20,
                          bottom: 96,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: (MediaQuery.sizeOf(context).width < 360
                                        ? AmoraTextStyles.headlineLarge
                                        : AmoraTextStyles.displaySmall)
                                    .copyWith(color: AppColors.surface),
                              ),
                              const SizedBox(height: AmoraSpacing.space8),
                              Text(
                                '${profile.profession ?? profile.city} - ${profile.distance} away',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AmoraTextStyles.bodyLarge.copyWith(
                                  color: AppColors.surface,
                                ),
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              Wrap(
                                spacing: AmoraSpacing.space8,
                                runSpacing: AmoraSpacing.space8,
                                children: [
                                  _SolidOverlayPill(text: profile.intent),
                                  if (visibleInterests.isNotEmpty)
                                    _SolidOverlayPill(text: visibleInterests.first),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // BOTTOM ACTION CONTROLS
                        Positioned(
                          left: AmoraSpacing.space16,
                          right: AmoraSpacing.space16,
                          bottom: AmoraSpacing.space16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AmoraRadius.xxxl),
                              border: Border.all(color: AppColors.borderGray),
                              boxShadow: AmoraShadows.level2,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AmoraSpacing.space12,
                                vertical: 10,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 270,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _CircleAction(
                                        icon: Icons.undo_rounded,
                                        label: 'Undo',
                                        onTap: widget.onUndo,
                                      ),
                                      _CircleAction(
                                        icon: Icons.close_rounded,
                                        label: 'Next',
                                        onTap: triggerSwipeLeftFromButton,
                                      ),
                                      _CircleAction(
                                        icon: Icons.favorite_rounded,
                                        label: 'Match',
                                        emphasis: true,
                                        onTap: triggerSwipeRightFromButton,
                                      ),
                                      _CircleAction(
                                        icon: Icons.chat_bubble_rounded,
                                        label: 'Chat',
                                        onTap: widget.onChat,
                                      ),
                                    ],
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
          ),
        ),
      ),
    );
  }
}

class _SwipeStampBadge extends StatelessWidget {
  const _SwipeStampBadge({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(
            text,
            style: AmoraTextStyles.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidOverlayBadge extends StatelessWidget {
  const _SolidOverlayBadge({
    required this.icon,
    required this.label,
    this.strong = false,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final bool strong;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: strong ? AppColors.deepWine : AppColors.surface,
        borderRadius: AmoraRadius.pillBorder,
        boxShadow: AmoraShadows.badge,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AmoraIconSizes.small,
              color: iconColor ??
                  (strong ? AppColors.premiumGold : AppColors.primaryPurple),
            ),
            const SizedBox(width: AmoraSpacing.space6),
            Text(
              label,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: strong ? AppColors.surface : AppColors.deepWine,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolidOverlayPill extends StatelessWidget {
  const _SolidOverlayPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .92),
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: AmoraTextStyles.labelMedium.copyWith(
            color: AppColors.deepWine,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasis = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AmoraRadius.pill),
          child: CircleAvatar(
            radius: 24,
            backgroundColor:
                emphasis ? AppColors.primaryPurple : AppColors.lavenderBackground,
            child: Icon(
              icon,
              color: emphasis ? AppColors.surface : AppColors.deepWine,
              size: AmoraIconSizes.medium,
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          label,
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.deepWine,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
