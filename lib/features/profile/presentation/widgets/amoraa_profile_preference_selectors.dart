import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmoraaPersonalPreferencesEditor extends StatelessWidget {
  const AmoraaPersonalPreferencesEditor({super.key, required this.controller});

  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmoraaSearchableSelect<String>(
          key: const ValueKey('profile-hometown-selector'),
          label: 'Hometown',
          value: controller.hometown.isEmpty ? null : controller.hometown,
          hintText: 'Select hometown',
          searchHint: 'Find your hometown',
          searchSemanticLabel: 'Search Gujarat hometowns',
          supportingText: 'Gujarat locations only',
          prefixIcon: Icons.home_work_outlined,
          allowClear: true,
          options: [
            for (final option
                in ProfileFormOptions.preferenceOptions[ProfilePreferenceType
                    .hometown]!)
              AmoraaSelectOption(
                value: option.id,
                label: option.label,
                description: option.description,
              ),
          ],
          onChanged: controller.setHometown,
        ),
        const SizedBox(height: AmoraSpacing.space16),
        AmoraaPronounSelector(
          selected: controller.pronouns,
          onChanged: controller.setPronouns,
        ),
        const SizedBox(height: AmoraSpacing.space16),
        AmoraaSelectField<String>(
          key: const ValueKey('profile-sexuality-selector'),
          label: 'Sexuality',
          value: controller.sexuality.isEmpty ? null : controller.sexuality,
          hintText: 'Select sexuality',
          supportingText: 'Choose one option',
          prefixIcon: Icons.favorite_outline_rounded,
          allowClear: true,
          options: [
            for (final option
                in ProfileFormOptions.preferenceOptions[ProfilePreferenceType
                    .sexuality]!)
              AmoraaSelectOption(value: option.id, label: option.label),
          ],
          onChanged: controller.setSexuality,
        ),
      ],
    );
  }
}

class AmoraaConnectionPreferencesEditor extends StatelessWidget {
  const AmoraaConnectionPreferencesEditor({
    super.key,
    required this.controller,
  });

  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ice Breaker', style: AmoraTextStyles.titleMedium),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          'Share one dating non-negotiable that matters to you.',
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Semantics(
          textField: true,
          label: 'Ice Breaker',
          hint: 'Share one dating non-negotiable that matters to you.',
          child: TextFormField(
            key: const ValueKey('profile-ice-breaker-field'),
            controller: controller.iceBreaker,
            minLines: 3,
            maxLines: 5,
            maxLength: 180,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            inputFormatters: [LengthLimitingTextInputFormatter(180)],
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => Semantics(
                  liveRegion: true,
                  label: '$currentLength of 180 characters',
                  child: Text(
                    '$currentLength/180',
                    key: const ValueKey('profile-ice-breaker-counter'),
                    style: AmoraTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            decoration: InputDecoration(
              hintText: 'What’s one thing you won’t compromise on?',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 54),
                child: Icon(Icons.format_quote_rounded),
              ),
              alignLabelWithHint: true,
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space20),
        AmoraaSelectField<CommunicationStyle>(
          key: const ValueKey('profile-communication-style-selector'),
          label: 'Communication Style',
          value: controller.communicationStyle,
          hintText: 'Select your communication style',
          supportingText: 'Choose the way you like to stay connected.',
          prefixIcon: Icons.forum_outlined,
          options: [
            for (final style in CommunicationStyle.values)
              AmoraaSelectOption(value: style, label: style.label),
          ],
          onChanged: controller.setCommunicationStyle,
        ),
        const SizedBox(height: AmoraSpacing.space24),
        Text('Qualities', style: AmoraTextStyles.titleMedium),
        const SizedBox(height: AmoraSpacing.space4),
        Text(
          'Choose up to ${ProfileFormOptions.maximumQualities} qualities you value in another person.',
          style: AmoraTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space8),
        Semantics(
          liveRegion: true,
          label:
              "You've chosen ${controller.valuedQualities.length} out of ${ProfileFormOptions.maximumQualities} options.",
          child: Text(
            "You've chosen ${controller.valuedQualities.length} out of ${ProfileFormOptions.maximumQualities} options.",
            key: const ValueKey('qualities-selection-count'),
            style: AmoraTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        AmoraaMultiSelectChipGroup(
          key: const ValueKey('profile-qualities-selector'),
          keyPrefix: 'quality',
          options: ProfileFormOptions.qualities,
          selected: controller.valuedQualities,
          maximumSelections: ProfileFormOptions.maximumQualities,
          limitMessage:
              'You can select up to ${ProfileFormOptions.maximumQualities} qualities.',
          onChanged: controller.setValuedQualities,
        ),
        const SizedBox(height: AmoraSpacing.space24),
        Text('Preferred Hours for Talking', style: AmoraTextStyles.titleMedium),
        const SizedBox(height: AmoraSpacing.space8),
        AmoraaMultiSelectChipGroup(
          key: const ValueKey('profile-talking-hours-selector'),
          keyPrefix: 'talking-hour',
          options: ProfileFormOptions.preferredTalkingHours,
          selected: controller.preferredTalkingHours,
          descriptions: ProfileFormOptions.preferredTalkingHourDescriptions,
          leadingIcon: Icons.schedule_rounded,
          cardStyle: true,
          onChanged: controller.setPreferredTalkingHours,
        ),
        const SizedBox(height: AmoraSpacing.space24),
        Text('Love Languages', style: AmoraTextStyles.titleMedium),
        const SizedBox(height: AmoraSpacing.space8),
        AmoraaMultiSelectChipGroup(
          key: const ValueKey('profile-love-languages-selector'),
          keyPrefix: 'love-language',
          options: ProfileFormOptions.loveLanguages,
          selected: controller.loveLanguages,
          iconFor: loveLanguageIcon,
          cardStyle: true,
          onChanged: controller.setLoveLanguages,
        ),
      ],
    );
  }
}

IconData loveLanguageIcon(String value) => switch (value) {
  'Words of Affirmation' => Icons.format_quote_rounded,
  'Quality Time' => Icons.schedule_rounded,
  'Acts of Service' => Icons.volunteer_activism_rounded,
  'Receiving Gifts' => Icons.card_giftcard_rounded,
  'Physical Touch' => Icons.connect_without_contact_rounded,
  _ => Icons.favorite_outline_rounded,
};

class AmoraaMultiSelectChipGroup extends StatelessWidget {
  const AmoraaMultiSelectChipGroup({
    super.key,
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.maximumSelections,
    this.limitMessage,
    this.descriptions = const <String, String>{},
    this.leadingIcon,
    this.iconFor,
    this.cardStyle = false,
  });

