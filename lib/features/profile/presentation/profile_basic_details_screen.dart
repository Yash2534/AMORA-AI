import 'package:amora_ai/core/theme/amora_text_styles.dart';
import 'package:amora_ai/core/theme/app_colors.dart';
import 'package:amora_ai/core/widgets/amora_inputs.dart';
import 'package:amora_ai/core/widgets/app_primary_button.dart';
import 'package:amora_ai/core/widgets/app_text_field.dart';
import 'package:amora_ai/core/widgets/responsive_mobile_frame.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:flutter/material.dart';

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
  late final TextEditingController _birthdate;
  late final TextEditingController _profession;
  late final TextEditingController _company;
  late final TextEditingController _education;
  late final TextEditingController _city;
  late String _gender;

  @override
  void initState() {
    super.initState();
    final profile = LocalProfileRepository.instance.profile;
    _name = TextEditingController(text: profile.name);
    _birthdate = TextEditingController(text: profile.birthdate);
    _profession = TextEditingController(text: profile.profession);
    _company = TextEditingController(text: profile.company);
    _education = TextEditingController(text: profile.education);
    _city = TextEditingController(text: profile.location);
    _gender = profile.gender.isEmpty ? 'Prefer not to say' : profile.gender;
  }

  @override
  void dispose() {
    _name.dispose();
    _birthdate.dispose();
    _profession.dispose();
    _company.dispose();
    _education.dispose();
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
                      AppTextField(
                        controller: _birthdate,
                        label: 'Date of birth',
                        hint: 'DD / MM / YYYY',
                        icon: Icons.cake_outlined,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      AmoraDropdownFormField<String>(
                        label: 'Gender',
                        value: _gender,
                        items: const [
                          'Woman',
                          'Man',
                          'Non-binary',
                          'Prefer not to say',
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _gender = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _profession,
                        label: 'Profession',
                        icon: Icons.work_outline_rounded,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _company,
                        label: 'Company (optional)',
                        icon: Icons.business_outlined,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _education,
                        label: 'Education',
                        icon: Icons.school_outlined,
                        textInputAction: TextInputAction.next,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _city,
                        label: 'City',
                        icon: Icons.location_city_rounded,
                        textInputAction: TextInputAction.done,
                        validator: _required,
                        onSubmitted: (_) => _save(),
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repository = LocalProfileRepository.instance;
    repository.save(
      repository.profile.copyWith(
        name: _name.text.trim(),
        birthdate: _birthdate.text.trim(),
        gender: _gender,
        profession: _profession.text.trim(),
        company: _company.text.trim(),
        education: _education.text.trim(),
        location: _city.text.trim(),
      ),
    );
    Navigator.of(context).pop(true);
  }
}
