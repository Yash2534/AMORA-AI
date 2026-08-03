import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/subscription/domain/amoraa_membership_status.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:flutter/material.dart';

class ProfilePreviewScreen extends StatefulWidget {
  const ProfilePreviewScreen({super.key});

  static const routeName = '/profile-preview';

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final _repository = LocalProfileRepository.instance;

  @override
  void initState() {
    super.initState();
    _repository.addListener(_refresh);
    AmoraaMembershipStatus.listenable.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    AmoraaMembershipStatus.listenable.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final publicProfile = AmoraaPublicProfileData.fromProfile(
      _repository.profile,
      _repository.currentPhotos,
      isAadhaarVerified: false,
      isPremium: AmoraaMembershipStatus.isPremiumActive,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile Preview'),
        leading: IconButton(
          tooltip: 'Back',
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
                sliver: SliverList.list(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'See how your profile appears to others.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.text.withValues(alpha: .68),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AmoraaPublicProfileDetails(profile: publicProfile),
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
                  ).pushReplacementNamed(ProfileEditScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  label: 'Return to Discover',
                  onPressed: () =>
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        DiscoverScreen.routeName,
                        (route) => false,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
