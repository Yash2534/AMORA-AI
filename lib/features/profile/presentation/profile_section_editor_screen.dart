import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ProfileSection { interests, prompts, lifestyle }

class ProfileSectionEditorScreen extends StatefulWidget {
  const ProfileSectionEditorScreen({super.key, required this.section});
  final ProfileSection section;

  @override
  State<ProfileSectionEditorScreen> createState() =>
      _ProfileSectionEditorScreenState();
}

class _ProfileSectionEditorScreenState
    extends State<ProfileSectionEditorScreen> {
  static const _interestGroups = <String, List<String>>{
    'Lifestyle': ['Coffee', 'Mindfulness', 'Volunteering', 'Reading'],
    'Food': ['Cooking', 'Cafes', 'Street food', 'Baking'],
    'Travel': ['Road trips', 'City breaks', 'Heritage walks', 'Beaches'],
    'Music': ['Live music', 'Indie', 'Classical', 'Bollywood'],
    'Fitness': ['Yoga', 'Running', 'Cycling', 'Hiking'],
    'Creativity': ['Photography', 'Design', 'Writing', 'Pottery'],
    'Technology': ['Flutter', 'Startups', 'Product design', 'Gaming'],
    'Nature & pets': ['Dogs', 'Cats', 'Gardening', 'Wildlife'],
  };
  static const _promptTitles = [
    'A perfect weekend for me is…',
    'The quickest way to my heart is…',
    'My ideal first date would be…',
  ];
  static const _lifestyleOptions = <String, List<String>>{
    'Drinking': ['Never', 'Sometimes', 'Socially'],
    'Smoking': ['No', 'Sometimes', 'Prefer not to say'],
    'Exercise': ['Daily', 'A few times a week', 'Occasionally'],
    'Food preference': ['Vegetarian', 'Vegan', 'Everything'],
    'Pets': ['Dog person', 'Cat person', 'Love all pets'],
    'Sleep habits': ['Early bird', 'Night owl', 'Flexible'],
  };

  late Set<String> _interests;
  late Map<String, String> _lifestyle;
  late Map<String, TextEditingController> _promptControllers;

  @override
  void initState() {
    super.initState();
    final profile = LocalProfileRepository.instance.profile;
    _interests = Set<String>.of(profile.interests);
    _lifestyle = Map<String, String>.of(profile.lifestyle);
    _promptControllers = {
      for (final title in _promptTitles)
        title: TextEditingController(text: profile.prompts[title] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final controller in _promptControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _title => switch (widget.section) {
    ProfileSection.interests => 'Interests',
    ProfileSection.prompts => 'Profile prompts',
    ProfileSection.lifestyle => 'Lifestyle',
  };

  bool get _canSave => switch (widget.section) {
    ProfileSection.interests =>
      _interests.length >= 5 && _interests.length <= 10,
    ProfileSection.prompts =>
      _promptControllers.values
              .where((controller) => controller.text.trim().isNotEmpty)
              .length >=
          3,
    ProfileSection.lifestyle => true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 680,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      _supporting,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    switch (widget.section) {
                      ProfileSection.interests => _buildInterests(),
                      ProfileSection.prompts => _buildPrompts(),
                      ProfileSection.lifestyle => _buildLifestyle(),
                    },
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: AppPrimaryButton(
                  label: 'Save ${_title.toLowerCase()}',
                  icon: Icons.check_rounded,
                  onPressed: _canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _supporting => switch (widget.section) {
    ProfileSection.interests =>
      'Choose 5–10 interests. Selected items include a check mark for accessible feedback.',
    ProfileSection.prompts =>
      'Complete three original prompts so your profile has natural conversation starters.',
    ProfileSection.lifestyle =>
      'Every answer is optional. Share only what feels comfortable.',
  };

  Widget _buildInterests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${_interests.length}/10 selected',
          style: AmoraTextStyles.labelLarge,
        ),
        const SizedBox(height: 16),
        for (final group in _interestGroups.entries) ...[
          Text(group.key, style: AmoraTextStyles.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in group.value)
                FilterChip(
                  label: Text(item),
                  selected: _interests.contains(item),
                  avatar: _interests.contains(item)
                      ? const Icon(Icons.check_rounded, size: 18)
                      : null,
                  onSelected: (selected) {
                    if (selected && _interests.length >= 10) return;
                    setState(
                      () => selected
                          ? _interests.add(item)
                          : _interests.remove(item),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildPrompts() {
    return Column(
      children: [
        for (final entry in _promptControllers.entries) ...[
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(entry.key, style: AmoraTextStyles.titleMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: entry.value,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 180,
                  inputFormatters: [LengthLimitingTextInputFormatter(180)],
                  decoration: const InputDecoration(
                    hintText: 'Write a specific, warm answer',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildLifestyle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in _lifestyleOptions.entries) ...[
          Text(entry.key, style: AmoraTextStyles.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in entry.value)
                ChoiceChip(
                  label: Text(option),
                  selected: _lifestyle[entry.key] == option,
                  onSelected: (selected) => setState(() {
                    selected
                        ? _lifestyle[entry.key] = option
                        : _lifestyle.remove(entry.key);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  void _save() {
    final repository = LocalProfileRepository.instance;
    final profile = repository.profile;
    repository.save(
      profile.copyWith(
        interests: _interests.toList(growable: false),
        prompts: {
          for (final entry in _promptControllers.entries)
            entry.key: entry.value.text.trim(),
        },
        lifestyle: _lifestyle,
      ),
    );
    Navigator.of(context).pop();
  }
}
