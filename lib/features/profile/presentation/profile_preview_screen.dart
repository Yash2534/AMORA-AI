import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/features/subscription/domain/amoraa_membership_status.dart';
import 'package:amora_ai/features/discover/presentation/discover_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/profile_detail_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_edit_screen.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_details.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_public_profile_view.dart';
import 'package:flutter/material.dart';

class ProfilePreviewScreen extends StatefulWidget {
  const ProfilePreviewScreen({super.key});

  static const routeName = '/profile-preview';

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  final _repository = LocalProfileRepository.instance;
  final _galleryController = PageController();
  int _photoIndex = 0;

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
    _galleryController.dispose();
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
    final displayProfile = publicProfile.toPublicDisplayProfile();
    final photos = publicProfile.orderedPhotos;
    if (_photoIndex >= photos.length) _photoIndex = 0;
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
        child: AmoraaPublicProfileView(
          mode: PublicProfileViewMode.preview,
          scrollKey: const Key('profile-preview-scroll'),
          galleryBuilder: (context, height, desktop) => ProfileMediaGallery(
            key: const ValueKey('profile-media-gallery'),
            height: height,
            profile: displayProfile,
            photos: photos,
            controller: _galleryController,
            selectedIndex: _photoIndex,
            mode: PublicProfileViewMode.preview,
            saved: false,
            onPageChanged: (index) => setState(() => _photoIndex = index),
            onBack: () {},
            onSave: () {},
            onMore: () {},
            onOpen: (index) =>
                _openFullScreenGallery(displayProfile, photos, index),
            onDoubleTap: null,
          ),
          story: ProfileStory(
            profile: displayProfile,
            mode: PublicProfileViewMode.preview,
            blocked: false,
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

  void _openFullScreenGallery(
    DummyProfile profile,
    List<ProfilePhotoViewData> photos,
    int initialIndex,
  ) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AmoraaProfileFullscreenGallery(
          profile: profile,
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}
