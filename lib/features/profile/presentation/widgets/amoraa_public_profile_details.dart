import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:flutter/foundation.dart';

/// Public-facing projection of the shared current-user profile.
///
/// This owns display normalization only. The rendered widget tree is shared
/// with Profile Detail through AmoraaPublicProfileView and ProfileStory.
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
    final normalizedLifestyle = ProfileFormOptions.normalizeLifestyleSelections(
      profile.lifestyle,
    );
    final heightCentimeters = ProfileFormOptions.parseHeightCentimeters(
      profile.lifestyle['Height'],
    );
    final primary = _primaryPhoto(photos);
    return AmoraaPublicProfileData(
      name: profile.name.trim().isEmpty ? 'AMORAA member' : profile.name.trim(),
      age: profile.age,
      city: ProfileFormOptions.normalizeCity(profile.location),
      gender: ProfileFormOptions.normalizeGender(profile.gender),
      occupation: ProfileFormOptions.displayOccupation(profile.profession),
      company: profile.company.trim(),
      education: ProfileFormOptions.normalizeEducation(profile.education),
      datingIntention: ProfileFormOptions.normalizeDatingIntention(
        profile.datingIntention,
      ),
      datingType: ProfileFormOptions.normalizeDatingType(
        profile.lifestyle['Type of Dating'] ?? profile.lifestyle['Dating Type'],
      ),
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

  List<ProfilePhotoViewData> get orderedPhotos => <ProfilePhotoViewData>[
    primaryPhoto,
    ...additionalPhotos,
  ];

  DummyProfile toPublicDisplayProfile() {
    final lifestyleByLabel = Map<String, String>.fromEntries(lifestyle);
    String value(String label) => lifestyleByLabel[label]?.trim() ?? '';
    final normalizedGender = gender.toLowerCase();
    return DummyProfile(
      id: 'current-user-public-preview',
      gender: normalizedGender == 'male' ? Gender.male : Gender.female,
      name: name,
      age: age ?? 0,
      city: city,
      profession: occupation,
      education: education,
      distance: '',
      score: isPremium ? 95 : 0,
      intent: datingIntention,
      personality: '',
      status: '',
      bio: bio,
      interests: interests,
      imageUrl: primaryPhoto.source,
      gallery: additionalPhotos
          .map((photo) => photo.source)
          .toList(growable: false),
      languages: languages,
      verification: isAadhaarVerified ? 'Verified profile' : '',
      lifestyle: lifestyle.map((entry) => entry.value).toList(growable: false),
      promptAnswers: Map<String, String>.fromEntries(prompts),
      travelPreference: '',
      musicTaste: '',
      foodPreference: value('Food preference'),
      weekendPlan: value('Sleep habits'),
      petPreference: value('Pets'),
      coffeePreference: datingType,
      religion: religion,
      community: '',
      height: height,
      fitnessLevel: value('Exercise'),
      smoking: value('Smoking'),
      drinking: value('Drinking'),
      children: '',
      loveLanguage: '',
      greenFlags: const <String>[],
      redFlags: const <String>[],
      familyValues: '',
      dateIdeas: datingType.isEmpty ? const <String>[] : <String>[datingType],
    );
  }

  static ProfilePhotoViewData _primaryPhoto(List<ProfilePhotoViewData> photos) {
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
