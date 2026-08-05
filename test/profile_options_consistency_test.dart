import 'dart:io';

import 'package:amora_ai/features/discover/presentation/advanced_filters_screen.dart';
import 'package:amora_ai/features/profile/data/local_profile_repository.dart';
import 'package:amora_ai/features/profile/domain/profile_form_options.dart';
import 'package:amora_ai/features/profile/domain/profile_form_validators.dart';
import 'package:amora_ai/features/profile/presentation/controllers/profile_form_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Filter-approved profile option catalogues are exact', () {
    expect(ProfileFormOptions.cities, const [
      'Gandhinagar',
      'Ahmedabad',
      'Surat',
      'Vadodara',
    ]);
    expect(ProfileFormOptions.datingIntentions, const [
      'Marriage Minded',
      'Long-Term Relationship',
      'Meaningful Dating',
      'Exploring Possibilities',
      'Friendship First',
      'Casual Connection',
    ]);
    expect(ProfileFormOptions.datingTypes, const [
      'Travel Companion',
      'Adventure Seeker',
      'Fitness Partner',
      'Foodie Partner',
      'Coffee Dates',
      'Pet Lover',
      'Movie Nights',
      'Music Lover',
      'Road Trip Buddy',
      'Book Lover',
      'Creative Soul',
      'Tech Enthusiast',
      'Wellness & Yoga',
      'Volunteer & Community',
    ]);
    const approvedHabits = <String>[
      'Yes',
      'Sometimes',
      'Never',
      'Prefer not to say',
    ];
    expect(ProfileFormOptions.habitFrequencyOptions, approvedHabits);
    expect(ProfileFormOptions.smokingOptions, approvedHabits);
    expect(ProfileFormOptions.drinkingOptions, approvedHabits);
    expect(ProfileFormOptions.weedOptions, approvedHabits);
    expect(ProfileFormOptions.habitOptions.keys, const [
      'Smoking',
      'Drinking',
      'Weed',
    ]);
    for (final options in ProfileFormOptions.habitOptions.values) {
      expect(
        identical(options, ProfileFormOptions.habitFrequencyOptions),
        isTrue,
      );
      expect(options.where((value) => value == 'Yes'), hasLength(1));
    }
    expect(ProfileFormOptions.education, const [
      'School & College',
      'Undergraduate',
      'Postgraduate',
      'Doctorate & Research',
      'Professional',
      'Other',
    ]);
    expect(ProfileFormOptions.genders, const ['Male', 'Female', 'Other']);
    expect(
      identical(ProfileFormOptions.genders, ProfileFormOptions.genderOptions),
      isTrue,
    );
    expect(ProfileFormOptions.occupations, const [
      'Entrepreneur',
      'Software Engineer',
      'Architect',
      'Doctor',
      'Designer',
      'Student',
      'Business Owner',
      'Marketing',
      'Finance',
      'Other',
    ]);
    expect(ProfileFormOptions.languages, const [
      'Gujarati',
      'Hindi',
      'English',
      'Marathi',
      'Punjabi',
      'Tamil',
      'Malayalam',
    ]);
    expect(ProfileFormOptions.religions, const [
      'Hindu',
      'Jain',
      'Muslim',
      'Sikh',
      'Christian',
      'Spiritual',
      'Open',
    ]);
  });

  test('Filters and both profile flows consume one option source', () {
    expect(identical(approvedFilterCities, ProfileFormOptions.cities), isTrue);

    final filters = File(
      'lib/features/discover/presentation/advanced_filters_screen.dart',
    ).readAsStringSync();
    final fields = File(
      'lib/features/profile/presentation/widgets/amoraa_profile_fields.dart',
    ).readAsStringSync();
    final edit = File(
      'lib/features/profile/presentation/widgets/amoraa_profile_form.dart',
    ).readAsStringSync();
    final completion = File(
      'lib/features/profile/presentation/profile_completion_screen.dart',
    ).readAsStringSync();

    for (final optionSource in const [
      'ProfileFormOptions.cities',
      'ProfileFormOptions.datingIntentions',
      'ProfileFormOptions.education',
      'ProfileFormOptions.occupations',
      'ProfileFormOptions.languages',
      'ProfileFormOptions.religions',
      'ProfileFormOptions.datingTypes',
      'ProfileFormOptions.habitFrequencyOptions',
    ]) {
      expect(filters, contains(optionSource));
    }
    expect(fields, contains('ProfileFormOptions.cities'));
    expect(fields, contains('ProfileFormOptions.education'));
    expect(fields, contains('ProfileFormOptions.occupations'));
    expect(edit, contains('AmoraaLocationIntentionsSection'));
    expect(edit, contains('AmoraaWorkEducationSection'));
    expect(completion, contains('AmoraaLocationIntentionsSection'));
    expect(completion, contains('AmoraaWorkEducationSection'));

    final onboarding = File(
      'lib/features/onboarding/presentation/profile_onboarding_flow.dart',
    ).readAsStringSync();
    final profileFields = File(
      'lib/features/profile/presentation/widgets/amoraa_profile_fields.dart',
    ).readAsStringSync();
    final sectionEditor = File(
      'lib/features/profile/presentation/profile_section_editor_screen.dart',
    ).readAsStringSync();
    expect(onboarding, contains('ProfileFormOptions.datingIntentions'));
    expect(profileFields, contains('ProfileFormOptions.interestGroups'));
    expect(profileFields, contains('ProfileFormOptions.lifestyleOptions'));
    expect(sectionEditor, contains('ProfileFormOptions.interestGroups'));
    expect(sectionEditor, contains('ProfileFormOptions.allLifestyleOptions'));

    for (final removedList in const [
      '_relationshipIntentions',
      '_educationList',
      '_professionList',
      '_religionList',
      '_languageList',
      '_lifestyleInterests',
    ]) {
      expect(filters, isNot(contains(removedList)));
    }
  });

  test(
    'onboarding, setup, date spots, and generated profiles share sources',
    () {
      final onboarding = File(
        'lib/features/onboarding/presentation/profile_onboarding_flow.dart',
      ).readAsStringSync();
      final setup = File(
        'lib/features/profile/presentation/profile_setup_screen.dart',
      ).readAsStringSync();
      final dateSpots = File(
        'lib/features/date_spots/presentation/date_spots_map_screen.dart',
      ).readAsStringSync();
      final profiles = File(
        'lib/core/data/image_repository.dart',
      ).readAsStringSync();

      expect(onboarding, contains('ProfileFormOptions.cities'));
      expect(onboarding, contains('ProfileFormOptions.genderOptions'));
      expect(setup, contains('ProfileFormOptions.cities'));
      expect(setup, contains('ProfileFormOptions.genderOptions'));
      expect(dateSpots, contains('ProfileFormOptions.cities'));
      expect(profiles, contains('ProfileFormOptions.cities'));
      expect(profiles, contains('ProfileFormOptions.education'));
      expect(setup, isNot(contains('_genderChoices')));
      expect(
        File('lib/features/onboarding/data/gujarat_cities.dart').existsSync(),
        isFalse,
      );
    },
  );

  test('selection codecs reject extras and map supported saved values', () {
    expect(
      ProfileFormOptions.normalizeOccupation('Product Designer'),
      'Designer',
    );
    expect(ProfileFormOptions.normalizeOccupation('Photographer'), isEmpty);
    expect(
      ProfileFormOptions.occupationSelectionFromStored('Photographer'),
      'Other',
    );
    expect(
      ProfileFormOptions.customOccupationFromStored('Photographer'),
      'Photographer',
    );
    expect(
      ProfileFormOptions.storedOccupationValue(
        'Other',
        customValue: '  Photographer  ',
      ),
      'Photographer',
    );
    expect(
      ProfileFormOptions.displayOccupation('Photographer'),
      'Photographer',
    );
    expect(
      ProfileFormOptions.normalizeEducation('Bachelor’s Degree'),
      'Undergraduate',
    );
    expect(
      ProfileFormOptions.normalizeEducation('Diploma'),
      'School & College',
    );
    expect(ProfileFormOptions.normalizeEducation('MBA'), 'Postgraduate');
    expect(
      ProfileFormOptions.normalizeEducation('PhD'),
      'Doctorate & Research',
    );
    expect(ProfileFormOptions.normalizeEducation('CFA'), 'Professional');
    expect(ProfileFormOptions.normalizeEducation('Nirma University'), 'Other');
    expect(
      ProfileFormOptions.customEducationFromStored('Nirma University'),
      'Nirma University',
    );
    expect(ProfileFormOptions.normalizeGender('Man'), 'Male');
    expect(ProfileFormOptions.normalizeGender('Women'), 'Female');
    expect(ProfileFormOptions.normalizeGender('Non-binary'), 'Other');
    expect(ProfileFormOptions.storedGenderValue('Male'), 'Man');
    expect(ProfileFormOptions.storedGenderValue('Female'), 'Woman');
    expect(
      ProfileFormOptions.storedGenderValue('Other', customValue: 'Non-binary'),
      'Non-binary',
    );
    expect(ProfileFormOptions.normalizeCity('Ahemdabad'), 'Ahmedabad');
    expect(
      ProfileFormOptions.normalizeDatingIntention('Casual'),
      'Casual Connection',
    );
    expect(ProfileFormOptions.normalizeCity('Rajkot'), isEmpty);
    expect(ProfileFormOptions.normalizeReligion('Prefer not to say'), isEmpty);
    expect(
      ProfileFormOptions.normalizeLifestyleValue('Drinking', 'Rarely'),
      'Sometimes',
    );
    expect(
      ProfileFormOptions.normalizeLifestyleValue('Smoking', 'Never'),
      'Never',
    );
    expect(ProfileFormOptions.normalizeLifestyleValue('Smoking', 'Yes'), 'Yes');
    expect(
      ProfileFormOptions.normalizeLifestyleValue('Smoking', 'No'),
      'Never',
    );
    expect(
      ProfileFormOptions.normalizeLifestyleValue('Drinking', 'Socially'),
      'Sometimes',
    );
    expect(
      ProfileFormOptions.normalizeLifestyleValue('Weed', 'Occasionally'),
      'Sometimes',
    );
    expect(
      ProfileFormOptions.normalizeInterest('Heritage Walks'),
      'Heritage walks',
    );
    expect(ProfileFormOptions.normalizeInterest('Gaming'), isEmpty);
    expect(ProfileFormOptions.parseLanguages('English, Telugu & Gujarati'), {
      'English',
      'Gujarati',
    });
  });

  test(
    'custom Education validation rejects blank and accepts trimmed text',
    () {
      expect(
        ProfileFormValidators.customEducation('Undergraduate', ''),
        isNull,
      );
      expect(
        ProfileFormValidators.customEducation('Other', '   '),
        'Specify education',
      );
      expect(
        ProfileFormValidators.customEducation('Other', '  Montessori  '),
        isNull,
      );
    },
  );

  test('custom Occupation validation and completion use one mapping', () {
    expect(ProfileFormValidators.customOccupation('Designer', ''), isNull);
    expect(
      ProfileFormValidators.customOccupation('Other', '   '),
      'Please enter your occupation.',
    );
    expect(
      ProfileFormValidators.customOccupation('Other', '  Photographer  '),
      isNull,
    );
    expect(ProfileFormOptions.isValidStoredOccupation('Other'), isFalse);
    expect(ProfileFormOptions.isValidStoredOccupation('Photographer'), isTrue);
  });

  test('legacy values load safely without mutating persisted profile data', () {
    final repository = LocalProfileRepository.instance;
    final original = repository.profile;
    addTearDown(() => repository.resetForTesting(original));
    final legacy = original.copyWith(
      education: 'Nirma University',
      profession: 'Photographer',
      location: 'Rajkot',
      gender: 'Woman',
    );
    repository.save(legacy);

    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    expect(controller.education.text, 'Other');
    expect(controller.customEducation.text, 'Nirma University');
    expect(controller.profession.text, 'Other');
    expect(controller.customOccupation.text, 'Photographer');
    expect(controller.city.text, isEmpty);
    expect(controller.gender, 'Female');
    expect(repository.profile.toJson(), legacy.toJson());

    controller.setGender('Male');
    controller.setGender('Other');
    expect(controller.draftProfile.gender, 'Other');
  });

  test('habit selectors replace values and completion recognizes Yes', () {
    final repository = LocalProfileRepository.instance;
    final original = repository.profile;
    addTearDown(() => repository.resetForTesting(original));
    repository.save(original.copyWith(lifestyle: const {'Drinking': 'Rarely'}));

    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);
    expect(controller.lifestyle['Drinking'], 'Sometimes');
    expect(repository.profile.lifestyle['Drinking'], 'Rarely');

    controller.setLifestyle('Drinking', 'Yes');
    expect(controller.lifestyle['Drinking'], 'Yes');
    controller.setLifestyle('Drinking', 'Sometimes');
    expect(controller.lifestyle['Drinking'], 'Sometimes');

    controller.setLifestyle('Weed', 'Never');
    expect(controller.lifestyle['Drinking'], 'Sometimes');
    expect(controller.lifestyle['Weed'], 'Never');

    final yesProfile = original.copyWith(lifestyle: const {'Smoking': 'Yes'});
    final lifestyle = yesProfile.completionResult.sections.firstWhere(
      (section) => section.title == 'Lifestyle',
    );
    expect(lifestyle.isComplete, isTrue);

    final weedOnlyProfile = original.copyWith(
      lifestyle: const {'Weed': 'Never'},
    );
    final weedOnlyLifestyle = weedOnlyProfile.completionResult.sections
        .firstWhere((section) => section.title == 'Lifestyle');
    expect(weedOnlyLifestyle.isComplete, isFalse);
  });

  test('height formatting and conversion have one shared implementation', () {
    expect(ProfileFormOptions.heightInchesToCentimeters(65), 165);
    expect(ProfileFormOptions.heightCentimetersToNearestInches(165), 65);
    expect(ProfileFormOptions.formatHeightFeet(165), '5\'5"');
    expect(ProfileFormOptions.formatProfileHeight(165), '5\'5" · 165 cm');
    expect(ProfileFormOptions.parseHeightCentimeters('5\'5" · 165 cm'), 165);
  });

  test('approved saved profile values load without changing filter state', () {
    final repository = LocalProfileRepository.instance;
    final original = repository.profile;
    addTearDown(() => repository.resetForTesting(original));
    final approved = original.copyWith(
      profession: 'Designer',
      education: 'Postgraduate',
      location: 'Surat',
      datingIntention: 'Marriage Minded',
      lifestyle: const {
        'Height': '5\'5" · 165 cm',
        'Languages': 'Gujarati & English',
        'Religion': 'Jain',
      },
    );
    repository.save(approved);
    final controller = ProfileFormController(repository: repository);
    addTearDown(controller.dispose);

    expect(controller.profession.text, 'Designer');
    expect(controller.education.text, 'Postgraduate');
    expect(controller.city.text, 'Surat');
    expect(controller.datingIntention.text, 'Marriage Minded');
    expect(controller.languages, {'Gujarati', 'English'});
    expect(controller.lifestyle['Religion'], 'Jain');

    final filters = File(
      'lib/features/discover/presentation/advanced_filters_screen.dart',
    ).readAsStringSync();
    expect(filters, isNot(contains('LocalProfileRepository')));
    expect(repository.profile.toJson(), approved.toJson());
  });
}
