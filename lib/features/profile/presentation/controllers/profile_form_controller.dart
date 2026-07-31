import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:flutter/material.dart';

class ProfileFormController extends ChangeNotifier {
  ProfileFormController({LocalProfileRepository? repository})
    : repository = repository ?? LocalProfileRepository.instance {
    _baseProfile = this.repository.profile;
    name = TextEditingController(text: _baseProfile.name);
    profession = TextEditingController(text: _baseProfile.profession);
    company = TextEditingController(text: _baseProfile.company);
    education = TextEditingController(text: _baseProfile.education);
    city = TextEditingController(text: _baseProfile.location);
    bio = TextEditingController(text: _baseProfile.bio);
    datingIntention = TextEditingController(text: _baseProfile.datingIntention);
    birthDate = _baseProfile.dateOfBirth;
    gender = switch (_baseProfile.gender.toLowerCase()) {
      'woman' || 'female' => 'Female',
      'man' || 'male' => 'Male',
      _ => '',
    };
    interests = Set<String>.of(
      ProfileInterestPolicy.visible(_baseProfile.interests),
    );
    _retiredInterests = ProfileInterestPolicy.retired(_baseProfile.interests);
    lifestyle = Map<String, String>.of(_baseProfile.lifestyle);
    final prompt = _baseProfile.prompts.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .firstOrNull;
    promptTitle = prompt?.key ?? ProfileFormOptions.promptTitles.first;
    _originalPromptTitle = prompt?.key;
    promptAnswer = TextEditingController(text: prompt?.value ?? '');
    for (final controller in _textControllers) {
      controller.addListener(_handleTextChanged);
    }
  }

  final LocalProfileRepository repository;
  late UserProfile _baseProfile;
  late final TextEditingController name;
  late final TextEditingController profession;
  late final TextEditingController company;
  late final TextEditingController education;
  late final TextEditingController city;
  late final TextEditingController bio;
  late final TextEditingController datingIntention;
  late final TextEditingController promptAnswer;
  late DateTime? birthDate;
  late String gender;
  late Set<String> interests;
  late Map<String, String> lifestyle;
  late String promptTitle;
  late List<String> _retiredInterests;
  String? _originalPromptTitle;
  bool saving = false;
  bool dirty = false;

  List<TextEditingController> get _textControllers => [
    name,
    profession,
    company,
    education,
    city,
    bio,
    datingIntention,
    promptAnswer,
  ];

  UserProfile get draftProfile {
    final prompts = Map<String, String>.of(_baseProfile.prompts);
    if (_originalPromptTitle != null && _originalPromptTitle != promptTitle) {
      prompts.remove(_originalPromptTitle);
    }
    if (promptAnswer.text.trim().isEmpty) {
      prompts.remove(promptTitle);
    } else {
      prompts[promptTitle] = promptAnswer.text.trim();
    }
    return _baseProfile.copyWith(
      name: name.text.trim(),
      birthdate: birthDate == null ? '' : AmoraDateOfBirth.format(birthDate!),
      gender: gender,
      bio: bio.text.trim(),
      profession: profession.text.trim(),
      company: company.text.trim(),
      education: education.text.trim(),
      location: city.text.trim(),
      datingIntention: datingIntention.text.trim(),
      interests: [...interests, ..._retiredInterests],
      lifestyle: lifestyle,
      prompts: prompts,
    );
  }

  void _handleTextChanged() => markDirty();

  void markDirty() {
    if (!dirty) dirty = true;
    notifyListeners();
  }

  void setBirthDate(DateTime? value) {
    birthDate = value;
    markDirty();
  }

  void setGender(String value) {
    gender = value;
    markDirty();
  }

  void setPromptTitle(String value) {
    promptTitle = value;
    markDirty();
  }

  void toggleInterest(String value, bool selected) {
    if (selected && interests.length >= 10) return;
    selected ? interests.add(value) : interests.remove(value);
    markDirty();
  }

  void setLifestyle(String key, String? value) {
    if (value == null || value.isEmpty || lifestyle[key] == value) {
      lifestyle.remove(key);
    } else {
      lifestyle[key] = value;
    }
    markDirty();
  }

  void refreshExternalProfile() {
    final refreshed = repository.profile;
    _baseProfile = refreshed;
    _retiredInterests = ProfileInterestPolicy.retired(refreshed.interests);
    notifyListeners();
  }

  Future<UserProfile> save() async {
    if (saving) return draftProfile;
    saving = true;
    notifyListeners();
    final updated = draftProfile;
    try {
      await repository.savePersisted(updated);
      _baseProfile = updated;
      _originalPromptTitle = promptTitle;
      dirty = false;
      return updated;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers) {
      controller
        ..removeListener(_handleTextChanged)
        ..dispose();
    }
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
