import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/amora_theme_controller.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class DarkModeSettingsScreen extends StatelessWidget {
  const DarkModeSettingsScreen({super.key});

  static const routeName = '/dark-mode-settings';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: SafeArea(
        child: ResponsiveMobileFrame(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AmoraSpacing.space20,
              AmoraSpacing.space12,
              AmoraSpacing.space20,
              AmoraSpacing.navigationContentInset +
                  MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Text('Theme', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AmoraSpacing.space8),
              Text(
                'AMORAA uses its approved light brand palette on every device.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AmoraSpacing.space20),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 64,
                  selected: true,
                  selectedTileColor: scheme.primaryContainer,
                  leading: Icon(
                    Icons.radio_button_checked_rounded,
                    color: scheme.primary,
                  ),
                  title: const Text(
                    'AMORAA light',
                    style: AmoraTextStyles.cardTitle,
                  ),
                  subtitle: const Text(
                    'Approved plum, pink, blush, and light surfaces',
                  ),
                ),
              ),
              const SizedBox(height: AmoraSpacing.space20),
              AppPrimaryButton(
                label: 'Save appearance',
                icon: Icons.check_rounded,
                onPressed: () => _save(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    AmoraThemeController.instance.update(ThemeMode.light);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Appearance preference saved')),
      );
  }
}
