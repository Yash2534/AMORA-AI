const crypto = require('crypto');

const FIRST_NAMES = [
  'Aarav', 'Aditi', 'Aisha', 'Ananya', 'Arjun', 'Avni', 'Dev', 'Diya', 'Esha', 'Harsh',
  'Ira', 'Ishaan', 'Kabir', 'Kavya', 'Krish', 'Meera', 'Mihir', 'Mira', 'Naina', 'Neel',
  'Nisha', 'Pranav', 'Priya', 'Rhea', 'Rohan', 'Saanvi', 'Samir', 'Sara', 'Shaurya', 'Tara',
  'Veer', 'Vihaan', 'Yash', 'Zara',
];
const LAST_NAMES = [
  'Bhat', 'Desai', 'Iyer', 'Joshi', 'Kapoor', 'Khan', 'Mehta', 'Menon', 'Nair', 'Patel',
  'Rao', 'Shah', 'Sharma', 'Singh', 'Soni', 'Trivedi', 'Verma', 'Vyas',
];
const CITIES = ['Ahmedabad', 'Gandhinagar', 'Surat', 'Vadodara'];
const PROFESSIONS = ['Software Engineer', 'Architect', 'Doctor', 'Designer', 'Entrepreneur', 'Marketing', 'Finance', 'Student', 'Business Owner'];
const EDUCATION = ['Undergraduate', 'Postgraduate', 'Doctorate & Research', 'Professional'];
const GOALS = ['Marriage Minded', 'Long-Term Relationship', 'Meaningful Dating', 'Exploring Possibilities', 'Friendship First', 'Casual Connection'];
const INTERESTS = [
  'Coffee', 'Mindfulness', 'Volunteering', 'Reading', 'Cooking', 'Cafes', 'Street food', 'Baking',
  'Road trips', 'City breaks', 'Heritage walks', 'Beaches', 'Live music', 'Indie', 'Classical',
  'Bollywood', 'Yoga', 'Running', 'Cycling', 'Hiking', 'Photography', 'Design', 'Writing',
  'Pottery', 'Dogs', 'Cats', 'Gardening', 'Wildlife',
];
const LANGUAGES = ['Gujarati', 'Hindi', 'English', 'Marathi', 'Punjabi', 'Tamil', 'Malayalam'];
const RELIGIONS = ['Hindu', 'Jain', 'Muslim', 'Sikh', 'Christian', 'Spiritual', 'Open'];
const QUALITIES = ['Kindness', 'Curiosity', 'Humour', 'Ambition', 'Empathy', 'Honesty', 'Patience', 'Creativity'];
const LOVE_LANGUAGES = ['Quality time', 'Words of affirmation', 'Acts of service', 'Physical touch', 'Receiving gifts'];
const TALKING_HOURS = ['Morning', 'Afternoon', 'Evening', 'Late night'];
const COMMUNICATION_STYLES = ['frequent_texting', 'occasional_texting', 'calls', 'voice_notes', 'deep_conversations', 'light_fun_conversations'];
const BIOS = [
  'I split my free time between finding tiny cafés, taking long walks, and planning the next weekend escape. Looking for someone kind, curious, and ready to laugh often.',
  'Designer by day, enthusiastic home cook by evening. I value thoughtful conversations, close friendships, and people who are excited by the little things.',
  'Usually outdoors before breakfast and reading after dinner. I am here for a grounded connection that feels easy, honest, and full of shared adventures.',
  'My ideal Sunday includes good coffee, a heritage walk, and cooking something ambitious. Hoping to meet someone warm who enjoys both plans and spontaneity.',
  'Curious about cities, stories, food, and how things work. I appreciate clear communication, playful humour, and building a life with plenty of room to grow.',
  'Calm energy, big laugh, and an ever-growing travel list. I care about family, meaningful work, and making time for the people who matter.',
  'I will happily trade restaurant recommendations, make the playlist, and stop for every dog we meet. Looking for genuine chemistry and a thoughtful partner.',
  'Equal parts ambitious and unhurried. Weekends are for cycling, live music, and catching up with friends over a meal that lasts too long.',
];
const COMPANIES = ['Acorn Studio', 'Aster Health', 'Bluebird Labs', 'Cedar Works', 'Daylight Design', 'Independent', 'Mosaic Ventures', 'Northstar Collective', 'Riverstone', 'Saffron & Co.'];
const MESSAGE_LINES = [
  "Hey! I saw that you're into hiking too.",
  'That place looks amazing. Where was that photo taken?',
  "I've been meaning to try that restaurant.",
  "How's your weekend going?",
  'A sunrise walk sounds like a very good plan.',
  'What is the best book you have read this year?',
  'Your coffee recommendation was excellent, by the way.',
  'I would absolutely join that heritage walk.',
  'Do you have a favourite live music spot in the city?',
  'That made me laugh. I needed that today.',
  'I am free Saturday afternoon if you want to continue this in person.',
  'Perfect. Shall we meet near the riverfront around four?',
];

