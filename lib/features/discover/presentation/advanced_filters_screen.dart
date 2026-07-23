import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_text_action.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/intent_chip.dart';
import 'package:amora_ai/core/widgets/lifestyle_chip.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:flutter/material.dart';

class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key});

  static const routeName = '/filters';

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  RangeValues _age = const RangeValues(24, 34);
  double _distance = 80;
  double _score = 80;
  final Set<String> _cities = {'Ahmedabad'};
  final Set<String> _intents = {'Long-Term Relationship'};
  final Set<String> _lifestyles = {'Coffee Dates'};
  final Set<String> _education = {};
  final Set<String> _profession = {};
  final Set<String> _community = {'Open to all'};
  final Set<String> _religion = {};
  final Set<String> _languages = {'Gujarati'};
  final Set<String> _height = {};
  final Set<String> _travel = {};
  final Set<String> _fitness = {};
  final Set<String> _coffee = {};
  final Set<String> _movies = {};
  String _smoking = 'Any';
  String _drinking = 'Any';
  String _pets = 'Any';
  String _children = 'Any';
  bool _verifiedOnly = true;
  bool _onlineNow = false;
  bool _hasPrompts = true;
  bool _eventInterest = false;

  int get _selectedCount =>
      _cities.length +
      _intents.length +
      _lifestyles.length +
      _education.length +
      _profession.length +
      _community.length +
      _religion.length +
      _languages.length +
      _height.length +
      _travel.length +
      _fitness.length +
      _coffee.length +
      _movies.length +
      [
        _verifiedOnly,
        _onlineNow,
        _hasPrompts,
        _eventInterest,
      ].where((value) => value).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth < 380
                  ? AmoraSpacing.space16
                  : AmoraSpacing.space24;
              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      AmoraSpacing.space16,
                      padding,
                      AmoraSpacing.navigationContentInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FilterHeader(
                          onBack: () => Navigator.of(context).maybePop(),
                          onReset: _reset,
                        ),
                        const SizedBox(height: AmoraSpacing.space20),
                        PremiumCard(
                          color: AppColors.activeContainer,
                          child: Text(
                            '$_selectedCount filters selected. AI will prioritize profiles matching your preferences.',
                            style: AmoraTextStyles.bodyMedium.copyWith(
                              color: AppColors.deepWine,
                            ),
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space20),
                        _RangeSection(
                          title: 'Age range',
                          value: '${_age.start.round()}-${_age.end.round()}',
                          child: RangeSlider(
                            values: _age,
                            min: 18,
                            max: 45,
                            activeColor: AppColors.primaryPurple,
                            onChanged: (value) => setState(() => _age = value),
                          ),
                        ),
                        _SliderSection(
                          title: 'Distance',
                          value: '${_distance.round()} km',
                          min: 0,
                          max: 300,
                          current: _distance,
                          onChanged: (value) =>
                              setState(() => _distance = value),
                        ),
                        _ChipSection(
                          title: 'City',
                          options: _citiesList,
                          selected: _cities,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Relationship Intentions',
                          options: relationshipIntentions,
                          selected: _intents,
                          onToggle: _toggle,
                          intent: true,
                        ),
                        _ChipSection(
                          title: 'Lifestyle Interests',
                          options: lifestyleInterests,
                          selected: _lifestyles,
                          onToggle: _toggle,
                          lifestyle: true,
                        ),
                        _ChipSection(
                          title: 'Education',
                          options: _educationList,
                          selected: _education,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Profession',
                          options: _professionList,
                          selected: _profession,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Community Preference',
                          options: _communityList,
                          selected: _community,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Religion',
                          options: _religionList,
                          selected: _religion,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Languages',
                          options: _languageList,
                          selected: _languages,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Height',
                          options: _heightList,
                          selected: _height,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Travel',
                          options: _travelList,
                          selected: _travel,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Fitness',
                          options: _fitnessList,
                          selected: _fitness,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Coffee',
                          options: _coffeeList,
                          selected: _coffee,
                          onToggle: _toggle,
                        ),
                        _ChipSection(
                          title: 'Movies',
                          options: _movieList,
                          selected: _movies,
                          onToggle: _toggle,
                        ),
                        _SegmentSection(
                          title: 'Smoking',
                          value: _smoking,
                          options: const ['Any', 'Never', 'Occasionally'],
                          onChanged: (value) =>
                              setState(() => _smoking = value),
                        ),
                        _SegmentSection(
                          title: 'Drinking',
                          value: _drinking,
                          options: const ['Any', 'Never', 'Socially'],
                          onChanged: (value) =>
                              setState(() => _drinking = value),
                        ),
                        _SegmentSection(
                          title: 'Pets',
                          value: _pets,
                          options: const ['Any', 'Pet friendly', 'No pets'],
                          onChanged: (value) => setState(() => _pets = value),
                        ),
                        _SegmentSection(
                          title: 'Children',
                          value: _children,
                          options: const ['Any', 'Wants', 'Open', 'No'],
                          onChanged: (value) =>
                              setState(() => _children = value),
                        ),
                        _SliderSection(
                          title: 'Minimum AI score',
                          value: '${_score.round()}%',
                          min: 50,
                          max: 100,
                          current: _score,
                          onChanged: (value) => setState(() => _score = value),
                        ),
                        PremiumCard(
                          child: Column(
                            children: [
                              _SwitchRow(
                                title: 'Verified profiles only',
                                value: _verifiedOnly,
                                onChanged: (value) =>
                                    setState(() => _verifiedOnly = value),
                              ),
                              _SwitchRow(
                                title: 'Online now',
                                value: _onlineNow,
                                onChanged: (value) =>
                                    setState(() => _onlineNow = value),
                              ),
                              _SwitchRow(
                                title: 'Has profile prompts',
                                value: _hasPrompts,
                                onChanged: (value) =>
                                    setState(() => _hasPrompts = value),
                              ),
                              _SwitchRow(
                                title: 'Has event interest',
                                value: _eventInterest,
                                onChanged: (value) =>
                                    setState(() => _eventInterest = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        12,
                        padding,
                        16 + MediaQuery.viewPaddingOf(context).bottom,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPinkBackground.withValues(
                          alpha: .94,
                        ),
                        boxShadow: AmoraShadows.bottomSheet,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              label: 'Reset',
                              variant: AppPrimaryButtonVariant.outlined,
                              onPressed: _reset,
                              icon: Icons.refresh_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: AppPrimaryButton(
                              label: 'Apply Filters',
                              icon: Icons.search_rounded,
                              onPressed: _apply,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _toggle(Set<String> selected, String option) {
    setState(() {
      if (selected.contains(option)) {
        selected.remove(option);
      } else {
        selected.add(option);
      }
    });
  }

  void _reset() {
    setState(() {
      _age = const RangeValues(18, 45);
      _distance = 300;
      _score = 80;
      _cities.clear();
      _intents.clear();
      _lifestyles.clear();
      _education.clear();
      _profession.clear();
      _community
        ..clear()
        ..add('Open to all');
      _religion.clear();
      _languages
        ..clear()
        ..add('Gujarati');
      _height.clear();
      _travel.clear();
      _fitness.clear();
      _coffee.clear();
      _movies.clear();
      _smoking = 'Any';
      _drinking = 'Any';
      _pets = 'Any';
      _children = 'Any';
      _verifiedOnly = false;
      _onlineNow = false;
      _hasPrompts = false;
      _eventInterest = false;
    });
  }

  void _apply() {
    Navigator.of(context).pushReplacementNamed(BrowseGridScreen.routeName);
    showAmoraSnackBar(context, message: 'Filters applied');
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.onBack, required this.onReset});

  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.headlineMedium.copyWith(
                color: AppColors.deepWine,
              ),
            ),
            Text(
              'Find matches aligned with your lifestyle and intentions.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textGray,
              ),
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Spacer(),
                  AmoraTextAction(
                    label: 'Reset',
                    icon: Icons.refresh_rounded,
                    tooltip: 'Reset all filters',
                    onPressed: onReset,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              title,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(child: title),
            const SizedBox(width: 12),
            AmoraTextAction(
              label: 'Reset',
              icon: Icons.refresh_rounded,
              tooltip: 'Reset all filters',
              onPressed: onReset,
            ),
          ],
        );
      },
    );
  }
}

