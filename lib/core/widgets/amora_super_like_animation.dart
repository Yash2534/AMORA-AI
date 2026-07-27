import 'dart:math' as math;

import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AmoraSuperLikeAnimation extends StatelessWidget {
  const AmoraSuperLikeAnimation({
    super.key,
    required this.animation,
    required this.profileName,
  });

  static const duration = Duration(milliseconds: 780);

  final Animation<double> animation;
  final String profileName;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        if (t == 0) return const SizedBox.shrink();
        final opacity = math.sin(math.pi * t).clamp(0.0, 1.0);
        final pulse = 1 + (math.sin(math.pi * t) * .22);
        return Opacity(
          opacity: opacity,
          child: Align(
            alignment: const Alignment(0, -.18),
            child: Semantics(
              liveRegion: true,
              label: 'Super Like sent to $profileName',
              child: SizedBox(
                width: 280,
                height: 230,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 150 * pulse,
                      height: 150 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.tertiary.withValues(alpha: .18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: .34),
                            blurRadius: 42,
                            spreadRadius: 10 * t,
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: (.72 + t * .5).clamp(.72, 1.14),
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.surface,
                          size: 46,
                        ),
                      ),
                    ),
                    for (final particle in const <(Offset, IconData)>[
                      (Offset(-72, -54), Icons.auto_awesome_rounded),
                      (Offset(76, -44), Icons.star_rounded),
                      (Offset(-92, 18), Icons.favorite_rounded),
                      (Offset(92, 26), Icons.auto_awesome_rounded),
                      (Offset(-54, 76), Icons.star_rounded),
                      (Offset(58, 82), Icons.favorite_rounded),
                    ])
                      Transform.translate(
                        offset: particle.$1 * (.35 + t),
                        child: Transform.scale(
                          scale: (.45 + t).clamp(.45, 1),
                          child: Icon(
                            particle.$2,
                            color: particle.$2 == Icons.favorite_rounded
                                ? AppColors.secondary
                                : AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppColors.tertiary),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .14),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppColors.secondary,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Text(
                              'Super Like sent',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