function createRandom(seed) {
  let state = seed >>> 0;
  return () => {
    state += 0x6D2B79F5;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

function pick(random, values) { return values[Math.floor(random() * values.length)]; }
function integer(random, minimum, maximum) { return minimum + Math.floor(random() * (maximum - minimum + 1)); }
function sample(random, values, count) {
  const copy = [...values];
  for (let index = copy.length - 1; index > 0; index -= 1) {
    const other = Math.floor(random() * (index + 1));
    [copy[index], copy[other]] = [copy[other], copy[index]];
  }
  return copy.slice(0, Math.min(count, copy.length));
}
function dateDaysBefore(referenceDate, days, extraMinutes = 0) {
  return new Date(referenceDate.getTime() - ((days * 1440 + extraMinutes) * 60 * 1000));
}
function dateForAge(referenceDate, age, offsetDays = 0) {
  const value = new Date(Date.UTC(referenceDate.getUTCFullYear() - age, referenceDate.getUTCMonth(), referenceDate.getUTCDate()));
  value.setUTCDate(value.getUTCDate() - offsetDays);
  return value.toISOString().slice(0, 10);
}
function slug(value) { return value.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/^\.|\.$/g, ''); }
function stablePair(firstId, secondId) { return firstId < secondId ? [firstId, secondId] : [secondId, firstId]; }
function pairKey(firstId, secondId) { return stablePair(firstId, secondId).join(':'); }

const DEMOS = [
  {
    key: 'demo-a', name: 'Aisha Mehta', email: 'demo.aisha@seed.amoraa.example.test', gender: 'Female', age: 27,
    city: 'Ahmedabad', profession: 'Architect', company: 'Daylight Design', education: 'Postgraduate',
    goals: ['Long-Term Relationship', 'Marriage Minded'],
    interests: ['Architecture', 'Coffee', 'Heritage walks', 'Photography', 'Reading', 'Road trips', 'Yoga'].filter((value) => INTERESTS.includes(value)),
    bio: 'Architect with a soft spot for old buildings, quiet cafés, and spontaneous road trips. I am looking for a thoughtful connection with someone who enjoys curious conversations and a well-planned Sunday.',
  },
  {
    key: 'demo-b', name: 'Rohan Shah', email: 'demo.rohan@seed.amoraa.example.test', gender: 'Male', age: 29,
    city: 'Ahmedabad', profession: 'Software Engineer', company: 'Bluebird Labs', education: 'Postgraduate',
    goals: ['Long-Term Relationship', 'Meaningful Dating'],
    interests: ['Coffee', 'Cooking', 'Hiking', 'Live music', 'Photography', 'Road trips', 'Running'],
    bio: 'Engineer, weekend trail hunter, and enthusiastic maker of breakfast. I value direct communication, a playful sense of humour, and finding someone to build both small rituals and big adventures with.',
  },
  {
    key: 'demo-c', name: 'Kavya Iyer', email: 'demo.kavya@seed.amoraa.example.test', gender: 'Female', age: 34,
    city: 'Vadodara', profession: 'Doctor', company: 'Aster Health', education: 'Professional',
    goals: ['Marriage Minded'],
    interests: ['Classical', 'Cooking', 'Gardening', 'Mindfulness', 'Reading', 'Volunteering', 'Yoga'],
    bio: 'Doctor, patient gardener, and lifelong reader. I make time for classical music, family dinners, and community work, and hope to meet someone steady, warm, and intentional.',
  },
];

function buildSeedBlueprint(config) {
  const random = createRandom(config.randomSeed);
  const users = [];
  for (let index = 0; index < config.userCount; index += 1) {
    const demo = DEMOS[index] || null;
    const sequence = index + 1;
    const first = demo ? demo.name.split(' ')[0] : pick(random, FIRST_NAMES);
    const last = demo ? demo.name.split(' ').slice(1).join(' ') : pick(random, LAST_NAMES);
    const name = demo?.name || `${first} ${last}`;
    const gender = demo?.gender || (index % 11 === 0 ? 'Other' : index % 2 === 0 ? 'Female' : 'Male');
    const age = demo?.age || (index === 3 ? 18 : index === 4 ? 79 : integer(random, 21, 48));
    const interests = demo?.interests || sample(random, INTERESTS, integer(random, 5, 10));
    const city = demo?.city || CITIES[index % CITIES.length];
    const createdDaysAgo = index === 5 ? 0 : index === 6 ? 900 : integer(random, 1, 420);
    const lastActiveMinutes = index % 5 === 0 ? integer(random, 1, 12) : integer(random, 45, 60 * 24 * 20);
    // Two photographs are the product minimum for a completed profile. Keeping
    // this fixed makes the demo asset set deterministic and easy to audit.
    const photoCount = 2;
    const email = demo?.email || `profile.${String(sequence).padStart(4, '0')}.${slug(first)}.${slug(last)}@seed.amoraa.example.test`;
    const languages = sample(random, LANGUAGES, integer(random, 1, 3));
    const religion = pick(random, RELIGIONS);
    users.push({
      key: demo?.key || `profile-${String(sequence).padStart(4, '0')}`,
      demo: Boolean(demo), name, email,
      phoneNumber: `+919990${String(sequence).padStart(6, '0')}`,
      gender, age, birthDate: dateForAge(config.referenceDate, age, index % 330),
      city, profession: demo?.profession || pick(random, PROFESSIONS), company: demo?.company || pick(random, COMPANIES),
      education: demo?.education || pick(random, EDUCATION), relationshipGoals: demo?.goals || sample(random, GOALS, integer(random, 1, 2)),
      interestedIn: gender === 'Male' ? ['Female'] : gender === 'Female' ? ['Male'] : ['Male', 'Female', 'Other'],
      bio: demo?.bio || (index === 9 ? 'Here for something real.' : `${pick(random, BIOS)} ${pick(random, ['Tell me about a place you would revisit.', 'Bonus points for a great playlist.', 'I always make room for dessert.', 'Teach me something you love.'])}`),
      interests, languages,
      hometown: pick(random, CITIES), religion,
      heightCm: index === 10 ? 137 : index === 11 ? 213 : integer(random, 150, 194),
      lifestyle: {
        Height: index % 4 === 0 ? 'Under 5′4″' : index % 4 === 1 ? '5′4″–5′7″' : index % 4 === 2 ? '5′8″–5′11″' : '6′0″ and above',
        Languages: languages.join(' & '),
        Religion: religion,
        Exercise: pick(random, ['Daily', 'A few times a week', 'Occasionally']),
        'Food preference': pick(random, ['Vegetarian', 'Vegan', 'Everything']),
        Pets: pick(random, ['Dog person', 'Cat person', 'Love all pets']),
        'Sleep habits': pick(random, ['Early bird', 'Night owl', 'Flexible']),
      },
      smoking: pick(random, ['Never', 'Sometimes', 'Prefer not to say']), drinking: pick(random, ['Never', 'Sometimes', 'Yes']), weed: pick(random, ['Never', 'Sometimes', 'Prefer not to say']),
      community: pick(random, ['Gujarati', 'Indian', 'Global', 'Open']),
      pronouns: gender === 'Male' ? ['He/Him'] : gender === 'Female' ? ['She/Her'] : ['They/Them'],
      sexuality: pick(random, ['Straight', 'Bisexual', 'Open']), valuedQualities: sample(random, QUALITIES, 3),
      loveLanguages: sample(random, LOVE_LANGUAGES, 2), preferredTalkingHours: sample(random, TALKING_HOURS, 2),
      communicationStyle: pick(random, COMMUNICATION_STYLES),
      prompts: {
        'A perfect Sunday looks like': pick(random, ['Coffee, a long walk, and cooking dinner together.', 'A slow morning followed by a spontaneous day trip.', 'Good music, close friends, and nowhere to rush.']),
        'The way to win me over is': pick(random, ['Be curious and communicate clearly.', 'Make me laugh and remember the little things.', 'Bring a thoughtful plan and an open mind.']),
      },
      iceBreaker: pick(random, ['What is a small thing that made your week better?', 'Which city would you revisit tomorrow?', 'What is your signature dish?']),
      preferredDistance: [20, 40, 80, 150][index % 4], photoCount,
      accountStatus: 'active', completed: true,
      identityVerified: Boolean(demo) || index % 4 === 0,
      createdAt: dateDaysBefore(config.referenceDate, createdDaysAgo, index),
      updatedAt: dateDaysBefore(config.referenceDate, Math.min(createdDaysAgo, integer(random, 0, 20)), index),
      lastActiveAt: dateDaysBefore(config.referenceDate, 0, lastActiveMinutes),
    });
  }
  return { users, random };
}

function shortHash(value) { return crypto.createHash('sha256').update(String(value)).digest('hex').slice(0, 12); }

module.exports = {
  CITIES, EDUCATION, GOALS, INTERESTS, LANGUAGES, MESSAGE_LINES, PROFESSIONS,
  buildSeedBlueprint, createRandom, dateDaysBefore, integer, pairKey, pick, sample, shortHash, stablePair,
};
