import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';

enum ProfileCompletionSectionId {
  photos,
  basicDetails,
  workEducation,
  locationIntentions,
  identityDetails,
  bio,
  interests,
  lifestyle,
  prompt,
}

class ProfileCompletionInput {
  const ProfileCompletionInput({
    required this.photoCount,
    required this.name,
    required this.birthdate,
    required this.gender,
    required this.profession,
    required this.education,
    required this.location,
    required this.datingIntention,
    required this.height,
    required this.languages,
    required this.religion,
    required this.bio,
    required this.interests,
    required this.lifestyle,
    required this.completedPromptCount,
  });

  final int photoCount;
  final String name;
  final DateTime? birthdate;
  final String gender;
  final String profession;
  final String education;
  final String location;
  final String datingIntention;
  final String height;
  final String languages;
  final String religion;
  final String bio;
  final List<String> interests;
  final Map<String, String> lifestyle;
  final int completedPromptCount;
}

class ProfileSectionProgress {
  const ProfileSectionProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.completedFields,
    required this.totalFields,
    required this.weight,
  });

  final ProfileCompletionSectionId id;
  final String title;
  final String description;
  final int completedFields;
  final int totalFields;
  final int weight;

  bool get isComplete => completedFields >= totalFields;
  bool get isPartial => completedFields > 0 && !isComplete;
  int get missingFields =>
      (totalFields - completedFields).clamp(0, totalFields);
  int get earnedWeight => totalFields == 0
      ? weight
      : ((completedFields / totalFields) * weight).round();

  String get statusLabel => isComplete
      ? 'Complete'
      : isPartial
      ? '$completedFields of $totalFields complete'
      : 'Incomplete';
}

class ProfileCompletionResult {
  const ProfileCompletionResult({
    required this.percentage,
    required this.sections,
  });

  final int percentage;
  final List<ProfileSectionProgress> sections;

  bool get isComplete => percentage == 100;
  int get completeSectionCount =>
      sections.where((section) => section.isComplete).length;
  int get partialSectionCount =>
      sections.where((section) => section.isPartial).length;
  int get remainingSectionCount =>
      sections.where((section) => !section.isComplete).length;
  int get remainingFieldCount =>
      sections.fold(0, (count, section) => count + section.missingFields);
  ProfileSectionProgress? get recommendedNext {
    for (final section in sections) {
      if (!section.isComplete) return section;
    }
    return null;
  }

  String get statusLabel => switch (percentage) {
    <= 24 => 'Let’s get started',
    <= 49 => 'Your profile is taking shape',
    <= 74 => 'You’re making great progress',
    <= 99 => 'Almost ready',
    _ => 'Profile complete',
  };
}

abstract final class ProfileCompletionCalculator {
  static const Set<String> _identityKeys = {'Height', 'Languages', 'Religion'};

  static ProfileCompletionResult calculate(ProfileCompletionInput input) {
    bool filled(String value) => value.trim().isNotEmpty;
    final validBirthdate = AmoraDateOfBirth.validate(input.birthdate) == null;
    final visibleInterestCount = ProfileInterestPolicy.visibleCount(
      input.interests,
    );
    final lifestyleComplete = input.lifestyle.entries.any(
      (entry) => !_identityKeys.contains(entry.key) && filled(entry.value),
    );

    final sections = <ProfileSectionProgress>[
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.photos,
        title: 'Profile Photos',
        description: 'Add at least two clear photos.',
        completedFields: input.photoCount.clamp(0, 2),
        totalFields: 2,
        weight: 15,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.basicDetails,
        title: 'Basic Details',
        description: 'Your name, birthday and gender.',
        completedFields: [
          filled(input.name),
          validBirthdate,
          filled(input.gender),
        ].where((value) => value).length,
        totalFields: 3,
        weight: 15,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.workEducation,
        title: 'Work & Education',
        description: 'Share your occupation and education.',
        completedFields: [
          filled(input.profession),
          filled(input.education),
        ].where((value) => value).length,
        totalFields: 2,
        weight: 10,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.locationIntentions,
        title: 'Location & Dating Intentions',
        description: 'Where you are and what you’re looking for.',
        completedFields: [
          filled(input.location),
          filled(input.datingIntention),
        ].where((value) => value).length,
        totalFields: 2,
        weight: 10,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.identityDetails,
        title: 'Height, Languages & Religion',
        description: 'A few details that help matches understand you.',
        completedFields: [
          filled(input.height),
          filled(input.languages),
          filled(input.religion),
        ].where((value) => value).length,
        totalFields: 3,
        weight: 15,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.bio,
        title: 'Bio',
        description: 'Write a warm introduction of at least 40 characters.',
        completedFields: input.bio.trim().length >= 40 ? 1 : 0,
        totalFields: 1,
        weight: 10,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.interests,
        title: 'Interests',
        description: 'Choose at least five interests.',
        completedFields: visibleInterestCount.clamp(0, 5),
        totalFields: 5,
        weight: 10,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.lifestyle,
        title: 'Lifestyle',
        description: 'Share at least one everyday-life preference.',
        completedFields: lifestyleComplete ? 1 : 0,
        totalFields: 1,
        weight: 5,
      ),
      ProfileSectionProgress(
        id: ProfileCompletionSectionId.prompt,
        title: 'Profile Prompt',
        description: 'Add one conversation-starting answer.',
        completedFields: input.completedPromptCount > 0 ? 1 : 0,
        totalFields: 1,
        weight: 10,
      ),
    ];
    final percentage = sections
        .fold<int>(0, (total, section) => total + section.earnedWeight)
        .clamp(0, 100);
    return ProfileCompletionResult(
      percentage: percentage,
      sections: List.unmodifiable(sections),
    );
  }
}
