import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/profile/data/public_profile_mapper.dart';
import 'package:flutter/foundation.dart';

enum ProfileReactionType { like, superLike }

/// Canonical relationship state loaded from the authenticated backend.
abstract interface class ProfileRelationshipRemoteDataSource {
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}

class AuthProfileRelationshipRemoteDataSource
    implements ProfileRelationshipRemoteDataSource {
  const AuthProfileRelationshipRemoteDataSource();

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) => AuthService.instance.authenticatedRequest(method, path, body: body);
}

class ProfileRelationshipController extends ChangeNotifier {
  factory ProfileRelationshipController({
    ProfileRelationshipRemoteDataSource? remote,
    bool allowRemoteWithoutSession = true,
  }) => ProfileRelationshipController._(remote, allowRemoteWithoutSession);

  ProfileRelationshipController._(
    this._remote,
    this._allowRemoteWithoutSession,
  );

  static final ProfileRelationshipController instance =
      ProfileRelationshipController(
        remote: const AuthProfileRelationshipRemoteDataSource(),
        allowRemoteWithoutSession: false,
      );

  final ProfileRelationshipRemoteDataSource? _remote;
  final bool _allowRemoteWithoutSession;
  bool get _canUseRemote =>
      _remote != null &&
      (_allowRemoteWithoutSession || AuthService.instance.currentUser != null);

  final Map<String, DummyProfile> _profilesById = <String, DummyProfile>{};
  final List<String> _savedProfileIds = <String>[];
  final List<String> _blockedProfileIds = <String>[];
  final List<String> _likedProfileIds = <String>[];
  final List<String> _superLikedProfileIds = <String>[];
  final List<String> _receivedLikeProfileIds = <String>[];
  int receivedLikesTotal = 0;
  bool receivedLikesLoading = false;
  String? receivedLikesError;
  bool loading = false;
  bool _savedLoadingMore = false;
  bool _likesLoadingMore = false;
  bool _superLikesLoadingMore = false;
  int _savedNextPage = 1;
  int _likesNextPage = 1;
  int _superLikesNextPage = 1;
  bool _savedHasMore = false;
  bool _likesHasMore = false;
  bool _superLikesHasMore = false;
  String? error;

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      ((response['data'] as Map?) ?? const <String, dynamic>{})
          .cast<String, dynamic>();

  Future<void> refreshRemote() async {
    if (!_canUseRemote || loading) {
      return;
    }
    final remote = _remote!;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait(<Future<Map<String, dynamic>>>[
        remote.request('GET', '/api/me/saved-profiles?page=1&limit=20'),
        remote.request('GET', '/api/me/likes?page=1&limit=20'),
        remote.request('GET', '/api/me/super-likes?page=1&limit=20'),
      ]);
      _replaceProfiles(_savedProfileIds, _profiles(results[0]));
      _replaceProfiles(_likedProfileIds, _profiles(results[1]));
      _replaceProfiles(_superLikedProfileIds, _profiles(results[2]));
      final savedPage = _nextPage(results[0]);
      final likesPage = _nextPage(results[1]);
      final superLikesPage = _nextPage(results[2]);
      _savedNextPage = savedPage.$1;
      _savedHasMore = savedPage.$2;
      _likesNextPage = likesPage.$1;
      _likesHasMore = likesPage.$2;
      _superLikesNextPage = superLikesPage.$1;
      _superLikesHasMore = superLikesPage.$2;
    } on AuthException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not load saved profiles and reactions.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReceivedLikes() async {
    if (!_canUseRemote || receivedLikesLoading) return;
    receivedLikesLoading = true;
    receivedLikesError = null;
    notifyListeners();
    try {
      final response = await _remote!.request(
        'GET',
        '/api/me/received-likes?page=1&limit=30',
      );
      _replaceProfiles(_receivedLikeProfileIds, _profiles(response));
      final total = _data(response)['total'];
      receivedLikesTotal = total is num
          ? total.toInt()
          : _receivedLikeProfileIds.length;
    } on AuthException catch (exception) {
      receivedLikesError = exception.message;
    } catch (_) {
      receivedLikesError = 'Could not load received likes.';
    } finally {
      receivedLikesLoading = false;
      notifyListeners();
    }
  }

