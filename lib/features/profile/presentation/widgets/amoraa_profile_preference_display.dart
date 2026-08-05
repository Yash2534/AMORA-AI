import 'package:amora_ai/core/data/image_repository.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/material.dart';

class AmoraaProfilePreferenceDisplay extends StatelessWidget {
  const AmoraaProfilePreferenceDisplay({super.key, required this.profile});

  final DummyProfile profile;

  @override
  Widget build(BuildContext context) {
    final identity = <_PreferenceValue>[
      _PreferenceValue(
        Icons.badge_outlined,
        'Pronouns',
        _ordered(profile.pronouns, ProfileFormOptions.pronouns),
      ),
      _PreferenceValue(
        Icons.favorite_outline_rounded,
        'Sexuality',
        <String>{
          ProfileFormOptions.normalizeSexuality(profile.sexuality),
        }.where((value) => value.isNotEmpty).toList(),
      ),
      _PreferenceValue(
        Icons.home_work_outlined,
        'Hometown',
        <String>{
          ProfileFormOptions.displayHometown(profile.hometown),
        }.where((value) => value.isNotEmpty).toList(),
      ),
    ].where((item) => item.values.isNotEmpty).toList(growable: false);
    final loveLanguages =
        profile.loveLanguages.isEmpty && profile.loveLanguage.trim().isNotEmpty
        ? <String>[profile.loveLanguage.trim()]
        : _ordered(profile.loveLanguages, ProfileFormOptions.loveLanguages);
    final connection = <_PreferenceValue>[
      _PreferenceValue(
        Icons.auto_awesome_rounded,
        'Qualities I value',
        _ordered(profile.valuedQualities, ProfileFormOptions.qualities),
      ),
      _PreferenceValue(
        Icons.schedule_rounded,
        'Preferred time to talk',
        _ordered(
          profile.preferredTalkingHours,
          ProfileFormOptions.preferredTalkingHours,
        ),
      ),
      _PreferenceValue(
        Icons.volunteer_activism_rounded,
        'Love Languages',
        loveLanguages,
      ),
    ].where((item) => item.values.isNotEmpty).toList(growable: false);
    if (identity.isEmpty && connection.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      key: const ValueKey('public-profile-preferences'),
      padding: const EdgeInsets.all(AmoraSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.tertiary.withValues(alpha: .62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (identity.isNotEmpty)
            _PreferenceGroup(title: 'Identity', values: identity),
          if (identity.isNotEmpty && connection.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AmoraSpacing.space16),
              child: Divider(height: 1),
            ),
          if (connection.isNotEmpty)
            _PreferenceGroup(title: 'Connection Style', values: connection),
        ],
      ),
    );
  }

  static List<String> _ordered(
    Iterable<String> values,
    List<String> approved,
  ) => ProfileFormOptions.normalizePreferenceValues(values, approved);
}

class _PreferenceGroup extends StatelessWidget {
  const _PreferenceGroup({required this.title, required this.values});

  final String title;
  final List<_PreferenceValue> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AmoraTextStyles.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AmoraSpacing.space12),
        for (var index = 0; index < values.length; index++) ...[
          _PreferenceRow(value: values[index]),
          if (index != values.length - 1)
            const SizedBox(height: AmoraSpacing.space12),
        ],
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.value});

  final _PreferenceValue value;

  @override
  Widget build(BuildContext context) {
    final display = value.values.join(' · ');
    return Semantics(
      label: '${value.label}, $display',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: .36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(value.icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: AmoraSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.label,
                    style: AmoraTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    display,
                    key: ValueKey('public-preference-${value.label}'),
                    style: AmoraTextStyles.bodyMedium.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceValue {
  const _PreferenceValue(this.icon, this.label, this.values);

  final IconData icon;
  final String label;
  final List<String> values;
}
