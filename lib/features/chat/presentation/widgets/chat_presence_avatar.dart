import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:flutter/material.dart';

class ChatPresenceAvatar extends StatelessWidget {
  const ChatPresenceAvatar({
    super.key,
    required this.profile,
    required this.online,
    this.radius = 28,
    this.showVerified = true,
  });

  static const onlineGreen = AppColors.success;

  final DummyProfile profile;
  final bool online;
  final double radius;
  final bool showVerified;

  @override
  Widget build(BuildContext context) {
    final dimension = radius * 2;
    return Semantics(
      image: true,
      label:
          '${profile.name} profile photo${online ? ', online now' : ''}${profile.verified && showVerified ? ', verified' : ''}',
      child: SizedBox(
        width: dimension + 4,
        height: dimension + 4,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: Container(
                width: dimension,
                height: dimension,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: .58),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .07),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: PremiumAvatar(
                  imageUrl: profile.imageUrl,
                  fallbackAsset: profile.fallbackAsset,
                  initials: profile.initials,
                  radius: radius - 1.5,
                  semanticLabel: '${profile.name} profile photo',
                ),
              ),
            ),
            if (profile.verified && showVerified)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 11,
                  ),
                ),
              ),
            if (online)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: onlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: onlineGreen.withValues(alpha: .3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
