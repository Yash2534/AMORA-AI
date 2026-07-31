import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_profile_image.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/premium_card.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/presentation/kyc_verification_screen.dart';
import 'package:amora_ai/features/profile/presentation/photo_manager_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_completion_metrics.dart';
import 'package:amora_ai/features/profile/presentation/profile_preview_screen.dart';
import 'package:amora_ai/features/profile/presentation/profile_section_editor_screen.dart';
import 'package:amora_ai/features/onboarding/data/gujarat_cities.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  static const routeName = '/edit-profile';

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const _occupations = <String>[
    'Software Engineer',
    'Product Designer',
    'Doctor',
    'Entrepreneur',
    'Consultant',
    'Teacher',
    'Chartered Accountant',
    'Architect',
    'Marketing Professional',
    'Government Professional',
    'Lawyer',
    'Creative Professional',
  ];
  static const _educationOptions = <String>[
    'High School',
    'Diploma',
    'Bachelor’s Degree',
    'Master’s Degree',
    'MBA',
    'Doctorate',
    'Professional Qualification',
  ];
  static const _datingIntentions = <String>[
    'Long-Term Relationship',
    'Marriage',
    'Intentional Dating',
    'Life Partner',
  ];
  final _formKey = GlobalKey<FormState>();
  final _repository = LocalProfileRepository.instance;

  late final TextEditingController _name;
  late final TextEditingController _profession;
  late final TextEditingController _company;
  late final TextEditingController _education;
  late final TextEditingController _city;
  late final TextEditingController _bio;
  late final TextEditingController _datingIntention;
  late String _gender;
  DateTime? _birthDate;
  bool _showDobError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = _repository.profile;
    _name = TextEditingController(text: profile.name);
    _birthDate = profile.dateOfBirth;
    _profession = TextEditingController(text: profile.profession);
    _company = TextEditingController(text: profile.company);
    _education = TextEditingController(text: profile.education);
    _city = TextEditingController(text: profile.location);
    _bio = TextEditingController(text: profile.bio);
    _datingIntention = TextEditingController(text: profile.datingIntention);
    _gender = switch (profile.gender.toLowerCase()) {
      'woman' || 'female' => 'Female',
      _ => 'Male',
    };
    _repository.addListener(_refresh);
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    _name.dispose();
    _profession.dispose();
    _company.dispose();
    _education.dispose();
    _city.dispose();
    _bio.dispose();
    _datingIntention.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = _repository.profile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit profile'),
            Text(
              'Shape the story people meet',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          tooltip: 'Back to profile',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview profile',
            onPressed: () =>
                Navigator.of(context).pushNamed(ProfilePreviewScreen.routeName),
            icon: const Icon(Icons.visibility_rounded),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: .08),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ResponsiveMobileFrame(
          maxWidth: 820,
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    40 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _EditorIntro(profile: profile),
                      const SizedBox(height: 24),
                      _EditorSection(
                        number: '01',
                        icon: Icons.photo_camera_rounded,
                        title: 'Photos',
                        subtitle:
                            '${profile.photos.length} of 6 photos · first is your lead photo',
                        trailingLabel: 'Manage',
                        onTrailing: () =>
                            _openNamed(PhotoManagerScreen.routeName),
                        child: _PhotoStrip(profile: profile),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '02',
                        icon: Icons.badge_rounded,
                        title: 'Basic info',
                        subtitle:
                            'The essentials people use to understand your everyday life.',
                        child: Column(
                          children: [
                            _PremiumField(
                              controller: _name,
                              label: 'Name',
                              icon: Icons.person_rounded,
                              validator: _required,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            AmoraDobField(
                              value: _birthDate,
                              errorText: _showDobError
                                  ? AmoraDateOfBirth.validate(_birthDate)
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  _birthDate = value;
                                  _showDobError = true;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _gender,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              items: const ['Male', 'Female']
                                  .map((value) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList(growable: false),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _gender = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _SearchableDropdownField(
                              controller: _profession,
                              label: 'Occupation',
                              icon: Icons.work_rounded,
                              options: _occupations,
                            ),
                            const SizedBox(height: 12),
                            _PremiumField(
                              controller: _company,
                              label: 'Company (optional)',
                              icon: Icons.business_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                            _SearchableDropdownField(
                              controller: _education,
                              label: 'Education',
                              icon: Icons.school_rounded,
                              options: _educationOptions,
                            ),
                            const SizedBox(height: 12),
                            _SearchableDropdownField(
                              controller: _city,
                              label: 'City',
                              icon: Icons.location_on_rounded,
                              options: gujaratCities,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '03',
                        icon: Icons.notes_rounded,
                        title: 'About me',
                        subtitle:
                            'A specific, warm introduction works better than a list.',
                        child: _PremiumField(
                          controller: _bio,
                          label: 'Bio',
                          hint: 'Tell people what life with you feels like',
                          icon: Icons.notes_rounded,
                          minLines: 5,
                          maxLines: 8,
                          maxLength: 240,
                          validator: (value) {
                            if ((value ?? '').trim().length < 40) {
                              return 'Use at least 40 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '04',
                        icon: Icons.forum_rounded,
                        title: 'Profile prompts',
                        subtitle:
                            '${profile.completedPromptCount} of 1 required conversation starter completed.',
                        trailingLabel: 'Edit',
                        onTrailing: () => _openSection(ProfileSection.prompts),
                        child: _PromptSummary(profile: profile),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '05',
                        icon: Icons.interests_rounded,
                        title: 'Interests',
                        subtitle:
                            '${profile.interests.length} selected · choose 5–10',
                        trailingLabel: 'Edit',
                        onTrailing: () =>
                            _openSection(ProfileSection.interests),
                        child: _ChipSummary(
                          values: profile.interests,
                          emptyLabel: 'No interests added yet',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '06',
                        icon: Icons.favorite_rounded,
                        title: 'Dating intentions',
                        subtitle:
                            'Be clear about the kind of connection you want.',
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _datingIntentions.contains(_datingIntention.text)
                              ? _datingIntention.text
                              : _datingIntentions.first,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Looking for',
                            prefixIcon: Icon(Icons.favorite_outline_rounded),
                          ),
                          items: _datingIntentions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value != null) {
                              _datingIntention.text = value;
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '07',
                        icon: Icons.psychology_alt_rounded,
                        title: 'Personality & lifestyle',
                        subtitle:
                            'Share only supported lifestyle details that feel comfortable.',
                        trailingLabel: 'Edit',
                        onTrailing: () =>
                            _openSection(ProfileSection.lifestyle),
                        child: _ChipSummary(
                          values: profile.lifestyle.entries
                              .map((entry) => '${entry.key}: ${entry.value}')
                              .toList(growable: false),
                          emptyLabel: 'No lifestyle details added',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _EditorSection(
                        number: '08',
                        icon: Icons.verified_user_rounded,
                        title: 'Verification',
                        subtitle:
                            'Review the verification flow already supported by AMORAA.',
                        trailingLabel: 'Review',
                        onTrailing: () =>
                            _openNamed(KycVerificationScreen.routeName),
                        child: const _VerificationEditorSummary(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _SaveBar(saving: _saving, onSave: _save),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _showDobError = true);
    if (!(_formKey.currentState?.validate() ?? false) ||
        AmoraDateOfBirth.validate(_birthDate) != null ||
        _saving) {
      return;
    }
    setState(() => _saving = true);
    final profile = _repository.profile;
    _repository.save(
      profile.copyWith(
        name: _name.text.trim(),
        birthdate: AmoraDateOfBirth.format(_birthDate!),
        gender: _gender,
        bio: _bio.text.trim(),
        profession: _profession.text.trim(),
        company: _company.text.trim(),
        education: _education.text.trim(),
        location: _city.text.trim(),
        datingIntention: _datingIntention.text.trim(),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile changes saved')));
  }

  Future<void> _openNamed(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) setState(() {});
  }

  Future<void> _openSection(ProfileSection section) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSectionEditorScreen(section: section),
      ),
    );
    if (mounted) setState(() {});
  }
}

class _EditorIntro extends StatelessWidget {
  const _EditorIntro({required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AmoraProfileImage(
          imageUrl: profile.primaryPhoto,
          assetPath: profile.primaryPhoto,
          initials: profile.name.isEmpty ? 'AM' : profile.name.substring(0, 1),
          width: 76,
          height: 92,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(22),
          semanticLabel: 'Primary profile photo',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Make every detail feel like you.',
                style: AmoraTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${profile.presentationCompletionPercent}% complete · changes stay in your existing profile draft.',
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.text.withValues(alpha: .7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailingLabel,
    this.onTrailing,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number  $title',
                      style: AmoraTextStyles.titleMedium.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AmoraTextStyles.bodyMedium.copyWith(
                        color: AppColors.text.withValues(alpha: .65),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingLabel != null)
                TextButton(onPressed: onTrailing, child: Text(trailingLabel!)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _SearchableDropdownField extends StatelessWidget {
  const _SearchableDropdownField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.options,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return DropdownMenu<String>(
          controller: controller,
          width: constraints.maxWidth,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          leadingIcon: Icon(icon),
          label: Text(label),
          hintText: 'Search $label',
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
          ),
          menuStyle: MenuStyle(
            maximumSize: const WidgetStatePropertyAll(Size.fromHeight(320)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          dropdownMenuEntries: options
              .map(
                (value) =>
                    DropdownMenuEntry<String>(value: value, label: value),
              )
              .toList(growable: false),
          onSelected: (value) {
            if (value != null) controller.text = value;
          },
        );
      },
    );
  }
}

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: maxLength == null
          ? null
          : [LengthLimitingTextInputFormatter(maxLength)],
      textInputAction: textInputAction,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        counterText: maxLength == null ? null : '',
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    if (profile.photos.isEmpty) {
      return const _EmptyEditorLine(
        icon: Icons.add_a_photo_rounded,
        label: 'Add at least two profile photos',
      );
    }
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: profile.photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final primary = index == profile.primaryPhotoIndex;
          return Stack(
            children: [
              AmoraProfileImage(
                imageUrl: profile.photos[index],
                assetPath: profile.photos[index],
                initials: 'AM',
                width: 98,
                height: 128,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(18),
                semanticLabel: primary
                    ? 'Primary profile photo'
                    : 'Profile photo ${index + 1}',
              ),
              if (primary)
                Positioned(
                  left: 7,
                  bottom: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'Lead',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PromptSummary extends StatelessWidget {
  const _PromptSummary({required this.profile});

  final LocalProfileDraft profile;

  @override
  Widget build(BuildContext context) {
    final prompts = profile.prompts.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (prompts.isEmpty) {
      return const _EmptyEditorLine(
        icon: Icons.add_comment_rounded,
        label: 'Add three profile prompts',
      );
    }
    return Column(
      children: [
        for (var index = 0; index < prompts.length; index++) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              prompts[index].key,
              style: AmoraTextStyles.labelLarge.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              prompts[index].value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AmoraTextStyles.bodyLarge,
            ),
          ),
          if (index != prompts.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: AppColors.primary.withValues(alpha: .08),
              ),
            ),
        ],
      ],
    );
  }
}

class _ChipSummary extends StatelessWidget {
  const _ChipSummary({required this.values, required this.emptyLabel});

  final List<String> values;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _EmptyEditorLine(
        icon: Icons.add_circle_outline_rounded,
        label: emptyLabel,
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          Chip(
            avatar: const Icon(
              Icons.favorite_border_rounded,
              size: 17,
              color: AppColors.primary,
            ),
            label: Text(value),
            backgroundColor: AppColors.background,
            side: BorderSide(color: AppColors.secondary.withValues(alpha: .35)),
          ),
      ],
    );
  }
}

class _VerificationEditorSummary extends StatelessWidget {
  const _VerificationEditorSummary();

  @override
  Widget build(BuildContext context) {
    return const _EmptyEditorLine(
      icon: Icons.shield_outlined,
      label: 'Verification status is managed by the existing verification flow',
    );
  }
}

class _EmptyEditorLine extends StatelessWidget {
  const _EmptyEditorLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AmoraTextStyles.bodyMedium.copyWith(
              color: AppColors.text.withValues(alpha: .7),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      shadowColor: AppColors.primary.withValues(alpha: .12),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: AppPrimaryButton(
                key: const ValueKey('profile-save-button'),
                label: 'Save profile',
                icon: Icons.check_rounded,
                isLoading: saving,
                onPressed: saving ? null : onSave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
