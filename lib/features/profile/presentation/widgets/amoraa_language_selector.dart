import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/material.dart';

class AmoraaLanguageSelector extends StatelessWidget {
  const AmoraaLanguageSelector({
    super.key,
    required this.selectedLanguages,
    required this.onChanged,
    this.showError = false,
  });

  final Set<String> selectedLanguages;
  final ValueChanged<Set<String>> onChanged;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final ordered = _orderedLanguages(selectedLanguages);
    return Column(
      key: const ValueKey('profile-language-selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Languages', style: AmoraTextStyles.titleMedium),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          'Select all languages you speak',
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        if (ordered.isEmpty)
          Text(
            'No languages selected',
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              for (final language in ordered)
                InputChip(
                  key: ValueKey('selected-language-$language'),
                  label: Text(language),
                  avatar: const Icon(Icons.translate_rounded, size: 18),
                  deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  deleteButtonTooltipMessage: 'Remove $language',
                  onDeleted: () {
                    onChanged(
                      Set<String>.of(selectedLanguages)..remove(language),
                    );
                  },
                ),
            ],
          ),
        const SizedBox(height: AmoraSpacing.space12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${ordered.length} selected',
                style: AmoraTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('add-languages-button'),
              onPressed: () => _openPicker(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add languages'),
            ),
          ],
        ),
        if (showError && ordered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AmoraSpacing.space4),
            child: Text(
              'Choose at least one language',
              style: AmoraTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LanguagePickerSheet(
        selectedLanguages: selectedLanguages,
        onChanged: onChanged,
      ),
    );
  }

  static List<String> _orderedLanguages(Iterable<String> values) {
    final remaining = values.toSet();
    return [
      for (final language in ProfileFormOptions.languageOptions)
        if (remaining.remove(language)) language,
      ...remaining.toList()..sort(),
    ];
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({
    required this.selectedLanguages,
    required this.onChanged,
  });

  final Set<String> selectedLanguages;
  final ValueChanged<Set<String>> onChanged;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.of(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final options =
        <String>{...ProfileFormOptions.languageOptions, ..._selected}
            .where((language) {
              return language.toLowerCase().contains(
                _query.toLowerCase().trim(),
              );
            })
            .toList(growable: false);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return FractionallySizedBox(
      heightFactor: .78,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AmoraSpacing.space20,
          AmoraSpacing.space16,
          AmoraSpacing.space20,
          AmoraSpacing.space16 + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.tertiary,
                  borderRadius: AmoraRadius.pillBorder,
                ),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            Text('Add languages', style: AmoraTextStyles.headlineSmall),
            const SizedBox(height: AmoraSpacing.space4),
            Text(
              '${_selected.length} selected',
              style: AmoraTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AmoraSpacing.space16),
            TextField(
              key: const ValueKey('language-search-field'),
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                labelText: 'Search languages',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Expanded(
              child: options.isEmpty
                  ? const Center(child: Text('No languages found'))
                  : ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final language = options[index];
                        final selected = _selected.contains(language);
                        return Semantics(
                          selected: selected,
                          button: true,
                          label: '$language language',
                          child: Material(
                            color: selected
                                ? AppColors.background
                                : AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.secondary
                                    : AppColors.tertiary,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('language-option-$language'),
                              onTap: () => _toggle(language),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: AmoraSpacing.minimumTouchTarget,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AmoraSpacing.space16,
                                    vertical: AmoraSpacing.space12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          language,
                                          style: AmoraTextStyles.titleMedium,
                                        ),
                                      ),
                                      Icon(
                                        selected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: selected
                                            ? AppColors.secondary
                                            : AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            FilledButton(
              key: const ValueKey('language-picker-done'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(String language) {
    setState(() {
      _selected.contains(language)
          ? _selected.remove(language)
          : _selected.add(language);
    });
    widget.onChanged(Set<String>.of(_selected));
  }
}