class _RangeSection extends StatelessWidget {
  const _RangeSection({
    required this.title,
    required this.value,
    required this.child,
  });

  final String title;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.fromLTRB(
        AmoraSpacing.space20,
        AmoraSpacing.space16,
        AmoraSpacing.space20,
        AmoraSpacing.space8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _FilterTitle(title)),
              Text(value, style: AmoraTextStyles.labelLarge),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _SliderSection extends StatelessWidget {
  const _SliderSection({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.current,
    required this.onChanged,
  });

  final String title;
  final String value;
  final double min;
  final double max;
  final double current;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space16),
      child: _RangeSection(
        title: title,
        value: value,
        child: Slider(
          value: current,
          min: min,
          max: max,
          activeColor: AppColors.primaryPurple,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.intent = false,
    this.lifestyle = false,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final void Function(Set<String> selected, String option) onToggle;
  final bool intent;
  final bool lifestyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space16),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterTitle(title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  if (intent)
                    IntentChip(
                      label: option,
                      selected: selected.contains(option),
                      onTap: () => onToggle(selected, option),
                    )
                  else if (lifestyle)
                    LifestyleChip(
                      label: option,
                      selected: selected.contains(option),
                      onTap: () => onToggle(selected, option),
                    )
                  else
                    AmoraFilterChip(
                      selected: selected.contains(option),
                      label: option,
                      onSelected: (_) => onToggle(selected, option),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AmoraTextStyles.titleMedium.copyWith(color: AppColors.deepWine),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: AmoraTextStyles.bodyLarge.copyWith(color: AppColors.textDark),
        ),
      ),
    );
  }
}

