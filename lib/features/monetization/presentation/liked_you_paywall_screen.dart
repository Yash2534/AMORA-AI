import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/premium_asset_image.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/monetization/data/monetization_repository.dart';
import 'package:amora_ai/features/monetization/domain/monetization_models.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_relationship_controller.dart';
import 'package:amora_ai/features/subscription/presentation/subscription_screen.dart';
import 'package:flutter/material.dart';

class LikedYouPaywallScreen extends StatefulWidget {
  const LikedYouPaywallScreen({super.key});

  static const routeName = '/liked-you-paywall';
  static const aliasRouteName = '/liked-you';

  @override
  State<LikedYouPaywallScreen> createState() => _LikedYouPaywallScreenState();
}

class _LikedYouPaywallScreenState extends State<LikedYouPaywallScreen> {
  final _relationships = ProfileRelationshipController.instance;
  MembershipState _membership = MembershipState.none;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _relationships.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _relationships.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _relationships.refreshReceivedLikes();
      final membership = await MonetizationRepository.instance
          .refreshMembership();
      if (!mounted) return;
      setState(() {
        _membership = membership;
        _error = _relationships.receivedLikesError;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load your received likes.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _relationships.receivedLikeProfiles;
    final total = _relationships.receivedLikesTotal;
    final unlocked = _membership.premium;
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'See Who Liked You',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: TextButton(
                    onPressed: _load,
                    child: Text(
                      '$_error\nTry again',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AmoraSpacing.space16,
                    AmoraSpacing.space20,
                    AmoraSpacing.space20,
                    AmoraSpacing.navigationContentInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PremiumCard(
                        color: AppColors.lavenderBackground,
                        child: Text(
                          total == 0
                              ? 'No one has liked your profile yet.'
                              : unlocked
                              ? '$total ${total == 1 ? 'person' : 'people'} liked you.'
                              : '$total ${total == 1 ? 'person' : 'people'} liked you. Unlock Gold to see every admirer.',
                          style: AmoraTextStyles.titleLarge.copyWith(
                            color: AppColors.deepWine,
                          ),
                        ),
                      ),
                      if (profiles.isNotEmpty) ...[
                        const SizedBox(height: AmoraSpacing.space16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: profiles.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: AmoraSpacing.space12,
                                mainAxisSpacing: AmoraSpacing.space12,
                                childAspectRatio: .78,
                              ),
                          itemBuilder: (context, index) {
                            final profile = profiles[index];
                            return _LockedProfileCard(
                              imageUrl: profile.imageUrl,
                              fallback: profile.fallbackAsset,
                              name: unlocked ? profile.name : 'Premium like',
                              locked: !unlocked,
                            );
                          },
                        ),
                      ],
                      if (total > 0 && !unlocked) ...[
                        const SizedBox(height: AmoraSpacing.space16),
                        AppPrimaryButton(
                          label: 'Unlock With Gold',
                          icon: Icons.workspace_premium_rounded,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(SubscriptionScreen.routeName),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _LockedProfileCard extends StatelessWidget {
  const _LockedProfileCard({
    required this.imageUrl,
    required this.fallback,
    required this.name,
    required this.locked,
  });

  final String imageUrl;
  final String fallback;
  final String name;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      radius: AmoraRadius.extraLarge,
      child: ClipRRect(
        borderRadius: AmoraRadius.card,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PremiumAssetImage(
              imageUrl: imageUrl,
              fallbackAsset: fallback,
              initials: 'AM',
              borderRadius: AmoraRadius.card,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .42),
              ),
            ),
            if (locked)
              Positioned(
                top: AmoraSpacing.space12,
                right: AmoraSpacing.space12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.deepWine,
                    borderRadius: AmoraRadius.pillBorder,
                    border: Border.all(color: AppColors.deepWine),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AmoraSpacing.space12,
                      vertical: AmoraSpacing.space8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.surface,
                          size: 15,
                        ),
                        const SizedBox(width: AmoraSpacing.space4),
                        Text(
                          'Gold',
                          style: AmoraTextStyles.labelMedium.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: AmoraSpacing.space12,
              right: AmoraSpacing.space12,
              bottom: AmoraSpacing.space12,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.titleMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
