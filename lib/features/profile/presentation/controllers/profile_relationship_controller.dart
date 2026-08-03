import 'package:amora_ai/core/data/image_repository.dart';
import 'package:flutter/foundation.dart';

enum ProfileReactionType { like, superLike }

/// Session-scoped state for profile actions that do not yet have a backend
/// persistence contract.
///
/// Entries are captured from the real profile the user acted on. The
/// controller intentionally starts empty and never seeds any relationship list
/// with repository samples.
class ProfileRelationshipController extends ChangeNotifier {
  ProfileRelationshipController();

  static final ProfileRelationshipController instance =
      ProfileRelationshipController();

  final Map<String, DummyProfile> _profilesById = <String, DummyProfile>{};
  final List<String> _savedProfileIds = <String>[];
  final List<String> _blockedProfileIds = <String>[];
  final List<String> _likedProfileIds = <String>[];
  final List<String> _superLikedProfileIds = <String>[];

  List<String> get savedProfileIds =>
      List<String>.unmodifiable(_savedProfileIds);

  List<String> get blockedProfileIds =>
      List<String>.unmodifiable(_blockedProfileIds);

  List<String> get likedProfileIds =>
      List<String>.unmodifiable(_likedProfileIds);

  List<String> get superLikedProfileIds =>
      List<String>.unmodifiable(_superLikedProfileIds);

  List<DummyProfile> get savedProfiles => _resolved(_savedProfileIds);

  List<DummyProfile> get blockedProfiles => _resolved(_blockedProfileIds);

  List<DummyProfile> get likedProfiles => _resolved(_likedProfileIds);

  List<DummyProfile> get superLikedProfiles => _resolved(_superLikedProfileIds);

  bool isSaved(String profileId) => _savedProfileIds.contains(profileId);

  bool isBlocked(String profileId) => _blockedProfileIds.contains(profileId);

  bool isLiked(String profileId) => _likedProfileIds.contains(profileId);

  bool isSuperLiked(String profileId) =>
      _superLikedProfileIds.contains(profileId);

  void toggleLiked(DummyProfile profile) {
    if (isLiked(profile.id)) {
      removeLike(profile.id);
    } else {
      likeProfile(profile);
    }
  }

  void likeProfile(DummyProfile profile) {
    _profilesById[profile.id] = profile;
    if (_likedProfileIds.contains(profile.id)) return;
    _likedProfileIds.add(profile.id);
    notifyListeners();
  }

  void removeLike(String profileId) {
    if (!_likedProfileIds.remove(profileId)) return;
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  void superLikeProfile(DummyProfile profile) {
    _profilesById[profile.id] = profile;
    if (_superLikedProfileIds.contains(profile.id)) return;
    _superLikedProfileIds.add(profile.id);
    notifyListeners();
  }

  void removeSuperLike(String profileId) {
    if (!_superLikedProfileIds.remove(profileId)) return;
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  void toggleSaved(DummyProfile profile) {
    if (isSaved(profile.id)) {
      removeSaved(profile.id);
    } else {
      saveProfile(profile);
    }
  }

  void saveProfile(DummyProfile profile) {
    _profilesById[profile.id] = profile;
    if (_savedProfileIds.contains(profile.id)) return;
    _savedProfileIds.add(profile.id);
    notifyListeners();
  }

  void removeSaved(String profileId) {
    if (!_savedProfileIds.remove(profileId)) return;
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  void blockProfile(DummyProfile profile) {
    _profilesById[profile.id] = profile;
    if (_blockedProfileIds.contains(profile.id)) return;
    _blockedProfileIds.add(profile.id);
    notifyListeners();
  }

  void unblockProfile(String profileId) {
    if (!_blockedProfileIds.remove(profileId)) return;
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  @visibleForTesting
  void clear() {
    if (_profilesById.isEmpty &&
        _savedProfileIds.isEmpty &&
        _blockedProfileIds.isEmpty &&
        _likedProfileIds.isEmpty &&
        _superLikedProfileIds.isEmpty) {
      return;
    }
    _profilesById.clear();
    _savedProfileIds.clear();
    _blockedProfileIds.clear();
    _likedProfileIds.clear();
    _superLikedProfileIds.clear();
    notifyListeners();
  }

  List<DummyProfile> _resolved(List<String> ids) =>
      List<DummyProfile>.unmodifiable(
        ids.map((id) => _profilesById[id]).whereType<DummyProfile>(),
      );

  void _removeUnreferencedProfile(String profileId) {
    if (!_savedProfileIds.contains(profileId) &&
        !_blockedProfileIds.contains(profileId) &&
        !_likedProfileIds.contains(profileId) &&
        !_superLikedProfileIds.contains(profileId)) {
      _profilesById.remove(profileId);
    }
  }
}
