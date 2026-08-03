import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/core/widgets/amoraa_select_field.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileBasicDetailsScreen extends StatefulWidget {
  const ProfileBasicDetailsScreen({super.key});

  static const routeName = '/profile-basic-details';

  @override
  State<ProfileBasicDetailsScreen> createState() =>
      _ProfileBasicDetailsScreenState();
}

class _ProfileBasicDetailsScreenState extends State<ProfileBasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _profession;
  late final TextEditingController _company;
  late final TextEditingController _education;
  late final TextEditingController _customEducation;
  late final TextEditingController _city;
  late String _gender;
  DateTime? _birthDate;
  bool _showDobError = false;

  @override
  void initState() {
    super.initState();
    final profile = LocalProfileRepository.instance.profile;
    _name = TextEditingController(text: profile.name);
    _birthDate = profile.dateOfBirth;
    _profession = TextEditingController(
      text: ProfileFormOptions.normalizeOccupation(profile.profession),
    );
    _company = TextEditingController(text: profile.company);
    _education = TextEditingController(
      text: ProfileFormOptions.normalizeEducation(profile.education),
    );
    _customEducation = TextEditingController(
      text: ProfileFormOptions.customEducationFromStored(profile.education),
    );
    _city = TextEditingController(
      text: ProfileFormOptions.normalizeCity(profile.location),
    );
    _gender = ProfileFormOptions.normalizeGender(profile.gender);
  }

  @override
  void dispose() {
    _name.dispose();
    _profession.dispose();
    _company.dispose();
    _education.dispose();
    _customEducation.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Basic details'),
        leading: IconButton(
          tooltip: 'Back to profile completion',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveMobileFrame(
          maxWidth: 560,
          child: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    children: [
                      Text(
                        'The details that help people understand your everyday life.',
                        style: AmoraTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _name,
                        label: 'Name',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      AmoraaSelectField<String>(
                        label: 'Gender',
                        value: _gender.isEmpty ? null : _gender,
                        hintText: 'Select gender',
                        prefixIcon: Icons.person_outline_rounded,
                        isRequired: true,
                        validator: (value) =>
                            ProfileFormValidators.approvedSelection(
                              value,
                              ProfileFormOptions.genderOptions,
                              'gender',
                            ),
                        options: [
                          for (final value in ProfileFormOptions.genderOptions)
                            AmoraaSelectOption(value: value, label: value),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _gender = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      AmoraaSearchableSelect<String>(
                        label: 'Occupation',
                        value: _profession.text.isEmpty
                            ? null
                            : _profession.text,
                        hintText: 'Select occupation',
                        searchHint: 'Search occupation',
                        prefixIcon: Icons.work_outline_rounded,
                        isRequired: true,
                        validator: (value) =>
                            ProfileFormValidators.approvedSelection(
                              value,
                              ProfileFormOptions.occupations,
                              'occupation',
                            ),
                        options: [
                          for (final value in ProfileFormOptions.occupations)
                            AmoraaSelectOption(value: value, label: value),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _profession.text = value);
                          }
                        },
                      ),
                      if (_education.text == 'Other') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey(
                            'profile-basic-custom-education-field',
                          ),
                          controller: _customEducation,
                          maxLength:
                              ProfileFormOptions.customEducationMaxLength,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              ProfileFormOptions.customEducationMaxLength,
                            ),
                          ],
                          validator: (value) =>
                              ProfileFormValidators.customEducation(
                                _education.text,
                                value,
                              ),
                          decoration: const InputDecoration(
                            labelText: 'Specify education',
                            hintText: 'Enter your education',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                            counterText: '',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _company,
                        label: 'Company (optional)',
                        icon: Icons.business_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AmoraaSelectField<String>(
                        label: 'Education',
                        value: _education.text.isEmpty ? null : _education.text,
                        hintText: 'Select education',
                        prefixIcon: Icons.school_outlined,
                        isRequired: true,
                        validator: (value) =>
                            ProfileFormValidators.approvedSelection(
                              value,
                              ProfileFormOptions.education,
                              'education',
                            ),
                        options: [
                          for (final value in ProfileFormOptions.education)
                            AmoraaSelectOption(value: value, label: value),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _education.text = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AmoraaSearchableSelect<String>(
                        label: 'City',
                        value: _city.text.isEmpty ? null : _city.text,
                        hintText: 'Select city',
                        searchHint: 'Search city',
                        prefixIcon: Icons.location_city_rounded,
                        isRequired: true,
                        validator: (value) =>
                            ProfileFormValidators.approvedSelection(
                              value,
                              ProfileFormOptions.cities,
                              'city',
                            ),
                        options: [
                          for (final value in ProfileFormOptions.cities)
                            AmoraaSelectOption(value: value, label: value),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _city.text = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: AppPrimaryButton(
                  key: const Key('save-basic-details'),
                  label: 'Save profile details',
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  void _save() {
    FocusScope.of(context).unfocus();
    if (_education.text == 'Other') {
      final trimmedCustomEducation = _customEducation.text.trim();
      if (trimmedCustomEducation != _customEducation.text) {
        _customEducation.value = TextEditingValue(
          text: trimmedCustomEducation,
          selection: TextSelection.collapsed(
            offset: trimmedCustomEducation.length,
          ),
        );
      }
    }
    setState(() => _showDobError = true);
    if (!(_formKey.currentState?.validate() ?? false) ||
        AmoraDateOfBirth.validate(_birthDate) != null) {
      return;
    }
    final repository = LocalProfileRepository.instance;
    repository.save(
      repository.profile.copyWith(
        name: _name.text.trim(),
        birthdate: AmoraDateOfBirth.format(_birthDate!),
        gender: ProfileFormOptions.storedGenderValue(_gender),
        profession: _profession.text.trim(),
        company: _company.text.trim(),
        education: _education.text.trim(),
        location: _city.text.trim(),
      ),
    );
    Navigator.of(context).pop(true);
  }
}
