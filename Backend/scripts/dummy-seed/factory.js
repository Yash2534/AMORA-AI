const crypto = require('crypto');

const CITIES = ['Ahmedabad', 'Gandhinagar', 'Surat', 'Vadodara', 'Pune', 'Mumbai'];
const PROFESSIONS = ['Software Engineer', 'Architect', 'Doctor', 'Product Designer', 'Entrepreneur', 'Marketing Strategist', 'Financial Analyst', 'Researcher', 'Chef', 'Photographer'];
const EDUCATION = ['Undergraduate', 'Postgraduate', 'Doctorate & Research', 'Professional'];
const GOALS = ['Marriage Minded', 'Long-Term Relationship', 'Meaningful Dating', 'Exploring Possibilities', 'Friendship First', 'Casual Connection'];
const INTERESTS = ['Coffee', 'Mindfulness', 'Volunteering', 'Reading', 'Cooking', 'Cafes', 'Street food', 'Baking', 'Road trips', 'City breaks', 'Heritage walks', 'Beaches', 'Live music', 'Indie', 'Classical', 'Bollywood', 'Yoga', 'Running', 'Cycling', 'Hiking', 'Photography', 'Design', 'Writing', 'Pottery', 'Dogs', 'Cats', 'Gardening', 'Wildlife'];
const LANGUAGES = ['Gujarati', 'Hindi', 'English', 'Marathi', 'Punjabi', 'Tamil', 'Malayalam'];
const QUALITIES = ['Kindness', 'Curiosity', 'Humour', 'Ambition', 'Empathy', 'Honesty', 'Patience', 'Creativity'];
const LOVE_LANGUAGES = ['Quality time', 'Words of affirmation', 'Acts of service', 'Physical touch', 'Receiving gifts'];
const TALKING_HOURS = ['Morning', 'Afternoon', 'Evening', 'Late night'];
const MESSAGE_LINES = ['Hey! Your profile made me smile.', 'That place looks amazing. Where was that photo taken?', 'I have been meaning to try that restaurant.', 'How is your week going?', 'A sunrise walk sounds like a very good plan.', 'What is the best book you have read this year?', 'Your coffee recommendation was excellent, by the way.', 'I would absolutely join that heritage walk.', 'Do you have a favourite live music spot in the city?', 'That made me laugh. I needed that today.', 'I am free Saturday afternoon if you want to continue this in person.', 'Perfect. Shall we meet near the riverfront around four?'];
const MASTER_INTERESTS = ['Coffee', 'Reading', 'Cooking', 'Road trips', 'Heritage walks', 'Photography', 'Yoga', 'Live music'];

const SCENARIOS = [
  ['master', 'MASTER_TEST_ACCOUNT', 'Aisha Mehta', 'Female', 27, 'very-high'],
  ['candidate-a', 'UNTOUCHED_DISCOVER', 'Arjun Desai', 'Male', 28, 'high'],
  ['candidate-b', 'HIGH_COMPATIBILITY', 'Rohan Shah', 'Male', 29, 'high'],
  ['candidate-c', 'MEDIUM_COMPATIBILITY', 'Kabir Menon', 'Male', 30, 'medium'],
  ['candidate-d', 'LOW_COMPATIBILITY', 'Dev Nair', 'Male', 26, 'low'],
  ['candidate-e', 'MASTER_SENT_LIKE', 'Ishaan Patel', 'Male', 31, 'medium'],
  ['candidate-f', 'RECIPROCAL_LIKE_TRIGGER', 'Neel Vyas', 'Male', 28, 'high'],
  ['candidate-g', 'SUPER_LIKED_MASTER', 'Veer Kapoor', 'Male', 30, 'medium'],
  ['candidate-h', 'UNTOUCHED_ROSE_TARGET', 'Mihir Joshi', 'Male', 27, 'low'],
  ['candidate-i', 'MATCH_NO_MESSAGES', 'Samir Khan', 'Male', 29, 'medium'],
  ['candidate-j', 'MATCH_SHORT_CHAT', 'Pranav Rao', 'Male', 32, 'high'],
  ['candidate-k', 'MATCH_UNREAD_CHAT', 'Aarav Singh', 'Male', 25, 'medium'],
  ['candidate-l', 'MATCH_ROSE_CHAT', 'Yash Trivedi', 'Male', 31, 'high'],
  ['candidate-m', 'SAVED_PROFILE', 'Harsh Bhat', 'Male', 28, 'medium'],
  ['candidate-n', 'BLOCKED_EXCLUDED', 'Shaurya Verma', 'Male', 29, 'high'],
  ['candidate-o', 'NON_RECIPROCAL_EXCLUDED', 'Krish Soni', 'Male', 27, 'medium'],
  ['candidate-p', 'AGE_EXCLUDED', 'Vikram Mehta', 'Male', 39, 'high'],
  ['candidate-q', 'INCOMPLETE_EXCLUDED', 'Aditya Patel', 'Male', 26, 'sparse'],
  ['candidate-r', 'VERIFIED_DISCOVER', 'Nikhil Iyer', 'Male', 30, 'high'],
  ['candidate-s', 'PREMIUM_DISCOVER', 'Karan Desai', 'Male', 32, 'medium'],
  ['candidate-t', 'VERY_HIGH_AI', 'Dhruv Shah', 'Male', 28, 'very-high'],
  ['candidate-u', 'MATCH_LONG_CHAT', 'Reyan Kapoor', 'Male', 29, 'high'],
  ['candidate-v', 'MATCH_READ_CHAT', 'Manav Nair', 'Male', 30, 'medium'],
  ['candidate-w', 'MATCH_IMAGE_CHAT', 'Vivaan Rao', 'Male', 27, 'high'],
  ['candidate-x', 'INACTIVE_EXCLUDED', 'Atharv Singh', 'Male', 28, 'high'],
].map(([key, role, name, gender, age, scoreBand]) => ({ key, role, name, gender, age, scoreBand }));

