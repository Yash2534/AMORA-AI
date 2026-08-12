import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_filter_chip.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amora_snackbar.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

class BioBuilderScreen extends StatefulWidget {
  const BioBuilderScreen({super.key});

  static const routeName = '/bio-builder';

  @override
  State<BioBuilderScreen> createState() => _BioBuilderScreenState();
}

class _BioBuilderScreenState extends State<BioBuilderScreen> {
  late final TextEditingController _bio;
  String _prompt = _prompts.first;

  @override
  void initState() {
    super.initState();
    _bio = TextEditingController(
      text: LocalProfileRepository.instance.profile.bio,
    );
  }

  @override
  void dispose() {
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _bio.text.characters.length;
    return Scaffold(
      appBar: AmoraAppBar(
        title: 'Bio Builder',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final prompt in _prompts)
                      AmoraFilterChip(
                        label: prompt,
                        selected: _prompt == prompt,
                        onSelected: (_) => setState(() => _prompt = prompt),
                      ),
                  ],
                ),
                const SizedBox(height: AmoraSpacing.space16),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _prompt,
                        style: AmoraTextStyles.titleSmall.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                      AppTextField(
                        controller: _bio,
                        label: 'Bio',
                        hint: 'Write a warm, specific bio',
                        minLines: 5,
                        maxLines: 8,
                        maxLength: 240,
                        counterText: '',
                        onChanged: (_) => setState(() {}),
                      ),
                      Text(
                        '$count/240 characters',
                        style: AmoraTextStyles.bodySmall.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                AppPrimaryButton(
                  label: 'Help me write',
                  icon: AmoraIcons.sparkle,
                  variant: AppPrimaryButtonVariant.outlined,
                  onPressed: _generate,
                ),
                const SizedBox(height: AmoraSpacing.space12),
                AppPrimaryButton(
                  label: 'Save Bio',
                  icon: AmoraIcons.check,
                  onPressed: count >= 40 ? _save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _generate() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Local writing preview', style: AmoraTextStyles.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'This deterministic suggestion is created on-device from your profile details. It is not AI-generated.',
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: 'Use suggestion',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                setState(() {
                  _bio.text =
                      'I am looking for something steady, kind, and real. My ideal date starts with coffee, honest conversation, and a plan we both feel excited about.';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final repository = LocalProfileRepository.instance;
    try {
      await repository.savePersisted(
        repository.profile.copyWith(bio: _bio.text.trim()),
      );
      if (!mounted) return;
      _snack('Bio saved to your profile');
      Navigator.of(context).pop(true);
    } on AuthException catch (error) {
      if (mounted) _snack(error.userMessage);
    } catch (_) {
      if (mounted) _snack('Could not save your bio. Please try again.');
    }
  }

  void _snack(String message) {
    showAmoraSnackBar(context, message: message);
  }
}

const _prompts = [
  'My ideal Sunday is...',
  'A green flag I value is...',
  'Together we could...',
  'I am looking for...',
];
