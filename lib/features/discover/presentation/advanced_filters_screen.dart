import 'dart:async';

import 'package:amora_ai/core/theme/amora_shadows.dart';
import 'package:amora_ai/core/theme/amora_header_tokens.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_screen_title.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/premium_motion.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';
import 'package:amora_ai/features/discover/presentation/widgets/amoraa_minimum_height_picker.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int visiblePreferenceChipLimit = 4;

const approvedFilterCities = ProfileFormOptions.cities;

@immutable
class ProfilePreferenceFilterState {
  const ProfilePreferenceFilterState({
    this.hometowns = const <String>{},
    this.qualities = const <String>{},
    this.pronouns = const <String>{},
    this.sexualities = const <String>{},
    this.preferredTalkingHours = const <String>{},
    this.loveLanguages = const <String>{},
    this.communicationStyles = const <CommunicationStyle>{},
  });

  final Set<String> hometowns;
  final Set<String> qualities;
  final Set<String> pronouns;
  final Set<String> sexualities;
  final Set<String> preferredTalkingHours;
  final Set<String> loveLanguages;
  final Set<CommunicationStyle> communicationStyles;

  bool get isEmpty =>
      hometowns.isEmpty &&
      qualities.isEmpty &&
      pronouns.isEmpty &&
      sexualities.isEmpty &&
      preferredTalkingHours.isEmpty &&
      loveLanguages.isEmpty &&
      communicationStyles.isEmpty;
}

final appliedProfilePreferenceFilters =
    ValueNotifier<ProfilePreferenceFilterState>(
      const ProfilePreferenceFilterState(),
    );

class AdvancedFiltersScreen extends StatefulWidget {
  const AdvancedFiltersScreen({super.key, this.apiService});

  static const routeName = '/filters';

  final DiscoverApiService? apiService;

  @override
  State<AdvancedFiltersScreen> createState() => _AdvancedFiltersScreenState();
}

class _AdvancedFiltersScreenState extends State<AdvancedFiltersScreen> {
  late final DiscoverApiService _discoverApi;
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
  int? _minimumHeightCm;
  final Set<String> _travel = {};
  final Set<String> _fitness = {};
  final Set<String> _coffee = {};
  final Set<String> _movies = {};
  final Set<String> _smoking = {};
  final Set<String> _drinking = {};
  final Set<String> _weed = {};
  final Set<String> _hometowns = {};
  final Set<String> _qualities = {};
  final Set<String> _pronouns = {};
  final Set<String> _sexualities = {};
  final Set<String> _preferredTalkingHours = {};
  final Set<String> _loveLanguages = {};
  final Set<CommunicationStyle> _communicationStyles = {};
  bool _verifiedOnly = true;
  bool _onlineNow = false;
  bool _hasPrompts = true;
  bool _eventInterest = false;

  late final TextEditingController _filterSearchController;
  late final TextEditingController _customEducationController;
  String? _customEducationError;
  Timer? _searchDebounce;
  Timer? _highlightTimer;
  String _languageQuery = '';
  String? _highlightedGroup;
  _FilterCategory _activeCategory = _FilterCategory.basics;
  bool _showAllLifestyle = false;
  final Set<String> _expandedGroups = {
    _GroupIds.basics,
    _GroupIds.intentions,
    _GroupIds.lifestyle,
    _GroupIds.trust,
  };