Object.assign(SCENARIOS[0], { email: 'master@seed.amoraa.example.test', city: 'Ahmedabad', profession: 'Product Designer', education: 'Postgraduate', premium: true, identityVerified: true });
Object.assign(SCENARIOS[15], { interestedIn: ['Male'] });
Object.assign(SCENARIOS[17], { completed: false });
Object.assign(SCENARIOS[18], { identityVerified: true });
Object.assign(SCENARIOS[19], { premium: true });
Object.assign(SCENARIOS[20], { identityVerified: true });
Object.assign(SCENARIOS[24], { accountStatus: 'deactivated' });

const POOL_NAMES = ['Anaya Iyer', 'Zoya Khan', 'Rhea Patel', 'Tara Menon', 'Avni Desai', 'Sana Sheikh', 'Mira Joshi', 'Naina Rao', 'Rahul Verma', 'Om Bhat', 'Siddharth Soni', 'Jay Shah', 'Meera Nair', 'Ira Kapoor', 'Diya Trivedi'];

function createRandom(seed) { let state = seed >>> 0; return () => { state += 0x6D2B79F5; let value = state; value = Math.imul(value ^ (value >>> 15), value | 1); value ^= value + Math.imul(value ^ (value >>> 7), value | 61); return ((value ^ (value >>> 14)) >>> 0) / 4294967296; }; }
function pick(random, values) { return values[Math.floor(random() * values.length)]; }
function integer(random, minimum, maximum) { return minimum + Math.floor(random() * (maximum - minimum + 1)); }
function sample(random, values, count) { const copy = [...values]; for (let i = copy.length - 1; i > 0; i -= 1) { const j = Math.floor(random() * (i + 1)); [copy[i], copy[j]] = [copy[j], copy[i]]; } return copy.slice(0, Math.min(count, copy.length)); }
function dateDaysBefore(referenceDate, days, extraMinutes = 0) { return new Date(referenceDate.getTime() - ((days * 1440 + extraMinutes) * 60000)); }
function dateForAge(referenceDate, age, offsetDays = 0) { const value = new Date(Date.UTC(referenceDate.getUTCFullYear() - age, referenceDate.getUTCMonth(), referenceDate.getUTCDate())); value.setUTCDate(value.getUTCDate() - offsetDays); return value.toISOString().slice(0, 10); }
function slug(value) { return value.toLowerCase().replace(/[^a-z0-9]+/g, '.').replace(/^\.|\.$/g, ''); }
function stablePair(firstId, secondId) { return firstId < secondId ? [firstId, secondId] : [secondId, firstId]; }
function pairKey(firstId, secondId) { return stablePair(firstId, secondId).join(':'); }

function compatibilityTemplate(band, random) {
  const templates = {
    'very-high': [MASTER_INTERESTS.slice(0, 7), ['Long-Term Relationship', 'Marriage Minded'], 'deep_conversations', ['English', 'Hindi', 'Gujarati'], 'Ahmedabad', 'Never', 'Sometimes', 'Never'],
    high: [MASTER_INTERESTS.slice(0, 6), ['Long-Term Relationship'], 'deep_conversations', ['English', 'Hindi'], 'Ahmedabad', 'Never', 'Sometimes', 'Never'],
    medium: [[...MASTER_INTERESTS.slice(0, 4), 'Running', 'Dogs'], ['Long-Term Relationship'], 'deep_conversations', ['English', 'Hindi'], 'Ahmedabad', 'Never', 'Never', 'Never'],
    low: [[...MASTER_INTERESTS.slice(0, 2), 'Cycling', 'Wildlife', 'Street food'], ['Long-Term Relationship'], 'deep_conversations', ['English', 'Hindi'], 'Ahmedabad', 'Never', 'Never', 'Never'],
    sparse: [['Coffee'], ['Exploring Possibilities'], 'occasional_texting', ['Hindi'], 'Vadodara', 'Prefer not to say', 'Prefer not to say', 'Prefer not to say'],
  };
  const [baseInterests, goals, style, languages, city, smoking, drinking, weed] = templates[band] || templates.medium;
  return { interests: [...baseInterests, ...sample(random, INTERESTS.filter((v) => !MASTER_INTERESTS.includes(v)), 2)].slice(0, 9), goals, style, languages, city, smoking, drinking, weed };
}

