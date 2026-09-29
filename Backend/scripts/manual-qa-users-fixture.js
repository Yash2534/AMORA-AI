const QA_USERS = Object.freeze({
  krupa: Object.freeze({
    key: 'krupa',
    name: 'Krupa',
    email: 'krupa@gmail.com',
    phoneNumber: '+919999000101',
    age: 27,
    gender: 'Female',
    interestedIn: Object.freeze(['Male']),
    profession: 'Designer',
    height: '165 cm',
    interests: Object.freeze(['Travel', 'Music', 'Movies', 'Food', 'Fitness']),
    bio: 'I enjoy travelling, music, movies, fitness and discovering new places with good people.',
    latitude: 23.022500,
    longitude: 72.571400,
    sourceProfileNumber: 1,
  }),
  yashu: Object.freeze({
    key: 'yashu',
    name: 'Yashu',
    email: 'yashu@gmail.com',
    phoneNumber: '+919999000102',
    age: 29,
    gender: 'Male',
    interestedIn: Object.freeze(['Female']),
    profession: 'Engineer',
    height: '178 cm',
    interests: Object.freeze(['Travel', 'Music', 'Movies', 'Food', 'Cricket']),
    bio: 'I enjoy travel, music, movies, good food, sports and meaningful conversations with interesting people.',
    latitude: 23.025000,
    longitude: 72.575000,
    sourceProfileNumber: 2,
  }),
});

function birthDateForAge(age, now = new Date()) {
  const year = now.getUTCFullYear() - age;
  return `${year}-06-15`;
}

function profileValues(definition, photos, now = new Date()) {
  const languages = ['English', 'Hindi', 'Gujarati'];
  return {
    birthDate: birthDateForAge(definition.age, now),
    gender: definition.gender,
    customGender: '',
    interestedIn: [...definition.interestedIn],
    relationshipGoals: ['Long-Term Relationship'],
    city: 'Ahmedabad',
    preferredDistance: 50,
    matchLatitude: definition.latitude,
    matchLongitude: definition.longitude,
    locationUpdatedAt: now,
    profession: definition.profession,
    company: '',
    education: 'Graduate',
    bio: definition.bio,
    iceBreaker: 'What is one place you would happily visit again?',
    hometown: 'Ahmedabad',
    interests: [...definition.interests],
    lifestyle: {
      Height: definition.height,
      Languages: languages.join(' & '),
      Religion: 'Open',
      Smoking: 'No',
      Drinking: 'Occasionally',
      Weed: 'No',
    },
    prompts: {
      'A perfect weekend looks like':
        'Good food, music, movement, and discovering somewhere new.',
    },
    pronouns: definition.gender === 'Female' ? ['She/Her'] : ['He/Him'],
    sexuality: 'Straight',
    valuedQualities: ['Kindness', 'Honesty', 'Communication'],
    loveLanguages: ['Quality time'],
    preferredTalkingHours: ['Evening'],
    // "Direct" is not a persisted enum. This is the existing canonical
    // direct, substantive communication option shared by both fixtures.
    communicationStyle: 'deep_conversations',
    photos,
    primaryPhotoIndex: 0,
    height: definition.height,
    smoking: 'No',
    drinking: 'Occasionally',
    weed: 'No',
    community: 'Open',
    religion: 'Open',
    languages,
    stage: 'complete',
    onboardingCompleted: true,
  };
}

function preferenceValues(userId) {
  return {
    userId,
    minAge: 25,
    maxAge: 35,
    maxDistanceKm: 50,
    minScore: 0,
    city: null,
    minHeight: null,
    hometown: [],
    datingIntentions: [],
    lifestyleTags: [],
    education: null,
    profession: null,
    community: null,
    religion: null,
    languages: [],
    pronouns: [],
    sexuality: null,
    qualities: [],
    preferredTalkingHours: [],
    loveLanguages: [],
    communicationStyles: [],
    smoking: null,
    drinking: null,
    weed: null,
    verifiedOnly: false,
    onlineNow: false,
    hasPrompts: false,
    hasEventInterest: false,
  };
}

module.exports = {
  QA_USERS,
  birthDateForAge,
  preferenceValues,
  profileValues,
};
