import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_search_bar.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/widgets/premium_editorial_panel.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/admin_shared/presentation/admin_dashboard_widgets.dart';
import 'package:flutter/material.dart';

class DateSpotsMapScreen extends StatefulWidget {
  const DateSpotsMapScreen({super.key});

  static const routeName = '/date-spots';

  @override
  State<DateSpotsMapScreen> createState() => _DateSpotsMapScreenState();
}

class _DateSpotsMapScreenState extends State<DateSpotsMapScreen> {
  final _searchController = TextEditingController();
  final Set<String> _saved = {};
  var _city = 'Ahmedabad';
  var _category = 'Coffee';
  var _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots
        .where(
          (spot) =>
              spot.city == _city &&
              spot.categories.contains(_category) &&
              (_query.isEmpty ||
                  spot.name.toLowerCase().contains(_query.toLowerCase())),
        )
        .toList();
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Date Spots',
        subtitle: 'Curated venues for intentional first dates.',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.surface],
          ),
        ),
        child: SafeArea(
          top: false,
          child: ResponsiveMobileFrame(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space16,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumEditorialPanel(
                    title: 'Rooftop, coffee, or quiet gallery?',
                    subtitle:
                        'AMORAA ranks venues by comfort, safety, conversation quality, and date intent.',
                    badge: 'AI Venue Match',
                    cta: 'Explore',
                    assetPath: ImageRepository.venues.first.imageUrl,
                    icon: Icons.location_on_rounded,
                    aspectRatio: 1.56,
                    onTap: () => showDashboardSnack(
                      context,
                      'Venue recommendations refreshed',
                    ),
                  ),
                  const SizedBox(height: 18),
                  AmoraSearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    hintText: 'Search cafes, restaurants, venues...',
                  ),
                  const SizedBox(height: 14),
                  AmoraaCompactSelect<String>(
                    key: const ValueKey('date-spots-city-selector'),
                    label: 'City',
                    value: _city,
                    prefixIcon: Icons.location_city_rounded,
                    options: [
                      for (final city in _cities)
                        AmoraaSelectOption(value: city, label: city),
                    ],
                    onChanged: (city) {
                      if (city != null) setState(() => _city = city);
                    },
                  ),
                  const SizedBox(height: 10),
                  AmoraaCompactSelect<String>(
                    key: const ValueKey('date-spots-category-selector'),
                    label: 'Venue category',
                    value: _category,
                    prefixIcon: Icons.category_outlined,
                    options: [
                      for (final category in _categories)
                        AmoraaSelectOption(value: category, label: category),
                    ],
                    onChanged: (category) {
                      if (category != null) {
                        setState(() => _category = category);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  const VenueMapPreviewCard(),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse the curated venue list below. Map view is currently unavailable.',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionLabel('Venue list'),
                  const SizedBox(height: 12),
                  for (final spot in spots)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DateSpotCard(
                        name: spot.name,
                        rating: spot.rating,
                        distance: spot.distance,
                        price: spot.price,
                        bestFor: spot.bestFor,
                        score: spot.score,
                        packagePrice: spot.packagePrice,
                        saved: _saved.contains(spot.name),
                        onDetails: () => showDashboardSnack(
                          context,
                          '${spot.name} details opened',
                        ),
                        onBuy: () => _showPackageDialog(spot),
                        onSave: () {
                          setState(() {
                            if (_saved.contains(spot.name)) {
                              _saved.remove(spot.name);
                            } else {
                              _saved.add(spot.name);
                            }
                          });
                          showDashboardSnack(
                            context,
                            _saved.contains(spot.name)
                                ? '${spot.name} saved'
                                : '${spot.name} removed',
                          );
                        },
                      ),
                    ),
                  if (spots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No venues found for this filter.'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPackageDialog(_Spot spot) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: const Icon(Icons.favorite_rounded, color: AppColors.primaryRose),
        title: const Text('Date Package Booked'),
        content: Text(
          '${spot.name} package ${spot.packagePrice} reserved for you.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _Spot {
  const _Spot({
    required this.name,
    required this.city,
    required this.categories,
    required this.rating,
    required this.distance,
    required this.price,
    required this.bestFor,
    required this.score,
    required this.packagePrice,
  });

  final String name;
  final String city;
  final List<String> categories;
  final String rating;
  final String distance;
  final String price;
  final String bestFor;
  final int score;
  final String packagePrice;
}

const _cities = ProfileFormOptions.cities;
const _categories = [
  'Coffee',
  'Rooftop',
  'Fine Dining',
  'Budget',
  'Quiet',
  'Live Music',
  'Couple Friendly',
];

final _spots = ImageRepository.venues
    .asMap()
    .entries
    .map((entry) => _spotFromVenue(entry.key, entry.value))
    .toList(growable: false);

_Spot _spotFromVenue(int index, VenueImageData venue) {
  return _Spot(
    name: venue.name,
    city: venue.city,
    categories: [
      venue.category,
      if (index.isEven) 'Couple Friendly' else 'Quiet',
      if (index % 3 == 0) 'Coffee' else 'Fine Dining',
    ],
    rating: (4.3 + ((index % 6) * .1)).toStringAsFixed(1),
    distance: '${(index % 9) + 1}.${index % 10} km',
    price: 'Rs ${700 + (index * 110)} for two',
    bestFor: venue.category,
    score: 84 + (index * 2) % 14,
    packagePrice: 'Rs ${599 + (index * 75)} package',
  );
}
