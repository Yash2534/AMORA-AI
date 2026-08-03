import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_icon_sizes.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/material.dart';

class AmoraProfileCardData {
  const AmoraProfileCardData({
    required this.name,
    required this.age,
    required this.city,
    required this.distance,
    required this.score,
    required this.intent,
    required this.imageUrl,
    this.fallbackAsset,
    this.initials,
    this.profession,
    this.bio,
    this.interests = const [],
    this.isOnline = true,
    this.isVerified = true,
  });

  final String name;
  final int age;
  final String city;
  final String distance;
  final int score;
  final String intent;
  final String imageUrl;
  final String? fallbackAsset;
  final String? initials;
  final String? profession;
  final String? bio;
  final List<String> interests;
  final bool isOnline;
  final bool isVerified;
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
    this.compact = false,
  });

  final AmoraProfileCardData profile;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const radius = AmoraRadius.extraLarge;
    final bio = profile.bio?.trim();
    final profession = profile.profession ?? 'Intentional dater';
    final interests = ProfileInterestPolicy.visible(
      profile.interests,
    ).take(compact ? 1 : 3).toList(growable: false);
    final intention = ProfileFormOptions.normalizeDatingIntention(
      profile.intent,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: AmoraRadius.card,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AmoraRadius.card,
          border: Border.all(color: AppColors.borderGray),
          boxShadow: AmoraShadows.premiumCard,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AmoraProfileImage(
                imageUrl: profile.imageUrl,
                assetPath: profile.fallbackAsset ?? _assetForName(profile.name),
                initials: profile.initials ?? _initialsForName(profile.name),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .42),
                ),
              ),
              Positioned(
                top: compact ? AmoraSpacing.space8 : AmoraSpacing.space12,
                left: compact ? AmoraSpacing.space8 : AmoraSpacing.space12,
                right: compact ? AmoraSpacing.space8 : AmoraSpacing.space12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: _AuraMatchBadge(
                        score: profile.score,
                        compact: compact,
                      ),
                    ),
                    const Spacer(),
                    if (profile.isVerified)
                      _VerifiedPill(compact: compact)
                    else if (profile.isOnline)
                      const _OnlineDot(),
                  ],
                ),
              ),
              Positioned(
                left: compact ? AmoraSpacing.space12 : AmoraSpacing.space20,
                right: compact ? AmoraSpacing.space12 : AmoraSpacing.space20,
                bottom: compact ? AmoraSpacing.space12 : AmoraSpacing.space20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${profile.name}, ${profile.age}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? AmoraTextStyles.titleMedium
                                  : AmoraTextStyles.headlineSmall)
                              .copyWith(color: AppColors.surface),
                    ),
                    const SizedBox(height: AmoraSpacing.space8),
                    Text(
                      '$profession - ${profile.distance} away',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                    if (!compact && bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: AmoraSpacing.space8),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AmoraTextStyles.bodySmall.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ],
                    const SizedBox(height: AmoraSpacing.space8),
                    Wrap(
                      spacing: AmoraSpacing.space8,
                      runSpacing: AmoraSpacing.space8,
                      children: [
                        if (intention.isNotEmpty) _OverlayPill(text: intention),
                        for (final interest in interests)
                          _OverlayPill(text: interest),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuraMatchBadge extends StatelessWidget {
  const _AuraMatchBadge({required this.score, required this.compact});

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AmoraSpacing.space8 : AmoraSpacing.space12,
          vertical: compact ? AmoraSpacing.space4 : AmoraSpacing.space8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.surface,
              size: AmoraIconSizes.small,
            ),
            const SizedBox(width: AmoraSpacing.space4),
            Flexible(
              child: Text(
                compact ? '$score%' : '$score% Aura Match',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AmoraRadius.pillBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space8,
          vertical: AmoraSpacing.space8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: AppColors.primaryPurple,
              size: AmoraIconSizes.small,
            ),
            if (!compact) ...[
              const SizedBox(width: AmoraSpacing.space4),
              Text(
                'Verified',
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AmoraIconSizes.small,
      height: AmoraIconSizes.small,
      decoration: BoxDecoration(
        color: AppColors.successGreen,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 3),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.deepWine,
        borderRadius: AmoraRadius.pillBorder,
        border: Border.all(color: AppColors.deepWine),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmoraSpacing.space8,
          vertical: AmoraSpacing.space4,
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.labelSmall.copyWith(color: AppColors.surface),
        ),
      ),
    );
  }
}

String _assetForName(String name) {
  return AppImages.profileForName(name);
}

String _initialsForName(String name) {
  return AppImages.initialsForName(name);
}
