import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/constants/app_images.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/domain/profile_completion_calculator.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
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
    this.hometown = '',
    this.valuedQualities = const <String>[],
    this.pronouns = const <String>[],
    this.sexuality = '',
    this.preferredTalkingHours = const <String>[],
    this.loveLanguages = const <String>[],
    this.iceBreaker = '',
    this.communicationStyle,
    this.serverCompletionPercent,
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
  final String hometown;
  final List<String> valuedQualities;
  final List<String> pronouns;
  final String sexuality;
  final List<String> preferredTalkingHours;
  final List<String> loveLanguages;
  final String iceBreaker;
  final CommunicationStyle? communicationStyle;
  final int? serverCompletionPercent;

  DateTime? get dateOfBirth => AmoraDateOfBirth.parse(birthdate);

  String get primaryPhoto => photos.isEmpty
      ? AppImages.fallbackProfile
      : photos[primaryPhotoIndex.clamp(0, photos.length - 1)];

  ProfileCompletionInput get completionInput => ProfileCompletionInput(
    photoCount: photos.length,
    name: name,
    birthdate: dateOfBirth,
    gender: gender,
    profession: profession,
    education: education,
    location: location,
    datingIntention: datingIntention,
    height: lifestyle['Height'] ?? '',
    languages: lifestyle['Languages'] ?? '',
    religion: lifestyle['Religion'] ?? '',
    bio: bio,
    interests: interests,
    lifestyle: lifestyle,
    completedPromptCount: completedPromptCount,
  );

  ProfileCompletionResult get completionResult =>
      ProfileCompletionCalculator.calculate(completionInput);

  List<ProfilePendingField> get pendingFields =>
      ProfileCompletionCalculator.pendingFields(completionInput);

  int get completionPercent =>
      serverCompletionPercent ?? completionResult.percentage;

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

  bool get requiredProfileComplete => serverCompletionPercent == null
      ? completionResult.isComplete
      : serverCompletionPercent == 100;

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
    bool clearVoicePrompt = false,
    String? videoPrompt,
    bool clearVideoPrompt = false,
    String? hometown,
    List<String>? valuedQualities,
    List<String>? pronouns,
    String? sexuality,
    List<String>? preferredTalkingHours,
    List<String>? loveLanguages,
    String? iceBreaker,
    CommunicationStyle? communicationStyle,
    bool clearCommunicationStyle = false,
    int? serverCompletionPercent,
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
      voicePrompt: clearVoicePrompt ? null : voicePrompt ?? this.voicePrompt,
      videoPrompt: clearVideoPrompt ? null : videoPrompt ?? this.videoPrompt,
      hometown: hometown ?? this.hometown,
      valuedQualities: List<String>.of(valuedQualities ?? this.valuedQualities),
      pronouns: List<String>.of(pronouns ?? this.pronouns),
      sexuality: sexuality ?? this.sexuality,
      preferredTalkingHours: List<String>.of(
        preferredTalkingHours ?? this.preferredTalkingHours,
      ),
      loveLanguages: List<String>.of(loveLanguages ?? this.loveLanguages),
      iceBreaker: iceBreaker ?? this.iceBreaker,
      communicationStyle: clearCommunicationStyle
          ? null
          : communicationStyle ?? this.communicationStyle,
      serverCompletionPercent:
          serverCompletionPercent ?? this.serverCompletionPercent,
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
    'hometown': hometown,
    'valuedQualities': valuedQualities,
    'pronouns': pronouns,
    'sexuality': sexuality,
    'preferredTalkingHours': preferredTalkingHours,
    'loveLanguages': loveLanguages,
    'iceBreaker': iceBreaker,
    'communicationStyle': communicationStyle?.storageValue,
    if (serverCompletionPercent != null)
      'profileCompletion': <String, Object?>{
        'percentage': serverCompletionPercent,
        'complete': serverCompletionPercent == 100,
      },
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

    final completion = json['profileCompletion'] as Map<Object?, Object?>?;
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
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
      hometown: json['hometown'] as String? ?? '',
      valuedQualities: strings('valuedQualities'),
      pronouns: strings('pronouns'),
      sexuality: json['sexuality'] as String? ?? '',
      preferredTalkingHours: strings('preferredTalkingHours'),
      loveLanguages: strings('loveLanguages'),
      iceBreaker: json['iceBreaker'] as String? ?? '',
      communicationStyle: CommunicationStyle.fromStorageValue(
        json['communicationStyle'],
      ),
      serverCompletionPercent: (completion?['percentage'] as num?)?.toInt(),
    );
  }
}

