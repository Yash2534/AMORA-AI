import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class DealbreakersScreen extends StatefulWidget {
  const DealbreakersScreen({super.key});

  static const routeName = '/dealbreakers';

  @override
  State<DealbreakersScreen> createState() => _DealbreakersScreenState();
}

class _DealbreakersScreenState extends State<DealbreakersScreen> {
  RangeValues _age = const RangeValues(24, 34);
  double _distance = 25;
  final Set<String> _mustHaves = {'Relationship intention', 'City'};
  final Map<String, String> _values = {
    'Smoking': 'No',
    'Drinking': 'Occasionally',
    'Kids': 'Open',
    'Religion/Community': 'Flexible',
    'Relationship intention': 'Long-term',
    'City': 'Ahmedabad',
    'Education': 'Graduate+',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(AmoraIcons.back),
                    ),
                    const SizedBox(width: AmoraSpacing.space12),
                    Expanded(
                      child: Text(
                        'Dealbreakers',
                        style: AmoraTextStyles.headlineSmall.copyWith(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space20),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Age range',
                        style: AmoraTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      RangeSlider(
                        values: _age,
                        min: 18,
                        max: 60,
                        divisions: 42,
                        labels: RangeLabels(
                          _age.start.round().toString(),
                          _age.end.round().toString(),
                        ),
                        onChanged: (value) => setState(() => _age = value),
                      ),
                      Text('${_age.start.round()}-${_age.end.round()} years'),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance',
                        style: AmoraTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Slider(
                        value: _distance,
                        min: 5,
                        max: 100,
                        divisions: 19,
                        label: '${_distance.round()} km',
                        onChanged: (value) => setState(() => _distance = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space12),
                for (final entry in _values.entries)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AmoraSpacing.space12,
                    ),
                    child: _PreferenceTile(
                      label: entry.key,
                      value: entry.value,
                      mustHave: _mustHaves.contains(entry.key),
                      onToggle: (value) => setState(() {
                        value
                            ? _mustHaves.add(entry.key)
                            : _mustHaves.remove(entry.key);
                      }),
                    ),
                  ),
                const SizedBox(height: AmoraSpacing.space8),
                AppPrimaryButton(
                  label: 'Save Preferences',
                  icon: AmoraIcons.check,
                  onPressed: () => showAmoraSnackBar(
                    context,
                    message: 'Dealbreakers saved for future feed integration',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.label,
    required this.value,
    required this.mustHave,
    required this.onToggle,
  });
  final String label;
  final String value;
  final bool mustHave;
  final ValueChanged<bool> onToggle;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: AmoraSpacing.compactCard,
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: mustHave,
      onChanged: onToggle,
      title: Text(
        label,
        style: AmoraTextStyles.titleSmall.copyWith(
          color: AppColors.deepWine,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(value),
      secondary: const Icon(AmoraIcons.filter),
    ),
  );
}
