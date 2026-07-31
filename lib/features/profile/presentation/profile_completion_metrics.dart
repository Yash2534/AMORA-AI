import 'package:amora_ai/features/profile/data/local_profile_repository.dart';

/// Presentation-only completion rules for the v1.0 profile experience.
///
/// Keeping these metrics outside the repository preserves the existing local
/// persistence and domain rules while allowing the UI to reflect AMORAA's
/// one-prompt requirement and the new completion fields.
extension ProfileCompletionMetrics on UserProfile {
  int get presentationCompletionPercent {
    var percentage = 0;
    if (photos.length >= 2) percentage += 20;
    if (basicDetailsComplete) percentage += 15;
    if (bio.trim().length >= 40) percentage += 15;
    if (interests.length >= 5) percentage += 15;
    if (completedPromptCount >= 1) percentage += 15;
    if (lifestyle.entries.any(
      (entry) => !const {'Height', 'Languages', 'Religion'}.contains(entry.key),
    )) {
      percentage += 5;
    }
    if ((lifestyle['Height'] ?? '').trim().isNotEmpty) percentage += 5;
    if ((lifestyle['Languages'] ?? '').trim().isNotEmpty) percentage += 5;
    if ((lifestyle['Religion'] ?? '').trim().isNotEmpty) percentage += 5;
    return percentage;
  }
}
