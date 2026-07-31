import 'package:amora_ai/core/media/amora_media_picker.dart';
import 'package:amora_ai/core/theme/amora_icons.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dialog.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:flutter/material.dart';

class PostEventFeedbackScreen extends StatefulWidget {
  const PostEventFeedbackScreen({
    super.key,
    this.mediaPicker = const DeviceAmoraMediaPicker(),
  });

  static const routeName = '/post-event-feedback';

  final AmoraMediaPicker mediaPicker;

  @override
  State<PostEventFeedbackScreen> createState() =>
      _PostEventFeedbackScreenState();
}

class _PostEventFeedbackScreenState extends State<PostEventFeedbackScreen> {
  final _comment = TextEditingController();
  final Map<String, double> _ratings = {
    'Overall Rating': 4,
    'Venue Rating': 4,
    'Host Rating': 5,
    'Food Rating': 4,
    'Safety Rating': 5,
    'Experience Rating': 4,
  };
  bool _recommend = true;
  AmoraPickedMedia? _photo;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

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
                const _Header(),
                const SizedBox(height: AmoraSpacing.space20),
                for (final entry in _ratings.entries)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AmoraSpacing.space12,
                    ),
                    child: _RatingCard(
                      label: entry.key,
                      value: entry.value,
                      onChanged: (value) =>
                          setState(() => _ratings[entry.key] = value),
                    ),
                  ),
                const SizedBox(height: AmoraSpacing.space8),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comment',
                        style: AmoraTextStyles.titleSmall.copyWith(
                          color: AppColors.deepWine,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                      AppTextField(
                        controller: _comment,
                        label: 'Event feedback',
                        hint: 'What made this event work for you?',
                        minLines: 4,
                        maxLines: 6,
                      ),
                      const SizedBox(height: AmoraSpacing.space12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.add_photo_alternate_rounded),
                        title: const Text('Upload a photo'),
                        subtitle: Text(
                          _photo == null
                              ? 'Optional · choose an event photo'
                              : '${_photo!.name} attached',
                        ),
                        trailing: _pickingPhoto
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _photo == null
                            ? const Icon(Icons.chevron_right_rounded)
                            : IconButton(
                                tooltip: 'Remove photo',
                                onPressed: () => setState(() => _photo = null),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                        onTap: _pickingPhoto ? null : _pickPhoto,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _recommend,
                        onChanged: (value) =>
                            setState(() => _recommend = value),
                        title: const Text('Recommend this event'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AmoraSpacing.space16),
                AppPrimaryButton(
                  label: 'Submit Feedback',
                  icon: AmoraIcons.send,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    showAmoraDialog<void>(
      context: context,
      title: 'Feedback submitted',
      message: 'Your event feedback was saved locally for this session.',
      icon: AmoraIcons.check,
      primaryLabel: 'Done',
      onPrimary: () => Navigator.pop(context),
    );
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    final result = await widget.mediaPicker.pickImage(
      source: AmoraMediaSource.gallery,
    );
    if (!mounted) return;
    setState(() => _pickingPhoto = false);
    if (!result.succeeded) {
      showAmoraMediaResult(
        context,
        result: result,
        picker: widget.mediaPicker,
        onRetry: _pickPhoto,
      );
      return;
    }
    setState(() => _photo = result.media);
  }
}

class _Header extends StatelessWidget {
  const _Header();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(AmoraIcons.back),
      ),
      const SizedBox(width: AmoraSpacing.space12),
      Expanded(
        child: Text(
          'Event Feedback',
          style: AmoraTextStyles.headlineSmall.copyWith(
            color: AppColors.deepWine,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${value.round()}/5',
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          label: '${value.round()}',
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
