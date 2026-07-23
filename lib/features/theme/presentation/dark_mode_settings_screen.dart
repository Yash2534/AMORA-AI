import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class DarkModeSettingsScreen extends StatefulWidget {
  const DarkModeSettingsScreen({super.key});

  static const routeName = '/dark-mode-settings';

  @override
  State<DarkModeSettingsScreen> createState() => _DarkModeSettingsScreenState();
}

class _DarkModeSettingsScreenState extends State<DarkModeSettingsScreen> {
  String _theme = 'System Theme';
  Color _accent = AppColors.primaryPurple;

  @override
  Widget build(BuildContext context) {
    final dark = _theme == 'Dark' || _theme == 'AMOLED';
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
                const _Header(),
                const SizedBox(height: 18),
                for (final theme in [
                  'System Theme',
                  'Light',
                  'Dark',
                  'AMOLED',
                  'Auto',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => setState(() => _theme = theme),
                      child: PremiumCard(
                        padding: const EdgeInsets.all(16),
                        color: _theme == theme
                            ? AppColors.primaryPurple.withValues(alpha: .10)
                            : AppColors.surface,
                        child: Row(
                          children: [
                            Icon(
                              _theme == theme
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: AppColors.primaryPurple,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                theme,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accent Color Preview',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        children: [
                          for (final color in [
                            AppColors.primaryPurple,
                            AppColors.primaryRose,
                            AppColors.premiumGold,
                            AppColors.successGreen,
                          ])
                            InkWell(
                              onTap: () => setState(() => _accent = color),
                              borderRadius: BorderRadius.circular(20),
                              child: CircleAvatar(
                                backgroundColor: color,
                                child: _accent == color
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: AppColors.surface,
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PreviewCards(dark: dark, accent: _accent),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Save',
                        icon: Icons.check_rounded,
                        onPressed: () =>
                            _snack('Theme preference saved locally'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppPrimaryButton(
                        label: 'Reset',
                        icon: Icons.restart_alt_rounded,
                        variant: AppPrimaryButtonVariant.outlined,
                        onPressed: () => setState(() {
                          _theme = 'System Theme';
                          _accent = AppColors.primaryPurple;
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Text(
          'Dark Mode',
          style: TextStyle(
            color: AppColors.deepWine,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _PreviewCards extends StatelessWidget {
  const _PreviewCards({required this.dark, required this.accent});
  final bool dark;
  final Color accent;
  @override
  Widget build(BuildContext context) => PremiumCard(
    color: dark ? AppColors.deepWine : AppColors.surface,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview Card',
          style: TextStyle(
            color: dark ? AppColors.surface : AppColors.deepWine,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Future ThemeMode integration can consume this local preference.',
          style: TextStyle(
            color: dark ? AppColors.surface : AppColors.textGray,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        AppPrimaryButton(label: 'Accent CTA', onPressed: () {}),
      ],
    ),
  );
}
