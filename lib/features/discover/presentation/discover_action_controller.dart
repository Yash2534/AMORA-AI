import 'package:flutter/foundation.dart';

enum DiscoverAction { pass, like, superLike, rewind, boost }

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

/// Deterministic, frontend-only state for the Discover deck.
///
/// Buttons and swipe gestures call the same methods. The controller owns tap
/// guarding, stable profile IDs, rewind history, per-profile image position,
/// and local liked/passed/super-liked state.
class DiscoverActionController extends ChangeNotifier {
  DiscoverActionController({
    required Iterable<String> profileIds,
    Iterable<String> mutualLikeProfileIds = const <String>[],
    this.transitionDuration = const Duration(milliseconds: 240),
  }) : _deck = List<String>.of(profileIds),
       _mutualLikeProfileIds = Set<String>.of(mutualLikeProfileIds);

  final Duration transitionDuration;
  final Set<String> _mutualLikeProfileIds;
  final List<String> _deck;
  final List<DiscoverHistoryEntry> _history = [];
  final Map<String, int> _imageIndices = {};
  final Set<String> likedProfileIds = {};
  final Set<String> passedProfileIds = {};
  final Set<String> superLikedProfileIds = {};

  bool _isTransitioning = false;
  bool _boostRequested = false;
  DiscoverAction? _activeAction;
  String? _matchedProfileId;

  bool get isTransitioning => _isTransitioning;
  bool get isEmpty => _deck.isEmpty;
  bool get canRewind => _history.isNotEmpty && !_isTransitioning;
  bool get boostRequested => _boostRequested;
  DiscoverAction? get activeAction => _activeAction;
  String? get currentProfileId => _deck.firstOrNull;
  String? get matchedProfileId => _matchedProfileId;
  List<String> get remainingProfileIds => List.unmodifiable(_deck);
  List<DiscoverHistoryEntry> get history => List.unmodifiable(_history);

  int imageIndexFor(String profileId) => _imageIndices[profileId] ?? 0;

  void setImageIndex(String profileId, int index) {
    _imageIndices[profileId] = index;
  }

  Future<void> passProfile() => _advance(DiscoverAction.pass);

  Future<void> rejectProfile() => _advance(DiscoverAction.pass);

  Future<void> likeProfile() => _advance(DiscoverAction.like);

  Future<void> superLikeProfile() => _advance(DiscoverAction.superLike);

  Future<void> rewindProfile() async {
    if (!canRewind) return;
    _isTransitioning = true;
    _activeAction = DiscoverAction.rewind;
    notifyListeners();
    await Future<void>.delayed(transitionDuration);
    final entry = _history.removeLast();
    _deck.insert(0, entry.profileId);
    _imageIndices[entry.profileId] = entry.imageIndex;
    passedProfileIds.remove(entry.profileId);
    likedProfileIds.remove(entry.profileId);
    superLikedProfileIds.remove(entry.profileId);
    _activeAction = null;
    _isTransitioning = false;
    notifyListeners();
  }

  Future<void> boostProfile() async {
    if (_isTransitioning) return;
    _activeAction = DiscoverAction.boost;
    _boostRequested = true;
    notifyListeners();
  }

  void consumeBoostRequest() {
    if (!_boostRequested) return;
    _boostRequested = false;
    _activeAction = null;
    notifyListeners();
  }

  void consumeMatch() {
    if (_matchedProfileId == null) return;
    _matchedProfileId = null;
    notifyListeners();
  }

  Future<void> _advance(DiscoverAction action) async {
    final profileId = currentProfileId;
    if (_isTransitioning || profileId == null) return;
    _isTransitioning = true;
    _activeAction = action;
    notifyListeners();
    await Future<void>.delayed(transitionDuration);

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
        if (_mutualLikeProfileIds.contains(profileId)) {
          _matchedProfileId = profileId;
        }
        break;
      case DiscoverAction.superLike:
        superLikedProfileIds.add(profileId);
        break;
      case DiscoverAction.rewind:
      case DiscoverAction.boost:
        break;
    }
    _activeAction = null;
    _isTransitioning = false;
    notifyListeners();
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
