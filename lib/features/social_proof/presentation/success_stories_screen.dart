import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  static const routeName = '/success-stories';

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Success Stories',
                        style: TextStyle(
                          color: AppColors.deepWine,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_loading)
                  const PremiumCard(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (final story in _stories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StoryCard(story: story),
                    ),
                const SizedBox(height: 6),
                AppPrimaryButton(
                  label: 'Share Your Story',
                  icon: Icons.favorite_rounded,
                  onPressed: () => _showShareSheet(context),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _loading = true);
                    await Future<void>.delayed(
                      const Duration(milliseconds: 500),
                    );
                    if (mounted) setState(() => _loading = false);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Show loading placeholder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AppPrimaryButton(
            label: 'Story submitted locally',
            icon: Icons.send_rounded,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story});
  final (String, String, String, String) story;
  @override
  Widget build(BuildContext context) {
    final image = ImageRepository.profileByName(story.$1);
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumAssetImage(
                imageUrl: image.imageUrl,
                fallbackAsset: image.fallbackAsset,
                initials: image.initials,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.$2,
                      style: const TextStyle(
                        color: AppColors.deepWine,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      story.$3,
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            story.$4,
            style: const TextStyle(
              color: AppColors.textGray,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

const _stories = [
  (
    'Aadhya',
    'Aadhya & Aarav',
    'Ahmedabad',
    'Coffee turned into a calm year of shared routines and family-first clarity.',
  ),
  (
    'Kavya',
    'Kavya & Dev',
    'Vadodara',
    'They met at an AMORA event and kept choosing thoughtful conversations.',
  ),
  (
    'Riya',
    'Riya & Neil',
    'Surat',
    'Verified intent, honest chats, and a rooftop date made the difference.',
  ),
];
