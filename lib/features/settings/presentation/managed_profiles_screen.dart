import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:flutter/material.dart';

class SavedProfilesScreen extends StatelessWidget {
  const SavedProfilesScreen({super.key});

  static const routeName = '/saved-profiles';

  @override
  Widget build(BuildContext context) {
    return ManagedProfilesScreen(
      title: 'Saved Profiles',
      subtitle: 'People you saved to revisit thoughtfully.',
      icon: Icons.bookmark_rounded,
      profiles: ImageRepository.profiles.take(4).toList(growable: false),
      emptyTitle: 'No saved profiles yet',
      emptyMessage:
          'Use the bookmark action on a profile to keep it available here.',
    );
  }
}

class BlockedProfilesScreen extends StatelessWidget {
  const BlockedProfilesScreen({super.key});

  static const routeName = '/blocked-profiles';

  @override
  Widget build(BuildContext context) {
    return const ManagedProfilesScreen(
      title: 'Blocked Profiles',
      subtitle: 'Private controls for profiles you chose not to see.',
      icon: Icons.block_rounded,
      profiles: [],
      emptyTitle: 'Your blocked list is clear',
      emptyMessage:
          'Profiles you block will appear here with an option to review them.',
    );
  }
}

class ManagedProfilesScreen extends StatelessWidget {
  const ManagedProfilesScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.profiles,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<DummyProfile> profiles;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: profiles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AmoraSpacing.space24),
                    child: PremiumCard(
                      radius: AmoraRadius.extraLarge,
                      padding: const EdgeInsets.all(AmoraSpacing.space24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.tertiary,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              icon,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: AmoraSpacing.space16),
                          Text(
                            emptyTitle,
                            textAlign: TextAlign.center,
                            style: AmoraTextStyles.titleLarge,
                          ),
                          const SizedBox(height: AmoraSpacing.space8),
                          Text(
                            emptyMessage,
                            textAlign: TextAlign.center,
                            style: AmoraTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AmoraSpacing.space20,
                    AmoraSpacing.space16,
                    AmoraSpacing.space20,
                    AmoraSpacing.space32,
                  ),
                  children: [
                    Text(title, style: AmoraTextStyles.headlineLarge),
                    const SizedBox(height: AmoraSpacing.space8),
                    Text(
                      subtitle,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AmoraSpacing.space20),
                    for (final profile in profiles) ...[
                      PremiumCard(
                        padding: EdgeInsets.zero,
                        child: InkWell(
                          borderRadius: AmoraRadius.card,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ProfileDetailScreen(profile: profile),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AmoraSpacing.space12),
                            child: Row(
                              children: [
                                AmoraProfileImage(
                                  imageUrl: profile.imageUrl,
                                  assetPath: profile.fallbackAsset,
                                  initials: profile.initials,
                                  width: 64,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                const SizedBox(width: AmoraSpacing.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${profile.name}, ${profile.age}',
                                        style: AmoraTextStyles.titleMedium,
                                      ),
                                      const SizedBox(
                                        height: AmoraSpacing.space4,
                                      ),
                                      Text(
                                        '${profile.profession} · ${profile.city}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AmoraTextStyles.bodySmall
                                            .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
