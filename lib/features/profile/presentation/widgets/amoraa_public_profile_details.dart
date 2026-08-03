import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_identity_badge.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_photo_view.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_story_image.dart';
import 'package:flutter/material.dart';

/// Public-facing projection of the shared [UserProfile].
///
/// This keeps display normalization in one place without creating a second
/// profile state or changing the persisted profile contract.
@immutable
class AmoraaPublicProfileData {
  const AmoraaPublicProfileData({
    required this.name,
    required this.age,
    required this.city,
    required this.gender,
    required this.occupation,
    required this.company,
    required this.education,
    required this.datingIntention,
    required this.datingIntentionDescription,
    required this.datingType,
    required this.bio,
    required this.height,
    required this.languages,
    required this.religion,
    required this.interests,
    required this.prompts,
    required this.lifestyle,
    required this.primaryPhoto,
    required this.additionalPhotos,
    required this.isAadhaarVerified,
    required this.isPremium,
  });

  factory AmoraaPublicProfileData.fromProfile(
    UserProfile profile,
    List<ProfilePhotoViewData> photos, {
    bool isAadhaarVerified = false,
    bool isPremium = false,
  }) {
    final intention = ProfileFormOptions.normalizeDatingIntention(
      profile.datingIntention,
    );
    final normalizedLifestyle = ProfileFormOptions.normalizeLifestyleSelections(
      profile.lifestyle,
    );
    final heightCentimeters = ProfileFormOptions.parseHeightCentimeters(
      profile.lifestyle['Height'],
    );
    final primary = _primaryPhoto(profile, photos);
    final datingType = ProfileFormOptions.normalizeDatingType(
      profile.lifestyle['Type of Dating'] ?? profile.lifestyle['Dating Type'],
    );
    return AmoraaPublicProfileData(
      name: profile.name.trim().isEmpty ? 'AMORAA member' : profile.name.trim(),
      age: profile.age,
      city: ProfileFormOptions.normalizeCity(profile.location),
      gender: ProfileFormOptions.normalizeGender(profile.gender),
      occupation: ProfileFormOptions.normalizeOccupation(profile.profession),
      company: profile.company.trim(),
      education: ProfileFormOptions.normalizeEducation(profile.education),
      datingIntention: intention,
      datingIntentionDescription:
          ProfileFormOptions.datingIntentionDescriptions[intention] ?? '',
      datingType: datingType,
      bio: profile.bio.trim(),
      height: heightCentimeters == null
          ? ''
          : ProfileFormOptions.formatProfileHeight(heightCentimeters),
      languages: ProfileFormOptions.parseLanguages(
        profile.lifestyle['Languages'],
      ).toList(growable: false),
      religion: ProfileFormOptions.normalizeReligion(
        profile.lifestyle['Religion'],
      ),
      interests: ProfileInterestPolicy.visible(profile.interests),
      prompts: profile.prompts.entries
          .where(
            (entry) =>
                entry.key.trim().isNotEmpty && entry.value.trim().isNotEmpty,
          )
          .map((entry) => MapEntry(entry.key.trim(), entry.value.trim()))
          .toList(growable: false),
      lifestyle: <MapEntry<String, String>>[
        for (final key in ProfileFormOptions.lifestyleOptions.keys)
          if ((normalizedLifestyle[key] ?? '').isNotEmpty)
            MapEntry(key, normalizedLifestyle[key]!),
      ],
      primaryPhoto: primary,
      additionalPhotos: photos
          .where((photo) => photo.id != primary.id)
          .toList(growable: false),
      isAadhaarVerified: isAadhaarVerified,
      isPremium: isPremium,
    );
  }

  final String name;
  final int? age;
  final String city;
  final String gender;
  final String occupation;
  final String company;
  final String education;
  final String datingIntention;
  final String datingIntentionDescription;
  final String datingType;
  final String bio;
  final String height;
  final List<String> languages;
  final String religion;
  final List<String> interests;
  final List<MapEntry<String, String>> prompts;
  final List<MapEntry<String, String>> lifestyle;
  final ProfilePhotoViewData primaryPhoto;
  final List<ProfilePhotoViewData> additionalPhotos;
  final bool isAadhaarVerified;
  final bool isPremium;

  static ProfilePhotoViewData _primaryPhoto(
    UserProfile profile,
    List<ProfilePhotoViewData> photos,
  ) {
    for (final photo in photos) {
      if (photo.isPrimary) return photo;
    }
    if (photos.isNotEmpty) return photos.first;
    return const ProfilePhotoViewData(
      id: 'profile-preview-fallback',
      source: AppImages.fallbackProfile,
      order: 0,
      isPrimary: true,
      uploadState: ProfilePhotoUploadState.bundled,
    );
  }
}

class AmoraaPublicProfileDetails extends StatelessWidget {
  const AmoraaPublicProfileDetails({super.key, required this.profile});

  final AmoraaPublicProfileData profile;

