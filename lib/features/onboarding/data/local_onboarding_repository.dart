import 'dart:async';
import 'dart:convert';

import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/foundation.dart';
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

  LocalOnboardingState copyWith({
    OnboardingStage? stage,
    DateTime? birthDate,
    String? gender,
    String? customGender,
    bool? showGender,
    Set<String>? interestedIn,
    String? relationshipGoal,
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
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      city: city ?? this.city,
      preferredDistance: preferredDistance ?? this.preferredDistance,
      accountVerified: accountVerified ?? this.accountVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
    );
  }
}

/// Deterministic, device-session state for the frontend prototype.
///
/// No server verification, GPS, or identity claim is made here. The singleton
/// matches the project's existing local repository pattern and can later be
/// backed by production storage without changing presentation code.
class LocalOnboardingRepository extends ChangeNotifier {
  LocalOnboardingRepository._();

  static final instance = LocalOnboardingRepository._();
  static const demoVerificationCode = '246810';
  static const _storageKey = 'amora.onboarding_state.v1';

  LocalOnboardingState _state = const LocalOnboardingState();
  LocalOnboardingState get state => _state;

  Future<void> initialize() async {
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
        return;
      }
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return;
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
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
        relationshipGoal: json['relationshipGoal'] as String?,
        city: json['city'] as String?,
        preferredDistance:
            (json['preferredDistance'] as num?)?.toDouble() ?? 50,
        accountVerified: json['accountVerified'] as bool? ?? false,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
        profileCompleted: json['profileCompleted'] as bool? ?? false,
      );
      notifyListeners();
    } catch (_) {
      // Keep the last valid state if local storage is unavailable or invalid.
    }
  }

  void update(LocalOnboardingState state) {
    _state = state;
    _syncUserProfile();
    notifyListeners();
    unawaited(_persistSafely());
  }

  void hydrateFromUserProfile() {
    final profile = LocalProfileRepository.instance.profile;
    _state = _state.copyWith(
      birthDate: profile.dateOfBirth,
      gender: profile.gender.isEmpty ? null : profile.gender,
      city: profile.location.isEmpty ? null : profile.location,
      relationshipGoal: profile.datingIntention.isEmpty
          ? null
          : profile.datingIntention,
    );
    notifyListeners();
  }

  bool verifyCode(String code) {
    if (code != demoVerificationCode) return false;
    update(_state.copyWith(accountVerified: true, stage: OnboardingStage.age));
    return true;
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
    _state = const LocalOnboardingState();
    notifyListeners();
    unawaited(_persistSafely());
  }

  Future<void> clearForAccountDeletion() async {
    _state = const LocalOnboardingState();
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  @visibleForTesting
  void resetForTesting([LocalOnboardingState? state]) {
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

  void _syncUserProfile() {
    final repository = LocalProfileRepository.instance;
    final profile = repository.profile;
    final selectedGender = _state.gender == 'Self-describe'
        ? _state.customGender.trim()
        : _state.gender?.trim();
    repository.save(
      profile.copyWith(
        birthdate: _state.birthDate == null
            ? null
            : AmoraDateOfBirth.format(_state.birthDate!),
        gender: selectedGender == null || selectedGender.isEmpty
            ? null
            : selectedGender,
        location: _state.city?.trim().isEmpty ?? true
            ? null
            : _state.city!.trim(),
        datingIntention: _state.relationshipGoal?.trim().isEmpty ?? true
            ? null
            : _state.relationshipGoal!.trim(),
      ),
    );
  }
}
