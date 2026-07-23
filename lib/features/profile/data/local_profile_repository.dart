import 'package:amora_ai/core/constants/app_images.dart';
import 'package:flutter/foundation.dart';

class LocalProfileDraft {
  const LocalProfileDraft({
    required this.name,
    required this.birthdate,
    required this.gender,
    required this.bio,
    required this.profession,
    required this.company,
    required this.education,
    required this.location,
    required this.datingIntention,
    required this.interests,
    required this.prompts,
    required this.lifestyle,
    required this.photos,
    required this.primaryPhotoIndex,
    required this.voicePrompt,
    required this.videoPrompt,
  });

  final String name;
  final String birthdate;
  final String gender;
  final String bio;
  final String profession;
  final String company;
  final String education;
  final String location;
  final String datingIntention;
  final List<String> interests;
  final Map<String, String> prompts;
  final Map<String, String> lifestyle;
  final List<String> photos;
  final int primaryPhotoIndex;
  final String? voicePrompt;
  final String? videoPrompt;

  String get primaryPhoto => photos.isEmpty
      ? AppImages.fallbackProfile
      : photos[primaryPhotoIndex.clamp(0, photos.length - 1)];

  int get completionPercent {
    var percentage = 0;
    if (photos.length >= 2) percentage += 25;
    if (basicDetailsComplete) percentage += 15;
    if (bio.trim().length >= 40) percentage += 15;
    if (interests.length >= 5) percentage += 15;
    if (completedPromptCount >= 3) percentage += 20;
    if (lifestyle.isNotEmpty) percentage += 10;
    return percentage;
  }

  int get completedPromptCount =>
      prompts.values.where((value) => value.trim().isNotEmpty).length;

  int? get age {
    final parts = birthdate.split('/').map((part) => part.trim()).toList();
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final today = DateTime.now();
    var value = today.year - year;
    if (today.month < month || (today.month == month && today.day < day)) {
      value--;
    }
    return value > 0 ? value : null;
  }

  bool get basicDetailsComplete =>
      name.trim().isNotEmpty &&
      birthdate.trim().isNotEmpty &&
      gender.trim().isNotEmpty &&
      profession.trim().isNotEmpty &&
      education.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      datingIntention.trim().isNotEmpty;

  bool get requiredProfileComplete =>
      basicDetailsComplete &&
      photos.length >= 2 &&
      bio.trim().length >= 40 &&
      interests.length >= 5 &&
      completedPromptCount >= 3;

  LocalProfileDraft copyWith({
    String? name,
    String? birthdate,
    String? gender,
    String? bio,
    String? profession,
    String? company,
    String? education,
    String? location,
    String? datingIntention,
    List<String>? interests,
    Map<String, String>? prompts,
    Map<String, String>? lifestyle,
    List<String>? photos,
    int? primaryPhotoIndex,
    String? voicePrompt,
    String? videoPrompt,
    bool clearVideoPrompt = false,
  }) {
    return LocalProfileDraft(
      name: name ?? this.name,
      birthdate: birthdate ?? this.birthdate,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      profession: profession ?? this.profession,
      company: company ?? this.company,
      education: education ?? this.education,
      location: location ?? this.location,
      datingIntention: datingIntention ?? this.datingIntention,
      interests: List<String>.of(interests ?? this.interests),
      prompts: Map<String, String>.of(prompts ?? this.prompts),
      lifestyle: Map<String, String>.of(lifestyle ?? this.lifestyle),
      photos: List<String>.of(photos ?? this.photos),
      primaryPhotoIndex: primaryPhotoIndex ?? this.primaryPhotoIndex,
      voicePrompt: voicePrompt ?? this.voicePrompt,
      videoPrompt: clearVideoPrompt ? null : videoPrompt ?? this.videoPrompt,
    );
  }
}

class LocalProfileRepository extends ChangeNotifier {
  LocalProfileRepository._();

  static final instance = LocalProfileRepository._();

  LocalProfileDraft _profile = const LocalProfileDraft(
    name: 'Yash Andrapiya',
    birthdate: '14 / 02 / 1998',
    gender: 'Man',
    bio:
        'Flutter engineer who values thoughtful conversations, family, and unhurried coffee dates.',
    profession: 'Flutter Engineer',
    company: 'Independent',
    education: 'Nirma University',
    location: 'Ahmedabad',
    datingIntention: 'Long-Term Relationship',
    interests: ['Coffee Dates', 'Family Values', 'Heritage Walks'],
    prompts: {
      'My ideal Sunday is...': 'Coffee, a long walk, and planning the week.',
      'A green flag I value is...': 'Clear, kind communication.',
      'Together we could...': 'Explore old-city cafés and live music.',
    },
    lifestyle: {'Exercise': 'A few times a week', 'Pets': 'Dog person'},
    photos: [
      AppImages.profileYash,
      'assets/images/profiles/male/male_06.jpg',
      'assets/images/profiles/male/male_08.jpg',
    ],
    primaryPhotoIndex: 0,
    voicePrompt: 'local://voice/ideal-sunday',
    videoPrompt: 'local://video/profile-intro',
  );

  LocalProfileDraft get profile => _profile;

  void save(LocalProfileDraft draft) {
    _profile = draft.copyWith(
      photos: draft.photos,
      interests: draft.interests,
      prompts: draft.prompts,
      primaryPhotoIndex: draft.photos.isEmpty
          ? 0
          : draft.primaryPhotoIndex.clamp(0, draft.photos.length - 1),
    );
    notifyListeners();
  }

  void updatePhotos(List<String> photos, int primaryPhotoIndex) {
    save(
      _profile.copyWith(
        photos: photos,
        primaryPhotoIndex: photos.isEmpty
            ? 0
            : primaryPhotoIndex.clamp(0, photos.length - 1),
      ),
    );
  }

  void updateVideoPrompt(String value) {
    save(_profile.copyWith(videoPrompt: value));
  }

  void startNewProfile(String name) {
    _profile = LocalProfileDraft(
      name: name.trim(),
      birthdate: '',
      gender: '',
      bio: '',
      profession: '',
      company: '',
      education: '',
      location: '',
      datingIntention: '',
      interests: const [],
      prompts: const {},
      lifestyle: const {},
      photos: const [],
      primaryPhotoIndex: 0,
      voicePrompt: null,
      videoPrompt: null,
    );
    notifyListeners();
  }
}
