/// Frontend visibility policy for interests retired from active AMORAA UI.
///
/// Retired values are deliberately retained in persisted profiles for backward
/// compatibility, but they never contribute to visible selections, validation,
/// or profile completion.
abstract final class ProfileInterestPolicy {
  static const Set<String> _retiredTechnologyValues = {
    'technology',
    'flutter',
    'startups',
    'product design',
    'gaming',
  };

  static bool isVisible(String interest) {
    final normalized = interest.trim().toLowerCase();
    return normalized.isNotEmpty &&
        !_retiredTechnologyValues.contains(normalized);
  }

  static List<String> visible(Iterable<String> interests) =>
      interests.where(isVisible).toList(growable: false);

  static List<String> retired(Iterable<String> interests) => interests
      .where((interest) => !isVisible(interest) && interest.trim().isNotEmpty)
      .toList(growable: false);

  static int visibleCount(Iterable<String> interests) =>
      interests.where(isVisible).length;
}
