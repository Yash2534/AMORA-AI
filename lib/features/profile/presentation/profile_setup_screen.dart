import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
<<<<<<< HEAD
import 'package:amora_ai/features/home/presentation/amora_home_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
=======
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
>>>>>>> main
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const routeName = '/profile-setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _minimumAge = 18;

  final _formKey = GlobalKey<FormState>();
<<<<<<< HEAD
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  final _heightController = TextEditingController(text: '5\'10"');
  late final TextEditingController _professionController;
  late final TextEditingController _companyController;
  late final TextEditingController _educationController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;
  late final TextEditingController _sundayController;
  late final TextEditingController _greenFlagController;
  late final TextEditingController _togetherController;

  final List<String?> _photos = List<String?>.filled(6, null, growable: true);
  final Set<String> _languages = {'Gujarati', 'Hindi', 'English'};
  final Set<String> _lifestyle = {'Coffee Dates', 'Family Values'};
  final Set<String> _travel = {'Heritage Walks'};
  final Set<String> _music = {'Old Bollywood'};
  final Set<String> _food = {'Gujarati thali'};
  String _gender = 'Man';
  String _intent = 'Long-Term Relationship';
  int _primaryPhoto = 0;

  double get _completion {
    var score = 0;
    if (_photos.any((photo) => photo != null)) score++;
    if (_nameController.text.trim().isNotEmpty) score++;
    if (_dobController.text.trim().isNotEmpty) score++;
    if (_gender.isNotEmpty) score++;
    if (_heightController.text.trim().isNotEmpty) score++;
    if (_professionController.text.trim().isNotEmpty) score++;
    if (_companyController.text.trim().isNotEmpty) score++;
    if (_educationController.text.trim().isNotEmpty) score++;
    if (_cityController.text.trim().isNotEmpty) score++;
    if (_languages.isNotEmpty) score++;
    if (_bioController.text.trim().length >= 40) score++;
    if (_lifestyle.length >= 2) score++;
    if (_travel.isNotEmpty && _music.isNotEmpty && _food.isNotEmpty) score++;
    if (_sundayController.text.trim().isNotEmpty) score++;
    if (_greenFlagController.text.trim().isNotEmpty) score++;
    if (_togetherController.text.trim().isNotEmpty) score++;
    return score / 16;
=======
  final _cityController = TextEditingController();

  String? _gender;
  DateTime? _dateOfBirth;
  String? _preferredGender;
  bool _showValidationErrors = false;
  bool _loading = false;

  bool get _hasValidDateOfBirth => _dateOfBirthError == null;

  bool get _isComplete =>
      _gender != null &&
      _hasValidDateOfBirth &&
      _preferredGender != null &&
      _cityController.text.trim().isNotEmpty;

  String? get _dateOfBirthError {
    final selected = _dateOfBirth;
    if (selected == null) return 'Select your date of birth';

    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(selected);
    if (selectedDay.isAfter(today)) {
      return 'Date of birth cannot be in the future';
    }
    if (selectedDay.isAfter(_dateYearsAgo(today, _minimumAge))) {
      return 'You must be at least $_minimumAge years old';
    }
    return null;
>>>>>>> main
  }

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    final profile = LocalProfileRepository.instance.profile;
    _nameController = TextEditingController(text: profile.name);
    _dobController = TextEditingController(text: profile.birthdate);
    _professionController = TextEditingController(text: profile.profession);
    _companyController = TextEditingController(text: profile.company);
    _educationController = TextEditingController(text: profile.education);
    _cityController = TextEditingController(text: profile.location);
    _bioController = TextEditingController(text: profile.bio);
    _sundayController = TextEditingController(
      text: profile.prompts['My ideal Sunday is...'],
    );
    _greenFlagController = TextEditingController(
      text: profile.prompts['A green flag I value is...'],
    );
    _togetherController = TextEditingController(
      text: profile.prompts['Together we could...'],
    );
    _gender = profile.gender;
    _intent = profile.datingIntention;
    _lifestyle
      ..clear()
      ..addAll(profile.interests.take(3));
    for (var i = 0; i < profile.photos.length && i < _photos.length; i++) {
      _photos[i] = profile.photos[i];
    }
    _primaryPhoto = profile.primaryPhotoIndex;
    for (final controller in [
      _nameController,
      _dobController,
      _heightController,
      _professionController,
      _companyController,
      _educationController,
      _cityController,
      _bioController,
      _sundayController,
      _greenFlagController,
      _togetherController,
    ]) {
      controller.addListener(() => setState(() {}));
    }
=======
    _cityController.addListener(_handleFormChanged);
>>>>>>> main
  }

  @override
  void dispose() {
<<<<<<< HEAD
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _professionController.dispose();
    _companyController.dispose();
    _educationController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _sundayController.dispose();
    _greenFlagController.dispose();
    _togetherController.dispose();
=======
    _cityController
      ..removeListener(_handleFormChanged)
      ..dispose();
>>>>>>> main
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 390
                  ? AmoraSpacing.space16
                  : AmoraSpacing.space24;
              final bottomPadding =
                  AmoraSpacing.space24 +
                  MediaQuery.viewPaddingOf(context).bottom +
                  MediaQuery.viewInsetsOf(context).bottom;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AmoraSpacing.space12,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight -
                          AmoraSpacing.space12 -
                          bottomPadding,
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _showValidationErrors
                        ? AutovalidateMode.always
                        : AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ScreenHeader(
                          canGoBack: Navigator.of(context).canPop(),
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
<<<<<<< HEAD
                        const SizedBox(height: AmoraSpacing.space20),
                        _PhotoManager(
                          photos: _photos,
                          primaryIndex: _primaryPhoto,
                          onAdd: _addPhoto,
                          onPrimary: (index) =>
                              setState(() => _primaryPhoto = index),
                          onReorder: _reorderPhoto,
                          onRemove: _removePhoto,
=======
                        const SizedBox(height: AmoraSpacing.space24),
                        Text(
                          'Tell us about yourself',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.headlineLarge.copyWith(
                            color: AppColors.primary,
                          ),
>>>>>>> main
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Text(
                          'A few essentials help AMORA create more meaningful matches for you.',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.bodyLarge.copyWith(
                            color: AppColors.textNeutral,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space24),
                        _FormSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _SectionHeading(
                                number: '1',
                                title: 'Gender',
                                description: 'How do you identify?',
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              _ChoiceGrid(
                                choices: _genderChoices,
                                selectedValue: _gender,
                                onSelected: (value) {
                                  setState(() => _gender = value);
                                },
                              ),
                              _InlineError(
                                message:
                                    _showValidationErrors && _gender == null
                                    ? 'Select your gender'
                                    : null,
                              ),
                              const _SectionDivider(),
                              const _SectionHeading(
                                number: '2',
                                title: 'Date of birth',
                                description:
                                    'You must be at least 18 to use AMORA.',
                              ),
<<<<<<< HEAD
                              const SizedBox(height: AmoraSpacing.space16),
                              AppTextField(
                                controller: _companyController,
                                label: 'Company',
                                icon: Icons.business_rounded,
                                validator: _required,
                              ),
                              const SizedBox(height: AmoraSpacing.space16),
                              AppTextField(
                                controller: _educationController,
                                label: 'Education',
                                icon: Icons.school_outlined,
                                validator: _required,
=======
                              const SizedBox(height: AmoraSpacing.space12),
                              _DateOfBirthField(
                                value: _dateOfBirth,
                                onTap: _pickDateOfBirth,
>>>>>>> main
                              ),
                              _InlineError(
                                message: _showValidationErrors
                                    ? _dateOfBirthError
                                    : null,
                              ),
                              const _SectionDivider(),
                              const _SectionHeading(
                                number: '3',
                                title: 'Preferred gender',
                                description: 'Who would you like to meet?',
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              _ChoiceGrid(
                                choices: _preferredGenderChoices,
                                selectedValue: _preferredGender,
                                preferThreeColumns: true,
                                onSelected: (value) {
                                  setState(() => _preferredGender = value);
                                },
                              ),
                              _InlineError(
                                message:
                                    _showValidationErrors &&
                                        _preferredGender == null
                                    ? 'Select a preferred gender'
                                    : null,
                              ),
                              const _SectionDivider(),
                              const _SectionHeading(
                                number: '4',
                                title: 'City',
                                description:
                                    'Enter the city where you want to discover matches.',
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              AppTextField(
                                controller: _cityController,
                                label: 'City',
                                hint: 'Enter your city',
                                icon: Icons.location_city_rounded,
                                keyboardType: TextInputType.streetAddress,
                                textInputAction: TextInputAction.done,
                                validator: _validateCity,
                                onSubmitted: (_) {
                                  if (_isComplete) _continue();
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space20),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: !_isComplete && !_loading
                              ? _requestValidation
                              : null,
                          child: AppPrimaryButton(
                            label: 'Continue',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: _loading,
                            onPressed: _isComplete && !_loading
                                ? _continue
                                : null,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space12),
                        Text(
                          'Your answers stay in this onboarding flow for now.',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.bodySmall.copyWith(
                            color: AppColors.textNeutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleFormChanged() {
    if (mounted) setState(() {});
  }

  void _requestValidation() {
    FocusScope.of(context).unfocus();
    setState(() => _showValidationErrors = true);
    _formKey.currentState?.validate();
  }

  Future<void> _pickDateOfBirth() async {
    FocusScope.of(context).unfocus();
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = _dateYearsAgo(today, _minimumAge);
    final firstDate = _dateYearsAgo(today, 100);
    final initialDate = _dateOfBirth == null
        ? _dateYearsAgo(today, 24)
        : _clampDate(DateUtils.dateOnly(_dateOfBirth!), firstDate, lastDate);

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select date of birth',
      fieldLabelText: 'Date of birth',
    );
    if (!mounted) return;
    setState(() {
      _showValidationErrors = true;
      if (selected != null) _dateOfBirth = DateUtils.dateOnly(selected);
    });
  }

<<<<<<< HEAD
  void _removePhoto(int index) {
    if (_photos[index] == null) return;
    setState(() {
      _photos.removeAt(index);
      _photos.add(null);
      final filled = _photos.whereType<String>().length;
      _primaryPhoto = filled == 0 ? 0 : _primaryPhoto.clamp(0, filled - 1);
    });
    _snack('Photo removed from this draft');
  }

  void _toggle(Set<String> selected, String value) {
    setState(() {
      if (!selected.add(value)) selected.remove(value);
    });
  }

  void _saveDraft() {
    LocalProfileRepository.instance.save(_buildDraft());
    AmoraSession.completeProfileStep(40);
    _snack('Profile draft saved locally');
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_photos.whereType<String>().length < 2) {
      _snack('Add at least two profile photos');
      return;
=======
  Future<void> _continue() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    setState(() => _showValidationErrors = true);

    final formIsValid = _formKey.currentState?.validate() ?? false;
    if (!formIsValid || !_isComplete) return;

    final trimmedCity = _cityController.text.trim();
    if (trimmedCity != _cityController.text) {
      _cityController.value = TextEditingValue(
        text: trimmedCity,
        selection: TextSelection.collapsed(offset: trimmedCity.length),
      );
>>>>>>> main
    }

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    AmoraSession.completeProfileStep(60);
<<<<<<< HEAD
    LocalProfileRepository.instance.save(_buildDraft());
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AmoraHomeScreen.routeName, (route) => false);
    }
  }

  LocalProfileDraft _buildDraft() {
    final previous = LocalProfileRepository.instance.profile;
    return previous.copyWith(
      name: _nameController.text.trim(),
      birthdate: _dobController.text.trim(),
      gender: _gender,
      bio: _bioController.text.trim(),
      profession: _professionController.text.trim(),
      company: _companyController.text.trim(),
      education: _educationController.text.trim(),
      location: _cityController.text.trim(),
      datingIntention: _intent,
      interests: <String>{
        ..._lifestyle,
        ..._travel,
        ..._music,
        ..._food,
      }.toList(),
      prompts: {
        'My ideal Sunday is...': _sundayController.text.trim(),
        'A green flag I value is...': _greenFlagController.text.trim(),
        'Together we could...': _togetherController.text.trim(),
      },
      photos: _photos.whereType<String>().toList(),
      primaryPhotoIndex: _primaryPhoto,
    );
=======
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
>>>>>>> main
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }
}

<<<<<<< HEAD
class _PhotoManager extends StatelessWidget {
  const _PhotoManager({
    required this.photos,
    required this.primaryIndex,
    required this.onAdd,
    required this.onPrimary,
    required this.onReorder,
    required this.onRemove,
  });

  final List<String?> photos;
  final int primaryIndex;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onPrimary;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Profile Photos',
            subtitle:
                'Add 2-6 local photos. Drag to reorder and mark the primary image.',
          ),
          const SizedBox(height: AmoraSpacing.space16),
          SizedBox(
            height: 178,
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              buildDefaultDragHandles: false,
              itemCount: photos.length,
              onReorderItem: onReorder,
              itemBuilder: (context, index) {
                return Padding(
                  key: ValueKey('photo-$index-${photos[index] ?? 'empty'}'),
                  padding: const EdgeInsets.only(right: AmoraSpacing.space12),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: _PhotoTile(
                      index: index,
                      imageUrl: photos[index],
                      primary: index == primaryIndex,
                      onAdd: () => onAdd(index),
                      onPrimary: () => onPrimary(index),
                      onRemove: () => onRemove(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.index,
    required this.imageUrl,
    required this.primary,
    required this.onAdd,
    required this.onPrimary,
    required this.onRemove,
  });

  final int index;
  final String? imageUrl;
  final bool primary;
  final VoidCallback onAdd;
  final VoidCallback onPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: InkWell(
        onTap: imageUrl == null ? onAdd : onPrimary,
        borderRadius: AmoraRadius.card,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: AppColors.lightPinkBackground,
            borderRadius: AmoraRadius.card,
            border: Border.all(
              color: primary ? AppColors.primaryPurple : AppColors.borderGray,
              width: primary ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                AmoraProfileImage(
                  imageUrl: imageUrl!,
                  assetPath: AppImages.fallbackMaleProfile,
                  initials: 'YA',
                  fit: BoxFit.cover,
                )
              else
                const Center(
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: AppColors.primaryPurple,
                    size: 30,
                  ),
                ),
              Positioned(
                right: AmoraSpacing.space4,
                top: AmoraSpacing.space4,
                child: imageUrl == null
                    ? const SizedBox.shrink()
                    : IconButton.filledTonal(
                        tooltip: 'Remove photo ${index + 1}',
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
              ),
              Positioned(
                left: AmoraSpacing.space8,
                right: AmoraSpacing.space8,
                bottom: AmoraSpacing.space8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AmoraRadius.pillBorder,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AmoraSpacing.space4,
                    ),
                    child: Text(
                      primary ? 'Primary' : 'Photo ${index + 1}',
                      textAlign: TextAlign.center,
                      style: AmoraTextStyles.labelMedium.copyWith(
                        color: AppColors.deepWine,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipEditor extends StatelessWidget {
  const _ChipEditor({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onToggle,
    this.lifestyle = false,
  });

  final String title;
  final String subtitle;
  final List<String> options;
  final Set<String> selected;
  final void Function(Set<String> selected, String value) onToggle;
  final bool lifestyle;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      radius: AmoraRadius.extraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: AmoraSpacing.space12),
          Wrap(
            spacing: AmoraSpacing.space8,
            runSpacing: AmoraSpacing.space8,
            children: [
              for (final option in options)
                lifestyle
                    ? LifestyleChip(
                        label: option,
                        selected: selected.contains(option),
                        onTap: () => onToggle(selected, option),
                      )
                    : FilterChip(
                        selected: selected.contains(option),
                        label: Text(option),
                        onSelected: (_) => onToggle(selected, option),
                        selectedColor: AppColors.primaryPurple.withValues(
                          alpha: .14,
                        ),
                        checkmarkColor: AppColors.primaryPurple,
                      ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
=======
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
>>>>>>> main
      children: [
        SizedBox(
          width: AmoraSpacing.minimumTouchTarget,
          child: canGoBack
              ? IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  color: AppColors.primary,
                  icon: const Icon(Icons.arrow_back_rounded),
                )
              : null,
        ),
        const Expanded(child: _BrandMark()),
        const SizedBox(width: AmoraSpacing.minimumTouchTarget),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: AppColors.surface,
            size: 22,
          ),
        ),
        const SizedBox(width: AmoraSpacing.space8),
        Flexible(
          child: Text(
            'AMORA AI',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AmoraTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormSurface extends StatelessWidget {
  const _FormSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AmoraSpacing.space20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AmoraRadius.extraLarge),
        border: Border.all(color: AppColors.tertiary),
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.tertiary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AmoraTextStyles.labelLarge.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AmoraSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AmoraTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AmoraSpacing.space4),
              Text(
                description,
                style: AmoraTextStyles.bodyMedium.copyWith(
                  color: AppColors.textNeutral,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AmoraSpacing.space20),
      child: Divider(color: AppColors.tertiary),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.choices,
    required this.selectedValue,
    required this.onSelected,
    this.preferThreeColumns = false,
  });

  final List<_ProfileChoice> choices;
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final bool preferThreeColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = preferThreeColumns && constraints.maxWidth >= 440
            ? 3
            : 2;
        final spacing = AmoraSpacing.space8 * (columns - 1);
        final itemWidth = (constraints.maxWidth - spacing) / columns;

        return Wrap(
          spacing: AmoraSpacing.space8,
          runSpacing: AmoraSpacing.space8,
          children: [
            for (final choice in choices)
              SizedBox(
                width: itemWidth,
                child: _ChoiceCard(
                  choice: choice,
                  selected: selectedValue == choice.value,
                  onTap: () => onSelected(choice.value),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _ProfileChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: choice.label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.tertiary : AppColors.surface,
          borderRadius: AmoraRadius.button,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.tertiary,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            canRequestFocus: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AmoraSpacing.space12,
                  vertical: AmoraSpacing.space12,
                ),
                child: Row(
                  children: [
                    Icon(
                      choice.icon,
                      color: selected ? AppColors.primary : AppColors.secondary,
                    ),
                    const SizedBox(width: AmoraSpacing.space8),
                    Expanded(
                      child: Text(
                        choice.label,
                        style: AmoraTextStyles.labelLarge.copyWith(
                          color: AppColors.textNeutral,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({required this.value, required this.onTap});

  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: value == null
          ? 'Select date of birth'
          : 'Date of birth, ${_formatDate(value!)}',
      child: InkWell(
        borderRadius: AmoraRadius.input,
        onTap: onTap,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            hintText: 'Select your date',
            prefixIcon: Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
            suffixIcon: Icon(
              Icons.expand_more_rounded,
              color: AppColors.secondary,
            ),
          ),
          child: Text(
            value == null ? 'Select your date' : _formatDate(value!),
            style: AmoraTextStyles.bodyLarge.copyWith(
              color: value == null ? AppColors.textNeutral : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: message == null
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(message),
              padding: const EdgeInsets.only(
                top: AmoraSpacing.space8,
                left: AmoraSpacing.space12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: AmoraSpacing.space8),
                  Expanded(
                    child: Text(
                      message!,
                      style: AmoraTextStyles.bodySmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileChoice {
  const _ProfileChoice({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

const _genderChoices = [
  _ProfileChoice(value: 'Man', label: 'Man', icon: Icons.male_rounded),
  _ProfileChoice(value: 'Woman', label: 'Woman', icon: Icons.female_rounded),
  _ProfileChoice(
    value: 'Non-binary',
    label: 'Non-binary',
    icon: Icons.transgender_rounded,
  ),
  _ProfileChoice(
    value: 'Prefer not to say',
    label: 'Prefer not to say',
    icon: Icons.person_outline_rounded,
  ),
];

const _preferredGenderChoices = [
  _ProfileChoice(value: 'Men', label: 'Men', icon: Icons.man_rounded),
  _ProfileChoice(value: 'Women', label: 'Women', icon: Icons.woman_rounded),
  _ProfileChoice(
    value: 'Everyone',
    label: 'Everyone',
    icon: Icons.groups_rounded,
  ),
];

DateTime _dateYearsAgo(DateTime date, int years) {
  final targetYear = date.year - years;
  final lastDayOfMonth = DateTime(targetYear, date.month + 1, 0).day;
  return DateTime(targetYear, date.month, math.min(date.day, lastDayOfMonth));
}

DateTime _clampDate(DateTime date, DateTime firstDate, DateTime lastDate) {
  if (date.isBefore(firstDate)) return firstDate;
  if (date.isAfter(lastDate)) return lastDate;
  return date;
}

String _formatDate(DateTime date) {
  return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