  final Map<_FilterCategory, GlobalKey> _categoryKeys = {
    for (final category in _FilterCategory.values) category: GlobalKey(),
  };
  final GlobalKey _careerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _discoverApi = widget.apiService ?? DiscoverApiService();
    _filterSearchController = TextEditingController();
    _customEducationController = TextEditingController();
    unawaited(_loadSavedFilters());
  }

  Future<void> _loadSavedFilters() async {
    final result = await _discoverApi.getFilters();
    if (!mounted) return;
    if (!result.success || result.data == null) {
      showAmoraSnackBar(
        context,
        message: result.message,
        tone: AmoraSnackBarTone.error,
      );
      return;
    }
    final filters = result.data!;
    Set<String> values(String key) =>
        ((filters[key] as List?) ?? const <dynamic>[])
            .map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toSet();
    String value(String key) => filters[key]?.toString() ?? '';
    void replace(Set<String> target, Iterable<String> source) {
      target
        ..clear()
        ..addAll(source);
    }

    setState(() {
      _age = RangeValues(
        ((filters['minAge'] as num?)?.toDouble() ?? 18)
            .clamp(18, 99)
            .toDouble(),
        ((filters['maxAge'] as num?)?.toDouble() ?? 45)
            .clamp(18, 99)
            .toDouble(),
      );
      _distance = ((filters['maxDistanceKm'] as num?)?.toDouble() ?? 80)
          .clamp(1, 500)
          .toDouble();
      _score = ((filters['minScore'] as num?)?.toDouble() ?? 80)
          .clamp(50, 100)
          .toDouble();
      replace(
        _cities,
        value('city').isEmpty ? const <String>[] : <String>[value('city')],
      );
      replace(_intents, values('datingIntentions'));
      replace(_lifestyles, values('lifestyleTags'));
      replace(
        _education,
        value('education').isEmpty
            ? const <String>[]
            : <String>[value('education')],
      );
      replace(
        _profession,
        value('profession').isEmpty
            ? const <String>[]
            : <String>[value('profession')],
      );
      replace(
        _community,
        value('community').isEmpty
            ? const <String>[]
            : <String>[value('community')],
      );
      replace(
        _religion,
        value('religion').isEmpty
            ? const <String>[]
            : <String>[value('religion')],
      );
      replace(_languages, values('languages'));
      replace(_hometowns, values('hometown'));
      replace(_qualities, values('qualities'));
      replace(_pronouns, values('pronouns'));
      replace(
        _sexualities,
        value('sexuality').isEmpty
            ? const <String>[]
            : <String>[value('sexuality')],
      );
      replace(_preferredTalkingHours, values('preferredTalkingHours'));
      replace(_loveLanguages, values('loveLanguages'));
      _communicationStyles
        ..clear()
        ..addAll(
          values('communicationStyles')
              .map(CommunicationStyle.fromStorageValue)
              .whereType<CommunicationStyle>(),
        );
      replace(
        _smoking,
        value('smoking').isEmpty
            ? const <String>[]
            : <String>[value('smoking')],
      );
      replace(
        _drinking,
        value('drinking').isEmpty
            ? const <String>[]
            : <String>[value('drinking')],
      );
      replace(
        _weed,
        value('weed').isEmpty ? const <String>[] : <String>[value('weed')],
      );
      _minimumHeightCm = (filters['minHeight'] as num?)?.toInt();
      _verifiedOnly = filters['verifiedOnly'] == true;
      _onlineNow = filters['onlineNow'] == true;
      _hasPrompts = filters['hasPrompts'] == true;
      _eventInterest = filters['hasEventInterest'] == true;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _highlightTimer?.cancel();
    _filterSearchController.dispose();
    _customEducationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 860,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380
                  ? 14.0
                  : 20.0;
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _FiltersHeader(
                          onBack: () => Navigator.of(context).maybePop(),
                          onReset: _reset,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              16,
                              horizontalPadding,
                              112,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _SelectedFiltersSummary(
                                  preferences: _activePreferences,
                                  onShowAll: _showSelectedPreferences,
                                ),
                                const SizedBox(height: 14),
                                _FilterSearchField(
                                  controller: _filterSearchController,
                                  hasQuery:
                                      _filterSearchController.text.isNotEmpty,
                                  noMatch: _highlightedGroup == _noSearchMatch,
                                  onChanged: _onFilterSearchChanged,
                                  onClear: _clearFilterSearch,
                                ),
                                const SizedBox(height: 12),
                                _FilterCategoryNav(
                                  active: _activeCategory,
                                  onSelected: _openCategory,
                                ),
                                const SizedBox(height: 18),
                                _buildBasicsSection(),
                                const SizedBox(height: 14),
                                _buildIntentionsSection(),
                                const SizedBox(height: 14),
                                _buildLifestyleSection(),
                                const SizedBox(height: 14),
                                _buildCareerSection(),
                                const SizedBox(height: 14),
                                _buildIdentitySection(),
                                const SizedBox(height: 14),
                                _buildCompatibilitySection(),
                                const SizedBox(height: 14),
                                _buildHabitsSection(),
                                const SizedBox(height: 14),
                                _buildTrustSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _StickyFiltersActionBar(
                        horizontalPadding: horizontalPadding,
                        onReset: _reset,
                        onApply: _apply,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBasicsSection() {
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.basics],
      id: _GroupIds.basics,
      icon: Icons.tune_rounded,
      title: 'Core preferences',
      subtitle: 'Age, distance, city and height',
      summary: _basicsSummary,
      selectedCount:
          _cities.length +
          _hometowns.length +
          (_minimumHeightCm == null ? 0 : 1),
      expanded: _expandedGroups.contains(_GroupIds.basics),
      highlighted: _highlightedGroup == _GroupIds.basics,
      onToggle: _toggleGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsivePair(
            children: [
              _RangeControl(
                icon: Icons.cake_outlined,
                emoji: '🎂',
                title: 'Age range',
                value: '${_age.start.round()}–${_age.end.round()} years',
                child: RangeSlider(
                  values: _age,
                  min: 18,
                  max: 45,
                  divisions: 27,
                  labels: RangeLabels(
                    '${_age.start.round()}',
                    '${_age.end.round()}',
                  ),
                  onChanged: (value) => setState(() => _age = value),
                ),
              ),
              _ValueSliderControl(
                icon: Icons.near_me_outlined,
                emoji: '📍',
                title: 'Distance',
                value: 'Up to ${_distance.round()} km',
                current: _distance,
                min: 0,
                max: 300,
                divisions: 60,
                onChanged: (value) => setState(() => _distance = value),
              ),
            ],
          ),
          const _FilterDivider(),
          _ResponsivePair(
            children: [
              _ControlBlock(
                key: const ValueKey('filters-city-control'),
                icon: Icons.location_city_rounded,
                title: 'City',
                description: 'Choose preferred cities',
                child: AmoraaCompactSelect<String>(
                  key: const ValueKey('filters-city-selector'),
                  label: 'City',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _cities,
                  hintText: 'Any city',
                  prefixIcon: Icons.location_city_rounded,
                  allowClear: true,
                  options: [
                    for (final option in ProfileFormOptions.cities)
                      AmoraaSelectOption(value: option, label: option),
                  ],
                  onSelectionChanged: (values) =>
                      _replaceSelection(_cities, values),
                ),
              ),
              _ControlBlock(
                icon: Icons.height_rounded,
                title: 'Height',
                description: 'Choose a minimum height for matches',
                child: _HeightFilterEntry(
                  value: minimumHeightSummary(_minimumHeightCm),
                  onTap: _openHeightPicker,
                ),
              ),
            ],
          ),
          const _FilterDivider(),
          _ControlBlock(
            key: const ValueKey('filters-hometown-control'),
            icon: Icons.home_work_outlined,
            title: 'Hometown',
            description: 'Choose one or more Gujarat hometowns',
            child: AmoraaSearchableSelect<String>(
              key: const ValueKey('filters-hometown-selector'),
              label: 'Hometown',
              selectionMode: AmoraaSelectionMode.multiple,
              selectedValues: _hometowns,
              hintText: 'Any hometown',
              searchHint: 'Find your hometown',
              searchSemanticLabel: 'Search Gujarat hometowns',
              prefixIcon: Icons.home_work_outlined,
              allowClear: true,
              options: [
                for (final option
                    in ProfileFormOptions
                        .preferenceOptions[ProfilePreferenceType.hometown]!)
                  AmoraaSelectOption(
                    value: option.id,
                    label: option.label,
                    description: option.description,
                  ),
              ],
              onSelectionChanged: (values) =>
                  _replaceSelection(_hometowns, values),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentionsSection() {
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.intentions],
      id: _GroupIds.intentions,
      icon: Icons.favorite_outline_rounded,
      title: 'Relationship intentions',
      subtitle: 'What kind of connection feels right',
      summary: _selectionSummary(_intents, fallback: 'Any intention'),
      selectedCount: _intents.length,
      expanded: _expandedGroups.contains(_GroupIds.intentions),
      highlighted: _highlightedGroup == _GroupIds.intentions,
      onToggle: _toggleGroup,
      child: AmoraaSelectField<String>(
        key: const ValueKey('filters-intention-selector'),
        label: 'Dating Intention',
        selectionMode: AmoraaSelectionMode.multiple,
        selectedValues: _intents,
        hintText: 'Any intention',
        prefixIcon: Icons.favorite_outline_rounded,
        allowClear: true,
        options: [
          for (final option in ProfileFormOptions.datingIntentions)
            AmoraaSelectOption(
              value: option,
              label: option,
              description:
                  ProfileFormOptions.datingIntentionDescriptions[option],
            ),
        ],
        onSelectionChanged: (values) => _replaceSelection(_intents, values),
      ),
    );
  }

  Widget _buildLifestyleSection() {
    final visible = _visibleLifestyleOptions;
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.lifestyle],
      id: _GroupIds.lifestyle,
      icon: Icons.interests_rounded,
      title: 'Lifestyle and interests',
      subtitle: 'The moments you would enjoy sharing',
      summary: _selectionSummary(
        _lifestyles,
        fallback: 'No interests selected',
      ),
      selectedCount: _lifestyles.length,
      expanded: _expandedGroups.contains(_GroupIds.lifestyle),
      highlighted: _highlightedGroup == _GroupIds.lifestyle,
      onToggle: _toggleGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: AmoraMotion.standard,
            curve: AmoraMotion.curve,
            alignment: Alignment.topCenter,
            child: _OptionWrap(
              options: visible,
              selected: _lifestyles,
              emojiFor: (option) => _lifestyleEmoji[option],
              icon: Icons.auto_awesome_rounded,
              onToggle: _toggle,
            ),
          ),
          if (ProfileFormOptions.datingTypes.length > 8) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('filters-lifestyle-show-more'),
              onPressed: () =>
                  setState(() => _showAllLifestyle = !_showAllLifestyle),
              icon: AnimatedRotation(
                turns: _showAllLifestyle ? .5 : 0,
                duration: AmoraMotion.fast,
                child: const Icon(Icons.expand_more_rounded),
              ),
              label: Text(_showAllLifestyle ? 'Show less' : 'Show more'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCareerSection() {
    return _ExpandableFilterSection(
      key: _careerKey,
      id: _GroupIds.career,
      icon: Icons.school_outlined,
      title: 'Education and profession',
      subtitle: 'Background and career preferences',
      summary: _joinedSummaries([
        _selectionSummary(_education),
        _selectionSummary(_profession),
      ]),
      selectedCount: _education.length + _profession.length,
      expanded: _expandedGroups.contains(_GroupIds.career),
      highlighted: _highlightedGroup == _GroupIds.career,
      onToggle: _toggleGroup,
      child: _ResponsivePair(
        children: [
          _ControlBlock(
            icon: Icons.school_outlined,
            title: 'Education',
            child: Column(
              children: [
                AmoraaCompactSelect<String>(
                  key: const ValueKey('filters-education-selector'),
                  label: 'Education',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _education,
                  hintText: 'Any education',
                  prefixIcon: Icons.school_outlined,
                  allowClear: true,
                  options: [
                    for (final option in ProfileFormOptions.education)
                      AmoraaSelectOption(value: option, label: option),
                  ],
                  onSelectionChanged: _setEducation,
                ),
                if (_education.contains('Other')) ...[
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('filters-custom-education-field'),
                    controller: _customEducationController,
                    maxLength: ProfileFormOptions.customEducationMaxLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(
                        ProfileFormOptions.customEducationMaxLength,
                      ),
                    ],
                    onChanged: (_) {
                      if (_customEducationError != null) {
                        setState(() => _customEducationError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Specify education',
                      hintText: 'Enter your education',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      counterText: '',
                      errorText: _customEducationError,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _ControlBlock(
            icon: Icons.work_outline_rounded,
            title: 'Profession',
            child: AmoraaSearchableSelect<String>(
              key: const ValueKey('filters-profession-selector'),
              label: 'Profession',
              selectionMode: AmoraaSelectionMode.multiple,
              selectedValues: _profession,
              hintText: 'Any profession',
              searchHint: 'Search profession',
              prefixIcon: Icons.work_outline_rounded,
              allowClear: true,
              options: [
                for (final option in ProfileFormOptions.occupations)
                  AmoraaSelectOption(value: option, label: option),
              ],
              onSelectionChanged: (values) =>
                  _replaceSelection(_profession, values),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    final visibleLanguages = ProfileFormOptions.languages
        .where(
          (language) => language.toLowerCase().contains(
            _languageQuery.trim().toLowerCase(),
          ),
        )
        .toList(growable: false);
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.identity],
      id: _GroupIds.identity,
      icon: Icons.person_outline_rounded,
      title: 'Identity and background',
      subtitle: 'Inclusive preferences you control',
      summary: _joinedSummaries([
        _selectionSummary(_community),
        _selectionSummary(_religion),
        _selectionSummary(_languages),
        _selectionSummary(_pronouns),
        _selectionSummary(_sexualities),
      ]),
      selectedCount:
          _community.length +
          _religion.length +
          _languages.length +
          _pronouns.length +
          _sexualities.length,
      expanded: _expandedGroups.contains(_GroupIds.identity),
      highlighted: _highlightedGroup == _GroupIds.identity,
      onToggle: _toggleGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsivePair(
            children: [
              _ControlBlock(
                icon: Icons.groups_outlined,
                title: 'Community preference',
                description: 'No preference is inferred automatically',
                child: _OptionWrap(
                  options: _communityList,
                  selected: _community,
                  onToggle: _toggle,
                ),
              ),
              _ControlBlock(
                icon: Icons.public_rounded,
                title: 'Religion',
                description: 'Choose only what you are comfortable sharing',
                child: AmoraaCompactSelect<String>(
                  label: 'Religion',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _religion,
                  hintText: 'Any religion',
                  prefixIcon: Icons.public_rounded,
                  allowClear: true,
                  options: [
                    for (final option in ProfileFormOptions.religions)
                      AmoraaSelectOption(value: option, label: option),
                  ],
                  onSelectionChanged: (values) =>
                      _replaceSelection(_religion, values),
                ),
              ),
            ],
          ),
          const _FilterDivider(),
          _ControlBlock(
            icon: Icons.translate_rounded,
            title: 'Languages',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompactSearchField(
                  key: const ValueKey('filters-language-search'),
                  hintText: 'Search languages',
                  onChanged: (value) => setState(() => _languageQuery = value),
                ),
                const SizedBox(height: 10),
                if (visibleLanguages.isEmpty)
                  const _InlineEmpty(message: 'No language matches that search')
                else
                  _OptionWrap(
                    options: visibleLanguages,
                    selected: _languages,
                    onToggle: _toggle,
                  ),
              ],
            ),
          ),
          const _FilterDivider(),
          _ResponsivePair(
            children: [
              _ControlBlock(
                icon: Icons.badge_outlined,
                title: 'Pronouns',
                child: AmoraaCompactSelect<String>(
                  key: const ValueKey('filters-pronouns-selector'),
                  label: 'Pronouns',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _pronouns,
                  hintText: 'Any pronouns',
                  prefixIcon: Icons.badge_outlined,
                  allowClear: true,
                  options: [
                    for (final option in ProfileFormOptions.pronouns)
                      AmoraaSelectOption(value: option, label: option),
                  ],
                  onSelectionChanged: (values) =>
                      _replaceSelection(_pronouns, values),
                ),
              ),
              _ControlBlock(
                icon: Icons.favorite_outline_rounded,
                title: 'Sexuality',
                child: AmoraaCompactSelect<String>(
                  key: const ValueKey('filters-sexuality-selector'),
                  label: 'Sexuality',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _sexualities,
                  hintText: 'Any sexuality',
                  prefixIcon: Icons.favorite_outline_rounded,
                  allowClear: true,
                  options: [
                    for (final option in ProfileFormOptions.sexualities)
                      AmoraaSelectOption(value: option, label: option),
                  ],
                  onSelectionChanged: (values) =>
                      _replaceSelection(_sexualities, values),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection() {
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.compatibility],
      id: _GroupIds.compatibility,
      icon: Icons.favorite_border_rounded,
      title: 'Compatibility',
      subtitle: 'Qualities, conversation rhythm and love languages',
      summary: _joinedSummaries([
        _selectionSummary(_qualities),
        _communicationStyleSummary,
        _selectionSummary(_preferredTalkingHours),
        _selectionSummary(_loveLanguages),
      ]),
      selectedCount:
          _qualities.length +
          _communicationStyles.length +
          _preferredTalkingHours.length +
          _loveLanguages.length,
      expanded: _expandedGroups.contains(_GroupIds.compatibility),
      highlighted: _highlightedGroup == _GroupIds.compatibility,
      onToggle: _toggleGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControlBlock(
            icon: Icons.auto_awesome_rounded,
            title: 'Their Qualities',
            description: 'Choose every quality that matters to you',
            child: AmoraaSearchableSelect<String>(
              key: const ValueKey('filters-qualities-selector'),
              label: 'Their Qualities',
              selectionMode: AmoraaSelectionMode.multiple,
              selectedValues: _qualities,
              hintText: 'Any qualities',
              searchHint: 'Find a quality',
              prefixIcon: Icons.auto_awesome_rounded,
              allowClear: true,
              options: [
                for (final option in ProfileFormOptions.qualities)
                  AmoraaSelectOption(value: option, label: option),
              ],
              onSelectionChanged: (values) =>
                  _replaceSelection(_qualities, values),
            ),
          ),
          const _FilterDivider(),
          _ControlBlock(
            icon: Icons.forum_outlined,
            title: 'Communication Style',
            description: 'Choose every way you enjoy staying connected',
            child: AmoraaSelectField<CommunicationStyle>(
              key: const ValueKey('filters-communication-style-selector'),
              label: 'Communication Style',
              selectionMode: AmoraaSelectionMode.multiple,
              selectedValues: _communicationStyles,
              hintText: 'Any communication style',
              supportingText: 'Select one or more communication styles.',
              prefixIcon: Icons.forum_outlined,
              allowClear: true,
              options: [
                for (final style in CommunicationStyle.values)
                  AmoraaSelectOption(value: style, label: style.label),
              ],
              onSelectionChanged: (values) =>
                  _replaceCommunicationStyles(values),
            ),
          ),
          const _FilterDivider(),
          _ResponsivePair(
            children: [
              _ControlBlock(
                icon: Icons.schedule_rounded,
                title: 'Preferred Hours for Talking',
                child: AmoraaCompactSelect<String>(
                  key: const ValueKey('filters-talking-hours-selector'),
                  label: 'Preferred Hours for Talking',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _preferredTalkingHours,
                  hintText: 'Any time',
                  prefixIcon: Icons.schedule_rounded,
                  allowClear: true,
                  options: [
                    for (final option
                        in ProfileFormOptions.preferredTalkingHours)
                      AmoraaSelectOption(
                        value: option,
                        label: option,
                        description: ProfileFormOptions
                            .preferredTalkingHourDescriptions[option],
                      ),
                  ],
                  onSelectionChanged: (values) =>
                      _replaceSelection(_preferredTalkingHours, values),
                ),
              ),
              _ControlBlock(
                icon: Icons.volunteer_activism_rounded,
                title: 'Love Languages',
                child: AmoraaCompactSelect<String>(
                  key: const ValueKey('filters-love-languages-selector'),
                  label: 'Love Languages',
                  selectionMode: AmoraaSelectionMode.multiple,
                  selectedValues: _loveLanguages,
                  hintText: 'Any love language',
                  prefixIcon: Icons.volunteer_activism_rounded,
                  allowClear: true,
                  options: [
                    for (final option in ProfileFormOptions.loveLanguages)
                      AmoraaSelectOption(value: option, label: option),
                  ],
                  onSelectionChanged: (values) =>
                      _replaceSelection(_loveLanguages, values),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSection() {
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.habits],
      id: _GroupIds.habits,
      icon: Icons.self_improvement_rounded,
      title: 'Habits',
      subtitle: 'Daily choices',
      summary: _habitsSummary,
      selectedCount: _smoking.length + _drinking.length + _weed.length,
      expanded: _expandedGroups.contains(_GroupIds.habits),
      highlighted: _highlightedGroup == _GroupIds.habits,
      onToggle: _toggleGroup,
      child: _ResponsiveTriple(
        children: [
          AmoraaCompactSelect<String>(
            key: const ValueKey('filters-smoking-selector'),
            label: 'Smoking',
            selectionMode: AmoraaSelectionMode.multiple,
            selectedValues: _smoking,
            hintText: 'Any',
            prefixIcon: Icons.smoke_free_rounded,
            options: [
              const AmoraaSelectOption(value: 'Any', label: 'Any'),
              for (final option in ProfileFormOptions.habitFrequencyOptions)
                AmoraaSelectOption(value: option, label: option),
            ],
            onSelectionChanged: (values) =>
                _setHabitSelection(_smoking, values),
          ),
          AmoraaCompactSelect<String>(
            key: const ValueKey('filters-drinking-selector'),
            label: 'Drinking',
            selectionMode: AmoraaSelectionMode.multiple,
            selectedValues: _drinking,
            hintText: 'Any',
            prefixIcon: Icons.local_bar_outlined,
            options: [
              const AmoraaSelectOption(value: 'Any', label: 'Any'),
              for (final option in ProfileFormOptions.habitFrequencyOptions)
                AmoraaSelectOption(value: option, label: option),
            ],
            onSelectionChanged: (values) =>
                _setHabitSelection(_drinking, values),
          ),
          AmoraaCompactSelect<String>(
            key: const ValueKey('filters-weed-selector'),
            label: 'Weed',
            selectionMode: AmoraaSelectionMode.multiple,
            selectedValues: _weed,
            hintText: 'Any',
            prefixIcon: Icons.grass_rounded,
            options: [
              const AmoraaSelectOption(value: 'Any', label: 'Any'),
              for (final option in ProfileFormOptions.habitFrequencyOptions)
                AmoraaSelectOption(value: option, label: option),
            ],
            onSelectionChanged: (values) => _setHabitSelection(_weed, values),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSection() {
    return _ExpandableFilterSection(
      key: _categoryKeys[_FilterCategory.trust],
      id: _GroupIds.trust,
      icon: Icons.verified_user_outlined,
      title: 'AI match quality and trust',
      subtitle: 'Compatibility guidance and profile signals',
      summary: _trustSummary,
      selectedCount: [
        _verifiedOnly,
        _onlineNow,
        _hasPrompts,
        _eventInterest,
      ].where((value) => value).length,
      expanded: _expandedGroups.contains(_GroupIds.trust),
      highlighted: _highlightedGroup == _GroupIds.trust,
      onToggle: _toggleGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ValueSliderControl(
            icon: Icons.auto_awesome_rounded,
            title: 'Minimum AI score',
            value: '${_score.round()}% compatibility',
            description:
                'Scores are guidance based on profile compatibility, not guarantees.',
            current: _score,
            min: 50,
            max: 100,
            divisions: 50,
            onChanged: (value) => setState(() => _score = value),
            infoTooltip:
                'Match scores help prioritize compatible profiles. They do not predict relationship outcomes.',
          ),
          const _FilterDivider(),
          _ResponsiveSwitchGrid(
            children: [
              _FilterSwitchTile(
                icon: Icons.verified_rounded,
                title: 'Verified profiles only',
                description: 'Prioritize profiles with completed verification',
                value: _verifiedOnly,
                onChanged: (value) => setState(() => _verifiedOnly = value),
              ),
              _FilterSwitchTile(
                icon: Icons.circle_outlined,
                title: 'Online now',
                description: 'Show people currently active',
                value: _onlineNow,
                onChanged: (value) => setState(() => _onlineNow = value),
              ),
              _FilterSwitchTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Has profile prompts',
                description: 'Profiles with more conversation context',
                value: _hasPrompts,
                onChanged: (value) => setState(() => _hasPrompts = value),
              ),
              _FilterSwitchTile(
                icon: Icons.event_outlined,
                title: 'Has event interest',
                description: 'People open to AMORAA experiences',
                value: _eventInterest,
                onChanged: (value) => setState(() => _eventInterest = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ActivePreference> get _activePreferences {
    final preferences = <_ActivePreference>[];
    final seenPreferences = <String>{};

    void add(String category, String label) {
      final normalized = label.trim();
      if (normalized.isEmpty ||
          !seenPreferences.add('$category\u0000$normalized')) {
        return;
      }
      preferences.add(_ActivePreference(category: category, label: normalized));
    }

    for (final value in _intents) {
      add('Relationship intention', value);
    }
    for (final value in _cities) {
      add('City', value);
    }
    for (final value in _hometowns) {
      add('Hometown', value);
    }
    for (final value in _languages) {
      add('Languages', value);
    }
    if (_verifiedOnly) add('Trust', 'Verified only');
    for (final value in _lifestyles) {
      add('Type of Dating', value);
    }
    for (final value in _community) {
      add('Community', value);
    }
    for (final value in _education) {
      add('Education', value);
    }
    for (final value in _profession) {
      add('Profession', value);
    }
    for (final value in _religion) {
      add('Religion', value);
    }
    if (_minimumHeightCm case final height?) {
      add('Height', minimumHeightSummary(height));
    }
    for (final value in _travel) {
      add('Travel', value);
    }
    for (final value in _fitness) {
      add('Fitness', value);
    }
    for (final value in _coffee) {
      add('Coffee', value);
    }
    for (final value in _movies) {
      add('Movies', value);
    }
    if (_onlineNow) add('Trust', 'Online now');
    if (_hasPrompts) add('Trust', 'Has profile prompts');
    if (_eventInterest) add('Events', 'Interested in events');
    for (final value in _smoking) {
      add('Smoking', value);
    }
    for (final value in _drinking) {
      add('Drinking', value);
    }
    for (final value in _weed) {
      add('Weed', value);
    }
    for (final value in _qualities) {
      add('Their Qualities', value);
    }
    for (final style in CommunicationStyle.values) {
      if (_communicationStyles.contains(style)) {
        add('Communication Style', style.label);
      }
    }
    for (final value in _pronouns) {
      add('Pronouns', value);
    }
    for (final value in _sexualities) {
      add('Sexuality', value);
    }
    for (final value in _preferredTalkingHours) {
      add('Preferred Hours for Talking', value);
    }
    for (final value in _loveLanguages) {
      add('Love Languages', value);
    }
    return preferences;
  }

  List<String> get _visibleLifestyleOptions {
    if (_showAllLifestyle) return ProfileFormOptions.datingTypes;
    final visible = <String>{
      ...ProfileFormOptions.datingTypes.take(8),
      ..._lifestyles,
    };
    return ProfileFormOptions.datingTypes
        .where(visible.contains)
        .toList(growable: false);
  }

  String get _basicsSummary {
    final parts = <String>[
      '${_age.start.round()}–${_age.end.round()} years',
      '${_distance.round()} km',
      if (_cities.isNotEmpty) _cities.join(', '),
      if (_hometowns.isNotEmpty) 'Hometown: ${_hometowns.join(', ')}',
      if (_minimumHeightCm case final height?) minimumHeightSummary(height),
    ];
    return parts.join(' • ');
  }

  String get _habitsSummary {
    final parts = <String>[
      if (_smoking.isNotEmpty) 'Smoking: ${_smoking.join(', ')}',
      if (_drinking.isNotEmpty) 'Drinking: ${_drinking.join(', ')}',
      if (_weed.isNotEmpty) 'Weed: ${_weed.join(', ')}',
    ];
    return parts.isEmpty ? 'Any lifestyle habits' : parts.join(' • ');
  }

  String get _trustSummary {
    final parts = <String>[
      '${_score.round()}% minimum',
      if (_verifiedOnly) 'Verified',
      if (_onlineNow) 'Online',
      if (_hasPrompts) 'Prompts',
      if (_eventInterest) 'Events',
    ];
    return parts.join(' • ');
  }

  String get _communicationStyleSummary {
    final labels = <String>[
      for (final style in CommunicationStyle.values)
        if (_communicationStyles.contains(style)) style.label,
    ];
    return labels.take(3).join(', ');
  }

  String _selectionSummary(Set<String> values, {String fallback = ''}) {
    if (values.isEmpty) return fallback;
    return values.take(3).join(', ');
  }

  String _joinedSummaries(List<String> values) {
    final visible = values.where((value) => value.isNotEmpty).toList();
    return visible.isEmpty ? 'No preferences selected' : visible.join(' • ');
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

  void _replaceSelection(Set<String> selected, Set<String> values) {
    setState(() {
      selected
        ..clear()
        ..addAll(values);
    });
  }

  void _replaceCommunicationStyles(Set<CommunicationStyle> values) {
    setState(() {
      _communicationStyles
        ..clear()
        ..addAll(values);
    });
  }

  void _setEducation(Set<String> values) {
    setState(() {
      _education
        ..clear()
        ..addAll(values);
      if (!_education.contains('Other')) _customEducationError = null;
    });
  }

  void _setHabitSelection(Set<String> selected, Set<String> values) {
    setState(() {
      final normalized = Set<String>.of(values);
      if (normalized.remove('Any') && selected.isNotEmpty) {
        normalized.clear();
      }
      selected
        ..clear()
        ..addAll(normalized);
    });
  }

  void _showSelectedPreferences() {
    final preferences = _activePreferences;
    if (preferences.length <= visiblePreferenceChipLimit) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) => _SelectedPreferencesSheet(
        preferences: preferences,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  Future<void> _openHeightPicker() async {
    final result = await showModalBottomSheet<MinimumHeightPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) => AmoraaMinimumHeightPicker(
        initialMinimumCentimeters: _minimumHeightCm,
        onClose: () => Navigator.of(sheetContext).pop(),
        onApply: (minimumCentimeters) => Navigator.of(
          sheetContext,
        ).pop(MinimumHeightPickerResult(minimumCentimeters)),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _minimumHeightCm = result.minimumCentimeters);
  }

  void _toggleGroup(String id) {
    setState(() {
      if (!_expandedGroups.add(id)) {
        _expandedGroups.remove(id);
      }
    });
  }

  void _openCategory(_FilterCategory category) {
    final id = category.groupId;
    setState(() {
      _activeCategory = category;
      _expandedGroups.add(id);
      _highlightedGroup = id;
    });
    _scrollTo(_categoryKeys[category]);
    _clearHighlightLater();
  }

  void _onFilterSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      final query = value.trim().toLowerCase();
      if (query.isEmpty) {
        setState(() => _highlightedGroup = null);
        return;
      }
      final target = _searchTargetFor(query);
      if (target == null) {
        setState(() => _highlightedGroup = _noSearchMatch);
        return;
      }
      setState(() {
        _highlightedGroup = target.id;
        _expandedGroups.add(target.id);
        if (target.category case final category?) {
          _activeCategory = category;
        }
      });
      _scrollTo(target.key);
      _clearHighlightLater();
    });
  }

  _SearchTarget? _searchTargetFor(String query) {
    if (_containsKeyword(query, const [
      'age',
      'distance',
      'city',
      'location',
      'height',
      'basic',
      'hometown',
    ])) {
      return _SearchTarget(
        id: _GroupIds.basics,
        key: _categoryKeys[_FilterCategory.basics],
        category: _FilterCategory.basics,
      );
    }
    if (_containsKeyword(query, const [
      'relationship',
      'intention',
      'marriage',
      'dating',
    ])) {
      return _SearchTarget(
        id: _GroupIds.intentions,
        key: _categoryKeys[_FilterCategory.intentions],
        category: _FilterCategory.intentions,
      );
    }
    if (_containsKeyword(query, const ['lifestyle', 'interest'])) {
      return _SearchTarget(
        id: _GroupIds.lifestyle,
        key: _categoryKeys[_FilterCategory.lifestyle],
        category: _FilterCategory.lifestyle,
      );
    }
    if (_containsKeyword(query, const [
      'quality',
      'qualities',
      'talking',
      'hours',
      'love language',
      'communication',
      'texting',
      'calls',
      'voice notes',
      'compatibility',
    ])) {
      return _SearchTarget(
        id: _GroupIds.compatibility,
        key: _categoryKeys[_FilterCategory.compatibility],
        category: _FilterCategory.compatibility,
      );
    }
    if (_containsKeyword(query, const [
      'education',
      'profession',
      'career',
      'work',
    ])) {
      return _SearchTarget(id: _GroupIds.career, key: _careerKey);
    }
    if (_containsKeyword(query, const [
      'community',
      'religion',
      'language',
      'identity',
      'background',
      'pronoun',
      'sexuality',
    ])) {
      return _SearchTarget(
        id: _GroupIds.identity,
        key: _categoryKeys[_FilterCategory.identity],
        category: _FilterCategory.identity,
      );
    }
    if (_containsKeyword(query, const [
      'smoking',
      'drinking',
      'weed',
      'habit',
    ])) {
      return _SearchTarget(
        id: _GroupIds.habits,
        key: _categoryKeys[_FilterCategory.habits],
        category: _FilterCategory.habits,
      );
    }
    if (_containsKeyword(query, const [
      'ai',
      'score',
      'verified',
      'online',
      'prompt',
      'event',
      'trust',
    ])) {
      return _SearchTarget(
        id: _GroupIds.trust,
        key: _categoryKeys[_FilterCategory.trust],
        category: _FilterCategory.trust,
      );
    }
    return null;
  }

  bool _containsKeyword(String query, List<String> keywords) {
    return keywords.any(
      (keyword) => keyword.contains(query) || query.contains(keyword),
    );
  }

  void _scrollTo(GlobalKey? key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = key?.currentContext;
      if (targetContext == null || !mounted) return;
      Scrollable.ensureVisible(
        targetContext,
        duration: AmoraMotion.standard,
        curve: AmoraMotion.curve,
        alignment: .08,
      );
    });
  }

  void _clearHighlightLater() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 950), () {
      if (mounted && _filterSearchController.text.isEmpty) {
        setState(() => _highlightedGroup = null);
      }
    });
  }

  void _clearFilterSearch() {
    _searchDebounce?.cancel();
    _filterSearchController.clear();
    setState(() => _highlightedGroup = null);
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
      _customEducationController.clear();
      _customEducationError = null;
      _profession.clear();
      _community
        ..clear()
        ..add('Open to all');
      _religion.clear();
      _languages
        ..clear()
        ..add('Gujarati');
      _minimumHeightCm = null;
      _travel.clear();
      _fitness.clear();
      _coffee.clear();
      _movies.clear();
      _smoking.clear();
      _drinking.clear();
      _weed.clear();
      _hometowns.clear();
      _qualities.clear();
      _pronouns.clear();
      _sexualities.clear();
      _preferredTalkingHours.clear();
      _loveLanguages.clear();
      _communicationStyles.clear();
      _verifiedOnly = false;
      _onlineNow = false;
      _hasPrompts = false;
      _eventInterest = false;
      appliedProfilePreferenceFilters.value =
          const ProfilePreferenceFilterState();
    });
    unawaited(_clearPersistedCommunicationStyles());
  }

  Future<void> _clearPersistedCommunicationStyles() async {
    final result = await _discoverApi.updateFilters(<String, dynamic>{
      'communicationStyles': <String>[],
    });
    if (!mounted || result.success) return;
    showAmoraSnackBar(
      context,
      message: result.message,
      tone: AmoraSnackBarTone.error,
    );
  }

  Future<void> _apply() async {
    final educationError = ProfileFormValidators.customEducation(
      _education.contains('Other') ? 'Other' : null,
      _customEducationController.text,
    );
    if (educationError != null) {
      setState(() => _customEducationError = educationError);
      return;
    }
    final customEducation = _customEducationController.text.trim();
    if (customEducation != _customEducationController.text) {
      _customEducationController.value = TextEditingValue(
        text: customEducation,
        selection: TextSelection.collapsed(offset: customEducation.length),
      );
    }
    final filters = <String, dynamic>{
      'minAge': _age.start.round(),
      'maxAge': _age.end.round(),
      'maxDistanceKm': _distance.round(),
      'minScore': _score.round(),
      'city': _cities.isEmpty ? '' : _cities.first,
      'minHeight': _minimumHeightCm?.toString() ?? '',
      'hometown': _hometowns.toList(),
      'datingIntentions': _intents.toList(),
      'lifestyleTags': _lifestyles.toList(),
      'education': _education.isEmpty ? '' : _education.first,
      'profession': _profession.isEmpty ? '' : _profession.first,
      'community': _community.isEmpty ? '' : _community.first,
      'religion': _religion.isEmpty ? '' : _religion.first,
      'languages': _languages.toList(),
      'pronouns': _pronouns.toList(),
      'sexuality': _sexualities.isEmpty ? '' : _sexualities.first,
      'qualities': _qualities.toList(),
      'preferredTalkingHours': _preferredTalkingHours.toList(),
      'loveLanguages': _loveLanguages.toList(),
      'communicationStyles': [
        for (final style in CommunicationStyle.values)
          if (_communicationStyles.contains(style)) style.storageValue,
      ],
      'smoking': _smoking.isEmpty ? '' : _smoking.first,
      'drinking': _drinking.isEmpty ? '' : _drinking.first,
      'weed': _weed.isEmpty ? '' : _weed.first,
      'verifiedOnly': _verifiedOnly,
      'onlineNow': _onlineNow,
      'hasPrompts': _hasPrompts,
      'hasEventInterest': _eventInterest,
    };
    final saved = await _discoverApi.updateFilters(filters);
    if (!mounted) return;
    if (!saved.success) {
      showAmoraSnackBar(
        context,
        message: saved.message,
        tone: AmoraSnackBarTone.error,
      );
      return;
    }
    final navigator = Navigator.of(context);
    appliedProfilePreferenceFilters.value = ProfilePreferenceFilterState(
      hometowns: Set<String>.unmodifiable(_hometowns),
      qualities: Set<String>.unmodifiable(_qualities),
      pronouns: Set<String>.unmodifiable(_pronouns),
      sexualities: Set<String>.unmodifiable(_sexualities),
      preferredTalkingHours: Set<String>.unmodifiable(_preferredTalkingHours),
      loveLanguages: Set<String>.unmodifiable(_loveLanguages),
      communicationStyles: Set<CommunicationStyle>.unmodifiable(
        _communicationStyles,
      ),
    );
    showAmoraSnackBar(context, message: 'Filters applied');
    if (navigator.canPop()) {
      navigator.pop(true);
    } else {
      navigator.pushReplacementNamed(BrowseGridScreen.routeName);
    }
  }
}

class _FiltersHeader extends StatelessWidget {
  const _FiltersHeader({required this.onBack, required this.onReset});

  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.tertiary.withValues(alpha: .78)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AmoraHeaderBackButton(
              key: const ValueKey('filters-back-button'),
              onPressed: onBack,
            ),
            const SizedBox(width: AmoraHeaderTokens.backTitleGap),
            const Expanded(
              child: AmoraScreenTitle(
                title: 'Filters',
                subtitle: 'Refine who appears in Discover',
              ),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              key: const ValueKey('filters-header-reset'),
              onPressed: onReset,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                minimumSize: const Size(72, 48),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reset', maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedFiltersSummary extends StatelessWidget {
  const _SelectedFiltersSummary({
    required this.preferences,
    required this.onShowAll,
  });

  final List<_ActivePreference> preferences;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final count = preferences.length;
    final visible = preferences
        .take(visiblePreferenceChipLimit)
        .toList(growable: false);
    final remainingCount = count > visiblePreferenceChipLimit
        ? count - visiblePreferenceChipLimit
        : 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.secondary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: AmoraSpacing.space8),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AmoraMotion.fast,
                    child: Text(
                      '$count ${count == 1 ? 'preference' : 'preferences'} selected',
                      key: ValueKey(count),
                      style: AmoraTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Your Discover feed will prioritize profiles that match these choices.',
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.text.withValues(alpha: .72),
              ),
            ),
            if (visible.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final preview in visible)
                    _SelectedPreview(
                      key: ValueKey('selected-preference-${preview.label}'),
                      label: preview.label,
                    ),
                  if (remainingCount > 0)
                    _SelectedPreview(
                      key: const ValueKey('selected-preferences-more'),
                      label: '+$remainingCount more',
                      semanticLabel:
                          'Show $remainingCount more selected filters',
                      onTap: onShowAll,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedPreview extends StatelessWidget {
  const _SelectedPreview({
    super.key,
    required this.label,
    this.semanticLabel,
    this.onTap,
  });

  final String label;
  final String? semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secondary.withValues(alpha: .35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AmoraTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Center(widthFactor: 1, child: chip),
    );
    if (onTap case final callback?) {
      return Semantics(
        button: true,
        label: semanticLabel ?? label,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: callback,
            borderRadius: BorderRadius.circular(18),
            child: content,
          ),
        ),
      );
    }
    return content;
  }
}

class _SelectedPreferencesSheet extends StatelessWidget {
  const _SelectedPreferencesSheet({
    required this.preferences,
    required this.onClose,
  });

  final List<_ActivePreference> preferences;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<String>>{};
    for (final preference in preferences) {
      grouped.putIfAbsent(preference.category, () => []).add(preference.label);
    }
    final height = (MediaQuery.sizeOf(context).height * .72).clamp(
      360.0,
      620.0,
    );
    return Material(
      key: const ValueKey('selected-preferences-sheet'),
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Preferences',
                            style: AmoraTextStyles.bottomSheetTitle.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${preferences.length} active choices',
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.text.withValues(alpha: .66),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('selected-preferences-close'),
                      tooltip: 'Close selected preferences',
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.tertiary),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: grouped.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AmoraSpacing.space16),
                  itemBuilder: (context, index) {
                    final entry = grouped.entries.elementAt(index);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: AmoraTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Wrap(
                          spacing: AmoraSpacing.space8,
                          runSpacing: AmoraSpacing.space8,
                          children: [
                            for (final label in entry.value)
                              _SelectedPreview(label: label),
                          ],
                        ),
                      ],
                    );
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

class _ActivePreference {
  const _ActivePreference({required this.category, required this.label});

  final String category;
  final String label;
}

class _FilterSearchField extends StatelessWidget {
  const _FilterSearchField({
    required this.controller,
    required this.hasQuery,
    required this.noMatch,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasQuery;
  final bool noMatch;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('filters-search-field'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search filters',
        helperText: noMatch ? 'No matching filter section' : null,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.secondary,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                tooltip: 'Clear filter search',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterCategoryNav extends StatelessWidget {
  const _FilterCategoryNav({required this.active, required this.onSelected});

  final _FilterCategory active;
  final ValueChanged<_FilterCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('filters-category-navigation'),
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _FilterCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final category = _FilterCategory.values[index];
          final selected = category == active;
          return _CategoryChip(
            key: ValueKey('filters-category-${category.label}'),
            category: category,
            selected: selected,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final _FilterCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.tertiary,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: AnimatedPadding(
          duration: AmoraMotion.fast,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 17,
                color: selected ? AppColors.surface : AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.surface : AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableFilterSection extends StatelessWidget {
  const _ExpandableFilterSection({
    super.key,
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.selectedCount,
    required this.expanded,
    required this.highlighted,
    required this.onToggle,
    required this.child,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String summary;
  final int selectedCount;
  final bool expanded;
  final bool highlighted;
  final ValueChanged<String> onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: ValueKey('filters-section-$id'),
      duration: AmoraMotion.standard,
      curve: AmoraMotion.curve,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? AppColors.secondary : AppColors.tertiary,
          width: highlighted ? 1.6 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: .16),
                  blurRadius: 22,
                  spreadRadius: -7,
                ),
              ]
            : AmoraShadows.level1,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              key: ValueKey('filters-section-toggle-$id'),
              onTap: () => onToggle(id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 76),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: .36),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 21),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              style: AmoraTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              expanded ? subtitle : summary,
                              maxLines: expanded ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: AmoraTextStyles.bodySmall.copyWith(
                                color: AppColors.text.withValues(alpha: .65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selectedCount > 0) ...[
                        const SizedBox(width: 7),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              '$selectedCount',
                              style: AmoraTextStyles.labelSmall.copyWith(
                                color: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 3),
                      AnimatedRotation(
                        turns: expanded ? .5 : 0,
                        duration: AmoraMotion.fast,
                        child: const Icon(
                          Icons.expand_more_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: AmoraMotion.standard,
              firstCurve: AmoraMotion.curve,
              secondCurve: AmoraMotion.curve,
              sizeCurve: AmoraMotion.curve,
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.tertiary.withValues(alpha: .62),
                    ),
                  ),
                ),
                child: Padding(padding: const EdgeInsets.all(16), child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700 && children.length == 2) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children.first),
              const SizedBox(width: 18),
              Expanded(child: children.last),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 18),
              children[index],
            ],
          ],
        );
      },
    );
  }
}

class _ResponsiveTriple extends StatelessWidget {
  const _ResponsiveTriple({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(width: 18),
                Expanded(child: children[index]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) const SizedBox(height: 18),
              children[index],
            ],
          ],
        );
      },
    );
  }
}

class _ControlBlock extends StatelessWidget {
  const _ControlBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.description,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: AmoraTextStyles.titleSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (description case final text?) ...[
          const SizedBox(height: 3),
          Text(
            text,
            style: AmoraTextStyles.bodySmall.copyWith(
              color: AppColors.text.withValues(alpha: .62),
            ),
          ),
        ],
        const SizedBox(height: 11),
        child,
      ],
    );
  }
}

class _RangeControl extends StatelessWidget {
  const _RangeControl({
    required this.icon,
    required this.title,
    required this.value,
    required this.child,
    this.emoji,
  });

  final IconData icon;
  final String? emoji;
  final String title;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _ControlBlock(
      icon: icon,
      title: title,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _ValuePill(emoji: emoji, value: value),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ValueSliderControl extends StatelessWidget {
  const _ValueSliderControl({
    required this.icon,
    required this.title,
    required this.value,
    required this.current,
    required this.min,
    required this.max,
    required this.onChanged,
    this.emoji,
    this.description,
    this.divisions,
    this.infoTooltip,
  });

  final IconData icon;
  final String? emoji;
  final String title;
  final String value;
  final String? description;
  final double current;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final String? infoTooltip;

  @override
  Widget build(BuildContext context) {
    return _ControlBlock(
      icon: icon,
      title: title,
      description: description,
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                child: _ValuePill(emoji: emoji, value: value),
              ),
              if (infoTooltip case final tooltip?) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: tooltip,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('About AI match scores'),
                      content: Text(tooltip),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondary,
                    size: 19,
                  ),
                ),
              ],
            ],
          ),
          Slider(
            value: current,
            min: min,
            max: max,
            divisions: divisions,
            label: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.value, this.emoji});

  final String value;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji case final emojiValue?) ...[
              Text(emojiValue, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
    this.icon,
    this.emojiFor,
  });

  final List<String> options;
  final Set<String> selected;
  final IconData? icon;
  final String? Function(String option)? emojiFor;
  final void Function(Set<String> selected, String option) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          _PremiumFilterChip(
            key: ValueKey('filter-option-$option'),
            label: option,
            selected: selected.contains(option),
            icon: icon,
            emoji: emojiFor?.call(option),
            onTap: () => onToggle(selected, option),
          ),
      ],
    );
  }
}

