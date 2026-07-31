import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.phoneNumber,
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
  final String email;
  final String phoneNumber;
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

  DateTime? get dateOfBirth => AmoraDateOfBirth.parse(birthdate);

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

  int? get age => AmoraDateOfBirth.age(dateOfBirth);

  bool get basicDetailsComplete =>
      name.trim().isNotEmpty &&
      AmoraDateOfBirth.validate(dateOfBirth) == null &&
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

  UserProfile copyWith({
    String? name,
    String? email,
    String? phoneNumber,
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
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
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

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'phoneNumber': phoneNumber,
    'birthdate': birthdate,
    'gender': gender,
    'bio': bio,
    'profession': profession,
    'company': company,
    'education': education,
    'location': location,
    'datingIntention': datingIntention,
    'interests': interests,
    'prompts': prompts,
    'lifestyle': lifestyle,
    'photos': photos,
    'primaryPhotoIndex': primaryPhotoIndex,
    'voicePrompt': voicePrompt,
    'videoPrompt': videoPrompt,
  };

  factory UserProfile.fromJson(Map<String, Object?> json) {
    List<String> strings(String key) =>
        (json[key] as List<Object?>? ?? const []).whereType<String>().toList(
          growable: false,
        );
    Map<String, String> stringMap(String key) =>
        (json[key] as Map<Object?, Object?>? ?? const {}).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );

    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? 'member@amora.ai',
      phoneNumber: json['phoneNumber'] as String? ?? '+91 98765 43210',
      birthdate: json['birthdate'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      company: json['company'] as String? ?? '',
      education: json['education'] as String? ?? '',
      location: json['location'] as String? ?? '',
      datingIntention: json['datingIntention'] as String? ?? '',
      interests: strings('interests'),
      prompts: stringMap('prompts'),
      lifestyle: stringMap('lifestyle'),
      photos: strings('photos'),
      primaryPhotoIndex: json['primaryPhotoIndex'] as int? ?? 0,
      voicePrompt: json['voicePrompt'] as String?,
      videoPrompt: json['videoPrompt'] as String?,
    );
  }
}

// Compatibility alias for existing presentation widgets. There is only one
// profile entity: UserProfile.
typedef LocalProfileDraft = UserProfile;

class LocalProfileRepository extends ChangeNotifier {
  LocalProfileRepository._();

  static final instance = LocalProfileRepository._();
  static const _storageKey = 'amora.user_profile.v1';

  UserProfile _profile = _defaultProfile;
  UserProfile get profile => _profile;

  Future<void> initialize() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      if (stored == null || stored.isEmpty) return;
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, Object?>) return;
      _apply(UserProfile.fromJson(decoded));
    } catch (_) {
      // Keep the last valid in-memory profile if local storage is unavailable
      // or contains invalid data.
    }
  }

  void save(UserProfile profile) {
    _apply(profile);
    unawaited(_persistSafely());
  }

  Future<void> savePersisted(UserProfile profile) async {
    _apply(profile);
    await _persist();
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

  Future<void> updatePhotosPersisted(
    List<String> photos,
    int primaryPhotoIndex,
  ) {
    return savePersisted(
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

  void startNewProfile(String name, {String? email, String? phoneNumber}) {
    save(
      UserProfile(
        name: name.trim(),
        email: email?.trim() ?? _profile.email,
        phoneNumber: phoneNumber?.trim() ?? _profile.phoneNumber,
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
      ),
    );
  }

  void _apply(UserProfile value) {
    final parsedBirthdate = AmoraDateOfBirth.parse(value.birthdate);
    final photos = List<String>.of(value.photos);
    _profile = value.copyWith(
      birthdate: parsedBirthdate == null
          ? ''
          : AmoraDateOfBirth.format(parsedBirthdate),
      photos: photos,
      interests: value.interests,
      prompts: value.prompts,
      primaryPhotoIndex: photos.isEmpty
          ? 0
          : value.primaryPhotoIndex.clamp(0, photos.length - 1),
    );
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(_profile.toJson()));
  }

  Future<void> _persistSafely() async {
    try {
      await _persist();
    } catch (_) {
      // The in-memory profile remains usable when device storage is
      // temporarily unavailable.
    }
  }

  Future<void> clearForAccountDeletion() async {
    _profile = _clearedProfile;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @visibleForTesting
  Future<void> resetForTesting([UserProfile? profile]) async {
    _profile = profile ?? _defaultProfile;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_storageKey);
    } catch (_) {
      // Tests without a shared_preferences platform implementation still use
      // the deterministic in-memory profile above.
    }
  }
}

const _defaultProfile = UserProfile(
  name: 'Yash Andrapiya',
  email: 'member@amora.ai',
  phoneNumber: '+91 98765 43210',
  birthdate: '14/02/1998',
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
    'Together we could...': 'Explore old-city cafes and live music.',
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

const _clearedProfile = UserProfile(
  name: '',
  email: '',
  phoneNumber: '',
  birthdate: '',
  gender: '',
  bio: '',
  profession: '',
  company: '',
  education: '',
  location: '',
  datingIntention: '',
  interests: [],
  prompts: {},
  lifestyle: {},
  photos: [],
  primaryPhotoIndex: 0,
  voicePrompt: null,
  videoPrompt: null,
);