abstract interface class OwnProfileRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthOwnProfileRemoteDataSource implements OwnProfileRemoteDataSource {
  const AuthOwnProfileRemoteDataSource();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => AuthService.instance.authenticatedRequest(method, path, body: body);
}

// Compatibility alias for existing presentation widgets. There is only one
// profile entity: UserProfile.
typedef LocalProfileDraft = UserProfile;

enum ProfilePhotoUploadState {
  bundled,
  uploaded,
  localOnly,
  uploading,
  failed,
  deleting,
}

@immutable
class ProfilePhotoViewData {
  const ProfilePhotoViewData({
    required this.id,
    required this.source,
    required this.order,
    required this.isPrimary,
    required this.uploadState,
    this.bytes,
    this.mimeType,
    this.errorMessage,
  });

  final String id;
  final String source;
  final int order;
  final bool isPrimary;
  final ProfilePhotoUploadState uploadState;
  final Uint8List? bytes;
  final String? mimeType;
  final String? errorMessage;

  String? get remoteUrl {
    final value = source.trim();
    return value.startsWith('http://') || value.startsWith('https://')
        ? value
        : null;
  }

  String? get dataUri {
    final value = source.trim();
    return value.startsWith('data:image/') ? value : null;
  }

  String? get localPath {
    final value = source.trim();
    if (value.startsWith('file://') ||
        RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value) ||
        value.startsWith('/')) {
      return value;
    }
    return null;
  }

  bool get isLocal => switch (uploadState) {
    ProfilePhotoUploadState.localOnly ||
    ProfilePhotoUploadState.uploading ||
    ProfilePhotoUploadState.failed => true,
    _ => false,
  };
}

class LocalProfileRepository extends ChangeNotifier {
  LocalProfileRepository._({OwnProfileRemoteDataSource? remote})
    : _remote = remote ?? const AuthOwnProfileRemoteDataSource();

  static final instance = LocalProfileRepository._();
  static const int maxProfilePhotos = 6;
  @visibleForTesting
  factory LocalProfileRepository.testing({
    required OwnProfileRemoteDataSource remote,
  }) => LocalProfileRepository._(remote: remote);

  final OwnProfileRemoteDataSource _remote;
  static const _storageKey = 'amora.user_profile.v1';

  UserProfile _profile = _defaultProfile;
  UserProfile get profile => _profile;
  final Map<String, String> _photoIds = {};
  final Map<String, ProfilePhotoUploadState> _photoStates = {};
  final Map<String, Uint8List> _photoBytes = {};
  final Map<String, String> _photoMimeTypes = {};
  final Map<String, String> _photoErrors = {};
  int _nextPhotoId = 0;
  String? lastSyncError;
  bool _hasHydratedAuthenticatedProfile = false;
  bool get hasHydratedAuthenticatedProfile => _hasHydratedAuthenticatedProfile;

  List<ProfilePhotoViewData> get currentPhotos =>
      List.unmodifiable(<ProfilePhotoViewData>[
        for (var index = 0; index < _profile.photos.length; index++)
          ProfilePhotoViewData(
            id: _photoIds.putIfAbsent(
              _profile.photos[index],
              () => 'profile-photo-${_nextPhotoId++}',
            ),
            source: _profile.photos[index],
            order: index,
            isPrimary: index == _profile.primaryPhotoIndex,
            uploadState: _photoStates.putIfAbsent(
              _profile.photos[index],
              () => _initialPhotoState(_profile.photos[index]),
            ),
            bytes: _photoBytes[_profile.photos[index]],
            mimeType: _photoMimeTypes[_profile.photos[index]],
            errorMessage: _photoErrors[_profile.photos[index]],
          ),
      ]);