  @override
  Widget build(BuildContext context) {
    final photos = profile.additionalPhotos;
    final firstPhoto = photos.isEmpty ? null : photos.first;
    final secondPhoto = photos.length < 2 ? null : photos[1];
    final remainingPhotos = photos.skip(2);
    final workDetails = <_PublicDetail>[
      if (profile.occupation.isNotEmpty)
        _PublicDetail(Icons.work_rounded, 'Occupation', profile.occupation),
      if (profile.company.isNotEmpty)
        _PublicDetail(Icons.business_rounded, 'Company', profile.company),
      if (profile.education.isNotEmpty)
        _PublicDetail(Icons.school_rounded, 'Education', profile.education),
    ];
    final identityDetails = <_PublicDetail>[
      if (profile.gender.isNotEmpty)
        _PublicDetail(Icons.person_rounded, 'Gender', profile.gender),
      if (profile.height.isNotEmpty)
        _PublicDetail(Icons.straighten_rounded, 'Height', profile.height),
      if (profile.languages.isNotEmpty)
        _PublicDetail(
          Icons.translate_rounded,
          'Languages',
          profile.languages.join(' · '),
        ),
      if (profile.religion.isNotEmpty)
        _PublicDetail(Icons.diversity_3_rounded, 'Religion', profile.religion),
    ];

    return Column(
      key: const ValueKey('public-profile-details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PublicProfileHero(profile: profile),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _PublicSection(
            key: const ValueKey('preview-bio-section'),
            icon: Icons.format_quote_rounded,
            title: 'About',
            child: _PublicBio(bio: profile.bio),
          ),
        ],
        if (firstPhoto != null) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _StoryPhoto(photo: firstPhoto),
        ],
        if (profile.prompts.isNotEmpty) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _PublicSection(
            key: const ValueKey('preview-prompts-section'),
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Profile prompts',
            child: _PromptList(prompts: profile.prompts),
          ),
        ],
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _PublicSection(
            key: const ValueKey('preview-interests-section'),
            icon: Icons.interests_rounded,
            title: 'Interests',
            child: _InterestChips(interests: profile.interests),
          ),
        ],
        if (secondPhoto != null) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _StoryPhoto(photo: secondPhoto),
        ],
        if (profile.lifestyle.isNotEmpty) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _PublicSection(
            key: const ValueKey('preview-lifestyle-section'),
            icon: Icons.auto_awesome_rounded,
            title: 'Lifestyle',
            child: _LifestyleDetails(entries: profile.lifestyle),
          ),
        ],
        if (workDetails.isNotEmpty) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _PublicSection(
            key: const ValueKey('preview-work-education-section'),
            icon: Icons.work_history_rounded,
            title: 'Work & education',
            child: _DetailCard(details: workDetails),
          ),
        ],
        if (identityDetails.isNotEmpty) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _PublicSection(
            key: const ValueKey('preview-personal-details-section'),
            icon: Icons.person_pin_circle_rounded,
            title: 'More about me',
            child: _DetailCard(details: identityDetails),
          ),
        ],
        if (resolveAmoraaIdentityBadge(
              isAadhaarVerified: profile.isAadhaarVerified,
              isPremium: profile.isPremium,
            ) ==
            AmoraaIdentityBadgeType.none) ...[
          const SizedBox(height: AmoraSpacing.space32),
          const _PublicSection(
            key: ValueKey('preview-verification-section'),
            icon: Icons.verified_user_outlined,
            title: 'Verification',
            child: _VerificationStatus(),
          ),
        ],
        for (final photo in remainingPhotos) ...[
          const SizedBox(height: AmoraSpacing.space32),
          _StoryPhoto(photo: photo),
        ],
      ],
    );
  }
}

class _PublicProfileHero extends StatelessWidget {
  const _PublicProfileHero({required this.profile});

  final AmoraaPublicProfileData profile;

  @override
  Widget build(BuildContext context) {
    final summary = <String>[
      if (profile.age != null) '${profile.age}',
      if (profile.city.isNotEmpty) profile.city,
    ];
    return Semantics(
      container: true,
      label: [profile.name, ...summary].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.tertiary.withValues(alpha: .72),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow.withValues(alpha: .12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AmoraaProfilePhotoView(
                          photo: profile.primaryPhoto,
                          semanticLabel:
                              'Primary profile photo of ${profile.name}',
                          borderRadius: BorderRadius.circular(24),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                            color: AppColors.text.withValues(alpha: .82),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AmoraTextStyles.headlineLarge.copyWith(
                                    color: AppColors.surface,
                                    fontSize: 30,
                                  ),
                                ),
                                if (summary.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    summary.join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AmoraTextStyles.bodyLarge.copyWith(
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (resolveAmoraaIdentityBadge(
                                      isAadhaarVerified:
                                          profile.isAadhaarVerified,
                                      isPremium: profile.isPremium,
                                    ) !=
                                    AmoraaIdentityBadgeType.none) ...[
                                  const SizedBox(height: 10),
                                  AmoraaIdentityBadge(
                                    isAadhaarVerified:
                                        profile.isAadhaarVerified,
                                    isPremium: profile.isPremium,
                                  ),
                                ],
                              ],
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
          if (profile.datingIntention.isNotEmpty ||
              profile.datingType.isNotEmpty) ...[
            const SizedBox(height: AmoraSpacing.space16),
            PremiumCard(
              key: const ValueKey('preview-relationship-intention'),
              radius: 22,
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile.datingIntention.isNotEmpty) ...[
                          Text(
                            profile.datingIntention,
                            style: AmoraTextStyles.titleMedium,
                          ),
                          if (profile
                              .datingIntentionDescription
                              .isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              profile.datingIntentionDescription,
                              style: AmoraTextStyles.bodyMedium.copyWith(
                                color: AppColors.text.withValues(alpha: .70),
                              ),
                            ),
                          ],
                        ],
                        if (profile.datingType.isNotEmpty) ...[
                          if (profile.datingIntention.isNotEmpty)
                            const SizedBox(height: 12),
                          Text(
                            'Type of dating',
                            style: AmoraTextStyles.labelSmall.copyWith(
                              color: AppColors.text.withValues(alpha: .58),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.datingType,
                            style: AmoraTextStyles.labelLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicSection extends StatelessWidget {
  const _PublicSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.tertiary),
                ),
                child: Icon(icon, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AmoraTextStyles.titleLarge)),
            ],
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        child,
      ],
    );
  }
}

class _PublicBio extends StatefulWidget {
  const _PublicBio({required this.bio});

