import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  static const routeName = '/accessibility-settings';

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends State<AccessibilitySettingsScreen> {
  bool _largeText = false;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReader = true;
  bool _colorBlind = false;
  bool _boldText = false;
  bool _haptics = true;
  double _fontSize = 16;
  double _buttonSize = 52;

  int get _score {
    final toggles = [
      _largeText,
      _highContrast,
      _reduceMotion,
      _screenReader,
      _colorBlind,
      _boldText,
      _haptics,
    ].where((value) => value).length;
    return (58 + toggles * 5 + (_fontSize > 17 ? 4 : 0)).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Accessibility',
        subtitle: 'Future-ready controls for inclusive dating UX.',
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AmoraSpacing.space16,
                AmoraSpacing.space20,
                AmoraSpacing.space20,
                AmoraSpacing.navigationContentInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ScoreCard(score: _score),
                  const SizedBox(height: 14),
                  PremiumCard(
                    child: Column(
                      children: [
                        _Toggle(
                          title: 'Large Text',
                          value: _largeText,
                          onChanged: (value) =>
                              setState(() => _largeText = value),
                        ),
                        _Toggle(
                          title: 'High Contrast Mode',
                          value: _highContrast,
                          onChanged: (value) =>
                              setState(() => _highContrast = value),
                        ),
                        _Toggle(
                          title: 'Reduce Motion',
                          value: _reduceMotion,
                          onChanged: (value) =>
                              setState(() => _reduceMotion = value),
                        ),
                        _Toggle(
                          title: 'Screen Reader Friendly',
                          value: _screenReader,
                          onChanged: (value) =>
                              setState(() => _screenReader = value),
                        ),
                        _Toggle(
                          title: 'Bold Text',
                          value: _boldText,
                          onChanged: (value) =>
                              setState(() => _boldText = value),
                        ),
                        _Toggle(
                          title: 'Haptic Feedback',
                          value: _haptics,
                          onChanged: (value) =>
                              setState(() => _haptics = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SliderCard(
                    title: 'Font Size',
                    value: _fontSize,
                    min: 14,
                    max: 24,
                    divisions: 10,
                    suffix: 'sp',
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                  const SizedBox(height: 14),
                  _SliderCard(
                    title: 'Button Size',
                    value: _buttonSize,
                    min: 44,
                    max: 64,
                    divisions: 10,
                    suffix: 'px',
                    onChanged: (value) => setState(() => _buttonSize = value),
                  ),
                  const SizedBox(height: 14),
                  _ColorBlindPreview(
                    enabled: _colorBlind,
                    onChanged: (value) => setState(() => _colorBlind = value),
                  ),
                  const SizedBox(height: 14),
                  _PreviewCard(
                    fontSize: _fontSize,
                    buttonSize: _buttonSize,
                    highContrast: _highContrast,
                    boldText: _boldText,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Save',
                          icon: Icons.check_rounded,
                          onPressed: () =>
                              _snack('Accessibility settings saved locally'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Reset',
                          variant: AppPrimaryButtonVariant.outlined,
                          icon: Icons.restart_alt_rounded,
                          onPressed: _reset,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _largeText = false;
      _highContrast = false;
      _reduceMotion = false;
      _screenReader = true;
      _colorBlind = false;
      _boldText = false;
      _haptics = true;
      _fontSize = 16;
      _buttonSize = 52;
    });
    _snack('Accessibility settings reset');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) => PremiumCard(
    color: AppColors.lavenderBackground,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Accessibility Score',
                style: TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$score%',
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: score / 100, minHeight: 9),
      ],
    ),
  );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: onChanged,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.onChanged,
  });
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title ${value.round()}$suffix',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()}$suffix',
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _ColorBlindPreview extends StatelessWidget {
  const _ColorBlindPreview({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => PremiumCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: enabled,
          onChanged: onChanged,
          title: const Text('Color Blind Friendly Preview'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final color in [
              AppColors.primaryPurple,
              AppColors.primaryRose,
              AppColors.premiumGold,
              AppColors.successGreen,
            ])
              Expanded(
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: enabled ? color.withValues(alpha: .72) : color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.fontSize,
    required this.buttonSize,
    required this.highContrast,
    required this.boldText,
  });
  final double fontSize;
  final double buttonSize;
  final bool highContrast;
  final bool boldText;
  @override
  Widget build(BuildContext context) => PremiumCard(
    color: highContrast ? AppColors.deepWine : AppColors.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessibility Preview',
          style: TextStyle(
            color: highContrast ? AppColors.surface : AppColors.deepWine,
            fontSize: fontSize,
            fontWeight: boldText ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: buttonSize,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('Readable CTA'),
          ),
        ),
      ],
    ),
  );
}
