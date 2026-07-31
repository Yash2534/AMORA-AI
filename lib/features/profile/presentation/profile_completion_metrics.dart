import 'package:amora_ai/features/profile/data/local_profile_repository.dart';

/// Presentation-only completion rules for the v1.0 profile experience.
///
/// Keeping these metrics outside the repository preserves the existing local
/// persistence and domain rules while allowing the UI to reflect AMORAA's
/// one-prompt requirement and the new completion fields.
extension ProfileCompletionMetrics on UserProfile {
  int get presentationCompletionPercent => completionResult.percentage;
}
