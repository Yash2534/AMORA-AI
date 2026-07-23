import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/material.dart';

/// Compatibility route alias for the single canonical Discover experience.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  static const routeName = '/discover';

  @override
  Widget build(BuildContext context) => const BrowseGridScreen();
}
<<<<<<< HEAD
=======

class _DiscoverScreenState extends State<DiscoverScreen>
    with TickerProviderStateMixin {
  late final AnimationController _gridController;
  double _distance = 300;
  String _intent = 'Long-Term Relationship';
  String _lifestyle = 'Coffee Dates';

  @override
  void initState() {
    super.initState();
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.lightPinkBackground,
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 380
                    ? AmoraSpacing.x4
                    : AmoraSpacing.x6;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        AmoraSpacing.x5,
                        horizontalPadding,
                        FloatingBottomNav.contentBottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _DiscoverHeader(),
                          const SizedBox(height: AmoraSpacing.x5),
                          const SearchFilterBar(),
                          const SizedBox(height: AmoraSpacing.x4),
                          FilterChipRow(
                            intent: _intent,
                            lifestyle: _lifestyle,
                            onIntentChanged: (value) {
                              setState(() => _intent = value);
                            },
                            onLifestyleChanged: (value) {
                              setState(() => _lifestyle = value);
                            },
                          ),
                          const SizedBox(height: AmoraSpacing.x3),
                          DistanceSliderSection(
                            value: _distance,
                            onChanged: (value) {
                              setState(() => _distance = value);
                            },
                          ),
                          const SizedBox(height: AmoraSpacing.x5),
                          _AnimatedProfileGrid(
                            controller: _gridController,
                            profiles: _discoverProfiles,
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: const Padding(
                        padding: EdgeInsets.fromLTRB(AmoraSpacing.x4, 0, 16, 0),
                        child: FloatingBottomNav(
                          activeTab: AmoraNavTab.discover,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepWine.withValues(alpha: .06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: AmoraSpacing.space16),
            const Icon(
              Icons.search_rounded,
              size: 22,
              color: AppColors.textGray,
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Text(
                'Search names, cities, interests',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textGray,
                ),
              ),
            ),
            const SizedBox(width: AmoraSpacing.space12),
            const Icon(Icons.tune_rounded, size: 22, color: AppColors.deepWine),
            const SizedBox(width: AmoraSpacing.space16),
          ],
        ),
      ),
    );
  }
}

class FilterChipRow extends StatelessWidget {
  const FilterChipRow({
    super.key,
    required this.intent,
    required this.lifestyle,
    required this.onIntentChanged,
    required this.onLifestyleChanged,
  });

  final String intent;
  final String lifestyle;
  final ValueChanged<String> onIntentChanged;
  final ValueChanged<String> onLifestyleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _SoftFilterChip(icon: Icons.verified_outlined, label: 'Verified'),
            _SoftFilterChip(leadingDot: true, label: 'Online now'),
            _SoftFilterChip(icon: Icons.filter_alt_outlined, label: 'Nearby'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in relationshipIntentions.take(3))
              IntentChip(
                label: option,
                selected: intent == option,
                onTap: () => onIntentChanged(option),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in lifestyleInterests.take(4))
              LifestyleChip(
                label: option,
                selected: lifestyle == option,
                onTap: () => onLifestyleChanged(option),
              ),
          ],
        ),
      ],
    );
  }
}

