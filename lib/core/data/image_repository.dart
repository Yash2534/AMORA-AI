import 'package:amora_ai/core/constants/app_images.dart';
import 'package:flutter/material.dart';

class ImageRepository {
  const ImageRepository._();

  static final profiles = <DummyProfile>[
    for (var i = 0; i < 150; i++) _profile(i, Gender.female),
    for (var i = 0; i < 150; i++) _profile(i, Gender.male),
  ];

  static final events = <EventImageData>[
    for (var i = 0; i < _eventNames.length; i++)
      EventImageData(
        id: _slug(_eventNames[i]),
        title: _eventNames[i],
        imageUrl: AppImages.eventAt(i),
        fallbackAsset: AppImages.eventAt(i),
        venue: _eventVenues[i],
        organizer: _eventHosts[i % _eventHosts.length],
        city: _eventCities[i % _eventCities.length],
        category: _eventCategories[i],
        icon: _eventIcons[i],
        ticketCount: 24 + (i * 7 % 96),
        countdown: i < 3 ? 'Tonight' : '${i + 2} days',
        rating: 4.4 + ((i % 6) * .1),
        mapHint: '${_eventCities[i % _eventCities.length]} central venue',
      ),
  ];

  static final venues = <VenueImageData>[
    for (var i = 0; i < _venueNames.length; i++)
      VenueImageData(
        id: _slug(_venueNames[i]),
        name: _venueNames[i],
        imageUrl: AppImages.dateSpotAt(i),
        fallbackAsset: AppImages.dateSpotAt(i),
        city: _eventCities[i % _eventCities.length],
        category: _venueCategories[i % _venueCategories.length],
        rating: 4.3 + ((i % 7) * .08),
        priceRange: i.isEven ? 'Rs 900 for two' : 'Rs 1,600 for two',
        bestFor: _venueBestFor[i % _venueBestFor.length],
      ),
  ];

  static DummyProfile profileAt(int index) => profiles[index % profiles.length];

  static DummyProfile profileByName(String name) {
    final key = name.toLowerCase().trim().split(RegExp(r'\s+')).first;
    return profiles.firstWhere((profile) {
      final first = profile.name.toLowerCase().split(RegExp(r'\s+')).first;
      return first == key || profile.name.toLowerCase() == key;
    }, orElse: () => profiles[_stableIndex(name, profiles.length)]);
  }

  static EventImageData eventByName(String name) {
    final lower = name.toLowerCase();
    return events.firstWhere(
      (event) =>
          lower.contains(event.title.toLowerCase()) ||
          lower.contains(event.id.replaceAll('-', ' ')),
      orElse: () => events[_stableIndex(name, events.length)],
    );
  }

  static VenueImageData venueByName(String name) {
    final lower = name.toLowerCase();
    return venues.firstWhere(
      (venue) =>
          lower.contains(venue.name.toLowerCase()) ||
          venue.name.toLowerCase().contains(lower),
      orElse: () => venues[_stableIndex(name, venues.length)],
    );
  }

  static int _stableIndex(String seed, int length) {
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash % length;
  }

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

enum Gender { female, male }

class DummyProfile {
  const DummyProfile({
    required this.id,
    required this.gender,
    required this.name,
    required this.age,
    required this.city,
    required this.profession,
    required this.education,
    required this.distance,
    required this.score,
    required this.intent,
    required this.personality,
    required this.status,
    required this.bio,
    required this.interests,
    required this.imageUrl,
    required this.gallery,
    required this.languages,
    required this.verification,
    required this.lifestyle,
    required this.promptAnswers,
    required this.travelPreference,
    required this.musicTaste,
    required this.foodPreference,
    required this.weekendPlan,
    required this.petPreference,
    required this.coffeePreference,
    required this.religion,
    required this.community,
    required this.height,
    required this.fitnessLevel,
    required this.smoking,
    required this.drinking,
    required this.children,
    required this.loveLanguage,
    required this.greenFlags,
    required this.redFlags,
    required this.familyValues,
    required this.dateIdeas,
  });

