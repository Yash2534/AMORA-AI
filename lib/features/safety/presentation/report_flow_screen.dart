import 'package:amora_ai/core/data/amora_image_data.dart';
import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/premium_avatar.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class ReportFlowScreen extends StatefulWidget {
  const ReportFlowScreen({
    super.key,
    this.mediaPicker = const DeviceAmoraMediaPicker(),
  });

  static const routeName = '/report-flow';

  final AmoraMediaPicker mediaPicker;

  @override
  State<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends State<ReportFlowScreen> {
  final _notes = TextEditingController();
  String _reason = 'Fake profile';
  AmoraPickedMedia? _screenshot;
  bool _pickingScreenshot = false;
  bool _submitted = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ResponsiveMobileFrame(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AmoraSpacing.space20,
                  AmoraSpacing.space20,
                  AmoraSpacing.space20,
                  AmoraSpacing.navigationContentInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        title: 'Report a Concern',
                        subtitle:
                            'AMORA reviews every report with safety-first moderation.',
                        icon: Icons.flag_rounded,
                      ),
                      const SizedBox(height: 18),
                      const _ProfileSummary(),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Reason',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final reason in _reasons)
                              ChoiceChip(
                                label: Text(reason),
                                selected: _reason == reason,
                                onSelected: (_) =>
                                    setState(() => _reason = reason),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notes',
                              style: TextStyle(
                                color: AppColors.deepWine,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _notes,
                              minLines: 4,
                              maxLines: 6,
                              decoration: const InputDecoration(
                                hintText:
                                    'Add context for the safety moderation team',
                                prefixIcon: Icon(Icons.edit_note_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.image_outlined),
                              title: const Text('Attach a screenshot'),
                              subtitle: Text(
                                _screenshot == null
                                    ? 'Optional · JPEG, PNG, WebP, HEIC, or HEIF · up to 12 MB'
                                    : '${_screenshot!.name} attached',
                              ),
                              trailing: _pickingScreenshot
                                  ? const SizedBox.square(
                                      dimension: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : _screenshot == null
                                  ? const Icon(Icons.chevron_right_rounded)
                                  : IconButton(
                                      tooltip: 'Remove screenshot',
                                      onPressed: () =>
                                          setState(() => _screenshot = null),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                              onTap: _pickingScreenshot
                                  ? null
                                  : _pickScreenshot,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: _submitted
                            ? 'Report Submitted'
                            : 'Submit Report',
                        icon: Icons.shield_rounded,
                        onPressed: _submitted ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    setState(() => _submitted = true);
    showAmoraDialog<void>(
      context: context,
      title: 'Report submitted',
      message: 'Thanks for helping keep AMORA respectful. Reason: $_reason.',
      icon: AmoraIcons.check,
      primaryLabel: 'Done',
      onPrimary: () => Navigator.pop(context),
    );
  }

  Future<void> _pickScreenshot() async {
    setState(() => _pickingScreenshot = true);
    final result = await widget.mediaPicker.pickImage(
      source: AmoraMediaSource.gallery,
    );
    if (!mounted) return;
    setState(() => _pickingScreenshot = false);
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: _pickScreenshot,
      );
      return;
    }
    setState(() => _screenshot = result.media);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.secondary, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: AppColors.surface),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.deepWine,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textGray,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          PremiumAvatar(
            imageUrl: AmoraImageData.profileAadhya,
            fallbackAsset: AmoraImageData.assetProfileAadhya,
            initials: 'AA',
            radius: 30,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aadhya, 23',
                  style: TextStyle(
                    color: AppColors.deepWine,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Safety team context preview',
                  style: TextStyle(
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.deepWine,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

const _reasons = [
  'Fake profile',
  'Harassment',
  'Inappropriate photo',
  'Scam',
  'Spam',
  'Other',
];
