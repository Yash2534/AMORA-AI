import 'package:amora_ai/core/widgets/amora_dob_field.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/communication_style.dart';
import 'package:amora_ai/features/profile/domain/profile_interest_policy.dart';
import 'package:flutter/foundation.dart' show mapEquals, setEquals;
import 'package:flutter/material.dart';

class ProfileFormController extends ChangeNotifier {
  ProfileFormController({LocalProfileRepository? repository})
    : repository = repository ?? LocalProfileRepository.instance {
    _baseProfile = this.repository.profile;
    name = TextEditingController(text: _baseProfile.name);
    profession = TextEditingController(
      text: ProfileFormOptions.occupationSelectionFromStored(
        _baseProfile.profession,
      ),
    );
    customOccupation = TextEditingController(
      text: ProfileFormOptions.customOccupationFromStored(
        _baseProfile.profession,
      ),
    );
    company = TextEditingController(text: _baseProfile.company);
    education = TextEditingController(
      text: ProfileFormOptions.normalizeEducation(_baseProfile.education),
    );
    customEducation = TextEditingController(
      text: ProfileFormOptions.customEducationFromStored(
        _baseProfile.education,
      ),
    );
    city = TextEditingController(
      text: ProfileFormOptions.normalizeCity(_baseProfile.location),
    );
    bio = TextEditingController(text: _baseProfile.bio);
    iceBreaker = TextEditingController(text: _baseProfile.iceBreaker);
    datingIntention = TextEditingController(
      text: ProfileFormOptions.normalizeDatingIntention(
        _baseProfile.datingIntention,
      ),
    );
    birthDate = _baseProfile.dateOfBirth;
    gender = ProfileFormOptions.normalizeGender(_baseProfile.gender);
    interests = Set<String>.of(
      ProfileInterestPolicy.visible(_baseProfile.interests),
    );
    _retiredInterests = ProfileInterestPolicy.retired(_baseProfile.interests);
    lifestyle = ProfileFormOptions.normalizeLifestyleSelections(
      _baseProfile.lifestyle,
    );
    languages = ProfileFormOptions.parseLanguages(lifestyle['Languages']);
    hometown = ProfileFormOptions.normalizeHometown(_baseProfile.hometown);
    valuedQualities = ProfileFormOptions.normalizePreferenceValues(
      _baseProfile.valuedQualities,
      ProfileFormOptions.qualities,
    ).toSet();
    pronouns = ProfileFormOptions.normalizePreferenceValues(
      _baseProfile.pronouns,
      ProfileFormOptions.pronouns,
    ).toSet();
    sexuality = ProfileFormOptions.normalizeSexuality(_baseProfile.sexuality);
    preferredTalkingHours = ProfileFormOptions.normalizePreferenceValues(
      _baseProfile.preferredTalkingHours,
      ProfileFormOptions.preferredTalkingHours,
    ).toSet();
    loveLanguages = ProfileFormOptions.normalizePreferenceValues(
      _baseProfile.loveLanguages,
      ProfileFormOptions.loveLanguages,
    ).toSet();
    communicationStyle = _baseProfile.communicationStyle;
    final prompt = _baseProfile.prompts.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .firstOrNull;
    promptTitle = prompt?.key ?? ProfileFormOptions.promptTitles.first;
    _originalPromptTitle = prompt?.key;
    promptAnswer = TextEditingController(text: prompt?.value ?? '');
    promptEditorActive = false;
    for (final controller in _textControllers) {
      controller.addListener(_handleTextChanged);
    }
  }

  final LocalProfileRepository repository;
  late UserProfile _baseProfile;
  late final TextEditingController name;
  late final TextEditingController profession;
  late final TextEditingController customOccupation;
  late final TextEditingController company;
  late final TextEditingController education;
  late final TextEditingController customEducation;
  late final TextEditingController city;
  late final TextEditingController bio;
  late final TextEditingController iceBreaker;
  late final TextEditingController datingIntention;
  late final TextEditingController promptAnswer;
  late DateTime? birthDate;
  late String gender;
  late Set<String> interests;
  late Map<String, String> lifestyle;
  late Set<String> languages;
  late String hometown;
  late Set<String> valuedQualities;
  late Set<String> pronouns;
  late String sexuality;
  late Set<String> preferredTalkingHours;
  late Set<String> loveLanguages;
  late CommunicationStyle? communicationStyle;
  late String promptTitle;
  late List<String> _retiredInterests;
  String? _originalPromptTitle;
  late bool promptEditorActive;
  bool saving = false;
  bool dirty = false;

  List<TextEditingController> get _textControllers => [
    name,
    profession,
    customOccupation,
    company,
    education,
    customEducation,
    city,
    bio,
    iceBreaker,
    datingIntention,
    promptAnswer,
  ];

