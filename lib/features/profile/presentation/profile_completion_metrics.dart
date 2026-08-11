import 'package:amora_ai/features/profile/data/local_profile_repository.dart';

/// Presentation-only completion rules for the v1.0 profile experience.
///
/// Authenticated profiles use the completion value returned by the backend.
/// Guest/form-only profiles retain the shared calculator as a draft preview.
extension ProfileCompletionMetrics on UserProfile {
  int get presentationCompletionPercent => completionPercent;
}
