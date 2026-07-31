abstract interface class PromptMediaService {
  List<String> availableVideoPreviews();
}

class LocalPromptMediaService implements PromptMediaService {
  const LocalPromptMediaService();

  @override
  List<String> availableVideoPreviews() => const [
    'local://video/profile-intro',
    'local://video/coffee-story',
    'local://video/weekend-plan',
  ];
}
