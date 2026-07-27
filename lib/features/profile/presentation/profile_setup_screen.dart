import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
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
  }

  @override
  void initState() {
    super.initState();
    _cityController.addListener(_handleFormChanged);
  }

  @override
  void dispose() {
    _cityController
      ..removeListener(_handleFormChanged)
      ..dispose();
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
                        const SizedBox(height: AmoraSpacing.space24),
                        Text(
                          'Tell us about yourself',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.headlineLarge.copyWith(
                            color: AppColors.primary,
                          ),
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
                              const SizedBox(height: AmoraSpacing.space12),
                              _DateOfBirthField(
                                value: _dateOfBirth,
                                onTap: _pickDateOfBirth,
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
    }

    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    AmoraSession.completeProfileStep(60);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
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
