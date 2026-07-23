enum ProfileStudioTool {
  bioWriter,
  profileReview,
  smartPhotoSelection,
  bestPhotoRecommendation,
  completenessScore,
}

class ProfileStudioPreview {
  const ProfileStudioPreview({
    required this.title,
    required this.summary,
    required this.items,
  });

  final String title;
  final String summary;
  final List<String> items;
}

abstract interface class ProfileStudioService {
  Future<ProfileStudioPreview> preview(ProfileStudioTool tool);
}

class MockProfileStudioService implements ProfileStudioService {
  const MockProfileStudioService();

  @override
  Future<ProfileStudioPreview> preview(ProfileStudioTool tool) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return switch (tool) {
      ProfileStudioTool.bioWriter => const ProfileStudioPreview(
        title: 'AI Bio Writer preview',
        summary: 'A deterministic local rewrite based on the current draft.',
        items: [
          'Flutter engineer who enjoys intentional conversations, calm coffee dates, and exploring Ahmedabad one thoughtful plan at a time.',
        ],
      ),
      ProfileStudioTool.profileReview => const ProfileStudioPreview(
        title: 'Profile Review preview',
        summary: 'Local review only; no profile data was uploaded.',
        items: [
          'Lead with a warm, centered photo.',
          'Make one prompt easier to answer.',
          'Mention a specific first-date idea.',
        ],
      ),
      ProfileStudioTool.smartPhotoSelection => const ProfileStudioPreview(
        title: 'Smart Photo Selection preview',
        summary: 'Demo ranking based on fixed local clarity labels.',
        items: ['Photo 1: strongest lead', 'Photo 3: best lifestyle signal'],
      ),
      ProfileStudioTool.bestPhotoRecommendation => const ProfileStudioPreview(
        title: 'Best Photo Recommendation preview',
        summary: 'Local recommendation; no face recognition was performed.',
        items: ['Use Photo 1 as primary', 'Keep Photo 2 as a supporting shot'],
      ),
      ProfileStudioTool.completenessScore => const ProfileStudioPreview(
        title: 'Completeness Score preview',
        summary: 'Calculated locally from filled profile sections.',
        items: ['Add one more prompt', 'Confirm the current video prompt'],
      ),
    };
  }
}
