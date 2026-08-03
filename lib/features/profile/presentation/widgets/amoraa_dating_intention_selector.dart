import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
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
    return AmoraaSelectField<String>(
      key: const ValueKey('profile-dating-intention-field'),
      label: 'Dating Intention',
      value: selected.isEmpty ? null : selected,
      hintText: 'Choose your intention',
      supportingText: 'Select one primary relationship goal.',
      prefixIcon: Icons.favorite_outline_rounded,
      isRequired: true,
      validator: (current) => current == null || current.isEmpty
          ? 'Choose a dating intention'
          : null,
      options: [
        for (final intention in ProfileFormOptions.datingIntentions)
          AmoraaSelectOption<String>(
            value: intention,
            label: intention,
            description:
                ProfileFormOptions.datingIntentionDescriptions[intention],
            icon: _iconFor(intention),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  static IconData _iconFor(String intention) => switch (intention) {
    'Marriage Minded' => Icons.diamond_rounded,
    'Long-Term Relationship' => Icons.favorite_rounded,
    'Meaningful Dating' => Icons.local_cafe_rounded,
    'Exploring Possibilities' => Icons.auto_awesome_rounded,
    'Friendship First' => Icons.handshake_rounded,
    'Casual Connection' => Icons.celebration_rounded,
    _ => Icons.favorite_outline_rounded,
  };
}
