import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_language_selector.dart';
import 'package:amora_ai/features/profile/presentation/widgets/amoraa_profile_prompt_selector.dart';
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
  late Set<String> _interests;
  late List<String> _retiredInterests;
  late Map<String, String> _lifestyle;
  late Map<String, TextEditingController> _promptControllers;

  @override
  void initState() {
    super.initState();
    final profile = LocalProfileRepository.instance.profile;
    _interests = Set<String>.of(
      ProfileInterestPolicy.visible(profile.interests),
    );
    _retiredInterests = ProfileInterestPolicy.retired(profile.interests);
    _lifestyle = ProfileFormOptions.normalizeLifestyleSelections(
      profile.lifestyle,
    );
    final existingPrompts = profile.prompts.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    final promptTitles = existingPrompts.isEmpty
        ? <String>[ProfileFormOptions.promptTitles.first]
        : existingPrompts.map((entry) => entry.key);
    _promptControllers = {
      for (final title in promptTitles)
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
    ProfileSection.prompts => _promptControllers.values.any(
      (controller) => controller.text.trim().isNotEmpty,
    ),
    ProfileSection.lifestyle => true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AmoraAppBar(
        title: _title,
        onBack: () => Navigator.of(context).maybePop(),
        maxContentWidth: 680,
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
      'Complete at least one original prompt so your profile has a natural conversation starter.',
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
        for (final group in ProfileFormOptions.interestGroups.entries) ...[
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
                  showCheckmark: false,
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
                AmoraaProfilePromptSelector(
                  key: ValueKey('profile-prompt-selector-${entry.key}'),
                  selectedPrompt: entry.key,
                  options: {
                    ...ProfileFormOptions.promptTitles,
                    ..._promptControllers.keys,
                  },
                  onSelected: (value) {
                    if (value != entry.key) {
                      _changePromptTitle(entry.key, value);
                    }
                  },
                ),
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
        for (final entry in ProfileFormOptions.allLifestyleOptions.entries) ...[
          if (entry.key == 'Religion') ...[
            PremiumCard(
              radius: 24,
              padding: const EdgeInsets.all(16),
              child: AmoraaLanguageSelector(
                selectedLanguages: ProfileFormOptions.parseLanguages(
                  _lifestyle['Languages'],
                ),
                onChanged: (languages) => setState(() {
                  final stored = ProfileFormOptions.serializeLanguages(
                    languages,
                  );
                  stored.isEmpty
                      ? _lifestyle.remove('Languages')
                      : _lifestyle['Languages'] = stored;
                }),
              ),
            ),
            const SizedBox(height: 12),
          ],
          PremiumCard(
            radius: 24,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _lifestyleIcon(entry.key),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: AmoraTextStyles.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            _lifestyle[entry.key] ?? 'Tap one to share',
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _lifestyle.containsKey(entry.key)
                          ? const Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('selected'),
                              color: AppColors.success,
                            )
                          : const Icon(
                              Icons.add_circle_outline_rounded,
                              key: ValueKey('empty'),
                              color: AppColors.textMuted,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in entry.value)
                      _LifestyleOption(
                        label: option,
                        selected: _lifestyle[entry.key] == option,
                        onTap: () => setState(() {
                          if (_lifestyle[entry.key] == option) {
                            _lifestyle.remove(entry.key);
                          } else {
                            _lifestyle[entry.key] = option;
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  IconData _lifestyleIcon(String key) => switch (key) {
    'Height' => Icons.height_rounded,
    'Languages' => Icons.translate_rounded,
    'Religion' => Icons.diversity_3_rounded,
    'Drinking' => Icons.local_bar_outlined,
    'Smoking' => Icons.smoke_free_rounded,
    'Exercise' => Icons.fitness_center_rounded,
    'Food preference' => Icons.restaurant_rounded,
    'Pets' => Icons.pets_rounded,
    _ => Icons.bedtime_outlined,
  };

  Future<void> _save() async {
    final repository = LocalProfileRepository.instance;
    final profile = repository.profile;
    try {
      await repository.savePersisted(
        profile.copyWith(
          interests: <String>[..._interests, ..._retiredInterests],
          prompts: {
            for (final entry in _promptControllers.entries)
              if (entry.value.text.trim().isNotEmpty)
                entry.key: entry.value.text.trim(),
          },
          lifestyle: _lifestyle,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save profile changes. Please try again.'),
          ),
        );
      }
    }
  }

  void _changePromptTitle(String previous, String next) {
    if (_promptControllers.containsKey(next)) return;
    final controller = _promptControllers[previous];
    if (controller == null) return;
    setState(() {
      final entries = _promptControllers.entries
          .map(
            (entry) =>
                MapEntry(entry.key == previous ? next : entry.key, entry.value),
          )
          .toList(growable: false);
      _promptControllers = Map<String, TextEditingController>.fromEntries(
        entries,
      );
    });
  }
}

class _LifestyleOption extends StatelessWidget {
  const _LifestyleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .18),
                      blurRadius: 14,
                      spreadRadius: -6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        key: ValueKey(true),
                        size: 18,
                        color: AppColors.surface,
                      )
                    : const SizedBox.shrink(key: ValueKey(false)),
              ),
              if (selected) const SizedBox(width: 6),
              Text(
                label,
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: selected ? AppColors.surface : AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