  final String bio;

  @override
  State<_PublicBio> createState() => _PublicBioState();
}

class _PublicBioState extends State<_PublicBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.bio.characters.length > 180;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return PremiumCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Text(
              widget.bio,
              maxLines: _expanded ? null : 5,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: AmoraTextStyles.bodyLarge.copyWith(height: 1.62),
            ),
          ),
          if (canExpand)
            Semantics(
              button: true,
              label: _expanded ? 'Show less biography' : 'Read more biography',
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Read more'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PromptList extends StatelessWidget {
  const _PromptList({required this.prompts});

  final List<MapEntry<String, String>> prompts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < prompts.length; index++) ...[
          Semantics(
            container: true,
            label:
                'Profile prompt, ${prompts[index].key}, answer, ${prompts[index].value}',
            child: PremiumCard(
              key: ValueKey('preview-prompt-$index'),
              radius: 22,
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompts[index].key,
                    style: AmoraTextStyles.labelLarge.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '“${prompts[index].value}”',
                    style: AmoraTextStyles.titleLarge.copyWith(
                      fontSize: 19,
                      height: 1.48,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (index != prompts.length - 1)
            const SizedBox(height: AmoraSpacing.space12),
        ],
      ],
    );
  }
}

class _InterestChips extends StatelessWidget {
  const _InterestChips({required this.interests});

  final List<String> interests;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final interest in interests)
            Semantics(
              label: 'Interest, $interest',
              child: Container(
                constraints: const BoxConstraints(minHeight: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: .30),
                  ),
                ),
                child: Text(interest, style: AmoraTextStyles.labelLarge),
              ),
            ),
        ],
      ),
    );
  }
}

class _LifestyleDetails extends StatelessWidget {
  const _LifestyleDetails({required this.entries});

  final List<MapEntry<String, String>> entries;

  static const _icons = <String, IconData>{
    'Drinking': Icons.local_bar_rounded,
    'Smoking': Icons.smoke_free_rounded,
    'Exercise': Icons.fitness_center_rounded,
    'Food preference': Icons.restaurant_rounded,
    'Pets': Icons.pets_rounded,
    'Sleep habits': Icons.bedtime_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth >= 360
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in entries)
              SizedBox(
                width: tileWidth,
                child: PremiumCard(
                  radius: 18,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _icons[entry.key] ?? Icons.auto_awesome_rounded,
                        color: AppColors.secondary,
                        size: 21,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: AmoraTextStyles.labelSmall.copyWith(
                                color: AppColors.text.withValues(alpha: .58),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.value,
                              style: AmoraTextStyles.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PublicDetail {
  const _PublicDetail(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.details});

  final List<_PublicDetail> details;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      details[index].icon,
                      color: AppColors.secondary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details[index].label,
                          style: AmoraTextStyles.bodySmall.copyWith(
                            color: AppColors.text.withValues(alpha: .58),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details[index].value,
                          style: AmoraTextStyles.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index != details.length - 1)
              Divider(
                height: 1,
                indent: 72,
                color: AppColors.tertiary.withValues(alpha: .52),
              ),
          ],
        ],
      ),
    );
  }
}

class _VerificationStatus extends StatelessWidget {
  const _VerificationStatus();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Verification status, not verified',
      child: PremiumCard(
        radius: 22,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Not verified', style: AmoraTextStyles.titleMedium),
                  SizedBox(height: 3),
                  Text(
                    'No completed identity verification is available.',
                    style: AmoraTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPhoto extends StatelessWidget {
  const _StoryPhoto({required this.photo});

  final ProfilePhotoViewData photo;

  @override
  Widget build(BuildContext context) {
    return AmoraaProfileStoryImage(
      key: ValueKey('preview-photo-${photo.id}'),
      image: photo.source,
      photo: photo,
      semanticLabel: 'Profile photo ${photo.order + 1}',
    );
  }
}
