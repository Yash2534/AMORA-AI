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
    'Long-Term Relationship',
    'Marriage',
    'Intentional Dating',
    'Life Partner',
  ];

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
    'Languages': [
      'English',
      'Hindi',
      'Gujarati',
      'English & Hindi',
      'English, Hindi & Gujarati',
    ],
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
}