class _SegmentSection extends StatelessWidget {
  const _SegmentSection({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AmoraSpacing.space16),
      child: PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterTitle(title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  AmoraFilterChip(
                    label: option,
                    selected: value == option,
                    onSelected: (_) => onChanged(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _citiesList = [
  'Ahmedabad',
  'Gandhinagar',
  'Vadodara',
  'Surat',
  'Rajkot',
  'Mumbai',
  'Pune',
];

const _educationList = [
  'Graduate',
  'Postgraduate',
  'MBA',
  'Engineer',
  'Doctor',
  'CA/Finance',
  'Design/Creative',
];

const _professionList = [
  'Entrepreneur',
  'Software Engineer',
  'Architect',
  'Doctor',
  'Designer',
  'Student',
  'Business Owner',
  'Marketing',
  'Finance',
];

const _communityList = [
  'Open to all',
  'Gujarati',
  'Jain',
  'Patel',
  'Brahmin',
  'Vaishnav',
  'Other',
];

const _religionList = [
  'Hindu',
  'Jain',
  'Muslim',
  'Sikh',
  'Christian',
  'Spiritual',
  'Open',
];

const _languageList = [
  'Gujarati',
  'Hindi',
  'English',
  'Marathi',
  'Punjabi',
  'Tamil',
  'Malayalam',
];

const _heightList = ['5\'0"+', '5\'4"+', '5\'8"+', '6\'0"+'];

const _travelList = [
  'Heritage trips',
  'Luxury stays',
  'Treks',
  'Beach breaks',
  'Food trails',
];

const _fitnessList = [
  'Active',
  'Yoga',
  'Gym regular',
  'Weekend sports',
  'Balanced',
];

const _coffeeList = ['Filter coffee', 'Iced latte', 'Masala chai', 'Cold brew'];

const _movieList = [
  'Rom-coms',
  'Thrillers',
  'Indie cinema',
  'Bollywood',
  'Comedy',
];
