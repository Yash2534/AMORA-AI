import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/config/amora_api_config.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/onboarding/data/onboarding_api_service.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OnboardingStage {
  verification,
  age,
  gender,
  interestedIn,
  relationshipGoal,
  location,
  starterProfile,
  profileCompletion,
  photos,
  complete,
}

@immutable
class LocalOnboardingState {
  const LocalOnboardingState({
    this.stage = OnboardingStage.gender,
    this.birthDate,
    this.gender,
    this.customGender = '',
    this.showGender = true,
    this.interestedIn = const <String>{},
    this.relationshipGoals = const <String>{},
    this.relationshipGoal,
    this.city,
    this.preferredDistance = 50,
    this.accountVerified = false,
    this.onboardingCompleted = false,
    this.profileCompleted = false,
  });

  final OnboardingStage stage;
  final DateTime? birthDate;
  final String? gender;
  final String customGender;
  final bool showGender;
  final Set<String> interestedIn;
  final Set<String> relationshipGoals;
  final String? relationshipGoal;
  final String? city;
  final double preferredDistance;
  final bool accountVerified;
  final bool onboardingCompleted;
  final bool profileCompleted;

  int? get age {
    final date = birthDate;
    if (date == null) return null;
    final today = DateTime.now();
    var value = today.year - date.year;
    if (today.month < date.month ||
        (today.month == date.month && today.day < date.day)) {
      value--;
    }
    return value;
  }

  bool get isAdult => (age ?? 0) >= 18;

  Set<String> get selectedRelationshipGoals {
    final storedValues = relationshipGoals.isEmpty
        ? <String>{?relationshipGoal}
        : relationshipGoals;
    return <String>{
      for (final value in storedValues)
        if (ProfileFormOptions.normalizeDatingIntention(value).isNotEmpty)
          ProfileFormOptions.normalizeDatingIntention(value),
    };
  }

  String? get primaryRelationshipGoal {
    final selected = selectedRelationshipGoals;
    final legacy = ProfileFormOptions.normalizeDatingIntention(
      relationshipGoal,
    );
    if (selected.contains(legacy)) return legacy;
    for (final option in ProfileFormOptions.datingIntentions) {
      if (selected.contains(option)) return option;
    }
    final rawLegacy = relationshipGoal?.trim() ?? '';
    return rawLegacy.isEmpty ? null : rawLegacy;
  }

