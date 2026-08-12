import 'package:flutter/foundation.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';

enum DiscoverAction { pass, like, superLike, rewind }

class DiscoverHistoryEntry {
  const DiscoverHistoryEntry({
    required this.profileId,
    required this.imageIndex,
    required this.action,
  });

  final String profileId;
  final int imageIndex;
  final DiscoverAction action;
}

/// Backend-synchronized state for the Discover deck.
///
/// Buttons and swipe gestures call the same persisted API operations. Local
/// state advances only after the backend accepts an action.
class DiscoverActionController extends ChangeNotifier {
  DiscoverActionController({
    required Iterable<String> profileIds,
    Iterable<String> mutualLikeProfileIds = const <String>[],
    DiscoverApiService? apiService,
    this.transitionDuration = const Duration(milliseconds: 240),
  }) : _deck = List<String>.of(profileIds),
       _apiService = apiService ?? DiscoverApiService();

  final Duration transitionDuration;
  final DiscoverApiService _apiService;
  final List<String> _deck;
  final List<DiscoverHistoryEntry> _history = [];
  final Map<String, int> _imageIndices = {};
  final Set<String> likedProfileIds = {};
  final Set<String> passedProfileIds = {};
  final Set<String> superLikedProfileIds = {};

  bool _isTransitioning = false;
  DiscoverAction? _activeAction;
  String? _matchedProfileId;
  String? _lastError;
  String? _matchId;
  Map<String, dynamic>? _matchedProfile;

  bool get isTransitioning => _isTransitioning;
  bool get isEmpty => _deck.isEmpty;
  bool get canRewind => _history.isNotEmpty && !_isTransitioning;
  DiscoverAction? get activeAction => _activeAction;
  String? get currentProfileId => _deck.firstOrNull;
  String? get matchedProfileId => _matchedProfileId;
  String? get matchId => _matchId;
  Map<String, dynamic>? get matchedProfile => _matchedProfile;
  String? get lastError => _lastError;
  List<String> get remainingProfileIds => List.unmodifiable(_deck);
  List<DiscoverHistoryEntry> get history => List.unmodifiable(_history);

  int imageIndexFor(String profileId) => _imageIndices[profileId] ?? 0;

  void setImageIndex(String profileId, int index) {
    _imageIndices[profileId] = index;
  }

  void appendProfileIds(Iterable<String> profileIds) {
    for (final profileId in profileIds) {
      if (!_deck.contains(profileId) &&
          !_history.any((entry) => entry.profileId == profileId)) {
        _deck.add(profileId);
      }
    }
    notifyListeners();
  }

  Future<bool> passProfile() => _advance(DiscoverAction.pass);

  Future<bool> rejectProfile() => _advance(DiscoverAction.pass);

  Future<bool> likeProfile() => _advance(DiscoverAction.like);

  Future<bool> superLikeProfile() => _advance(DiscoverAction.superLike);

  Future<bool> rewindProfile() async {
    if (!canRewind) return false;
    _isTransitioning = true;
    _activeAction = DiscoverAction.rewind;
    notifyListeners();
    await Future<void>.delayed(transitionDuration);
    final result = await _apiService.rewind();
    if (!result.success) {
      _activeAction = null;
      _isTransitioning = false;
      _lastError = result.message;
      notifyListeners();
      return false;
    }
    final entry = _history.removeLast();
    _deck.insert(0, entry.profileId);
    _imageIndices[entry.profileId] = entry.imageIndex;
    passedProfileIds.remove(entry.profileId);
    likedProfileIds.remove(entry.profileId);
    superLikedProfileIds.remove(entry.profileId);
    _activeAction = null;
    _isTransitioning = false;
    notifyListeners();
    return true;
  }

  void consumeMatch() {
    if (_matchedProfileId == null) return;
    _matchedProfileId = null;
    _matchId = null;
    _matchedProfile = null;
    notifyListeners();
  }

  Future<bool> _advance(DiscoverAction action) async {
    final profileId = currentProfileId;
    if (_isTransitioning || profileId == null) return false;
    _isTransitioning = true;
    _activeAction = action;
    notifyListeners();
    await Future<void>.delayed(transitionDuration);

    final result = await _apiService.swipe(
      targetUserId: profileId,
      action: switch (action) {
        DiscoverAction.pass => 'pass',
        DiscoverAction.like => 'like',
        DiscoverAction.superLike => 'superLike',
        _ => 'pass',
      },
    );
    if (!result.success) {
      _activeAction = null;
      _isTransitioning = false;
      _lastError = result.message;
      notifyListeners();
      return false;
    }

    _history.add(
      DiscoverHistoryEntry(
        profileId: profileId,
        imageIndex: imageIndexFor(profileId),
        action: action,
      ),
    );
    _deck.removeAt(0);
    switch (action) {
      case DiscoverAction.pass:
        passedProfileIds.add(profileId);
        break;
      case DiscoverAction.like:
        likedProfileIds.add(profileId);
        break;
      case DiscoverAction.superLike:
        superLikedProfileIds.add(profileId);
        break;
      case DiscoverAction.rewind:
        break;
    }
    _activeAction = null;
    _isTransitioning = false;
    notifyListeners();
    if (result.data!.matched) {
      _matchedProfileId = profileId;
      _matchId = result.data!.matchId;
      _matchedProfile = result.data!.matchedProfile;
      notifyListeners();
    }
    return true;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