class _HeightFilterEntry extends StatelessWidget {
  const _HeightFilterEntry({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Minimum height, $value',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          key: const ValueKey('filters-height-picker'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AmoraSpacing.space16,
              vertical: AmoraSpacing.space12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.tertiary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    key: const ValueKey('filters-height-summary'),
                    style: AmoraTextStyles.titleSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumFilterChip extends StatelessWidget {
  const _PremiumFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: selected,
      label: '$label, ${selected ? 'selected' : 'not selected'}',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: AnimatedContainer(
            duration: AmoraMotion.fast,
            curve: AmoraMotion.curve,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.tertiary,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji case final value?)
                  Text(value, style: const TextStyle(fontSize: 16))
                else if (icon case final value?)
                  Icon(
                    value,
                    size: 17,
                    color: selected ? AppColors.surface : AppColors.secondary,
                  ),
                if (emoji != null || icon != null) const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AmoraTextStyles.labelMedium.copyWith(
                      color: selected ? AppColors.surface : AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 16,
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

class _ResponsiveSwitchGrid extends StatelessWidget {
  const _ResponsiveSwitchGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 700;
        final width = twoColumns
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _FilterSwitchTile extends StatelessWidget {
  const _FilterSwitchTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: title,
      child: AnimatedContainer(
        duration: AmoraMotion.fast,
        constraints: const BoxConstraints(minHeight: 82),
        decoration: BoxDecoration(
          color: value
              ? AppColors.tertiary.withValues(alpha: .28)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? AppColors.secondary : AppColors.tertiary,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: SwitchListTile(
            value: value,
            onChanged: onChanged,
            contentPadding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
            secondary: Icon(icon, color: AppColors.primary, size: 22),
            title: Text(
              title,
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            subtitle: Text(
              description,
              maxLines: 2,
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.text.withValues(alpha: .64),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSearchField extends StatelessWidget {
  const _CompactSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.secondary,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.4),
        ),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppColors.secondary,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AmoraTextStyles.bodySmall)),
        ],
      ),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Divider(
        height: 1,
        color: AppColors.tertiary.withValues(alpha: .62),
      ),
    );
  }
}

class _StickyFiltersActionBar extends StatelessWidget {
  const _StickyFiltersActionBar({
    required this.horizontalPadding,
    required this.onReset,
    required this.onApply,
  });

  final double horizontalPadding;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .96),
        border: Border(
          top: BorderSide(color: AppColors.tertiary.withValues(alpha: .7)),
        ),
        boxShadow: AmoraShadows.bottomSheet,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          10,
          horizontalPadding,
          12,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 35,
              child: _FilterActionButton(
                key: const ValueKey('filters-bottom-reset'),
                label: 'Reset',
                icon: Icons.refresh_rounded,
                outlined: true,
                onPressed: onReset,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 65,
              child: _FilterActionButton(
                key: const ValueKey('filters-apply-button'),
                label: 'Apply Filters',
                icon: Icons.check_rounded,
                onPressed: onApply,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
    if (outlined) {
      return OutlinedButton(onPressed: onPressed, style: style, child: child);
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

class _SearchTarget {
  const _SearchTarget({required this.id, required this.key, this.category});

  final String id;
  final GlobalKey? key;
  final _FilterCategory? category;
}

enum _FilterCategory {
  basics('Basics', Icons.tune_rounded, _GroupIds.basics),
  intentions(
    'Intentions',
    Icons.favorite_outline_rounded,
    _GroupIds.intentions,
  ),
  lifestyle('Lifestyle', Icons.auto_awesome_rounded, _GroupIds.lifestyle),
  identity('Identity', Icons.person_outline_rounded, _GroupIds.identity),
  compatibility(
    'Compatibility',
    Icons.favorite_border_rounded,
    _GroupIds.compatibility,
  ),
  habits('Habits', Icons.local_cafe_outlined, _GroupIds.habits),
  trust('AI & Trust', Icons.verified_user_outlined, _GroupIds.trust);

  const _FilterCategory(this.label, this.icon, this.groupId);

  final String label;
  final IconData icon;
  final String groupId;
}

abstract final class _GroupIds {
  static const basics = 'basics';
  static const intentions = 'intentions';
  static const lifestyle = 'lifestyle';
  static const career = 'career';
  static const identity = 'identity';
  static const compatibility = 'compatibility';
  static const habits = 'habits';
  static const trust = 'trust';
}

const _noSearchMatch = '__no_match__';

const _lifestyleEmoji = <String, String>{
  'Travel Companion': '✈️',
  'Adventure Seeker': '🏔️',
  'Fitness Partner': '💪',
  'Foodie Partner': '🍜',
  'Coffee Dates': '☕',
  'Pet Lover': '🐾',
  'Movie Nights': '🎬',
  'Music Lover': '🎵',
  'Road Trip Buddy': '🚗',
  'Book Lover': '📚',
  'Creative Soul': '🎨',
  'Tech Enthusiast': '💻',
  'Wellness & Yoga': '🧘',
  'Volunteer & Community': '❤️',
};

const _communityList = [
  'Open to all',
  'Gujarati',
  'Jain',
  'Patel',
  'Brahmin',
  'Vaishnav',
  'Other',
];
