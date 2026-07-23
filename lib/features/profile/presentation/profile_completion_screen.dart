import 'package:amora_ai/core/navigation/main_shell.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/bio_builder_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_basic_details_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_section_editor_screen.dart';
import 'package:flutter/material.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  static const routeName = '/profile-completion';

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _repository = LocalProfileRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 720,
          child: CustomScrollView(
            key: const Key('profile-completion-hub'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back to Discover',
                          onPressed: _returnToDiscover,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complete your profile',
                            style: AmoraTextStyles.headlineLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A thoughtful profile gives people something real to connect with.',
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    PremiumCard(
                      child: Row(
                        children: [
                          PremiumAssetImage(
                            imageUrl: profile.primaryPhoto,
                            fallbackAsset: profile.primaryPhoto,
                            initials: profile.name.isEmpty
                                ? 'AM'
                                : profile.name.substring(0, 1),
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name,
                                  style: AmoraTextStyles.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: profile.completionPercent / 100,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                const SizedBox(height: 6),
                                Text('${profile.completionPercent}% complete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Required', style: AmoraTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    _SectionTile(
                      icon: Icons.photo_library_rounded,
                      title: 'Photos',
                      description: '${profile.photos.length} of 2 minimum',
                      complete: profile.photos.length >= 2,
                      onTap: () => _openNamed(PhotoManagerScreen.routeName),
                    ),
                    _SectionTile(
                      icon: Icons.badge_rounded,
                      title: 'Basic details',
                      description: 'Name, work, education and city',
                      complete: profile.basicDetailsComplete,
                      onTap: () =>
                          _openNamed(ProfileBasicDetailsScreen.routeName),
                    ),
                    _SectionTile(
                      icon: Icons.notes_rounded,
                      title: 'Bio',
                      description: 'Tell your story in a few warm lines',
                      complete: profile.bio.trim().length >= 40,
                      onTap: () => _openNamed(BioBuilderScreen.routeName),
                    ),
                    _SectionTile(
                      icon: Icons.interests_rounded,
                      title: 'Interests',
                      description: '${profile.interests.length} of 5 minimum',
                      complete: profile.interests.length >= 5,
                      onTap: () => _openSection(ProfileSection.interests),
                    ),
                    _SectionTile(
                      icon: Icons.chat_rounded,
                      title: 'Prompts',
                      description:
                          '${profile.completedPromptCount} of 3 minimum',
                      complete: profile.completedPromptCount >= 3,
                      onTap: () => _openSection(ProfileSection.prompts),
                    ),
                    const SizedBox(height: 20),
                    Text('Optional', style: AmoraTextStyles.titleLarge),
                    const SizedBox(height: 12),
                    _SectionTile(
                      icon: Icons.self_improvement_rounded,
                      title: 'Lifestyle',
                      description: 'Share habits only when you want to',
                      optional: true,
                      complete: profile.lifestyle.isNotEmpty,
                      onTap: () => _openSection(ProfileSection.lifestyle),
                    ),
                    const SizedBox(height: 20),
                    AppPrimaryButton(
                      label: 'Preview profile',
                      icon: Icons.visibility_rounded,
                      variant: AppPrimaryButtonVariant.outlined,
                      onPressed: () =>
                          _openNamed(ProfilePreviewScreen.routeName),
                    ),
                    const SizedBox(height: 12),
                    AppPrimaryButton(
                      key: const Key('start-discovering-button'),
                      label: 'Return to Discover',
                      icon: Icons.explore_rounded,
                      onPressed: _returnToDiscover,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openNamed(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) setState(() {});
  }

  Future<void> _openSection(ProfileSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSectionEditorScreen(section: section),
      ),
    );
    if (mounted) setState(() {});
  }

  void _returnToDiscover() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushNamedAndRemoveUntil(MainShell.routeName, (route) => false);
    }
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.complete,
    required this.onTap,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool complete;
  final bool optional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: Semantics(
          button: true,
          label:
              'Open profile section $title, ${complete
                  ? 'complete'
                  : optional
                  ? 'optional'
                  : 'needs attention'}',
          child: ListTile(
            minTileHeight: 80,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.activeContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            title: Text(title, style: AmoraTextStyles.titleMedium),
            subtitle: Text(
              '${optional ? 'Optional' : 'Required'} · $description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  complete
                      ? Icons.check_circle_rounded
                      : optional
                      ? Icons.remove_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: complete
                      ? AppColors.success
                      : optional
                      ? AppColors.textMuted
                      : AppColors.secondary,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