  List<DummyProfile> _profiles(Map<String, dynamic> response) =>
      ((_data(response)['profiles'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (value) =>
                publicProfileFromJson(value.cast<String, dynamic>()).profile,
          )
          .toList(growable: false);

  (int, bool) _nextPage(Map<String, dynamic> response) {
    final values = _data(response)['pagination'];
    final pagination = values is Map
        ? values.cast<String, dynamic>()
        : const <String, dynamic>{};
    final hasMore = pagination['hasMore'] == true;
    return ((pagination['nextPage'] as num?)?.toInt() ?? 1, hasMore);
  }

  void _replaceProfiles(List<String> ids, List<DummyProfile> profiles) {
    ids
      ..clear()
      ..addAll(profiles.map((profile) => profile.id));
    for (final profile in profiles) {
      _profilesById[profile.id] = profile;
    }
  }

  void _appendProfiles(List<String> ids, List<DummyProfile> profiles) {
    for (final profile in profiles) {
      _profilesById[profile.id] = profile;
      if (!ids.contains(profile.id)) ids.add(profile.id);
    }
  }

  bool get savedHasMore => _savedHasMore;
  bool get savedLoadingMore => _savedLoadingMore;
  bool reactionHasMore(ProfileReactionType type) =>
      type == ProfileReactionType.like ? _likesHasMore : _superLikesHasMore;
  bool reactionLoadingMore(ProfileReactionType type) =>
      type == ProfileReactionType.like
      ? _likesLoadingMore
      : _superLikesLoadingMore;

  Future<void> loadMoreSaved() async {
    if (!_canUseRemote || !_savedHasMore || _savedLoadingMore) return;
    _savedLoadingMore = true;
    error = null;
    notifyListeners();
    try {
      final response = await _remote!.request(
        'GET',
        '/api/me/saved-profiles?page=$_savedNextPage&limit=20',
      );
      _appendProfiles(_savedProfileIds, _profiles(response));
      final nextPage = _nextPage(response);
      _savedNextPage = nextPage.$1;
      _savedHasMore = nextPage.$2;
    } on AuthException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not load more saved profiles.';
    } finally {
      _savedLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreReactions(ProfileReactionType type) async {
    final hasMore = reactionHasMore(type);
    final loadingMore = reactionLoadingMore(type);
    if (!_canUseRemote || !hasMore || loadingMore) return;
    if (type == ProfileReactionType.like) {
      _likesLoadingMore = true;
    } else {
      _superLikesLoadingMore = true;
    }
    error = null;
    notifyListeners();
    try {
      final page = type == ProfileReactionType.like
          ? _likesNextPage
          : _superLikesNextPage;
      final segment = type == ProfileReactionType.like
          ? 'likes'
          : 'super-likes';
      final response = await _remote!.request(
        'GET',
        '/api/me/$segment?page=$page&limit=20',
      );
      if (type == ProfileReactionType.like) {
        _appendProfiles(_likedProfileIds, _profiles(response));
        final nextPage = _nextPage(response);
        _likesNextPage = nextPage.$1;
        _likesHasMore = nextPage.$2;
      } else {
        _appendProfiles(_superLikedProfileIds, _profiles(response));
        final nextPage = _nextPage(response);
        _superLikesNextPage = nextPage.$1;
        _superLikesHasMore = nextPage.$2;
      }
    } on AuthException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not load more reactions.';
    } finally {
      if (type == ProfileReactionType.like) {
        _likesLoadingMore = false;
      } else {
        _superLikesLoadingMore = false;
      }
      notifyListeners();
    }
  }

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

  List<DummyProfile> get receivedLikeProfiles =>
      _resolved(_receivedLikeProfileIds);

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

  Future<void> likeProfilePersisted(DummyProfile profile) async {
    if (_canUseRemote) {
      await _remote!.request(
        'POST',
        '/api/discover/swipe',
        body: {'targetUserId': int.parse(profile.id), 'action': 'like'},
      );
    }
    likeProfile(profile);
  }

  void removeLike(String profileId) {
    if (!_likedProfileIds.remove(profileId)) return;
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  Future<void> removeLikePersisted(String profileId) async {
    if (_canUseRemote) {
      await _remote!.request('DELETE', '/api/reactions/$profileId');
    }
    removeLike(profileId);
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

  Future<void> removeSuperLikePersisted(String profileId) async {
    if (_canUseRemote) {
      await _remote!.request('DELETE', '/api/reactions/$profileId');
    }
    removeSuperLike(profileId);
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

  Future<void> saveProfilePersisted(DummyProfile profile) async {
    if (_canUseRemote) {
      await _remote!.request('PUT', '/api/me/saved-profiles/${profile.id}');
    }
    saveProfile(profile);
  }

  void removeSaved(String profileId) {
    if (!_savedProfileIds.remove(profileId)) return;
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  Future<void> removeSavedPersisted(String profileId) async {
    if (_canUseRemote) {
      await _remote!.request('DELETE', '/api/me/saved-profiles/$profileId');
    }
    removeSaved(profileId);
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
  void clear() => clearSessionState();

  void clearSessionState() {
    if (_profilesById.isEmpty &&
        _savedProfileIds.isEmpty &&
        _blockedProfileIds.isEmpty &&
        _likedProfileIds.isEmpty &&
        _superLikedProfileIds.isEmpty &&
        _receivedLikeProfileIds.isEmpty) {
      return;
    }
    _profilesById.clear();
    _savedProfileIds.clear();
    _blockedProfileIds.clear();
    _likedProfileIds.clear();
    _superLikedProfileIds.clear();
    _receivedLikeProfileIds.clear();
    receivedLikesTotal = 0;
    receivedLikesLoading = false;
    receivedLikesError = null;
    _savedNextPage = 1;
    _likesNextPage = 1;
    _superLikesNextPage = 1;
    _savedHasMore = false;
    _likesHasMore = false;
    _superLikesHasMore = false;
    _savedLoadingMore = false;
    _likesLoadingMore = false;
    _superLikesLoadingMore = false;
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
        !_superLikedProfileIds.contains(profileId) &&
        !_receivedLikeProfileIds.contains(profileId)) {
      _profilesById.remove(profileId);
    }
  }
}
