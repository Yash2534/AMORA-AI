import 'dart:math' as math;

import 'package:amora_ai/core/access/amora_access.dart';
import 'package:amora_ai/core/auth/auth_service.dart';
import 'package:amora_ai/core/theme/amora_spacing.dart';
import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/core/widgets/amora_app_bar.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/discover/presentation/browse_grid_screen.dart';
import 'package:amora_ai/features/onboarding/data/local_onboarding_repository.dart';
import 'package:amora_ai/features/onboarding/data/onboarding_api_service.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  static const routeName = '/profile-setup';

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
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
      ProfileFormOptions.cities.contains(_cityController.text.trim());

  String? get _dateOfBirthError => AmoraDateOfBirth.validate(_dateOfBirth);

  @override
  void initState() {
    super.initState();
    final profile = LocalProfileRepository.instance.profile;
    final onboarding = LocalOnboardingRepository.instance.state;
    _gender = ProfileFormOptions.normalizeGender(profile.gender);
    if (_gender?.isEmpty == true) _gender = null;
    _dateOfBirth = profile.dateOfBirth;
    _cityController.text = ProfileFormOptions.normalizeCity(profile.location);
    _preferredGender = onboarding.interestedIn.isEmpty
        ? null
        : ProfileFormOptions.normalizeGender(onboarding.interestedIn.first);
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
              const horizontalPadding = AmoraSpacing.space20;
              final bottomPadding =
                  AmoraSpacing.space24 +
                  MediaQuery.viewPaddingOf(context).bottom +
                  MediaQuery.viewInsetsOf(context).bottom;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AmoraSpacing.space4,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(
                      0,
                      constraints.maxHeight -
                          AmoraSpacing.space4 -
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
                        const SizedBox(height: AmoraSpacing.space16),
                        Text(
                          'Tell us about yourself',
                          textAlign: TextAlign.center,
                          style: AmoraTextStyles.headlineLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AmoraSpacing.space8),
                        Text(
                          'A few essentials help AMORAA create more meaningful matches for you.',
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
                              AmoraaSelectField<String>(
                                key: const ValueKey(
                                  'profile-setup-gender-selector',
                                ),
                                label: 'Gender',
                                value: _gender,
                                hintText: 'Select your gender',
                                prefixIcon: Icons.person_rounded,
                                isRequired: true,
                                errorText:
                                    _showValidationErrors && _gender == null
                                    ? 'Select your gender'
                                    : null,
                                options: [
                                  for (final value
                                      in ProfileFormOptions.genderOptions)
                                    AmoraaSelectOption(
                                      value: value,
                                      label: value,
                                      icon: _genderIcon(value),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _gender = value);
                                  }
                                },
                              ),
                              const _SectionDivider(),
                              const _SectionHeading(
                                number: '2',
                                title: 'Date of birth',
                                description:
                                    'You must be at least 18 to use AMORAA.',
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              AmoraDobField(
                                value: _dateOfBirth,
                                errorText: _showValidationErrors
                                    ? _dateOfBirthError
                                    : null,
                                onChanged: (value) {
                                  setState(() {
                                    _dateOfBirth = value;
                                    _showValidationErrors = true;
                                  });
                                },
                              ),
                              const _SectionDivider(),
                              const _SectionHeading(
                                number: '3',
                                title: 'Preferred gender',
                                description: 'Who would you like to meet?',
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              AmoraaSelectField<String>(
                                key: const ValueKey(
                                  'profile-setup-preferred-gender-selector',
                                ),
                                label: 'Preferred gender',
                                value: _preferredGender,
                                hintText: 'Select who you would like to meet',
                                prefixIcon: Icons.people_alt_rounded,
                                isRequired: true,
                                errorText:
                                    _showValidationErrors &&
                                        _preferredGender == null
                                    ? 'Select a preferred gender'
                                    : null,
                                options: [
                                  for (final value
                                      in ProfileFormOptions.genderOptions)
                                    AmoraaSelectOption(
                                      value: value,
                                      label: value,
                                      icon: _genderIcon(value),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _preferredGender = value);
                                  }
                                },
                              ),
                              const _SectionDivider(),
                              const _SectionHeading(
                                number: '4',
                                title: 'City',
                                description:
                                    'Enter the city where you want to discover matches.',
                              ),
                              const SizedBox(height: AmoraSpacing.space12),
                              AmoraaSelectField<String>(
                                label: 'City',
                                value:
                                    ProfileFormOptions.cities.contains(
                                      _cityController.text,
                                    )
                                    ? _cityController.text
                                    : null,
                                hintText: 'Select city',
                                prefixIcon: Icons.location_city_rounded,
                                isRequired: true,
                                validator: _validateCity,
                                options: [
                                  for (final city in ProfileFormOptions.cities)
                                    AmoraaSelectOption(
                                      value: city,
                                      label: city,
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    _cityController.text = value;
                                  }
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
                          'Your answers are saved to your AMORAA profile.',
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
    final repository = LocalProfileRepository.instance;
    try {
      final preferenceResult = await OnboardingApiService().saveInterestedIn(
        <String>[_preferredGender!],
      );
      if (!preferenceResult.success) {
        throw AuthException(preferenceResult.message);
      }
      await repository.savePersisted(
        repository.profile.copyWith(
          birthdate: AmoraDateOfBirth.format(_dateOfBirth!),
          gender: ProfileFormOptions.storedGenderValue(_gender),
          location: trimmedCity,
        ),
      );
      await LocalOnboardingRepository.instance.syncFromServer();
      if (!mounted) return;
      AmoraSession.completeProfileStep(60);
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(BrowseGridScreen.routeName, (route) => false);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile could not be saved. Please try again.'),
        ),
      );
    }
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    return ProfileFormOptions.cities.contains(value.trim())
        ? null
        : 'Select city';
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
          child: canGoBack ? AmoraHeaderBackButton(onPressed: onBack) : null,
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
            'AMORAA',
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

IconData _genderIcon(String value) => switch (value) {
  'Male' => Icons.male_rounded,
  'Female' => Icons.female_rounded,
  _ => Icons.person_outline_rounded,
};
