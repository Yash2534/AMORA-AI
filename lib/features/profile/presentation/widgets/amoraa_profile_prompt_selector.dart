import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

Future<void> showAmoraaProfilePromptPicker(
  BuildContext context, {
  required String selectedPrompt,
  required Iterable<String> options,
  required ValueChanged<String> onSelected,
}) {
  final available = <String>{...options};
  if (selectedPrompt.isNotEmpty) available.add(selectedPrompt);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _PromptPickerSheet(
      selectedPrompt: selectedPrompt,
      options: available.toList(growable: false),
      onSelected: (value) {
        onSelected(value);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class AmoraaProfilePromptSelector extends StatelessWidget {
  const AmoraaProfilePromptSelector({
    super.key,
    required this.selectedPrompt,
    required this.options,
    required this.onSelected,
  });

  final String selectedPrompt;
  final Iterable<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selectedPrompt.isNotEmpty,
      label: selectedPrompt.isEmpty
          ? 'Choose a profile prompt'
          : 'Selected profile prompt, $selectedPrompt',
      child: Material(
        key: const ValueKey('profile-prompt-card-selector'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.tertiary),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showAmoraaProfilePromptPicker(
            context,
            selectedPrompt: selectedPrompt,
            options: options,
            onSelected: onSelected,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(AmoraSpacing.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: AmoraSpacing.minimumTouchTarget,
                    height: AmoraSpacing.minimumTouchTarget,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.format_quote_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AmoraSpacing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPrompt.isEmpty
                              ? 'Choose a prompt'
                              : selectedPrompt,
                          style: AmoraTextStyles.titleMedium,
                        ),
                        const SizedBox(height: AmoraSpacing.space4),
                        Text(
                          'Tap to browse prompt cards',
                          style: AmoraTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptPickerSheet extends StatefulWidget {
  const _PromptPickerSheet({
    required this.selectedPrompt,
    required this.options,
    required this.onSelected,
  });

  final String selectedPrompt;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  State<_PromptPickerSheet> createState() => _PromptPickerSheetState();
}

class _PromptPickerSheetState extends State<_PromptPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.options
        .where((prompt) {
          return prompt.toLowerCase().contains(_query.toLowerCase().trim());
        })
        .toList(growable: false);
    return FractionallySizedBox(
      heightFactor: .78,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AmoraSpacing.space20,
          AmoraSpacing.space16,
          AmoraSpacing.space20,
          AmoraSpacing.space16 + MediaQuery.viewInsetsOf(context).bottom,
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
            Text('Choose a prompt', style: AmoraTextStyles.headlineSmall),
            const SizedBox(height: AmoraSpacing.space16),
            TextField(
              key: const ValueKey('prompt-search-field'),
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search prompts',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AmoraSpacing.space12),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No prompts found'))
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AmoraSpacing.space8),
                      itemBuilder: (context, index) {
                        final prompt = visible[index];
                        final selected = prompt == widget.selectedPrompt;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label: 'Profile prompt, $prompt',
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
                              key: ValueKey('prompt-option-$prompt'),
                              onTap: () => widget.onSelected(prompt),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: AmoraSpacing.minimumTouchTarget,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AmoraSpacing.space16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.format_quote_rounded,
                                        color: AppColors.secondary,
                                      ),
                                      const SizedBox(
                                        width: AmoraSpacing.space12,
                                      ),
                                      Expanded(
                                        child: Text(
                                          prompt,
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
          ],
        ),
      ),
    );
  }
}
