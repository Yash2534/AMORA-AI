import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_screen.dart';
import 'package:flutter/material.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({super.key});
  static const routeName = '/profile-preview';

  @override
  Widget build(BuildContext context) {
    final profile = LocalProfileRepository.instance.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile preview'),
        leading: IconButton(
          tooltip: 'Return to profile completion',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: CustomScrollView(
            key: const Key('profile-preview-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 180),
                sliver: SliverList.list(
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 5,
                      child: PremiumAssetImage(
                        imageUrl: profile.primaryPhoto,
                        fallbackAsset: profile.primaryPhoto,
                        initials: profile.name.isEmpty
                            ? 'AM'
                            : profile.name.substring(0, 1),
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      profile.age == null
                          ? profile.name
                          : '${profile.name}, ${profile.age}',
                      style: AmoraTextStyles.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.location} • ${profile.datingIntention}',
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PreviewSection(
                      title: 'About me',
                      child: Text(profile.bio),
                    ),
                    _PreviewSection(
                      title: 'Interests',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final interest in profile.interests)
                            Chip(label: Text(interest)),
                        ],
                      ),
                    ),
                    for (final prompt in profile.prompts.entries)
                      if (prompt.value.trim().isNotEmpty)
                        _PreviewSection(
                          title: prompt.key,
                          child: Text(
                            prompt.value,
                            style: AmoraTextStyles.titleMedium,
                          ),
                        ),
                    for (var index = 0; index < profile.photos.length; index++)
                      if (index != profile.primaryPhotoIndex) ...[
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: PremiumAssetImage(
                            imageUrl: profile.photos[index],
                            fallbackAsset: profile.photos[index],
                            initials: 'AM',
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    if (profile.lifestyle.isNotEmpty)
                      _PreviewSection(
                        title: 'Lifestyle',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in profile.lifestyle.entries)
                              Chip(label: Text('${entry.key}: ${entry.value}')),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppPrimaryButton(
                  label: 'Edit profile',
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: () => Navigator.of(
                    context,
                  ).pushReplacementNamed(ProfileCompletionScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Return to Discover',
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    if (navigator.canPop()) {
                      navigator.pop();
                    } else {
                      navigator.pushNamedAndRemoveUntil(
                        MainShell.routeName,
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AmoraTextStyles.titleLarge),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