  final String keyPrefix;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final int? maximumSelections;
  final String? limitMessage;
  final Map<String, String> descriptions;
  final IconData? leadingIcon;
  final IconData Function(String value)? iconFor;
  final bool cardStyle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: [
        for (final option in options)
          _PreferenceChoice(
            key: ValueKey('$keyPrefix-option-$option'),
            label: option,
            description: descriptions[option],
            icon: iconFor?.call(option) ?? leadingIcon,
            selected: selected.contains(option),
            cardStyle: cardStyle,
            onTap: () => _toggle(context, option),
          ),
      ],
    );
  }

  void _toggle(BuildContext context, String option) {
    final next = Set<String>.of(selected);
    if (!next.remove(option)) {
      if (maximumSelections != null && next.length >= maximumSelections!) {
        final message =
            limitMessage ?? 'You can select up to $maximumSelections options.';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        return;
      }
      next.add(option);
    }
    onChanged(next);
  }
}

class _PreferenceChoice extends StatelessWidget {
  const _PreferenceChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.cardStyle,
    required this.onTap,
    this.description,
    this.icon,
  });

  final String label;
  final String? description;
  final IconData? icon;
  final bool selected;
  final bool cardStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: AmoraSpacing.space8),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AmoraTextStyles.labelLarge.copyWith(
                  color: AppColors.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (description case final text?) ...[
                const SizedBox(height: 2),
                Text(
                  text,
                  style: AmoraTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.add_circle_outline,
          size: 20,
          color: selected ? AppColors.secondary : AppColors.primary,
        ),
      ],
    );
    return Semantics(
      button: true,
      toggled: selected,
      label: '$label, ${selected ? 'selected' : 'not selected'}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          minHeight: 48,
          maxWidth: cardStyle ? 260 : double.infinity,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tertiary.withValues(alpha: .72)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(cardStyle ? 18 : 999),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.tertiary,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(cardStyle ? 18 : 999),
          child: InkWell(
            borderRadius: BorderRadius.circular(cardStyle ? 18 : 999),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AmoraSpacing.space12,
                vertical: cardStyle ? AmoraSpacing.space12 : 10,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class AmoraaPronounSelector extends StatelessWidget {
  const AmoraaPronounSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Pronouns, ${selected.isEmpty ? 'none selected' : selected.join(', ')}',
      child: OutlinedButton(
        key: const ValueKey('profile-pronouns-selector'),
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          minimumSize: const Size.fromHeight(64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: () => _open(context),
        child: Row(
          children: [
            const Icon(Icons.badge_outlined),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pronouns', style: AmoraTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(
                    selected.isEmpty ? 'Select up to 4' : selected.join(' · '),
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: selected.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) => _PronounSheet(initial: selected),
    );
    if (result != null) onChanged(result);
  }
}

class _PronounSheet extends StatefulWidget {
  const _PronounSheet({required this.initial});

  final Set<String> initial;

  @override
  State<_PronounSheet> createState() => _PronounSheetState();
}

class _PronounSheetState extends State<_PronounSheet> {
  late final Set<String> _selected = Set<String>.of(widget.initial);
  String? _limitMessage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        key: const ValueKey('pronoun-selector-sheet'),
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .82,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pronouns',
                            style: AmoraTextStyles.headlineSmall,
                          ),
                          Text(
                            'Select up to 4',
                            style: AmoraTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close pronoun selector',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: AmoraSpacing.space12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in ProfileFormOptions.pronouns)
                        if (_selected.contains(value))
                          InputChip(
                            key: ValueKey('selected-pronoun-$value'),
                            label: Text(value),
                            onDeleted: () => setState(() {
                              _selected.remove(value);
                              _limitMessage = null;
                            }),
                          ),
                    ],
                  ),
                ],
                if (_limitMessage case final message?) ...[
                  const SizedBox(height: AmoraSpacing.space8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      message,
                      key: const ValueKey('pronoun-limit-message'),
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AmoraSpacing.space8),
                Expanded(
                  child: ListView(
                    children: [
                      for (final value in ProfileFormOptions.pronouns)
                        CheckboxListTile(
                          key: ValueKey('pronoun-option-$value'),
                          value: _selected.contains(value),
                          title: Text(value),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (_) => _toggle(value),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                FilledButton(
                  key: const ValueKey('pronoun-selector-done'),
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text('Done (${_selected.length})'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(String value) {
    setState(() {
      if (_selected.remove(value)) {
        _limitMessage = null;
      } else if (_selected.length >= ProfileFormOptions.maximumPronouns) {
        _limitMessage = 'You can select up to 4 pronouns.';
      } else {
        _selected.add(value);
        _limitMessage = null;
      }
    });
  }
}