  final String id;
  final Gender gender;
  final String name;
  final int age;
  final String city;
  final String profession;
  final String education;
  final String distance;
  final int score;
  final String intent;
  final String personality;
  final String status;
  final String bio;
  final List<String> interests;
  final String imageUrl;
  final List<String> gallery;
  final List<String> languages;
  final String verification;
  final List<String> lifestyle;
  final Map<String, String> promptAnswers;
  final String travelPreference;
  final String musicTaste;
  final String foodPreference;
  final String weekendPlan;
  final String petPreference;
  final String coffeePreference;
  final String religion;
  final String community;
  final String height;
  final String fitnessLevel;
  final String smoking;
  final String drinking;
  final String children;
  final String loveLanguage;
  final List<String> greenFlags;
  final List<String> redFlags;
  final String familyValues;
  final List<String> dateIdeas;

  String get fallbackAsset => gender == Gender.female
      ? AppImages.femaleProfileFallback
      : AppImages.maleProfileFallback;
  String get initials => AppImages.initialsForName(name);
  String get compatibility => '$score%';
  bool get verified => verification.toLowerCase().contains('verified');
  bool get premium => score >= 91;
}

class EventImageData {
  const EventImageData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.venue,
    required this.organizer,
    required this.city,
    required this.category,
    required this.icon,
    required this.ticketCount,
    required this.countdown,
    required this.rating,
    required this.mapHint,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String fallbackAsset;
  final String venue;
  final String organizer;
  final String city;
  final String category;
  final IconData icon;
  final int ticketCount;
  final String countdown;
  final double rating;
  final String mapHint;
}

class VenueImageData {
  const VenueImageData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.city,
    required this.category,
    required this.rating,
    required this.priceRange,
    required this.bestFor,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String fallbackAsset;
  final String city;
  final String category;
  final double rating;
  final String priceRange;
  final String bestFor;
}

DummyProfile _profile(int index, Gender gender) {
  final female = gender == Gender.female;
  final firstNames = female ? _femaleNames : _maleNames;
  final first = firstNames[index % firstNames.length];
  final last = _lastNames[(index * 7) % _lastNames.length];
  final city =
      _profileCities[(index * 5 + (female ? 1 : 3)) % _profileCities.length];
  final profession =
      (female ? _femaleProfessions : _maleProfessions)[index %
          (female ? _femaleProfessions.length : _maleProfessions.length)];
  final intent = _intentions[index % _intentions.length];
  final score = 82 + ((index * 7 + (female ? 9 : 5)) % 17);
  final interestOffset = index * 3;
  final interests = [
    for (var i = 0; i < 5; i++)
      _interests[(interestOffset + i * 4) % _interests.length],
  ];
  final lifestyle = [
    _fitness[(index + 1) % _fitness.length],
    _weekendPlans[(index + 3) % _weekendPlans.length],
    _food[(index + 4) % _food.length],
  ];
  final primaryPhoto = AppImages.profileAt(index, male: !female);
  final gallery = AppImages.galleryForIndex(index, male: !female);
  return DummyProfile(
    id: '${female ? 'female' : 'male'}-${index + 1}',
    gender: gender,
    name: '$first $last',
    age: 23 + ((index * 5 + (female ? 0 : 2)) % 12),
    city: city,
    profession: profession,
    education: _education[(index * 3) % _education.length],
    distance: '${2 + ((index * 11) % 295)} km',
    score: score,
    intent: intent,
    personality: _personalities[index % _personalities.length],
    status: index % 5 == 0
        ? 'Online now'
        : index % 3 == 0
        ? 'Recently active'
        : 'Verified',
    bio:
        '${_bioOpeners[index % _bioOpeners.length]} ${_bioClosers[(index * 2) % _bioClosers.length]}',
    interests: interests,
    imageUrl: primaryPhoto,
    gallery: [primaryPhoto, ...gallery],
    languages: _languageSets[index % _languageSets.length],
    verification: index % 4 == 0
        ? 'Selfie + ID + workplace verified'
        : 'Selfie + ID verified',
    lifestyle: lifestyle,
    promptAnswers: {
      'My ideal Sunday is': _weekendPlans[index % _weekendPlans.length],
      'A green flag I value is': _greenFlags[index % _greenFlags.length],
      'Together we could': _dateIdeas[index % _dateIdeas.length],
    },
    travelPreference: _travel[(index * 2) % _travel.length],
    musicTaste: _music[(index * 3) % _music.length],
    foodPreference: _food[(index * 5) % _food.length],
    weekendPlan: _weekendPlans[(index * 7) % _weekendPlans.length],
    petPreference: _pets[(index * 2) % _pets.length],
    coffeePreference: _coffee[(index * 3) % _coffee.length],
    religion: _religions[index % _religions.length],
    community: _communities[(index * 2) % _communities.length],
    height: female ? '5\'${2 + (index % 8)}"' : '5\'${7 + (index % 6)}"',
    fitnessLevel: _fitness[index % _fitness.length],
    smoking: _smoking[index % _smoking.length],
    drinking: _drinking[(index + 1) % _drinking.length],
    children: _children[(index + 2) % _children.length],
    loveLanguage: _loveLanguages[index % _loveLanguages.length],
    greenFlags: [
      _greenFlags[index % _greenFlags.length],
      _greenFlags[(index + 4) % _greenFlags.length],
    ],
    redFlags: [
      _redFlags[index % _redFlags.length],
      _redFlags[(index + 3) % _redFlags.length],
    ],
    familyValues: _familyValues[index % _familyValues.length],
    dateIdeas: [
      _dateIdeas[index % _dateIdeas.length],
      _dateIdeas[(index + 5) % _dateIdeas.length],
      _dateIdeas[(index + 9) % _dateIdeas.length],
    ],
  );
}

const _femaleNames = [
  'Aadhya',
  'Kavya',
  'Riya',
  'Ananya',
  'Meera',
  'Nisha',
  'Krisha',
  'Sneha',
  'Ishita',
  'Diya',
  'Tara',
  'Mahi',
  'Avni',
  'Jiya',
  'Pooja',
  'Leela',
  'Reva',
  'Prisha',
  'Zoya',
  'Sana',
  'Myra',
  'Aarohi',
  'Kiara',
  'Ira',
  'Navya',
  'Vanya',
  'Suhani',
  'Tanvi',
  'Ayesha',
  'Fatima',
  'Mira',
  'Dhriti',
  'Esha',
  'Gayatri',
  'Hiral',
  'Jhanvi',
  'Lavanya',
  'Mahek',
  'Neha',
  'Ojasvi',
  'Pari',
  'Ruhi',
  'Saanvi',
  'Trisha',
  'Urvi',
  'Vidhi',
  'Yamini',
  'Aditi',
  'Charvi',
  'Devika',
];
const _maleNames = [
  'Arjun',
  'Yash',
  'Dhruv',
  'Aarav',
  'Vihaan',
  'Rohan',
  'Dev',
  'Kabir',
  'Neil',
  'Samar',
  'Harsh',
  'Ishan',
  'Parth',
  'Manav',
  'Ayaan',
  'Vivaan',
  'Kunal',
  'Om',
  'Rudra',
  'Nirav',
  'Aditya',
  'Aryan',
  'Reyansh',
  'Shaurya',
  'Ved',
  'Nikhil',
  'Akash',
  'Karan',
  'Rahul',
  'Siddharth',
  'Varun',
  'Mihir',
  'Darshan',
  'Jay',
  'Laksh',
  'Mohit',
  'Pranav',
  'Rishi',
  'Tanay',
  'Utkarsh',
  'Virat',
  'Zain',
  'Aniket',
  'Bhavik',
  'Chirag',
  'Eshan',
  'Farhan',
  'Gaurav',
  'Hemant',
];
const _lastNames = [
  'Shah',
  'Patel',
  'Mehta',
  'Desai',
  'Joshi',
  'Iyer',
  'Rao',
  'Kapoor',
  'Malhotra',
  'Bose',
  'Nair',
  'Menon',
  'Khan',
  'Sheikh',
  'Ansari',
  'Trivedi',
  'Vyas',
  'Reddy',
  'Pillai',
  'Chopra',
  'Agarwal',
  'Bhatia',
  'Kulkarni',
  'Saxena',
  'Banerjee',
];
const _profileCities = [
  'Ahmedabad',
  'Gandhinagar',
  'Vadodara',
  'Surat',
  'Rajkot',
  'Mumbai',
  'Pune',
  'Delhi',
  'Bengaluru',
  'Hyderabad',
  'Jaipur',
  'Indore',
  'Chandigarh',
  'Kochi',
  'Lucknow',
  'Nagpur',
];
const _femaleProfessions = [
  'UX Designer',
  'Architect',
  'Doctor',
  'Marketing Lead',
  'Classical Singer',
  'Interior Stylist',
  'Chartered Accountant',
  'Fashion Buyer',
  'Product Designer',
  'Wedding Planner',
  'Psychologist',
  'Civil Engineer',
  'Dermatologist',
  'Art Curator',
  'Brand Strategist',
  'Professor',
];
const _maleProfessions = [
  'Photographer',
  'Flutter Engineer',
  'Founder',
  'Product Manager',
  'Investment Analyst',
  'Fitness Coach',
  'Corporate Lawyer',
  'Journalist',
  'Data Scientist',
  'Chef',
  'Hotelier',
  'Musician',
  'Textile Entrepreneur',
  'Veterinarian',
  'Film Editor',
  'Pilot',
];
const _education = [
  'CEPT University',
  'IIM Ahmedabad',
  'NID Ahmedabad',
  'Mumbai University',
  'Delhi University',
  'Symbiosis Pune',
  'Christ University',
  'MS University',
  'NIFT Mumbai',
  'Manipal University',
  'Ashoka University',
  'BITS Pilani',
];
const _intentions = [
  'Meaningful Dating',
  'Long-Term Relationship',
  'Marriage Minded',
  'Intentional Dating',
  'Friendship First',
  'Exploring Possibilities',
  'Serious Dating',
];
const _personalities = [
  'INFJ',
  'ENFJ',
  'ISFJ',
  'ENFP',
  'INTJ',
  'ESFJ',
  'ENTP',
  'ISTJ',
];
const _interests = [
  'Coffee Dates',
  'Architecture',
  'Garba Nights',
  'Heritage Walks',
  'Design',
  'Fitness Partner',
  'Road Trips',
  'Foodie Partner',
  'Live Concert',
  'Event Buddy',
  'Music',
  'Family Values',
  'Art Cafe',
  'Desserts',
  'Board Games',
  'Fine Dining',
  'Travel',
  'Museums',
  'Indie Music',
  'Book Cafe',
  'Startup Talks',
  'Temple Visit',
  'Cycling',
  'Books',
  'Street Food',
  'AI',
  'Poetry',
  'Filter Coffee',
  'Cooking',
  'Mindfulness',
];
const _bioOpeners = [
  'I like people who are kind when nobody is watching.',
  'My weekdays are ambitious and my weekends are intentionally slow.',
  'I notice good playlists, thoughtful questions, and consistent effort.',
  'Family warmth, honest conversation, and quiet confidence matter to me.',
  'I am building a full life and looking for someone emotionally present.',
];
const _bioClosers = [
  'A first date with good coffee and no performance sounds perfect.',
  'Bonus points if you can plan ahead and laugh easily.',
  'I prefer clarity, shared values, and gentle humour.',
  'Let us start with a real conversation and see where it goes.',
  'Slow chemistry beats noisy attention every time.',
];
const _languageSets = [
  ['Gujarati', 'Hindi', 'English'],
  ['Hindi', 'English', 'Marathi'],
  ['Tamil', 'Hindi', 'English'],
  ['Malayalam', 'English', 'Hindi'],
  ['Punjabi', 'Hindi', 'English'],
  ['Bengali', 'Hindi', 'English'],
];
const _travel = [
  'Slow heritage trips',
  'Weekend treks',
  'Luxury staycations',
  'Beach breaks',
  'Food-led city trips',
  'Spiritual getaways',
];
const _music = [
  'Indie Hindi',
  'Old Bollywood',
  'Sufi nights',
  'Classical fusion',
  'Lo-fi playlists',
  'Live acoustic sets',
];
const _food = [
  'Gujarati thali',
  'South Indian breakfast',
  'Sushi and ramen',
  'Street food walks',
  'Home-style meals',
  'Dessert tasting',
];
const _weekendPlans = [
  'Coffee, errands, and a sunset walk',
  'A museum visit and dinner',
  'Morning workout and family lunch',
  'Live music with close friends',
  'A long drive outside the city',
  'Cooking something elaborate at home',
];
const _pets = [
  'Dog friendly',
  'Cat friendly',
  'Open to pets',
  'No pets at home',
];
const _coffee = [
  'Iced latte',
  'Filter coffee',
  'Masala chai',
  'Americano',
  'Cold brew',
];
const _religions = [
  'Hindu',
  'Muslim',
  'Sikh',
  'Christian',
  'Jain',
  'Spiritual',
  'Open',
];
const _communities = [
  'Gujarati',
  'Punjabi',
  'Marathi',
  'Tamil',
  'Malayali',
  'Bengali',
  'Rajasthani',
];
const _fitness = [
  'Active',
  'Yoga weekly',
  'Gym regular',
  'Weekend sports',
  'Balanced',
];
const _smoking = ['Never', 'No', 'Occasionally'];
const _drinking = ['Never', 'Socially', 'Rarely'];
const _children = [
  'Open to children',
  'Wants children',
  'Undecided',
  'Does not want children',
];
const _loveLanguages = [
  'Quality time',
  'Words of affirmation',
  'Acts of service',
  'Thoughtful gifts',
];
const _greenFlags = [
  'Clear communication',
  'Consistency',
  'Kindness under stress',
  'Respect for family boundaries',
  'Emotional accountability',
];
const _redFlags = [
  'Disrespectful humour',
  'Unclear intentions',
  'Last-minute chaos',
  'Dismissive conflict style',
  'Performative dating',
];
const _familyValues = [
  'Close-knit but independent',
  'Traditional with modern boundaries',
  'Warm, respectful, and involved',
  'Private but supportive',
];
const _dateIdeas = [
  'A quiet cafe followed by a heritage walk',
  'Garba workshop and dinner',
  'Bookstore browsing with filter coffee',
  'Rooftop mocktails and live music',
  'Museum afternoon with dessert after',
  'Food walk through the old city',
];

const _eventNames = [
  'Coffee Meetup at Roastery Culture',
  'Garba Night for Singles',
  'Live Music Social',
  'Startup Networking Mixer',
  'Old City Food Walk',
  'Weekend Trek to Polo Forest',
  'Rooftop Stand-up Comedy',
  'Book Club Brunch',
  'Museum Tour and Chai',
  'Premium Speed Dating',
  'Pet Lovers Cafe Meetup',
  'Sufi Courtyard Evening',
  'Founder Date Night',
  'Sunday Cycling Social',
  'Art and Mocktails Workshop',
  'Gujarati Thali Table',
  'Sunset Lakeside Walk',
  'Movie Night Under Stars',
  'Mindful Dating Workshop',
  'Dessert Trail Social',
];
const _eventCategories = [
  'Coffee Meetups',
  'Garba',
  'Live Music',
  'Startup Networking',
  'Food Walk',
  'Weekend Trek',
  'Stand-up Comedy',
  'Book Club',
  'Museum Tour',
  'Speed Dating',
  'Coffee Meetups',
  'Live Music',
  'Startup Networking',
  'Weekend Trek',
  'Museum Tour',
  'Food Walk',
  'Coffee Meetups',
  'Live Music',
  'Book Club',
  'Food Walk',
];
const _eventVenues = [
  'Roastery Culture, Bodakdev',
  'Laxmi Vilas Lawn',
  'Natarani Amphitheatre',
  'iHub Navrangpura',
  'Manek Chowk Heritage Gate',
  'Polo Forest Base Camp',
  'Skyline Terrace',
  'Chapter One Books',
  'Kasturbhai Lalbhai Museum',
  'The Social Table',
  'Paws Cafe',
  'Sarkhej Courtyard',
  'Founders Table',
  'Riverfront Promenade',
  'Arthshila Studio',
  'Nava Heritage Kitchen',
  'Kankaria Lakefront',
  'Drive-In Courtyard',
  'The Mind Studio',
  'Cocoa Date House',
];
const _eventHosts = [
  'AMORAA Curated',
  'Velvet Circle',
  'Sangam Socials',
  'Founders Circle',
  'Trail Hearts',
  'City Culture Club',
];
const _eventCities = [
  'Ahmedabad',
  'Gandhinagar',
  'Vadodara',
  'Surat',
  'Rajkot',
  'Mumbai',
  'Pune',
  'Delhi',
  'Bengaluru',
  'Hyderabad',
];
const _eventIcons = [
  Icons.coffee_rounded,
  Icons.celebration_rounded,
  Icons.music_note_rounded,
  Icons.handshake_rounded,
  Icons.restaurant_rounded,
  Icons.terrain_rounded,
  Icons.theater_comedy_rounded,
  Icons.menu_book_rounded,
  Icons.museum_rounded,
  Icons.bolt_rounded,
  Icons.pets_rounded,
  Icons.nightlife_rounded,
  Icons.business_center_rounded,
  Icons.directions_bike_rounded,
  Icons.palette_rounded,
  Icons.dinner_dining_rounded,
  Icons.water_rounded,
  Icons.movie_rounded,
  Icons.psychology_rounded,
  Icons.cake_rounded,
];
const _venueNames = [
  'Velvet Bean Luxury Cafe',
  'Saffron Room Fine Dining',
  'Juniper Tea Lounge',
  'Gardenia Courtyard',
  'Skyline Social Lounge',
  'Lakeview Brew House',
  'Private Table Atelier',
  'Canvas Art Cafe',
  'Chapter and Chai Book Cafe',
  'Mithai Dessert House',
  'Rooftop 28',
  'The Quiet Cup',
  'Nava Heritage Kitchen',
  'Blue Door Bistro',
  'Moonlit Terrace',
  'Olive Courtyard',
  'Riverfront Coffee Lab',
  'The Glasshouse',
  'Pearl Banquet Lounge',
  'Banyan Garden Restaurant',
  'Cocoa Date House',
  'Lotus Lake Cafe',
  'The Listening Room',
  'Spice Route Dining',
  'Sunset Patio',
];
const _venueCategories = [
  'Coffee',
  'Fine Dining',
  'Quiet',
  'Rooftop',
  'Couple Friendly',
  'Live Music',
  'Budget',
];
const _venueBestFor = [
  'First date',
  'Anniversary dinner',
  'Quiet conversation',
  'Photo-friendly',
  'Low-pressure meetup',
  'Music lovers',
];
