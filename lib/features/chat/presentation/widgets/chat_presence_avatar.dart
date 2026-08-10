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
        width: dimension,
        height: dimension,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: .48),
                  ),
                ),
                child: PremiumAvatar(
                  imageUrl: profile.imageUrl,
                  fallbackAsset: profile.fallbackAsset,
                  initials: profile.initials,
                  radius: radius - 1,
                  semanticLabel: '${profile.name} profile photo',
                ),
              ),
            ),
            if (profile.verified && showVerified)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 10,
                  ),
                ),
              ),
            if (online)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  key: const ValueKey('chat-presence-online-indicator'),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: onlineGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
