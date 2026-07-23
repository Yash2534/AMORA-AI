class VoicePromptPreview {
  const VoicePromptPreview({required this.duration, required this.label});

  final Duration duration;
  final String label;
}

abstract interface class PromptMediaService {
  Future<VoicePromptPreview?> loadVoicePrompt(String? localReference);
  List<String> availableVideoPreviews();
}

class LocalPromptMediaService implements PromptMediaService {
  const LocalPromptMediaService();

  @override
  Future<VoicePromptPreview?> loadVoicePrompt(String? localReference) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (localReference == null) return null;
    return const VoicePromptPreview(
      duration: Duration(seconds: 18),
      label: 'My ideal Sunday',
    );
  }

  @override
  List<String> availableVideoPreviews() => const [
    'local://video/profile-intro',
    'local://video/coffee-story',
    'local://video/weekend-plan',
  ];
}