  UserProfile get draftProfile {
    final updatedLifestyle = Map<String, String>.of(lifestyle);
    final storedLanguages = ProfileFormOptions.serializeLanguages(languages);
    if (storedLanguages.isEmpty) {
      updatedLifestyle.remove('Languages');
    } else {
      updatedLifestyle['Languages'] = storedLanguages;
    }
    final prompts = Map<String, String>.of(_baseProfile.prompts);
    if (promptEditorActive) {
      if (_originalPromptTitle != null) prompts.remove(_originalPromptTitle);
      final answer = promptAnswer.text.trim();
      if (answer.isNotEmpty) prompts[promptTitle] = answer;
    }
    return _baseProfile.copyWith(
      name: name.text.trim(),
      birthdate: birthDate == null ? '' : AmoraDateOfBirth.format(birthDate!),
      gender: ProfileFormOptions.storedGenderValue(gender),
      bio: bio.text.trim(),
      iceBreaker: iceBreaker.text.trim(),
      communicationStyle: communicationStyle,
      profession: ProfileFormOptions.storedOccupationValue(
        profession.text,
        customValue: customOccupation.text,
      ),
      company: company.text.trim(),
      education: education.text.trim(),
      location: city.text.trim(),
      datingIntention: datingIntention.text.trim(),
      interests: [...interests, ..._retiredInterests],
      lifestyle: updatedLifestyle,
      prompts: prompts,
      hometown: hometown,
      valuedQualities: ProfileFormOptions.normalizePreferenceValues(
        valuedQualities,
        ProfileFormOptions.qualities,
      ),
      pronouns: ProfileFormOptions.normalizePreferenceValues(
        pronouns,
        ProfileFormOptions.pronouns,
      ),
      sexuality: sexuality,
      preferredTalkingHours: ProfileFormOptions.normalizePreferenceValues(
        preferredTalkingHours,
        ProfileFormOptions.preferredTalkingHours,
      ),
      loveLanguages: ProfileFormOptions.normalizePreferenceValues(
        loveLanguages,
        ProfileFormOptions.loveLanguages,
      ),
    );
  }

  Map<String, String> get savedPrompts => Map.unmodifiable({
    for (final entry in _baseProfile.prompts.entries)
      if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
  });

  String? get promptEditingOriginalTitle => _originalPromptTitle;

  Iterable<String> get availablePromptTitles =>
      ProfileFormOptions.promptTitles.where(
        (title) =>
            !savedPrompts.containsKey(title) || title == _originalPromptTitle,
      );

  bool get canAddPrompt =>
      savedPrompts.length < ProfileFormOptions.maximumProfilePrompts &&
      availablePromptTitles.isNotEmpty;

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

  void setEducation(String value) {
    education.text = value;
    markDirty();
  }

  void setOccupation(String value) {
    profession.text = value;
    markDirty();
  }

  void setPromptTitle(String value) {
    promptTitle = value;
    markDirty();
  }

  void beginAddPrompt(String title) {
    if (!canAddPrompt || !availablePromptTitles.contains(title)) return;
    _originalPromptTitle = null;
    promptTitle = title;
    promptAnswer.clear();
    promptEditorActive = true;
    dirty = _hasUnsavedNonPromptChanges();
    notifyListeners();
  }

  void beginEditPrompt(String title) {
    final answer = savedPrompts[title];
    if (answer == null) return;
    _originalPromptTitle = title;
    promptTitle = title;
    promptAnswer.text = answer;
    promptEditorActive = true;
    dirty = _hasUnsavedNonPromptChanges();
    notifyListeners();
  }

  void cancelPromptEditing() {
    final originalTitle = _originalPromptTitle;
    promptEditorActive = false;
    _originalPromptTitle = null;
    if (originalTitle == null) {
      promptAnswer.clear();
    } else {
      promptTitle = originalTitle;
      promptAnswer.text = _baseProfile.prompts[originalTitle] ?? '';
    }
    dirty = _hasUnsavedNonPromptChanges();
    notifyListeners();
  }

