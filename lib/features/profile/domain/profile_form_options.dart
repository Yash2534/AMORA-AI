abstract final class ProfileFormOptions {
  static const occupations = <String>[
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

  static const education = <String>[
    'High School',
    'Diploma',
    'Bachelor’s Degree',
    'Master’s Degree',
    'MBA',
    'Doctorate',
    'Professional Qualification',
  ];

  static const datingIntentions = <String>[
    'Marriage Minded',
    'Long-Term Relationship',
    'Meaningful Dating',
    'Exploring Possibilities',
    'Friendship First',
    'Travel Companion',
    'Fun & Experiences',
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
    'Travel Companion':
        'Looking for someone to explore new places and shared experiences with.',
    'Fun & Experiences':
        'Interested in exciting activities, events, and memorable experiences.',
  };

  static const languageOptions = <String>['English', 'Hindi', 'Gujarati'];

  static const interestGroups = <String, List<String>>{
    'Lifestyle': ['Coffee', 'Mindfulness', 'Volunteering', 'Reading'],
    'Food': ['Cooking', 'Cafes', 'Street food', 'Baking'],
    'Travel': ['Road trips', 'City breaks', 'Heritage walks', 'Beaches'],
    'Music': ['Live music', 'Indie', 'Classical', 'Bollywood'],
    'Fitness': ['Yoga', 'Running', 'Cycling', 'Hiking'],
    'Creativity': ['Photography', 'Design', 'Writing', 'Pottery'],
    'Nature & pets': ['Dogs', 'Cats', 'Gardening', 'Wildlife'],
  };

  static const promptTitles = <String>[
    'My ideal Sunday is...',
    'A green flag I value is...',
    'Together we could...',
  ];

  static const identityOptions = <String, List<String>>{
    'Height': ['Under 5′4″', '5′4″–5′7″', '5′8″–5′11″', '6′0″ and above'],
    'Religion': [
      'Hindu',
      'Muslim',
      'Christian',
      'Sikh',
      'Jain',
      'Spiritual',
      'Prefer not to say',
    ],
  };

  static const lifestyleOptions = <String, List<String>>{
    'Drinking': ['Never', 'Sometimes', 'Socially'],
    'Smoking': ['No', 'Sometimes', 'Prefer not to say'],
    'Exercise': ['Daily', 'A few times a week', 'Occasionally'],
    'Food preference': ['Vegetarian', 'Vegan', 'Everything'],
    'Pets': ['Dog person', 'Cat person', 'Love all pets'],
    'Sleep habits': ['Early bird', 'Night owl', 'Flexible'],
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
        .where((language) => language.isNotEmpty)
        .toSet();
  }

  static String serializeLanguages(Iterable<String> selectedLanguages) {
    final selected = selectedLanguages.toSet();
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
      'open to anything' || 'see where it goes' => 'Exploring Possibilities',
      'new friends' => 'Friendship First',
      'travel partner' => 'Travel Companion',
      'fun' || 'casual' || 'casual connection' => 'Fun & Experiences',
      _ => '',
    };
  }
}
