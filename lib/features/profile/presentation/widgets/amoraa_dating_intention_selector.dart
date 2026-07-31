import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/material.dart';

class AmoraaDatingIntentionSelector extends StatelessWidget {
  const AmoraaDatingIntentionSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = ProfileFormOptions.normalizeDatingIntention(value);
    return FormField<String>(
      key: const ValueKey('profile-dating-intention-field'),
      initialValue: selected,
      validator: (current) => current == null || current.isEmpty
          ? 'Choose a dating intention'
          : null,
      builder: (field) {
        final current = field.value ?? selected;
        final description =
            ProfileFormOptions.datingIntentionDescriptions[current];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dating Intention', style: AmoraTextStyles.titleMedium),
            const SizedBox(height: AmoraSpacing.space8),
            Semantics(
              button: true,
              selected: current.isNotEmpty,
              label: current.isEmpty
                  ? 'Choose a dating intention'
                  : 'Dating intention, $current',
              child: Material(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: field.hasError
                        ? AppColors.primary
                        : AppColors.tertiary,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final next = await _openPicker(context, current);
                    if (next == null) return;
                    field.didChange(next);
                    onChanged(next);
                  },
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
                            child: Icon(
                              _iconFor(current),
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: AmoraSpacing.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.isEmpty
                                      ? 'Choose your intention'
                                      : current,
                                  style: AmoraTextStyles.titleMedium,
                                ),
                                if (description != null) ...[
                                  const SizedBox(height: AmoraSpacing.space4),
                                  Text(
                                    description,
                                    style: AmoraTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: AmoraSpacing.space12,
                  top: AmoraSpacing.space8,
                ),
                child: Text(
                  field.errorText!,
                  style: AmoraTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<String?> _openPicker(BuildContext context, String selected) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: .86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space20,
                AmoraSpacing.space16,
                AmoraSpacing.space20,
                AmoraSpacing.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Text(
                    'Choose your dating intention',
                    style: AmoraTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: AmoraSpacing.space4),
                  Text(
                    'Select one primary relationship goal.',
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space4,
                  AmoraSpacing.space20,
                  AmoraSpacing.space24,
                ),
                itemCount: ProfileFormOptions.datingIntentions.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AmoraSpacing.space8),
                itemBuilder: (context, index) {
                  final intention = ProfileFormOptions.datingIntentions[index];
                  final isSelected = intention == selected;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: '$intention dating intention',
                    child: Material(
                      color: isSelected
                          ? AppColors.background
                          : AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.tertiary,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: ValueKey('dating-intention-$intention'),
                        onTap: () => Navigator.of(context).pop(intention),
                        child: Padding(
                          padding: const EdgeInsets.all(AmoraSpacing.space16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconFor(intention),
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: AmoraSpacing.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      intention,
                                      style: AmoraTextStyles.titleMedium,
                                    ),
                                    const SizedBox(height: AmoraSpacing.space4),
                                    Text(
                                      ProfileFormOptions
                                          .datingIntentionDescriptions[intention]!,
                                      style: AmoraTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.textMuted,
                              ),
                            ],
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

  static IconData _iconFor(String intention) => switch (intention) {
    'Marriage Minded' => Icons.diamond_rounded,
    'Long-Term Relationship' => Icons.favorite_rounded,
    'Meaningful Dating' => Icons.local_cafe_rounded,
    'Exploring Possibilities' => Icons.auto_awesome_rounded,
    'Friendship First' => Icons.handshake_rounded,
    'Travel Companion' => Icons.flight_rounded,
    'Fun & Experiences' => Icons.celebration_rounded,
    _ => Icons.favorite_outline_rounded,
  };
}