function buildSeedBlueprint(config) {
  const random = createRandom(config.randomSeed);
  const scenarios = [...SCENARIOS];
  while (scenarios.length < config.userCount) {
    const index = scenarios.length;
    const name = POOL_NAMES[(index - 25) % POOL_NAMES.length] || `Development Profile ${index + 1}`;
    const gender = index % 5 === 0 ? 'Other' : index % 3 === 0 ? 'Female' : 'Male';
    scenarios.push({ key: `pool-${String(index + 1).padStart(2, '0')}`, role: 'PAGINATION_POOL', name, gender, age: 22 + (index % 14), city: CITIES[index % CITIES.length], scoreBand: ['low', 'medium', 'high', 'very-high'][index % 4], identityVerified: index % 4 === 0, premium: index % 7 === 0 });
  }
  const users = scenarios.slice(0, config.userCount).map((scenario, index) => {
    const sequence = index + 1; const template = compatibilityTemplate(scenario.scoreBand || 'medium', random); const isMaster = scenario.key === 'master';
    const completed = scenario.completed !== false; const gender = scenario.gender || 'Male'; const age = scenario.age || integer(random, 22, 36);
    const languages = isMaster ? ['English', 'Hindi', 'Gujarati'] : template.languages; const interests = isMaster ? MASTER_INTERESTS : (completed ? template.interests : ['Coffee']); const city = scenario.city || template.city;
    const createdAt = dateDaysBefore(config.referenceDate, 120 - Math.min(100, index * 2), index); const religion = ['Hindu', 'Jain', 'Muslim', 'Sikh', 'Spiritual', 'Open'][index % 6]; const heightCm = 158 + (index % 32);
    return { ...scenario, sequence, completed, age, gender, city,
      email: scenario.email || `${slug(scenario.key)}.${slug(scenario.name)}@seed.amoraa.example.test`, phoneNumber: `+919991${String(sequence).padStart(6, '0')}`, birthDate: dateForAge(config.referenceDate, age, index % 300),
      profession: scenario.profession || PROFESSIONS[index % PROFESSIONS.length], company: ['Daylight Design', 'Bluebird Labs', 'Aster Health', 'Riverstone', 'Independent'][index % 5], education: scenario.education || EDUCATION[index % EDUCATION.length],
      relationshipGoals: isMaster ? ['Long-Term Relationship', 'Marriage Minded'] : template.goals, interestedIn: scenario.interestedIn || (isMaster ? ['Everyone'] : ['Female']),
      bio: completed ? `${scenario.name.split(' ')[0]} enjoys ${interests.slice(0, 3).join(', ').toLowerCase()} and values honest conversation. Looking for a grounded connection with curiosity, laughter, and room to grow.` : 'Still finishing this profile.',
      interests, languages, hometown: CITIES[index % 4], religion, heightCm,
      lifestyle: { Height: `${heightCm} cm`, Languages: languages.join(' & '), Religion: religion, Exercise: ['Daily', 'A few times a week', 'Occasionally'][index % 3], 'Food preference': ['Vegetarian', 'Vegan', 'Everything'][index % 3], Pets: ['Dog person', 'Cat person', 'Love all pets'][index % 3], 'Sleep habits': ['Early bird', 'Night owl', 'Flexible'][index % 3] },
      smoking: isMaster ? 'Never' : template.smoking, drinking: isMaster ? 'Sometimes' : template.drinking, weed: isMaster ? 'Never' : template.weed,
      community: ['Gujarati', 'Indian', 'Global', 'Open'][index % 4], pronouns: gender === 'Male' ? ['He/Him'] : gender === 'Female' ? ['She/Her'] : ['They/Them'], sexuality: isMaster ? 'Bisexual' : (index % 7 === 0 ? 'Bisexual' : 'Straight'),
      valuedQualities: sample(random, QUALITIES, 3), loveLanguages: sample(random, LOVE_LANGUAGES, 2), preferredTalkingHours: sample(random, TALKING_HOURS, 2), communicationStyle: isMaster ? 'deep_conversations' : template.style,
      prompts: completed ? { 'A perfect Sunday looks like': 'Coffee, a long walk, and cooking dinner together.', 'The way to win me over is': 'Be curious, kind, and communicate clearly.' } : {}, iceBreaker: completed ? 'What is a small thing that made your week better?' : '',
      preferredDistance: 120, photoCount: 2, accountStatus: scenario.accountStatus || 'active', identityVerified: Boolean(isMaster || scenario.identityVerified), premium: Boolean(isMaster || scenario.premium),
      createdAt, updatedAt: dateDaysBefore(config.referenceDate, Math.min(10, index % 12), index), lastActiveAt: dateDaysBefore(config.referenceDate, 0, index * 7) };
  });
  return { users, random };
}

function shortHash(value) { return crypto.createHash('sha256').update(String(value)).digest('hex').slice(0, 12); }
module.exports = { CITIES, EDUCATION, GOALS, INTERESTS, LANGUAGES, MESSAGE_LINES, SCENARIOS, buildSeedBlueprint, createRandom, dateDaysBefore, integer, pairKey, pick, sample, shortHash, stablePair };