  Future<void> initialize() async {
    if (AuthService.instance.currentUser != null) {
      prepareForAuthenticatedUser();
      try {
        await refreshFromServer();
      } on AuthException catch (error) {
        lastSyncError = error.message;
      }
      return;
    }
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

  void prepareForAuthenticatedUser() {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    _hasHydratedAuthenticatedProfile = false;
    lastSyncError = null;
    _apply(
      UserProfile(
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        birthdate: '',
        gender: '',
        bio: '',
        profession: '',
        company: '',
        education: '',
        location: '',
        datingIntention: '',
        interests: const <String>[],
        prompts: const <String, String>{},
        lifestyle: const <String, String>{},
        photos: const <String>[],
        primaryPhotoIndex: 0,
        voicePrompt: null,
        videoPrompt: null,
      ),
    );
  }

  void save(UserProfile profile) {
    if (AuthService.instance.currentUser != null) {
      final previous = _profile;
      _apply(profile);
      unawaited(
        _saveRemote(profile, baseline: previous).catchError((Object error) {
          lastSyncError = error is AuthException
              ? error.message
              : error.toString();
          _apply(previous);
        }),
      );
      return;
    }
    _apply(profile);
    unawaited(_persistSafely());
  }

  /// Replaces presentation state without issuing another backend write.
  ///
  /// Server hydration and onboarding field edits use this path so reading a
  /// canonical profile cannot race a second full-profile PUT back to MySQL.
  void updateInSession(UserProfile profile) => _apply(profile);

  Future<void> savePersisted(UserProfile profile) async {
    if (AuthService.instance.currentUser != null) {
      await _saveRemote(profile, baseline: _profile);
      return;
    }
    _apply(profile);
    await _persist();
  }

  Future<void> refreshFromServer() async {
    if (AuthService.instance.currentUser == null) return;
    try {
      final response = await _remote.request('GET', '/api/me/profile');
      final profile = ((response['data'] as Map?)?['profile'] as Map?)
          ?.cast<String, dynamic>();
      if (profile == null) {
        throw const AuthException('Own profile response is invalid.');
      }
      lastSyncError = null;
      _hasHydratedAuthenticatedProfile = true;
      _apply(UserProfile.fromJson(profile.cast<String, Object?>()));
    } on AuthException catch (error) {
      lastSyncError = error.userMessage;
      notifyListeners();
      rethrow;
    } catch (_) {
      lastSyncError = 'Profile could not be loaded. Please try again.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _saveRemote(
    UserProfile profile, {
    required UserProfile baseline,
  }) async {
    final birthDate = profile.dateOfBirth;
    final previousBirthDate = baseline.dateOfBirth;
    final photosChanged = !listEquals(profile.photos, baseline.photos);
    final body = <String, dynamic>{
      if (profile.name != baseline.name) 'name': profile.name,
      if (birthDate != previousBirthDate && birthDate != null)
        'birthdate':
            '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
      if (profile.gender != baseline.gender) 'gender': profile.gender,
      if (profile.bio != baseline.bio) 'bio': profile.bio,
      if (profile.profession != baseline.profession)
        'profession': profile.profession,
      if (profile.company != baseline.company) 'company': profile.company,
      if (profile.education != baseline.education)
        'education': profile.education,
      if (profile.location != baseline.location) 'location': profile.location,
      if (profile.datingIntention != baseline.datingIntention)
        'datingIntention': profile.datingIntention,
      if (!listEquals(profile.interests, baseline.interests))
        'interests': profile.interests,
      if (!mapEquals(profile.prompts, baseline.prompts))
        'prompts': profile.prompts,
      if (!mapEquals(profile.lifestyle, baseline.lifestyle))
        'lifestyle': profile.lifestyle,
      if (profile.hometown != baseline.hometown) 'hometown': profile.hometown,
      if (!listEquals(profile.valuedQualities, baseline.valuedQualities))
        'valuedQualities': profile.valuedQualities,
      if (!listEquals(profile.pronouns, baseline.pronouns))
        'pronouns': profile.pronouns,
      if (profile.sexuality != baseline.sexuality)
        'sexuality': profile.sexuality,
      if (!listEquals(
        profile.preferredTalkingHours,
        baseline.preferredTalkingHours,
      ))
        'preferredTalkingHours': profile.preferredTalkingHours,
      if (!listEquals(profile.loveLanguages, baseline.loveLanguages))
        'loveLanguages': profile.loveLanguages,
      if (profile.iceBreaker != baseline.iceBreaker)
        'iceBreaker': profile.iceBreaker,
      if (profile.communicationStyle != baseline.communicationStyle)
        'communicationStyle': profile.communicationStyle?.storageValue,
      if (photosChanged &&
          profile.photos.every((value) => value.startsWith('http')))
        'photos': profile.photos,
      if ((photosChanged ||
              profile.primaryPhotoIndex != baseline.primaryPhotoIndex) &&
          profile.photos.isNotEmpty &&
          profile.photos.every((value) => value.startsWith('http')))
        'primaryPhotoIndex': profile.primaryPhotoIndex,
    };
    if (body.isEmpty) {
      _apply(profile);
      return;
    }
    final response = await _remote.request(
      'PUT',
      '/api/me/profile',
      body: body,
    );
    final canonical = ((response['data'] as Map?)?['profile'] as Map?)
        ?.cast<String, dynamic>();
    if (canonical == null) {
      throw const AuthException('Updated profile response is invalid.');
    }
    lastSyncError = null;
    _hasHydratedAuthenticatedProfile = true;
    _apply(UserProfile.fromJson(canonical.cast<String, Object?>()));
  }

  Future<String> uploadPhoto(String localSource) async {
    final bytes = _photoBytes[localSource];
    final mimeType = _photoMimeTypes[localSource];
    if (bytes == null || mimeType == null) {
      throw const AuthException('The selected photo is no longer available.');
    }
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };
    final response = await AuthService.instance.authenticatedMultipart(
      '/api/onboarding/photos',
      field: 'photos',
      bytes: bytes,
      filename: 'profile-${DateTime.now().microsecondsSinceEpoch}.$extension',
      mimeType: mimeType,
    );
    final onboarding = ((response['data'] as Map?)?['onboarding'] as Map?)
        ?.cast<String, dynamic>();
    final photos = (onboarding?['photos'] as List?) ?? const <dynamic>[];
    if (photos.isEmpty) {
      throw const AuthException('The photo upload returned no file.');
    }
    final value = photos.last.toString();
    return value.startsWith('http') ? value : '${AmoraApiConfig.baseUrl}$value';
  }

  Future<void> deletePhotoPersisted(int index) async {
    if (AuthService.instance.currentUser == null) {
      removePhotoInSession(index);
      return;
    }
    await AuthService.instance.authenticatedRequest(
      'DELETE',
      '/api/onboarding/photos/$index',
    );
    await refreshFromServer();
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

  void updatePhotosInSession(List<String> photos, int primaryPhotoIndex) {
    _apply(
      _profile.copyWith(
        photos: photos,
        primaryPhotoIndex: photos.isEmpty
            ? 0
            : primaryPhotoIndex.clamp(0, photos.length - 1),
      ),
    );
  }

  void addPhotoInSession(
    String source, {
    ProfilePhotoUploadState uploadState = ProfilePhotoUploadState.localOnly,
    Uint8List? bytes,
    String? mimeType,
  }) {
    if (source.trim().isEmpty ||
        _profile.photos.contains(source) ||
        _profile.photos.length >= maxProfilePhotos) {
      return;
    }
    _photoIds[source] = 'profile-photo-${_nextPhotoId++}';
    _photoStates[source] = uploadState;
    if (bytes != null && bytes.isNotEmpty) _photoBytes[source] = bytes;
    if (mimeType != null && mimeType.trim().isNotEmpty) {
      _photoMimeTypes[source] = mimeType.trim();
    }
    final photos = [..._profile.photos, source];
    updatePhotosInSession(
      photos,
      photos.length == 1 ? 0 : _profile.primaryPhotoIndex,
    );
  }

  void setPrimaryPhotoInSession(int index) {
    if (index < 0 || index >= _profile.photos.length) return;
    updatePhotosInSession(_profile.photos, index);
  }

  void removePhotoInSession(int index) {
    if (index < 0 || index >= _profile.photos.length) return;
    final photos = List<String>.of(_profile.photos);
    final removed = photos.removeAt(index);
    _photoIds.remove(removed);
    _photoStates.remove(removed);
    _photoBytes.remove(removed);
    _photoMimeTypes.remove(removed);
    _photoErrors.remove(removed);
    var primary = _profile.primaryPhotoIndex;
    if (photos.isEmpty) {
      primary = 0;
    } else if (index < primary) {
      primary--;
    } else if (index == primary) {
      primary = index.clamp(0, photos.length - 1);
    }
    updatePhotosInSession(photos, primary);
  }

  void reorderPhotosInSession(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _profile.photos.length) return;
    final photos = List<String>.of(_profile.photos);
    final primarySource = photos[_profile.primaryPhotoIndex];
    final target = newIndex.clamp(0, photos.length - 1);
    final photo = photos.removeAt(oldIndex);
    photos.insert(target, photo);
    updatePhotosInSession(photos, photos.indexOf(primarySource));
  }

  void setPhotoUploadState(
    String source,
    ProfilePhotoUploadState uploadState, {
    String? errorMessage,
  }) {
    if (!_profile.photos.contains(source)) return;
    _photoStates[source] = uploadState;
    if (errorMessage == null || errorMessage.trim().isEmpty) {
      _photoErrors.remove(source);
    } else {
      _photoErrors[source] = errorMessage.trim();
    }
    notifyListeners();
  }

  void replacePhotoSourceInSession(String localSource, String remoteUrl) {
    final index = _profile.photos.indexOf(localSource);
    final normalizedRemoteUrl = remoteUrl.trim();
    if (index < 0 || !_isRemotePhotoUrl(normalizedRemoteUrl)) return;
    final photos = List<String>.of(_profile.photos)
      ..[index] = normalizedRemoteUrl;
    final id = _photoIds.remove(localSource);
    final bytes = _photoBytes.remove(localSource);
    final mimeType = _photoMimeTypes.remove(localSource);
    _photoStates.remove(localSource);
    _photoErrors.remove(localSource);
    if (id != null) _photoIds[normalizedRemoteUrl] = id;
    if (bytes != null && bytes.isNotEmpty) {
      _photoBytes[normalizedRemoteUrl] = bytes;
    }
    if (mimeType != null && mimeType.isNotEmpty) {
      _photoMimeTypes[normalizedRemoteUrl] = mimeType;
    }
    _photoStates[normalizedRemoteUrl] = ProfilePhotoUploadState.uploaded;
    updatePhotosInSession(photos, _profile.primaryPhotoIndex);
  }

  Future<void> updatePhotosPersisted(
    List<String> photos,
    int primaryPhotoIndex,
  ) async {
    if (photos.length > maxProfilePhotos) {
      throw const AuthException('A maximum of 6 photos is allowed.');
    }
    final normalizedPrimary = photos.isEmpty
        ? 0
        : primaryPhotoIndex.clamp(0, photos.length - 1);
    final next = _profile.copyWith(
      photos: photos,
      primaryPhotoIndex: normalizedPrimary,
    );
    if (AuthService.instance.currentUser == null) {
      _apply(next);
      await _persist();
      return;
    }
    if (photos.any((photo) => !_isRemotePhotoUrl(photo))) {
      throw const AuthException(
        'Upload every local photo before saving your profile.',
      );
    }
    final response = await _remote.request(
      'PUT',
      '/api/me/profile',
      body: <String, dynamic>{
        'photos': photos,
        if (photos.isNotEmpty) 'primaryPhotoIndex': normalizedPrimary,
      },
    );
    final canonical = ((response['data'] as Map?)?['profile'] as Map?)
        ?.cast<String, dynamic>();
    if (canonical == null) {
      throw const AuthException('Updated profile response is invalid.');
    }
    lastSyncError = null;
    _hasHydratedAuthenticatedProfile = true;
    _apply(UserProfile.fromJson(canonical.cast<String, Object?>()));
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
    final activeSources = photos.toSet();
    _photoIds.removeWhere((source, _) => !activeSources.contains(source));
    _photoStates.removeWhere((source, _) => !activeSources.contains(source));
    _photoBytes.removeWhere((source, _) => !activeSources.contains(source));
    _photoMimeTypes.removeWhere((source, _) => !activeSources.contains(source));
    _photoErrors.removeWhere((source, _) => !activeSources.contains(source));
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    final primarySource = _profile.photos.isEmpty
        ? null
        : _profile.photos[_profile.primaryPhotoIndex];
    final durablePhotos = currentPhotos
        .where(
          (photo) =>
              photo.uploadState != ProfilePhotoUploadState.localOnly &&
              photo.uploadState != ProfilePhotoUploadState.uploading &&
              photo.uploadState != ProfilePhotoUploadState.failed,
        )
        .map((photo) => photo.source)
        .toList(growable: false);
    final selectedDurableIndex = primarySource == null
        ? -1
        : durablePhotos.indexOf(primarySource);
    final durablePrimaryIndex = selectedDurableIndex < 0
        ? 0
        : selectedDurableIndex;
    final durableProfile = _profile.copyWith(
      photos: durablePhotos,
      primaryPhotoIndex: durablePrimaryIndex,
    );
    await preferences.setString(
      _storageKey,
      jsonEncode(durableProfile.toJson()),
    );
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
    clearSessionProfile();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  void clearSessionProfile() {
    _profile = _clearedProfile;
    lastSyncError = null;
    _hasHydratedAuthenticatedProfile = false;
    _photoIds.clear();
    _photoStates.clear();
    _photoBytes.clear();
    _photoMimeTypes.clear();
    _photoErrors.clear();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetForTesting([UserProfile? profile]) async {
    _profile = profile ?? _testProfile;
    _hasHydratedAuthenticatedProfile = true;
    _photoIds.clear();
    _photoStates.clear();
    _photoBytes.clear();
    _photoMimeTypes.clear();
    _photoErrors.clear();
    _nextPhotoId = 0;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_storageKey);
    } catch (_) {
      // Tests without a shared_preferences platform implementation still use
      // the deterministic in-memory profile above.
    }
  }

  static ProfilePhotoUploadState _initialPhotoState(String source) {
    final value = source.trim().toLowerCase();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ProfilePhotoUploadState.uploaded;
    }
    if (value.startsWith('data:image/') ||
        value.startsWith('file://') ||
        RegExp(r'^[a-z]:[\\/]').hasMatch(value) ||
        value.startsWith('/')) {
      return ProfilePhotoUploadState.localOnly;
    }
    return ProfilePhotoUploadState.bundled;
  }

  static bool _isRemotePhotoUrl(String source) {
    final uri = Uri.tryParse(source);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

// Production starts with no profile data. Authenticated sessions replace this
// from /api/me/profile; unauthenticated sessions must never inherit a demo user.
const _defaultProfile = _clearedProfile;

// Explicit fixture used only through resetForTesting. It is never selected by
// the application startup, signup, login, or profile-loading paths.
const _testProfile = UserProfile(
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
  hometown: 'Gandhinagar',
  valuedQualities: ['Empathy', 'Loyalty', 'Humour'],
  pronouns: ['he', 'him'],
  sexuality: 'Straight',
  preferredTalkingHours: ['Evening', 'Late Night'],
  loveLanguages: ['Quality Time', 'Words of Affirmation'],
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
