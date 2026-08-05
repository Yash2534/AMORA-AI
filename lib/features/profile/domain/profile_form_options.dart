abstract final class ProfileFormOptions {
  static const cities = <String>[
    'Gandhinagar',
    'Ahmedabad',
    'Surat',
    'Vadodara',
  ];

  static const occupations = <String>[
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
  ];

  static const education = <String>[
    'School & College',
    'Undergraduate',
    'Postgraduate',
    'Doctorate & Research',
    'Professional',
    'Other',
  ];

  static const datingIntentions = <String>[
    'Marriage Minded',
    'Long-Term Relationship',
    'Meaningful Dating',
    'Exploring Possibilities',
    'Friendship First',
    'Casual Connection',
  ];

  static const datingIntentionDescriptions = <String, String>{
    'Marriage Minded':
        'Focused on marriage and building a committed future together.',
    'Long-Term Relationship':
        'Looking for a serious relationship with long-term potential.',
    'Meaningful Dating':
        'Open to dating and building a genuine emotional connection.',
    'Exploring Possibilities':
        'Open-minded and seeing where a meaningful connection can lead.',
    'Friendship First':
        'Prefer to build trust and friendship before moving forward.',
    'Casual Connection':
        'Interested in exciting activities, events, and memorable experiences.',
  };

  /// Date-style preferences currently approved by Discover Filters.
  ///
  /// This remains separate from [datingIntentions]: these values describe how
  /// someone prefers to spend time together, not the relationship they seek.
  static const datingTypes = <String>[
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
  ];

  static const languages = <String>[
    'Gujarati',
    'Hindi',
    'English',
    'Marathi',
    'Punjabi',
    'Tamil',
    'Malayalam',
  ];

  // Compatibility name retained for existing shared language widgets.
  static const languageOptions = languages;

  static const religions = <String>[
    'Hindu',
    'Jain',
    'Muslim',
    'Sikh',
    'Christian',
    'Spiritual',
    'Open',
  ];

  static const genders = <String>['Male', 'Female', 'Other'];

  // Compatibility name retained for existing shared profile fields.
  static const genderOptions = genders;

  static const int customEducationMaxLength = 80;
  static const int customOccupationMaxLength = 60;

  static const minimumSupportedHeightCm = 137;
  static const maximumSupportedHeightCm = 213;
  static const defaultHeightCm = 165;

  static const interestGroups = <String, List<String>>{
    'Lifestyle': ['Coffee', 'Mindfulness', 'Volunteering', 'Reading'],
    'Food': ['Cooking', 'Cafes', 'Street food', 'Baking'],
    'Travel': ['Road trips', 'City breaks', 'Heritage walks', 'Beaches'],
    'Music': ['Live music', 'Indie', 'Classical', 'Bollywood'],
    'Fitness': ['Yoga', 'Running', 'Cycling', 'Hiking'],
    'Creativity': ['Photography', 'Design', 'Writing', 'Pottery'],
    'Nature & pets': ['Dogs', 'Cats', 'Gardening', 'Wildlife'],
  };

  static final List<String> interests = List<String>.unmodifiable(
    interestGroups.values.expand((group) => group),
  );

  static const promptTitles = <String>[
    'My ideal Sunday is...',
    'A green flag I value is...',
    'Together we could...',
  ];

  static const int maximumProfilePrompts = 3;
  static const int profilePromptAnswerMaxLength = 180;

  static const identityOptions = <String, List<String>>{
    'Height': ['Under 5′4″', '5′4″–5′7″', '5′8″–5′11″', '6′0″ and above'],
    'Religion': religions,
  };

  static const habitFrequencyOptions = <String>[
    'Yes',
    'Sometimes',
    'Never',
    'Prefer not to say',
  ];

  static const smokingOptions = habitFrequencyOptions;
  static const drinkingOptions = habitFrequencyOptions;
  static const weedOptions = habitFrequencyOptions;

  static const habitOptions = <String, List<String>>{
    'Smoking': smokingOptions,
    'Drinking': drinkingOptions,
    'Weed': weedOptions,
  };

  static const nonHabitLifestyleOptions = <String, List<String>>{
    'Exercise': ['Daily', 'A few times a week', 'Occasionally'],
    'Food preference': ['Vegetarian', 'Vegan', 'Everything'],
    'Pets': ['Dog person', 'Cat person', 'Love all pets'],
    'Sleep habits': ['Early bird', 'Night owl', 'Flexible'],
  };

  static const lifestyleOptions = <String, List<String>>{
    ...habitOptions,
    ...nonHabitLifestyleOptions,
  };

  // Weed is optional and intentionally does not alter the existing profile
  // completion rule or percentage.
  static const completionLifestyleOptions = <String, List<String>>{
    'Smoking': smokingOptions,
    'Drinking': drinkingOptions,
    ...nonHabitLifestyleOptions,
  };

  static const allLifestyleOptions = <String, List<String>>{
    ...identityOptions,
    ...lifestyleOptions,
  };

  static Set<String> parseLanguages(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty) return <String>{};
    return value
        .split(RegExp(r'\s*(?:,|&|·|\band\b)\s*', caseSensitive: false))
        .map((language) => language.trim())
        .where(languages.contains)
        .toSet();
  }

  static String serializeLanguages(Iterable<String> selectedLanguages) {
    final selected = selectedLanguages.where(languages.contains).toSet();
    final ordered = <String>[
      for (final language in languageOptions)
        if (selected.remove(language)) language,
      ...selected.toList()..sort(),
    ];
    return switch (ordered.length) {
      0 => '',
      1 => ordered.first,
      2 => '${ordered.first} & ${ordered.last}',
      _ => '${ordered.take(ordered.length - 1).join(', ')} & ${ordered.last}',
    };
  }

  static String normalizeDatingIntention(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (datingIntentions.contains(value)) return value;
    return switch (value.toLowerCase()) {
      'marriage' || 'life partner' => 'Marriage Minded',
      'serious' || 'serious dating' => 'Long-Term Relationship',
      'intentional dating' || 'dating' || 'date' => 'Meaningful Dating',
      'open to anything' ||
      'see where it goes' ||
      'dating and seeing where it goes' ||
      'still figuring it out' => 'Exploring Possibilities',
      'new friends' || 'friendship' => 'Friendship First',
      'fun' || 'casual' || 'casual connection' => 'Casual Connection',
      _ => '',
    };
  }

  static String normalizeDatingType(String? storedValue) =>
      _approvedValue(storedValue, datingTypes);

  static String normalizeInterest(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (interests.contains(value)) return value;
    return switch (value.toLowerCase()) {
      'coffee dates' || 'filter coffee' => 'Coffee',
      'heritage walks' => 'Heritage walks',
      'road trips' => 'Road trips',
      'street food' => 'Street food',
      'live concert' => 'Live music',
      'indie music' => 'Indie',
      'books' || 'book lover' || 'book cafe' => 'Reading',
      _ => '',
    };
  }

  static String normalizeLifestyleValue(String key, String? storedValue) {
    final value = storedValue?.trim() ?? '';
    final options = lifestyleOptions[key];
    if (options == null || value.isEmpty) return '';
    if (options.contains(value)) return value;
    final normalized = value.toLowerCase();
    return switch (key) {
      'Drinking' => switch (normalized) {
        'no' => 'Never',
        'occasionally' || 'rarely' => 'Sometimes',
        'social' || 'socially' => 'Sometimes',
        _ => '',
      },
      'Smoking' => switch (normalized) {
        'no' => 'Never',
        'occasionally' || 'rarely' => 'Sometimes',
        _ => '',
      },
      'Weed' => switch (normalized) {
        'no' => 'Never',
        'occasionally' || 'rarely' => 'Sometimes',
        _ => '',
      },
      _ => '',
    };
  }

  static Map<String, String> normalizeLifestyleSelections(
    Map<String, String> stored,
  ) {
    final result = Map<String, String>.of(stored);
    for (final key in lifestyleOptions.keys) {
      if (!result.containsKey(key)) continue;
      final normalized = normalizeLifestyleValue(key, result[key]);
      if (normalized.isEmpty) {
        result.remove(key);
      } else {
        result[key] = normalized;
      }
    }
    final religion = normalizeReligion(result['Religion']);
    if (religion.isEmpty) {
      result.remove('Religion');
    } else {
      result['Religion'] = religion;
    }
    final languages = serializeLanguages(parseLanguages(result['Languages']));
    if (languages.isEmpty) {
      result.remove('Languages');
    } else {
      result['Languages'] = languages;
    }
    return result;
  }

  static String normalizeCity(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (cities.contains(value)) return value;
    return switch (value.toLowerCase()) {
      'gandhinager' => 'Gandhinagar',
      'ahemdabad' => 'Ahmedabad',
      'vadodra' => 'Vadodara',
      _ => '',
    };
  }

  static String normalizeEducation(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty) return '';
    if (education.contains(value)) return value;
    final normalized = value
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll("'s", '')
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized == 'school' ||
        normalized == 'college' ||
        normalized == 'secondary' ||
        normalized.contains('high school') ||
        normalized.contains('secondary school') ||
        normalized.contains('secondary education') ||
        normalized.contains('diploma')) {
      return 'School & College';
    }
    if (RegExp(
      r'(^|\s)(undergraduate|graduate|bachelor|b tech|b e|b sc|b com|b a|bba|mbbs)(\s|$)',
    ).hasMatch(normalized)) {
      return 'Undergraduate';
    }
    if (RegExp(
      r'(^|\s)(postgraduate|master|mba|m tech|m sc|m com|m a|mca)(\s|$)',
    ).hasMatch(normalized)) {
      return 'Postgraduate';
    }
    if (normalized.contains('phd') ||
        normalized.contains('doctorate') ||
        normalized.contains('doctoral') ||
        normalized.contains('postdoctoral') ||
        normalized.contains('post doctoral')) {
      return 'Doctorate & Research';
    }
    if (normalized == 'professional' ||
        normalized.contains('professional certification') ||
        RegExp(r'(^|[\s/])(ca|cs|cma|cfa)([\s/]|$)').hasMatch(normalized)) {
      return 'Professional';
    }
    return 'Other';
  }

  static String customEducationFromStored(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'other') return '';
    return normalizeEducation(value) == 'Other' ? value : '';
  }

  static String normalizeOccupation(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty) return '';
    if (occupations.contains(value)) return value;
    return switch (value.toLowerCase()) {
      'flutter engineer' => 'Software Engineer',
      'product designer' || 'creative professional' => 'Designer',
      'marketing professional' => 'Marketing',
      'chartered accountant' => 'Finance',
      'other' => 'Other',
      _ => '',
    };
  }

  static String occupationSelectionFromStored(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty) return '';
    final normalized = normalizeOccupation(value);
    return normalized.isEmpty ? 'Other' : normalized;
  }

  static String customOccupationFromStored(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'other') return '';
    return normalizeOccupation(value).isEmpty ? value : '';
  }

  static String storedOccupationValue(
    String? frontendValue, {
    String customValue = '',
  }) {
    final selected = normalizeOccupation(frontendValue);
    if (selected == 'Other') return customValue.trim();
    return selected;
  }

  static String displayOccupation(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'other') return '';
    final normalized = normalizeOccupation(value);
    return normalized.isEmpty ? value : normalized;
  }

  static bool isValidStoredOccupation(String? storedValue) {
    final value = displayOccupation(storedValue);
    if (value.isEmpty) return false;
    final normalized = normalizeOccupation(storedValue);
    return normalized.isNotEmpty || value.length <= customOccupationMaxLength;
  }

  static String normalizeReligion(String? storedValue) =>
      _approvedValue(storedValue, religions);

  static String normalizeGender(String? storedValue) {
    final value = storedValue?.trim().toLowerCase() ?? '';
    return switch (value) {
      'woman' || 'women' || 'female' => 'Female',
      'man' || 'men' || 'male' => 'Male',
      'other' ||
      'non-binary' ||
      'nonbinary' ||
      'non-binary people' ||
      'transgender' ||
      'custom' ||
      'self-describe' ||
      'prefer not to say' => 'Other',
      _ => '',
    };
  }

  static String storedGenderValue(
    String? frontendValue, {
    String customValue = '',
  }) {
    return switch (normalizeGender(frontendValue)) {
      'Male' => 'Man',
      'Female' => 'Woman',
      'Other' when customValue.trim().isNotEmpty => customValue.trim(),
      'Other' => 'Other',
      _ => '',
    };
  }

  static int heightInchesToCentimeters(int inches) => (inches * 2.54).round();

  static int heightCentimetersToNearestInches(int centimeters) =>
      (centimeters / 2.54).round();

  static String formatHeightFeet(int centimeters) {
    final inches = heightCentimetersToNearestInches(centimeters);
    return '${inches ~/ 12}\'${inches % 12}"';
  }

  static String formatHeightCentimeters(int centimeters) => '$centimeters cm';

  static String formatProfileHeight(int centimeters) =>
      '${formatHeightFeet(centimeters)} · ${formatHeightCentimeters(centimeters)}';

  static String formatMinimumHeight(int? centimeters) =>
      centimeters == null ? 'Any height' : '${formatHeightFeet(centimeters)}+';

  static int? parseHeightCentimeters(String? storedValue) {
    final value = storedValue?.trim() ?? '';
    final centimeters = RegExp(
      r'(\d{3})\s*cm',
      caseSensitive: false,
    ).firstMatch(value);
    if (centimeters != null) {
      return _supportedHeight(int.parse(centimeters.group(1)!));
    }
    final feet = RegExp(
      r'''(\d)\s*['′]\s*(\d{1,2})\s*["″]''',
    ).firstMatch(value);
    if (feet == null) return null;
    final inches = int.parse(feet.group(1)!) * 12 + int.parse(feet.group(2)!);
    return _supportedHeight(heightInchesToCentimeters(inches));
  }

  static String heightSemanticsLabel(int centimeters) {
    final inches = heightCentimetersToNearestInches(centimeters);
    return 'Selected height, ${inches ~/ 12} feet ${inches % 12} inches';
  }

  static String _approvedValue(String? storedValue, List<String> options) {
    final value = storedValue?.trim() ?? '';
    return options.contains(value) ? value : '';
  }

  static int? _supportedHeight(int centimeters) {
    if (centimeters < minimumSupportedHeightCm ||
        centimeters > maximumSupportedHeightCm) {
      return null;
    }
    return centimeters;
  }
}
