import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class LivenessCheckScreen extends StatelessWidget {
  const LivenessCheckScreen({super.key});

  static const routeName = '/liveness-check';

  @override
  Widget build(BuildContext context) {
    return const _RoadmapPremiumScreen(
      title: 'Liveness Check',
      subtitle: 'Selfie verification with clear identity signals.',
      icon: Icons.face_retouching_natural_rounded,
    );
  }
}

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  static const routeName = '/stories';

  @override
  Widget build(BuildContext context) {
    return const _RoadmapPremiumScreen(
      title: 'Stories and Success',
      subtitle: 'Premium member moments and social proof.',
      icon: Icons.auto_stories_rounded,
    );
  }
}

class TwentyQuestionsScreen extends StatelessWidget {
  const TwentyQuestionsScreen({super.key});

  static const routeName = '/twenty-questions';

  @override
  Widget build(BuildContext context) {
    return const _RoadmapPremiumScreen(
      title: '20 Questions',
      subtitle: 'Intent-led prompts for better compatibility.',
      icon: Icons.quiz_rounded,
    );
  }
}

class TrustedContactsScreen extends StatelessWidget {
  const TrustedContactsScreen({super.key});

  static const routeName = '/trusted-contacts';

  @override
  Widget build(BuildContext context) {
    return const _RoadmapPremiumScreen(
      title: 'Trusted Contacts',
      subtitle: 'Share safer dating plans with people you trust.',
      icon: Icons.contact_phone_rounded,
    );
  }
}

class VideoSpeedDatingRoomScreen extends StatelessWidget {
  const VideoSpeedDatingRoomScreen({super.key});

  static const routeName = '/video-speed-dating-room';

  @override
  Widget build(BuildContext context) {
    return const _RoadmapPremiumScreen(
      title: 'Video Speed Dating',
      subtitle: 'A polished preview for moderated video introductions.',
      icon: Icons.video_camera_front_rounded,
    );
  }
}

class PollPromptsScreen extends StatelessWidget {
  const PollPromptsScreen({super.key});

  static const routeName = '/poll-prompts';

  @override
  Widget build(BuildContext context) {
    return const _RoadmapPremiumScreen(
      title: 'Poll Prompts',
      subtitle: 'Lightweight prompts that make profiles easier to answer.',
      icon: Icons.poll_rounded,
    );
  }
}

class _RoadmapPremiumScreen extends StatelessWidget {
  const _RoadmapPremiumScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: title,
        subtitle: subtitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumCard(
                  radius: 28,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(icon, color: AppColors.surface, size: 28),
                      ),
                      const SizedBox(height: 18),
                      AppPrimaryButton(
                        label: 'Continue',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