  Future<UserProfile> savePrompt() async {
    if (!promptEditorActive || saving) return draftProfile;
    final answer = promptAnswer.text.trim();
    if (answer.isEmpty ||
        answer.length > ProfileFormOptions.profilePromptAnswerMaxLength) {
      throw StateError('The profile prompt answer is invalid.');
    }
    final hasOtherChanges = _hasUnsavedNonPromptChanges();
    final prompts = Map<String, String>.of(_baseProfile.prompts);
    if (_originalPromptTitle case final originalTitle?) {
      prompts.remove(originalTitle);
    }
    prompts[promptTitle] = answer;
    final updated = _baseProfile.copyWith(prompts: prompts);
    saving = true;
    notifyListeners();
    try {
      await repository.savePersisted(updated);
      if (answer != promptAnswer.text) {
        promptAnswer.value = TextEditingValue(
          text: answer,
          selection: TextSelection.collapsed(offset: answer.length),
        );
      }
      _baseProfile = repository.profile;
      _originalPromptTitle = null;
      promptEditorActive = false;
      dirty = hasOtherChanges;
      return _baseProfile;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  void setLanguages(Set<String> values) {
    languages = Set<String>.of(values);
    markDirty();
  }

  void setHometown(String? value) {
    hometown = ProfileFormOptions.normalizeHometown(value);
    markDirty();
  }

  void setValuedQualities(Set<String> values) {
    valuedQualities = ProfileFormOptions.normalizePreferenceValues(
      values,
      ProfileFormOptions.qualities,
    ).take(ProfileFormOptions.maximumQualities).toSet();
    markDirty();
  }

  void setPronouns(Set<String> values) {
    pronouns = ProfileFormOptions.normalizePreferenceValues(
      values,
      ProfileFormOptions.pronouns,
    ).take(ProfileFormOptions.maximumPronouns).toSet();
    markDirty();
  }

  void setSexuality(String? value) {
    sexuality = ProfileFormOptions.normalizeSexuality(value);
    markDirty();
  }

  void setPreferredTalkingHours(Set<String> values) {
    preferredTalkingHours = ProfileFormOptions.normalizePreferenceValues(
      values,
      ProfileFormOptions.preferredTalkingHours,
    ).toSet();
    markDirty();
  }

  void setLoveLanguages(Set<String> values) {
    loveLanguages = ProfileFormOptions.normalizePreferenceValues(
      values,
      ProfileFormOptions.loveLanguages,
    ).toSet();
    markDirty();
  }

  void setCommunicationStyle(CommunicationStyle? value) {
    if (value == null) return;
    communicationStyle = value;
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
    lifestyle = ProfileFormOptions.normalizeLifestyleSelections(
      refreshed.lifestyle,
    );
    languages = ProfileFormOptions.parseLanguages(lifestyle['Languages']);
    hometown = ProfileFormOptions.normalizeHometown(refreshed.hometown);
    valuedQualities = ProfileFormOptions.normalizePreferenceValues(
      refreshed.valuedQualities,
      ProfileFormOptions.qualities,
    ).toSet();
    pronouns = ProfileFormOptions.normalizePreferenceValues(
      refreshed.pronouns,
      ProfileFormOptions.pronouns,
    ).toSet();
    sexuality = ProfileFormOptions.normalizeSexuality(refreshed.sexuality);
    preferredTalkingHours = ProfileFormOptions.normalizePreferenceValues(
      refreshed.preferredTalkingHours,
      ProfileFormOptions.preferredTalkingHours,
    ).toSet();
    loveLanguages = ProfileFormOptions.normalizePreferenceValues(
      refreshed.loveLanguages,
      ProfileFormOptions.loveLanguages,
    ).toSet();
    notifyListeners();
  }

  Future<UserProfile> save() async {
    if (saving) return draftProfile;
    if (profession.text == 'Other') {
      final trimmedCustomOccupation = customOccupation.text.trim();
      if (trimmedCustomOccupation != customOccupation.text) {
        customOccupation.value = TextEditingValue(
          text: trimmedCustomOccupation,
          selection: TextSelection.collapsed(
            offset: trimmedCustomOccupation.length,
          ),
        );
      }
    }
    if (education.text == 'Other') {
      final trimmedCustomEducation = customEducation.text.trim();
      if (trimmedCustomEducation != customEducation.text) {
        customEducation.value = TextEditingValue(
          text: trimmedCustomEducation,
          selection: TextSelection.collapsed(
            offset: trimmedCustomEducation.length,
          ),
        );
      }
    }
    if (promptEditorActive) {
      final trimmedPrompt = promptAnswer.text.trim();
      if (trimmedPrompt != promptAnswer.text) {
        promptAnswer.value = TextEditingValue(
          text: trimmedPrompt,
          selection: TextSelection.collapsed(offset: trimmedPrompt.length),
        );
      }
    }
    saving = true;
    notifyListeners();
    final updated = draftProfile;
    try {
      await repository.savePersisted(updated);
      _baseProfile = repository.profile;
      _originalPromptTitle = null;
      promptEditorActive = false;
      dirty = false;
      return _baseProfile;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  bool _hasUnsavedNonPromptChanges() {
    final draft = draftProfile;
    return draft.name != _baseProfile.name ||
        draft.birthdate != _baseProfile.birthdate ||
        draft.gender != _baseProfile.gender ||
        draft.bio != _baseProfile.bio ||
        draft.iceBreaker != _baseProfile.iceBreaker ||
        draft.profession != _baseProfile.profession ||
        draft.company != _baseProfile.company ||
        draft.education != _baseProfile.education ||
        draft.location != _baseProfile.location ||
        draft.datingIntention != _baseProfile.datingIntention ||
        draft.communicationStyle != _baseProfile.communicationStyle ||
        draft.hometown != _baseProfile.hometown ||
        !setEquals(
          draft.valuedQualities.toSet(),
          _baseProfile.valuedQualities.toSet(),
        ) ||
        !setEquals(draft.pronouns.toSet(), _baseProfile.pronouns.toSet()) ||
        draft.sexuality != _baseProfile.sexuality ||
        !setEquals(
          draft.preferredTalkingHours.toSet(),
          _baseProfile.preferredTalkingHours.toSet(),
        ) ||
        !setEquals(
          draft.loveLanguages.toSet(),
          _baseProfile.loveLanguages.toSet(),
        ) ||
        !setEquals(draft.interests.toSet(), _baseProfile.interests.toSet()) ||
        !mapEquals(draft.lifestyle, _baseProfile.lifestyle);
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
