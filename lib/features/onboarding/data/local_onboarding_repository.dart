import 'package:flutter/foundation.dart';

enum OnboardingStage {
  verification,
  age,
  gender,
  interestedIn,
  relationshipGoal,
  location,
  starterProfile,
  profileCompletion,
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

  LocalOnboardingState _state = const LocalOnboardingState();
  LocalOnboardingState get state => _state;

  void update(LocalOnboardingState state) {
    _state = state;
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
  }

  @visibleForTesting
  void resetForTesting([LocalOnboardingState? state]) {
    _state = state ?? const LocalOnboardingState();
    notifyListeners();
  }
}
