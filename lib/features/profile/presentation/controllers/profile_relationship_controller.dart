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

class _PendingReactionMutation {
  const _PendingReactionMutation({required this.liked, required this.future});

  final bool liked;
  final Future<void> future;
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
  final Map<String, int> _savedRevisions = <String, int>{};
  final Map<String, int> _likedRevisions = <String, int>{};
  final Map<String, int> _superLikedRevisions = <String, int>{};
  final Map<String, _PendingReactionMutation> _reactionMutations =
      <String, _PendingReactionMutation>{};
  int _relationshipRevision = 0;
  int _sessionEpoch = 0;
  int _refreshRequestId = 0;
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
    final startedAtRevision = _relationshipRevision;
    final sessionEpoch = _sessionEpoch;
    final requestId = ++_refreshRequestId;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait(<Future<Map<String, dynamic>>>[
        remote.request('GET', '/api/me/saved-profiles?page=1&limit=20'),
        remote.request('GET', '/api/me/likes?page=1&limit=20'),
        remote.request('GET', '/api/me/super-likes?page=1&limit=20'),
      ]);
      if (sessionEpoch != _sessionEpoch || requestId != _refreshRequestId) {
        return;
      }
      _replaceProfilesPreservingNewerMutations(
        _savedProfileIds,
        _profiles(results[0]),
        _savedRevisions,
        startedAtRevision,
      );
      _replaceProfilesPreservingNewerMutations(
        _likedProfileIds,
        _profiles(results[1]),
        _likedRevisions,
        startedAtRevision,
      );
      _replaceProfilesPreservingNewerMutations(
        _superLikedProfileIds,
        _profiles(results[2]),
        _superLikedRevisions,
        startedAtRevision,
      );
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
      if (sessionEpoch == _sessionEpoch && requestId == _refreshRequestId) {
        loading = false;
        notifyListeners();
      }
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

  void _replaceProfilesPreservingNewerMutations(
    List<String> ids,
    List<DummyProfile> profiles,
    Map<String, int> revisions,
    int startedAtRevision,
  ) {
    final changedIds = revisions.entries
        .where((entry) => entry.value > startedAtRevision)
        .map((entry) => entry.key)
        .toSet();
    final locallyPresentChangedIds = ids
        .where(changedIds.contains)
        .toList(growable: false);
    final remoteProfiles = profiles
        .where((profile) => !changedIds.contains(profile.id))
        .toList(growable: false);
    ids
      ..clear()
      ..addAll(remoteProfiles.map((profile) => profile.id))
      ..addAll(locallyPresentChangedIds);
    for (final profile in remoteProfiles) {
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

  bool isReactionMutating(String profileId) =>
      _reactionMutations.containsKey(profileId);

  int relationshipRevisionFor(String profileId) => <int>[
    _savedRevisions[profileId] ?? 0,
    _likedRevisions[profileId] ?? 0,
    _superLikedRevisions[profileId] ?? 0,
  ].reduce((left, right) => left > right ? left : right);

  void applyAuthoritativeRelationship(
    DummyProfile profile,
    PublicRelationshipState relationship, {
    int? unlessChangedSince,
  }) {
    if (unlessChangedSince != null &&
        relationshipRevisionFor(profile.id) != unlessChangedSince) {
      _profilesById[profile.id] = profile;
      return;
    }
    _profilesById[profile.id] = profile;
    _setMembership(
      _savedProfileIds,
      _savedRevisions,
      profile.id,
      relationship.saved,
    );
    _setMembership(
      _likedProfileIds,
      _likedRevisions,
      profile.id,
      relationship.liked,
    );
    _setMembership(
      _superLikedProfileIds,
      _superLikedRevisions,
      profile.id,
      relationship.superLiked,
    );
    notifyListeners();
  }

  void toggleLiked(DummyProfile profile) {
    if (isLiked(profile.id)) {
      removeLike(profile.id);
    } else {
      likeProfile(profile);
    }
  }

  void likeProfile(DummyProfile profile) {
    _profilesById[profile.id] = profile;
    _setMembership(_likedProfileIds, _likedRevisions, profile.id, true);
    notifyListeners();
  }

  Future<void> likeProfilePersisted(DummyProfile profile) {
    if (isLiked(profile.id) && !isReactionMutating(profile.id)) {
      return Future<void>.value();
    }
    return _serializeReactionMutation(profile.id, true, () async {
      final sessionEpoch = _sessionEpoch;
      if (_canUseRemote) {
        final response = await _remote!.request(
          'POST',
          '/api/discover/swipe',
          body: {'targetUserId': int.parse(profile.id), 'action': 'like'},
        );
        final data = _data(response);
        final likeStatus = data['likeStatus']?.toString();
        if (data['liked'] != true &&
            likeStatus != 'liked' &&
            likeStatus != 'already_liked') {
          throw StateError('Like response did not confirm persisted state.');
        }
      }
      if (sessionEpoch == _sessionEpoch) likeProfile(profile);
    });
  }

  void removeLike(String profileId) {
    _setMembership(_likedProfileIds, _likedRevisions, profileId, false);
    _removeUnreferencedProfile(profileId);
    notifyListeners();
  }

  Future<void> removeLikePersisted(String profileId) =>
      _serializeReactionMutation(profileId, false, () async {
        final sessionEpoch = _sessionEpoch;
        if (_canUseRemote) {
          final response = await _remote!.request(
            'DELETE',
            '/api/reactions/$profileId',
          );
          if (_data(response)['liked'] != false) {
            throw StateError(
              'Unlike response did not confirm persisted state.',
            );
          }
        }
        if (sessionEpoch == _sessionEpoch) removeLike(profileId);
      });

  Future<void> _serializeReactionMutation(
    String profileId,
    bool liked,
    Future<void> Function() mutation,
  ) {
    final existing = _reactionMutations[profileId];
    if (existing != null && existing.liked == liked) return existing.future;
    late final Future<void> operation;
    operation =
        (() async {
          if (existing != null) {
            try {
              await existing.future;
            } catch (_) {
              // A later explicit mutation still runs after a failed request.
            }
          }
          await mutation();
        })().whenComplete(() {
          if (identical(_reactionMutations[profileId]?.future, operation)) {
            _reactionMutations.remove(profileId);
            notifyListeners();
          }
        });
    _reactionMutations[profileId] = _PendingReactionMutation(
      liked: liked,
      future: operation,
    );
    notifyListeners();
    return operation;
  }

  void _setMembership(
    List<String> ids,
    Map<String, int> revisions,
    String profileId,
    bool present,
  ) {
    _relationshipRevision++;
    revisions[profileId] = _relationshipRevision;
    if (present) {
      if (!ids.contains(profileId)) ids.add(profileId);
    } else {
      ids.remove(profileId);
    }
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
    _sessionEpoch++;
    _refreshRequestId++;
    loading = false;
    error = null;
    _profilesById.clear();
    _savedProfileIds.clear();
    _blockedProfileIds.clear();
    _likedProfileIds.clear();
    _superLikedProfileIds.clear();
    _receivedLikeProfileIds.clear();
    _savedRevisions.clear();
    _likedRevisions.clear();
    _superLikedRevisions.clear();
    _reactionMutations.clear();
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