class DistanceSliderSection extends StatelessWidget {
  const DistanceSliderSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Distance',
          maxLines: 1,
          style: AmoraTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppColors.primaryPurple,
              inactiveTrackColor: AppColors.borderGray,
              thumbColor: AppColors.primaryPurple,
              overlayColor: AppColors.primaryPurple.withValues(alpha: .12),
            ),
            child: Slider(
              value: value,
              min: 25,
              max: 300,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 56,
          child: Text(
            '${value.round()} km',
            maxLines: 1,
            textAlign: TextAlign.right,
            style: AmoraTextStyles.labelLarge.copyWith(
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileGridCard extends StatelessWidget {
  const ProfileGridCard({super.key, required this.profile});

  final DiscoverProfile profile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepWine.withValues(alpha: .12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _GridImage(imageUrl: profile.imageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.transparent,
                    AppColors.transparent,
                    AppColors.text,
                  ],
                  stops: [0, .48, 1],
                ),
              ),
            ),
            Positioned(
              top: 9,
              left: 8,
              child: _CompactMatchBadge(percent: profile.matchPercent),
            ),
            if (profile.isOnline)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${profile.name} ${profile.age}',
                            maxLines: 1,
                            style: AmoraTextStyles.titleMedium.copyWith(
                              color: AppColors.surface,
                              shadows: [
                                Shadow(
                                  color: AppColors.text,
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_outlined,
                        color: AppColors.softPink,
                        size: 15,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.city} - ${profile.distance}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: AppColors.surface,
                      shadows: [Shadow(color: AppColors.text, blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Discover',
            maxLines: 1,
            style: AmoraTextStyles.headlineLarge.copyWith(
              color: AppColors.deepWine,
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Text(
          'Search verified people by intent, values, and lifestyle.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
        ),
      ],
    );
  }
}

class _AnimatedProfileGrid extends StatelessWidget {
  const _AnimatedProfileGrid({
    required this.controller,
    required this.profiles,
  });

  final AnimationController controller;
  final List<DiscoverProfile> profiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final cardWidth = (constraints.maxWidth - spacing) / 2;
        final cardHeight = cardWidth.clamp(160.0, 216.0) * 1.34;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < profiles.length; index++)
              _FadeInGridItem(
                controller: controller,
                index: index,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(ProfileDetailScreen.routeName),
                    child: ProfileGridCard(profile: profiles[index]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FadeInGridItem extends StatelessWidget {
  const _FadeInGridItem({
    required this.controller,
    required this.index,
    required this.child,
  });

  final AnimationController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index * .055).clamp(0.0, .58);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _SoftFilterChip extends StatelessWidget {
  const _SoftFilterChip({
    required this.label,
    this.icon,
    this.leadingDot = false,
  });

  final String label;
  final IconData? icon;
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    return AmoraFilterChip(
      label: label,
      selected: leadingDot,
      icon: leadingDot ? Icons.circle_rounded : icon,
      onSelected: (_) {},
    );
  }
}

class _CompactMatchBadge extends StatelessWidget {
  const _CompactMatchBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: AmoraRadius.pillBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.deepWine.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.surface,
              size: 12,
            ),
            const SizedBox(width: 3),
            Text(
              '$percent%',
              maxLines: 1,
              style: AmoraTextStyles.labelMedium.copyWith(
                color: AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridImage extends StatelessWidget {
  const _GridImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AmoraProfileImage(
      imageUrl: imageUrl,
      assetPath: AppImages.profileAadhya,
      initials: 'AM',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }
}

class DiscoverProfile {
  const DiscoverProfile({
    required this.name,
    required this.age,
    required this.city,
    required this.distance,
    required this.matchPercent,
    required this.imageUrl,
    this.isOnline = true,
  });

  final String name;
  final int age;
  final String city;
  final String distance;
  final int matchPercent;
  final String imageUrl;
  final bool isOnline;
}

final _discoverProfiles = [
  DiscoverProfile(
    name: 'Kavya',
    age: 24,
    city: 'Ahmedabad',
    distance: '3 km',
    matchPercent: 96,
    imageUrl: AppImages.profileKavya,
  ),
  DiscoverProfile(
    name: 'Aarav',
    age: 27,
    city: 'Ahmedabad',
    distance: '5 km',
    matchPercent: 94,
    imageUrl: AppImages.profileAarav,
  ),
  DiscoverProfile(
    name: 'Aadhya',
    age: 23,
    city: 'Gandhinagar',
    distance: '18 km',
    matchPercent: 92,
    imageUrl: AppImages.profileAadhya,
  ),
  DiscoverProfile(
    name: 'Dhruv',
    age: 29,
    city: 'Vadodara',
    distance: '110 km',
    matchPercent: 89,
    imageUrl: AppImages.profileAt(2, male: true),
  ),
  DiscoverProfile(
    name: 'Riya',
    age: 25,
    city: 'Ahmedabad',
    distance: '7 km',
    matchPercent: 91,
    imageUrl: AppImages.profileRiya,
  ),
  DiscoverProfile(
    name: 'Arjun',
    age: 26,
    city: 'Surat',
    distance: '265 km',
    matchPercent: 87,
    imageUrl: AppImages.profileAt(3, male: true),
  ),
  DiscoverProfile(
    name: 'Ananya',
    age: 28,
    city: 'Ahmedabad',
    distance: '4 km',
    matchPercent: 93,
    imageUrl: AppImages.profileAnanya,
  ),
  DiscoverProfile(
    name: 'Yash',
    age: 28,
    city: 'Rajkot',
    distance: '215 km',
    matchPercent: 90,
    imageUrl: AppImages.profileYash,
  ),
];
>>>>>>> main
