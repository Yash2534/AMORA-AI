import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/material.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/features/discover/data/discover_api_service.dart';

class DealbreakersScreen extends StatefulWidget {
  const DealbreakersScreen({super.key, this.apiService});

  final DiscoverApiService? apiService;

  static const routeName = '/dealbreakers';

  @override
  State<DealbreakersScreen> createState() => _DealbreakersScreenState();
}

class _DealbreakersScreenState extends State<DealbreakersScreen> {
  late final DiscoverApiService _api;
  RangeValues _age = const RangeValues(24, 34);
  double _distance = 25;
  final Set<String> _mustHaves = {'Relationship intention', 'City'};
  final Map<String, String> _values = {
    'Smoking': ProfileFormOptions.smokingOptions.first,
    'Drinking': ProfileFormOptions.drinkingOptions[1],
    'Kids': 'Open',
    'Religion/Community': 'Flexible',
    'Relationship intention': ProfileFormOptions.datingIntentions[1],
    'City': 'Ahmedabad',
    'Education': 'Undergraduate',
  };
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.apiService ?? DiscoverApiService();
    if (widget.apiService != null || AuthService.instance.currentUser != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _api.getFilters();
    if (!mounted) return;
    if (!result.success || result.data == null) {
      setState(() {
        _loading = false;
        _error = result.message;
      });
      return;
    }
    final value = result.data!;
    setState(() {
      _age = RangeValues(
        (value['minAge'] as num?)?.toDouble() ?? 24,
        (value['maxAge'] as num?)?.toDouble() ?? 34,
      );
      _distance = (value['maxDistanceKm'] as num?)?.toDouble() ?? 25;
      _mustHaves.clear();
      if ((value['smoking']?.toString() ?? '').isNotEmpty)
        _mustHaves.add('Smoking');
      if ((value['drinking']?.toString() ?? '').isNotEmpty)
        _mustHaves.add('Drinking');
      if (((value['datingIntentions'] as List?) ?? const []).isNotEmpty)
        _mustHaves.add('Relationship intention');
      if ((value['city']?.toString() ?? '').isNotEmpty) _mustHaves.add('City');
      if ((value['education']?.toString() ?? '').isNotEmpty)
        _mustHaves.add('Education');
      if ((value['community']?.toString() ?? '').isNotEmpty)
        _mustHaves.add('Religion/Community');
      _loading = false;
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _api.updateFilters(<String, dynamic>{
      'minAge': _age.start.round(),
      'maxAge': _age.end.round(),
      'maxDistanceKm': _distance.round(),
      'smoking': _mustHaves.contains('Smoking') ? _values['Smoking'] : '',
      'drinking': _mustHaves.contains('Drinking') ? _values['Drinking'] : '',
      'datingIntentions': _mustHaves.contains('Relationship intention')
          ? <String>[_values['Relationship intention']!]
          : <String>[],
      'city': _mustHaves.contains('City') ? _values['City'] : '',
      'education': _mustHaves.contains('Education') ? _values['Education'] : '',
      'community': _mustHaves.contains('Religion/Community')
          ? _values['Religion/Community']
          : '',
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = result.success ? null : result.message;
    });
    showAmoraSnackBar(
      context,
      message: result.success ? 'Preferences saved' : result.message,
      tone: result.success
          ? AmoraSnackBarTone.success
          : AmoraSnackBarTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Dealbreakers',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AmoraSpacing.space16,
              AmoraSpacing.space20,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AmoraSpacing.space8),
                ],
                AppPrimaryButton(
                  label: 'Save Preferences',
                  icon: AmoraIcons.check,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
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