  LocalOnboardingState copyWith({
    OnboardingStage? stage,
    DateTime? birthDate,
    String? gender,
    String? customGender,
    bool? showGender,
    Set<String>? interestedIn,
    Set<String>? relationshipGoals,
    String? relationshipGoal,
    bool clearRelationshipGoal = false,
    String? city,
    double? preferredDistance,
    bool? accountVerified,
    bool? onboardingCompleted,
    bool? profileCompleted,
  }) {
    return LocalOnboardingState(
      stage: stage ?? this.stage,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      customGender: customGender ?? this.customGender,
      showGender: showGender ?? this.showGender,
      interestedIn: Set<String>.of(interestedIn ?? this.interestedIn),
      relationshipGoals: Set<String>.of(
        relationshipGoals ?? this.relationshipGoals,
      ),
      relationshipGoal: clearRelationshipGoal
          ? null
          : relationshipGoal ?? this.relationshipGoal,
      city: city ?? this.city,
      preferredDistance: preferredDistance ?? this.preferredDistance,
      accountVerified: accountVerified ?? this.accountVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
}

/// Local presentation state mirrored to the authenticated onboarding API.
///
/// No server verification, GPS, or identity claim is made here. The singleton
/// matches the project's existing local repository pattern and can later be
/// backed by production storage without changing presentation code.
class LocalOnboardingRepository extends ChangeNotifier
    with WidgetsBindingObserver {
  LocalOnboardingRepository._();

  static final instance = LocalOnboardingRepository._();
  static const _storageKey = 'amora.onboarding_state.v1';

  LocalOnboardingState _state = const LocalOnboardingState();
  final OnboardingApiService _api = OnboardingApiService();
  Future<void> _syncQueue = Future<void>.value();
  int _syncFailureCount = 0;
  bool _testingMode = false;
  bool _lifecycleObserverRegistered = false;
  final ValueNotifier<String?> syncError = ValueNotifier<String?>(null);
  LocalOnboardingState get state => _state;

  Future<void> initialize() async {
    if (!_lifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      if (stored == null || stored.isEmpty) {
        final profile = LocalProfileRepository.instance.profile;
        final previouslyCompleted =
            profile.dateOfBirth != null &&
            profile.gender.trim().isNotEmpty &&
            profile.location.trim().isNotEmpty &&
            profile.datingIntention.trim().isNotEmpty &&
            profile.photos.length >= 2;
        if (previouslyCompleted) {
          _state = const LocalOnboardingState(
            stage: OnboardingStage.complete,
            onboardingCompleted: true,
          );
          await _persist();
          notifyListeners();
        }
      } else {
        final decoded = jsonDecode(stored);
        if (decoded is Map) {
          final json = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final stageName = json['stage'] as String?;
          final stage = OnboardingStage.values
              .where((value) => value.name == stageName)
              .firstOrNull;
          final birthDateValue = json['birthDate'] as String?;
          _state = LocalOnboardingState(
            stage: stage ?? OnboardingStage.gender,
            birthDate: birthDateValue == null
                ? null
                : DateTime.tryParse(birthDateValue),
            gender: json['gender'] as String?,
            customGender: json['customGender'] as String? ?? '',
            showGender: json['showGender'] as bool? ?? true,
            interestedIn:
                (json['interestedIn'] as List?)?.whereType<String>().toSet() ??
                const <String>{},
            relationshipGoals:
                (json['relationshipGoals'] as List?)
                    ?.whereType<String>()
                    .toSet() ??
                const <String>{},
            relationshipGoal: json['relationshipGoal'] as String?,
            city: json['city'] as String?,
            preferredDistance:
                (json['preferredDistance'] as num?)?.toDouble() ?? 50,
            accountVerified: json['accountVerified'] as bool? ?? false,
            onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
            profileCompleted: json['profileCompleted'] as bool? ?? false,
          );
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep the last valid state if local storage is unavailable or invalid.
    }
    if (AuthService.instance.currentUser != null) {
      final synchronized = await syncFromServer();
      if (!synchronized) prepareForAuthenticatedUser();
    }
  }

  void update(LocalOnboardingState state) {
    _state = state;
    _syncUserProfile();
    notifyListeners();
    unawaited(_persistSafely());
    if (!_testingMode) unawaited(_enqueueSync(state));
  }

  Future<bool> updatePersisted(LocalOnboardingState state) async {
    if (!_testingMode && state.stage == OnboardingStage.complete) {
      return completeOnboarding(state);
    }
    final failureCheckpoint = _syncFailureCount;
    final previous = _state;
    _state = state;
    _syncUserProfile();
    notifyListeners();
    await _persist();
    if (_testingMode) return true;
    await _enqueueSync(state);
    final saved = _syncFailureCount == failureCheckpoint;
    if (!saved) {
      _state = state.copyWith(
        stage: previous.stage,
        onboardingCompleted: previous.onboardingCompleted,
      );
      await _persistSafely();
      notifyListeners();
    }
    return saved;
  }

  Future<bool> completeOnboarding([LocalOnboardingState? desiredState]) async {
    final next = desiredState ?? _state;
    if (_testingMode) {
      _state = next.copyWith(
        stage: OnboardingStage.complete,
        onboardingCompleted: true,
      );
      notifyListeners();
      return true;
    }
    await _syncQueue;
    syncError.value = null;
    final completed = await _syncAll(next);
    if (!completed) return false;
    try {
      await LocalProfileRepository.instance.refreshFromServer();
      await syncFromServer();
    } on AuthException catch (error) {
      _logFailure('refresh', error.userMessage);
      return false;
    }
    final confirmed = _state.onboardingCompleted;
    if (!confirmed) {
      _logFailure(
        'complete',
        'The server did not confirm profile completion. Please try again.',
      );
    }
    return confirmed;
  }

  void hydrateFromUserProfile() {
    final profile = LocalProfileRepository.instance.profile;
    _state = _state.copyWith(
      birthDate: profile.dateOfBirth,
      gender: profile.gender.isEmpty ? null : profile.gender,
      city: profile.location.isEmpty ? null : profile.location,
      relationshipGoals: profile.datingIntention.isEmpty
          ? const <String>{}
          : <String>{profile.datingIntention},
      relationshipGoal: profile.datingIntention.isEmpty
          ? null
          : profile.datingIntention,
      clearRelationshipGoal: profile.datingIntention.isEmpty,
    );
    notifyListeners();
  }

  void markProfileCompleted(bool value) {
    update(
      _state.copyWith(
        profileCompleted: value,
        stage: value
            ? OnboardingStage.complete
            : OnboardingStage.profileCompletion,
      ),
    );
  }

  void resetForNewAccount() {
    _state = const LocalOnboardingState(stage: OnboardingStage.verification);
    notifyListeners();
    unawaited(_persistSafely());
  }

  void prepareForAuthenticatedUser() {
    if (_testingMode) return;
    _state = LocalOnboardingState(
      stage: OnboardingStage.age,
      accountVerified: AuthService.instance.currentUser?.isVerified ?? false,
    );
    notifyListeners();
  }

  void clearSyncError() => syncError.value = null;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(syncFromServer());
  }

  Future<bool> syncFromServer() async {
    if (AuthService.instance.currentUser == null) return false;
    final result = await _api.status();
    if (!result.success || result.data == null) {
      _logFailure('status', result.message);
      return false;
    }
    _applyServerProfile(result.data!);
    await _persistSafely();
    notifyListeners();
    return true;
  }

  Future<void> clearForAccountDeletion() async {
    _state = const LocalOnboardingState();
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @visibleForTesting
  void resetForTesting([LocalOnboardingState? state]) {
    _testingMode = true;
    _syncFailureCount = 0;
    _syncQueue = Future<void>.value();
    _state = state ?? const LocalOnboardingState();
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(<String, Object?>{
        'stage': _state.stage.name,
        'birthDate': _state.birthDate?.toIso8601String(),
        'gender': _state.gender,
        'customGender': _state.customGender,
        'showGender': _state.showGender,
        'interestedIn': _state.interestedIn.toList(),
        'relationshipGoals': [
          for (final option in ProfileFormOptions.datingIntentions)
            if (_state.selectedRelationshipGoals.contains(option)) option,
        ],
        'relationshipGoal': _state.relationshipGoal,
        'city': _state.city,
        'preferredDistance': _state.preferredDistance,
        'accountVerified': _state.accountVerified,
        'onboardingCompleted': _state.onboardingCompleted,
        'profileCompleted': _state.profileCompleted,
      }),
    );
  }

  Future<void> _persistSafely() async {
    try {
      await _persist();
    } catch (_) {
      // The in-memory state remains available if persistence fails.
    }
  }

  Future<void> _enqueueSync(LocalOnboardingState state) {
    _syncQueue = _syncQueue.then((_) => _syncState(state)).catchError((error) {
      developer.log(
        'Onboarding sync queue failed.',
        name: 'AmoraOnboarding',
        error: error,
      );
    });
    return _syncQueue;
  }

  Future<void> _syncState(LocalOnboardingState state) async {
    switch (state.stage) {
      case OnboardingStage.age:
        if (state.birthDate != null) {
          await _record('age', _api.saveAge(state.birthDate!));
        }
        break;
      case OnboardingStage.gender:
        if (state.gender != null && state.gender!.isNotEmpty) {
          await _record(
            'gender',
            _api.saveGender(state.gender!, customGender: state.customGender),
          );
        }
        break;
      case OnboardingStage.interestedIn:
        if (state.interestedIn.isNotEmpty) {
          await _record(
            'interestedIn',
            _api.saveInterestedIn(state.interestedIn),
          );
        }
        break;
      case OnboardingStage.relationshipGoal:
        if (state.selectedRelationshipGoals.isNotEmpty) {
          await _record(
            'relationshipGoal',
            _api.saveRelationshipGoals(state.selectedRelationshipGoals),
          );
        }
        break;
      case OnboardingStage.location:
        if (state.city != null && state.city!.trim().isNotEmpty) {
          await _record(
            'location',
            _api.saveLocation(state.city!.trim(), state.preferredDistance),
          );
        }
        break;
      case OnboardingStage.starterProfile:
        await _syncProfileData(includeStarter: true, includeCompletion: false);
        break;
      case OnboardingStage.profileCompletion:
        await _syncProfileData(includeStarter: true, includeCompletion: true);
        break;
      case OnboardingStage.photos:
        await _syncPhotos();
        break;
      case OnboardingStage.complete:
        await _syncAll(state);
        break;
      case OnboardingStage.verification:
        break;
    }
  }

  Future<bool> _syncAll(LocalOnboardingState state) async {
    if (state.birthDate != null) {
      if (!await _record('age', _api.saveAge(state.birthDate!))) return false;
    }
    if (state.gender != null && state.gender!.isNotEmpty) {
      if (!await _record(
        'gender',
        _api.saveGender(state.gender!, customGender: state.customGender),
      )) {
        return false;
      }
    }
    if (state.interestedIn.isNotEmpty) {
      if (!await _record(
        'interestedIn',
        _api.saveInterestedIn(state.interestedIn),
      )) {
        return false;
      }
    }
    if (state.selectedRelationshipGoals.isNotEmpty) {
      if (!await _record(
        'relationshipGoal',
        _api.saveRelationshipGoals(state.selectedRelationshipGoals),
      )) {
        return false;
      }
    }
    if (state.city != null && state.city!.trim().isNotEmpty) {
      if (!await _record(
        'location',
        _api.saveLocation(state.city!.trim(), state.preferredDistance),
      )) {
        return false;
      }
    }
    if (!await _syncProfileData(
      includeStarter: true,
      includeCompletion: true,
    )) {
      return false;
    }
    if (!await _syncPhotos()) return false;
    final result = await _api.complete();
    if (!result.success || result.data == null) {
      _logFailure('complete', result.message);
      return false;
    }
    _applyServerProfile(result.data!);
    await _persistSafely();
    notifyListeners();
    return true;
  }

  Future<bool> _syncProfileData({
    required bool includeStarter,
    required bool includeCompletion,
  }) async {
    final profile = LocalProfileRepository.instance.profile;
    if (includeStarter &&
        profile.profession.trim().isNotEmpty &&
        profile.education.trim().isNotEmpty) {
      if (!await _record(
        'starterProfile',
        _api.saveStarterProfile(
          profession: profile.profession.trim(),
          company: profile.company.trim(),
          education: profile.education.trim(),
        ),
      )) {
        return false;
      }
    }
    if (includeCompletion) {
      if (!await _record(
        'profileCompletion',
        _api.saveProfileCompletion(<String, dynamic>{
          'bio': profile.bio,
          'interests': profile.interests,
          'lifestyle': profile.lifestyle,
          'prompts': profile.prompts,
          'hometown': profile.hometown,
          'pronouns': profile.pronouns,
          'sexuality': profile.sexuality,
          'valuedQualities': profile.valuedQualities,
          'loveLanguages': profile.loveLanguages,
          'preferredTalkingHours': profile.preferredTalkingHours,
          'communicationStyle': profile.communicationStyle?.storageValue,
        }),
      )) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _syncPhotos() async {
    final profileRepository = LocalProfileRepository.instance;
    final photos = profileRepository.currentPhotos;
    if (photos.any(
      (photo) => photo.uploadState == ProfilePhotoUploadState.uploading,
    )) {
      _logFailure('photos', 'Wait for every photo upload to finish.');
      return false;
    }
    if (photos.any(
      (photo) => photo.isLocal && (photo.bytes == null || photo.bytes!.isEmpty),
    )) {
      _logFailure('photos', 'Upload every local photo before continuing.');
      return false;
    }
    final uploads = <OnboardingPhotoUpload>[
      for (final photo in photos)
        if (photo.isLocal && photo.bytes != null && photo.bytes!.isNotEmpty)
          OnboardingPhotoUpload(
            bytes: photo.bytes!,
            mimeType: photo.mimeType ?? 'image/jpeg',
            fileName: '${photo.id}.${_extensionForMimeType(photo.mimeType)}',
          ),
    ];
    if (uploads.isNotEmpty) {
      final result = await _api.uploadPhotos(uploads);
      if (!result.success || result.data == null) {
        _logFailure('photos', result.message);
        return false;
      }
      final serverPhotos = _strings(result.data!.values['photos']);
      if (serverPhotos.length != photos.length) {
        _logFailure('photos', 'The server returned an invalid photo set.');
        return false;
      }
      profileRepository.updatePhotosInSession(
        serverPhotos.map(_absolutePhotoUrl).toList(growable: false),
        result.data!.values['primaryPhotoIndex'] as int? ?? 0,
      );
    }
    final current = profileRepository.profile;
    if (current.photos.isNotEmpty) {
      if (!await _record(
        'primaryPhoto',
        _api.setPrimaryPhoto(current.primaryPhotoIndex),
      )) {
        return false;
      }
    }
    return true;
  }

  Future<bool> _record(
    String operation,
    Future<OnboardingApiResult<OnboardingRemoteProfile>> request,
  ) async {
    final result = await request;
    if (!result.success) {
      _logFailure(operation, result.message);
      return false;
    }
    return true;
  }

  void _applyServerProfile(OnboardingRemoteProfile remote) {
    final values = remote.values;
    final birthDate = values['birthDate'] is String
        ? DateTime.tryParse(values['birthDate'] as String)
        : null;
    final gender = values['gender'] as String?;
    final interestedIn = _strings(values['interestedIn']);
    final relationshipGoals = _strings(values['relationshipGoals']);
    final city = values['city'] as String?;
    final serverStage =
        OnboardingStage.values
            .where((stage) => stage.name == values['stage'])
            .firstOrNull ??
        OnboardingStage.age;
    _state = LocalOnboardingState(
      stage: serverStage,
      birthDate: birthDate,
      gender: gender?.isNotEmpty == true ? gender : null,
      customGender: values['customGender'] as String? ?? '',
      showGender: true,
      interestedIn: interestedIn.toSet(),
      relationshipGoals: relationshipGoals.toSet(),
      relationshipGoal: relationshipGoals.firstOrNull,
      city: city?.isNotEmpty == true ? city : null,
      preferredDistance:
          (values['preferredDistance'] as num?)?.toDouble() ?? 50,
      accountVerified: AuthService.instance.currentUser?.isVerified ?? false,
      onboardingCompleted: values['onboardingCompleted'] as bool? ?? false,
      profileCompleted:
          serverStage.index >= OnboardingStage.profileCompletion.index,
    );
    final profile = LocalProfileRepository.instance.profile;
    final photos = _strings(values['photos']);
    LocalProfileRepository.instance.updateInSession(
      profile.copyWith(
        birthdate: birthDate == null
            ? null
            : AmoraDateOfBirth.format(birthDate),
        gender: gender?.isNotEmpty == true
            ? ProfileFormOptions.storedGenderValue(
                gender,
                customValue: values['customGender'] as String? ?? '',
              )
            : null,
        customGender: values['customGender'] as String? ?? '',
        bio: values['bio'] as String? ?? '',
        profession: values['profession'] as String? ?? '',
        company: values['company'] as String? ?? '',
        education: values['education'] as String? ?? '',
        location: city ?? '',
        datingIntention: relationshipGoals.isEmpty
            ? ''
            : relationshipGoals.first,
        interests: _strings(values['interests']),
        prompts: _stringMap(values['prompts']),
        lifestyle: _stringMap(values['lifestyle']),
        photos: photos.map(_absolutePhotoUrl).toList(growable: false),
        primaryPhotoIndex:
            values['primaryPhotoIndex'] as int? ?? profile.primaryPhotoIndex,
        hometown: values['hometown'] as String? ?? profile.hometown,
        valuedQualities: _strings(values['valuedQualities']),
        pronouns: _strings(values['pronouns']),
        sexuality: values['sexuality'] as String? ?? '',
        preferredTalkingHours: _strings(values['preferredTalkingHours']),
        loveLanguages: _strings(values['loveLanguages']),
        communicationStyle: CommunicationStyle.fromStorageValue(
          values['communicationStyle'],
        ),
        clearCommunicationStyle: values['communicationStyle'] == null,
      ),
    );
  }

  List<String> _strings(Object? value) => (value as List? ?? const <Object?>[])
      .whereType<String>()
      .toList(growable: false);
  Map<String, String> _stringMap(Object? value) =>
      (value as Map? ?? const <Object?, Object?>{}).map(
        (key, item) => MapEntry(key.toString(), item.toString()),
      );
  String _absolutePhotoUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://')
      ? value
      : '${AmoraApiConfig.baseUrl}${value.startsWith('/') ? '' : '/'}$value';
  String _extensionForMimeType(String? mimeType) => switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    _ => 'jpg',
  };
  void _logFailure(String operation, String message) {
    _syncFailureCount++;
    developer.log(
      'Onboarding $operation sync failed: $message',
      name: 'AmoraOnboarding',
    );
    syncError.value = message;
  }

  void _syncUserProfile() {
    final repository = LocalProfileRepository.instance;
    final profile = repository.profile;
    final selectedGender = ProfileFormOptions.storedGenderValue(
      _state.gender,
      customValue: _state.customGender,
    );
    repository.updateInSession(
      profile.copyWith(
        birthdate: _state.birthDate == null
            ? null
            : AmoraDateOfBirth.format(_state.birthDate!),
        gender: selectedGender.isEmpty ? null : selectedGender,
        customGender: _state.customGender.trim(),
        location: _state.city?.trim().isEmpty ?? true
            ? null
            : _state.city!.trim(),
        datingIntention: _state.primaryRelationshipGoal?.trim().isEmpty ?? true
            ? null
            : _state.primaryRelationshipGoal!.trim(),
      ),
    );
  }
}
