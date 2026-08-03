import 'package:amora_ai/features/profile/domain/profile_form_options.dart';

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
        !_retiredTechnologyValues.contains(normalized) &&
        ProfileFormOptions.normalizeInterest(interest).isNotEmpty;
  }

  static List<String> visible(Iterable<String> interests) {
    final visible = <String>[];
    final seen = <String>{};
    for (final interest in interests) {
      final normalized = ProfileFormOptions.normalizeInterest(interest);
      if (isVisible(interest) && seen.add(normalized)) visible.add(normalized);
    }
    return visible;
  }

  static List<String> retired(Iterable<String> interests) => interests
      .where((interest) => !isVisible(interest) && interest.trim().isNotEmpty)
      .toList(growable: false);

  static int visibleCount(Iterable<String> interests) =>
      visible(interests).length;
}
