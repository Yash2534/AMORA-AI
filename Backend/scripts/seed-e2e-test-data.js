require('../src/config/bootstrapEnv');
require('../src/config/env');

const bcrypt = require('bcrypt');
const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const {
  plans,
  walletProducts,
  boosts: boostProducts,
  gifts,
} = require('./seed-monetization-catalog');

const SEED_PASSWORD = 'AmoraaQA!2026';
const UNVERIFIED_OTP = '246810';
const email = (key) => `qa.${key}@example.test`;

const personas = [
  { key: 'aarav', label: 'A', name: 'Aarav Mehta', gender: 'Male', birthDate: '1994-08-18', city: 'Ahmedabad', profession: 'Product Designer', education: 'NID Ahmedabad', verified: true, scenario: 'Primary testing account', image: 'male_01.png' },
  { key: 'diya', label: 'B', name: 'Diya Shah', gender: 'Female', birthDate: '1997-02-11', city: 'Ahmedabad', profession: 'Architect', education: 'CEPT University', verified: true, scenario: 'Eligible Discover candidate with no prior interaction', image: 'female_01.png' },
  { key: 'kavya', label: 'C', name: 'Kavya Patel', gender: 'Female', birthDate: '1996-06-24', city: 'Ahmedabad', profession: 'Brand Strategist', education: 'MICA', verified: true, scenario: 'Mutual like and existing match', image: 'female_02.png' },
  { key: 'riya', label: 'D', name: 'Riya Desai', gender: 'Female', birthDate: '1998-01-09', city: 'Vadodara', profession: 'Urban Planner', education: 'CEPT University', verified: true, scenario: 'Already passed by the primary account', image: 'female_03.png' },
  { key: 'meera', label: 'E', name: 'Meera Joshi', gender: 'Female', birthDate: '1995-11-03', city: 'Ahmedabad', profession: 'Clinical Psychologist', education: 'Gujarat University', verified: true, scenario: 'Incoming like awaiting response', image: 'female_04.png' },
  { key: 'ananya', label: 'F', name: 'Ananya Rao', gender: 'Female', birthDate: '1994-04-27', city: 'Ahmedabad', profession: 'Documentary Filmmaker', education: 'FTII', verified: true, scenario: 'Existing match with chat history', image: 'female_05.png' },
  { key: 'nisha', label: 'G', name: 'Nisha Trivedi', gender: 'Female', birthDate: '2000-09-15', city: null, profession: null, education: null, verified: true, incomplete: true, scenario: 'Incomplete onboarding profile', image: 'female_06.png' },
  { key: 'isha', label: 'H', name: 'Isha Kapoor', gender: 'Female', birthDate: '1999-12-02', city: 'Ahmedabad', profession: 'Research Associate', education: 'Ahmedabad University', verified: false, scenario: 'Unverified local account', image: 'female_07.png' },
  { key: 'sara', label: 'I', name: 'Sara Khan', gender: 'Female', birthDate: '1993-03-19', city: 'Ahmedabad', profession: 'Hospitality Consultant', education: 'IHM Ahmedabad', verified: true, accountStatus: 'deactivated', scenario: 'Deactivated and inactive profile', image: 'female_08.png' },
  { key: 'tara', label: 'J', name: 'Tara Bhatt', gender: 'Female', birthDate: '1996-07-30', city: 'Ahmedabad', profession: 'Content Producer', education: 'St. Xavier’s College', verified: true, scenario: 'Blocked and reported profile', image: 'female_09.png' },
  { key: 'vihaan', label: 'K', name: 'Vihaan Shah', gender: 'Male', birthDate: '1990-10-12', city: 'Ahmedabad', profession: 'Community Curator', education: 'IIM Ahmedabad', verified: true, role: 'host', scenario: 'Verified event host', image: 'male_02.png' },
  { key: 'leela', label: 'L', name: 'Leela Nair', gender: 'Female', birthDate: '1997-05-20', city: 'Gandhinagar', profession: 'Sustainability Analyst', education: 'TERI School', verified: true, scenario: 'Outgoing Super Like', image: 'female_10.png' },
  { key: 'neha', label: 'M', name: 'Neha Soni', gender: 'Female', birthDate: '1995-01-16', city: 'Ahmedabad', profession: 'Ceramic Artist', education: 'MSU Baroda', verified: true, scenario: 'Saved profile', image: 'female_11.png' },
  { key: 'priya', label: 'N', name: 'Priya Menon', gender: 'Female', birthDate: '1996-12-08', city: 'Ahmedabad', profession: 'Data Journalist', education: 'Asian College of Journalism', verified: true, scenario: 'Reciprocal-like API mutation candidate', image: 'female_12.png' },
  { key: 'zoya', label: 'O', name: 'Zoya Mirza', gender: 'Female', birthDate: '1998-08-05', city: 'Ahmedabad', profession: 'Landscape Designer', education: 'CEPT University', verified: true, scenario: 'Save/pass API mutation candidate', image: 'female_13.png' },
];

function assertSafeTarget() {
  if (!process.argv.includes('--confirm-development-db')) {
    throw new Error('Run this seed only through npm run seed:e2e.');
  }
  if (process.env.NODE_ENV === 'production') {
    throw new Error('E2E test data seeding is disabled in production.');
  }
  if (!process.env.DB_NAME || /prod|production/i.test(process.env.DB_NAME)) {
    throw new Error('The configured database name is not safe for E2E seeding.');
  }
}

function copySeedAssets() {
  const projectRoot = path.resolve(__dirname, '..', '..');
  const destination = path.resolve(__dirname, '..', 'uploads', 'e2e-test');
  const identityDestination = path.resolve(__dirname, '..', 'private-uploads', 'identity-verification');
  fs.mkdirSync(destination, { recursive: true });
  fs.mkdirSync(identityDestination, { recursive: true });
  const profileSources = path.join(projectRoot, 'assets', 'images', 'profiles');
  for (let index = 0; index < personas.length; index += 1) {
    const persona = personas[index];
    const group = persona.gender === 'Male' ? 'male' : 'female';
    const first = path.join(profileSources, group, persona.image);
    const extension = path.extname(persona.image);
    const secondNumber = String(((index + 6) % 12) + 1).padStart(2, '0');
    let secondName = `${group}_${secondNumber}.png`;
    if (!fs.existsSync(path.join(profileSources, group, secondName))) secondName = `${group}_${secondNumber}.jpg`;
    const second = path.join(profileSources, group, secondName);
    fs.copyFileSync(first, path.join(destination, `${persona.key}-primary${extension}`));
    fs.copyFileSync(second, path.join(destination, `${persona.key}-gallery${path.extname(secondName)}`));
    const identityExtension = extension.toLowerCase() === '.jpg' ? '.jpg' : '.png';
    const aadhaarName = `e2e-${persona.key}-document${identityExtension}`;
    const selfieName = `e2e-${persona.key}-selfie${identityExtension}`;
    fs.copyFileSync(first, path.join(identityDestination, aadhaarName));
    fs.copyFileSync(first, path.join(identityDestination, selfieName));
    fs.chmodSync(path.join(identityDestination, aadhaarName), 0o600);
    fs.chmodSync(path.join(identityDestination, selfieName), 0o600);
    persona.identityFixture = {
      aadhaarStoragePath: `identity-verification/${aadhaarName}`,
      selfieStoragePath: `identity-verification/${selfieName}`,
      mimeType: identityExtension === '.jpg' ? 'image/jpeg' : 'image/png',
      sizeBytes: fs.statSync(first).size,
    };
    persona.photos = [
      `/uploads/e2e-test/${persona.key}-primary${extension}`,
      `/uploads/e2e-test/${persona.key}-gallery${path.extname(secondName)}`,
    ];
  }
  const eventSources = path.join(projectRoot, 'assets', 'images', 'events');
  for (const name of ['coffee_meetup.png', 'garba_night.png', 'live_music.png', 'old_city_food_walk.png', 'startup_networking_mixer.png']) {
    fs.copyFileSync(path.join(eventSources, name), path.join(destination, name));
  }
}

async function upsertBy(model, where, values, transaction) {
  const [row, created] = await model.findOrCreate({
    where,
    defaults: { ...where, ...values },
    transaction,
  });
  if (!created) await row.update(values, { transaction });
  return row;
}

function profileValues(persona, index) {
  const incomplete = persona.incomplete === true;
  return {
    birthDate: persona.birthDate,
    gender: persona.gender,
    customGender: '',
    interestedIn: persona.gender === 'Male' ? ['Female'] : ['Male'],
    relationshipGoals: incomplete ? [] : [index % 3 === 0 ? 'Long-term relationship' : 'Meaningful Dating'],
    city: persona.city,
    preferredDistance: 80,
    profession: persona.profession,
    company: incomplete ? null : ['Studio Meridian', 'Civic Labs', 'Sahaj Collective'][index % 3],
    education: persona.education,
    bio: incomplete ? null : `${persona.name.split(' ')[0]} values thoughtful conversation, a calm sense of humour, and weekends spent discovering independent cafés, local art, and new walking routes.`,
    iceBreaker: incomplete ? '' : 'What is one small ritual that makes your week better?',
    hometown: incomplete ? '' : ['Ahmedabad', 'Vadodara', 'Surat', 'Kochi'][index % 4],
    interests: incomplete ? [] : ['Coffee', 'Travel', 'Live music', 'Books', index % 2 ? 'Photography' : 'Cooking'],
    lifestyle: incomplete ? {} : {
      Height: persona.gender === 'Male' ? '178' : '165',
      Languages: 'English, Hindi, Gujarati',
      Religion: index % 2 ? 'Spiritual' : 'Hindu',
      Exercise: index % 2 ? 'Yoga and walking' : 'Three times a week',
      Smoking: 'Never',
      Drinking: 'Socially',
      Pets: index % 2 ? 'Dog person' : 'Open to pets',
      'Food preference': index % 2 ? 'Vegetarian' : 'Everything in moderation',
    },
    prompts: incomplete ? {} : {
      'My ideal Sunday is': 'Coffee, a long walk, and cooking dinner with friends.',
      'A green flag I value is': 'Kindness that stays consistent when nobody is watching.',
      'Together we could': 'Explore a new neighbourhood without planning every minute.',
    },
    pronouns: persona.gender === 'Male' ? ['He/Him'] : ['She/Her'],
    sexuality: 'Straight',
    valuedQualities: incomplete ? [] : ['Kindness', 'Curiosity', 'Emotional maturity'],
    loveLanguages: incomplete ? [] : ['Quality Time', 'Words of Affirmation'],
    preferredTalkingHours: incomplete ? [] : ['Evenings', 'Weekend mornings'],
    communicationStyle: incomplete ? null : ['deep_conversations', 'calls', 'voice_notes'][index % 3],
    photos: persona.photos,
    primaryPhotoIndex: 0,
    personality: incomplete ? null : ['Reflective', 'Warm', 'Playful'][index % 3],
    travelPreference: incomplete ? null : 'Slow travel with room for local recommendations',
    musicTaste: incomplete ? null : 'Indie, acoustic, and Indian classical',
    foodPreference: incomplete ? null : 'Local vegetarian favourites',
    weekendPlan: incomplete ? null : 'Markets, museums, and unhurried brunches',
    petPreference: incomplete ? null : 'Open to pets',
    coffeePreference: incomplete ? null : 'Filter coffee',
    height: incomplete ? null : persona.gender === 'Male' ? '178' : '165',
    fitnessLevel: incomplete ? null : 'Active a few times a week',
    children: incomplete ? null : 'Open to children',
    smoking: incomplete ? null : 'Never',
    drinking: incomplete ? null : 'Socially',
    weed: incomplete ? null : 'Never',
    community: incomplete ? null : 'Gujarati',
    religion: incomplete ? null : index % 2 ? 'Spiritual' : 'Hindu',
    familyValues: incomplete ? null : 'Close-knit and independent',
    loveLanguage: incomplete ? null : 'Quality Time',
    languages: incomplete ? [] : ['English', 'Hindi', 'Gujarati'],
    greenFlags: incomplete ? [] : ['Communicates clearly', 'Respects boundaries'],
    redFlags: incomplete ? [] : ['Dishonesty', 'Dismissive communication'],
    dateIdeas: incomplete ? [] : ['Old-city food walk', 'Pottery workshop'],
    stage: incomplete ? 'starterProfile' : 'complete',
    onboardingCompleted: !incomplete,
  };
}

async function seedCatalog(models, transaction) {
  for (const value of plans) await models.SubscriptionPlan.upsert(value, { transaction });
  for (const value of walletProducts) await models.WalletProduct.upsert(value, { transaction });
  for (const value of boostProducts) await models.BoostProduct.upsert(value, { transaction });
  for (const value of gifts) await models.Gift.upsert(value, { transaction });
}

async function seed() {
  assertSafeTarget();
  copySeedAssets();
  await initializeDatabase();
  const sequelize = getSequelize();
  const models = getModels();
  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 12);
  const otpHash = await bcrypt.hash(UNVERIFIED_OTP, 12);
  const users = {};
  const now = new Date();

  await sequelize.transaction(async (transaction) => {
    await seedCatalog(models, transaction);

    for (let index = 0; index < personas.length; index += 1) {
      const persona = personas[index];
      const phoneNumber = `+91910000${String(100 + index).padStart(4, '0')}`;
      const accountStatus = persona.accountStatus || 'active';
      const identityStatus = persona.key === 'isha' ? 'pending' : 'verified';
      const identityVerifiedAt = identityStatus === 'verified'
        ? new Date('2026-02-01T10:00:00.000Z')
        : null;
      const user = await upsertBy(models.User, { email: email(persona.key) }, {
        name: persona.name,
        phoneNumber,
        passwordHash,
        authProvider: 'local',
        googleId: null,
        isVerified: persona.verified,
        identityVerifiedAt,
        termsAcceptedAt: new Date('2026-01-15T10:00:00.000Z'),
        accountStatus,
        deactivatedAt: accountStatus === 'deactivated' ? new Date(now.getTime() - 14 * 86400000) : null,
        deletedAt: null,
        tokenVersion: 0,
        deletionReason: null,
        deletionDetails: null,
        role: persona.role || 'user',
        lastActiveAt: ['sara', 'nisha'].includes(persona.key)
          ? new Date(now.getTime() - 30 * 86400000)
          : new Date(now.getTime() - (index % 5) * 60000),
      }, transaction);
      users[persona.key] = user;
      await upsertBy(models.IdentityVerification, { userId: user.id }, {
        status: identityStatus,
        aadhaarStoragePath: persona.identityFixture.aadhaarStoragePath,
        aadhaarMimeType: persona.identityFixture.mimeType,
        aadhaarSizeBytes: persona.identityFixture.sizeBytes,
        selfieStoragePath: persona.identityFixture.selfieStoragePath,
        selfieMimeType: persona.identityFixture.mimeType,
        selfieSizeBytes: persona.identityFixture.sizeBytes,
        submittedAt: new Date('2026-01-30T10:00:00.000Z'),
        reviewedAt: identityVerifiedAt,
        reviewerUserId: null,
        reviewNote: identityVerifiedAt ? 'Development-only seeded verification fixture.' : null,
        rejectionReason: null,
      }, transaction);
      await upsertBy(models.OnboardingProfile, { userId: user.id }, profileValues(persona, index), transaction);
      await upsertBy(models.DiscoverFilterPreference, { userId: user.id }, {
        minAge: 22,
        maxAge: 40,
        maxDistanceKm: 100,
        minScore: 0,
        city: '',
        minHeight: null,
        hometown: [],
        datingIntentions: [],
        lifestyleTags: [],
        education: '',
        profession: '',
        community: '',
        religion: '',
        languages: [],
        pronouns: [],
        sexuality: '',
        qualities: [],
        preferredTalkingHours: [],
        loveLanguages: [],
        communicationStyles: [],
        smoking: '',
        drinking: '',
        weed: '',
        verifiedOnly: true,
        onlineNow: false,
        hasPrompts: false,
        hasEventInterest: false,
      }, transaction);
      await upsertBy(models.NotificationPreference, { userId: user.id }, {
        newMatches: true,
        messages: true,
        eventReminders: true,
        paymentsAndMembership: true,
        offers: false,
        safetyUpdates: true,
        pushEnabled: false,
        emailEnabled: true,
        smsEnabled: false,
        quietHoursEnabled: true,
        quietStart: '22:00',
        quietEnd: '07:00',
      }, transaction);
    }

    const primaryId = users.aarav.id;
    await models.Boost.destroy({ where: { userId: primaryId, idempotencyKey: 'e2e:verify:boost' }, transaction });
    await models.GiftTransaction.destroy({ where: { senderId: primaryId, idempotencyKey: 'e2e:verify:gift' }, transaction });
    await models.BoostEntitlement.destroy({
      where: {
        userId: primaryId,
        idempotencyKey: { [Op.in]: ['redemption:e2e:verify:redemption', 'wallet:e2e:verify:boost-purchase'] },
      },
      transaction,
    });
    await models.WalletTransaction.destroy({
      where: {
        userId: primaryId,
        idempotencyKey: { [Op.in]: ['e2e:verify:redemption', 'e2e:verify:boost-purchase', 'e2e:verify:gift'] },
      },
      transaction,
    });
    await models.Message.destroy({
      where: { senderId: primaryId, text: 'E2E verification message persisted through the API.' },
      force: true,
      transaction,
    });
    await models.EventGroupMessage.destroy({
      where: { senderId: primaryId, text: 'E2E verification group message.' },
      transaction,
    });
    await models.Report.destroy({
      where: {
        reporterUserId: primaryId,
        reportedUserId: users.zoya.id,
        targetType: 'profile',
        targetId: String(users.zoya.id),
        reason: 'other',
      },
      transaction,
    });
    await models.DiscoverAction.destroy({
      where: { actorUserId: primaryId, targetUserId: { [Op.in]: [users.priya.id, users.zoya.id] } },
      transaction,
    });
    await models.Match.destroy({
      where: {
        userOneId: Math.min(primaryId, users.priya.id),
        userTwoId: Math.max(primaryId, users.priya.id),
      },
      transaction,
    });

    const pendingOtp = await models.OtpToken.findOne({
      where: { phoneNumber: users.isha.phoneNumber, purpose: 'account_verification' },
      order: [['id', 'DESC']],
      transaction,
    });
    const otpValues = { codeHash: otpHash, expiresAt: new Date(now.getTime() + 7 * 86400000), attempts: 0, consumed: false };
    if (pendingOtp) await pendingOtp.update(otpValues, { transaction });
    else await models.OtpToken.create({ phoneNumber: users.isha.phoneNumber, purpose: 'account_verification', ...otpValues }, { transaction });

    const action = async (actor, target, value, createdAt) => upsertBy(
      models.DiscoverAction,
      { actorUserId: users[actor].id, targetUserId: users[target].id },
      { action: value, createdAt, updatedAt: createdAt },
      transaction,
    );
    await action('aarav', 'kavya', 'like', new Date(now.getTime() - 10 * 86400000));
    await action('kavya', 'aarav', 'like', new Date(now.getTime() - 10 * 86400000 + 60000));
    await action('aarav', 'riya', 'pass', new Date(now.getTime() - 7 * 86400000));
    await action('meera', 'aarav', 'like', new Date(now.getTime() - 2 * 3600000));
    await action('aarav', 'ananya', 'superLike', new Date(now.getTime() - 20 * 86400000));
    await action('ananya', 'aarav', 'like', new Date(now.getTime() - 20 * 86400000 + 60000));
    await action('aarav', 'leela', 'superLike', new Date(now.getTime() - 86400000));
    await action('priya', 'aarav', 'like', new Date(now.getTime() - 30 * 60000));

    const matchFor = async (left, right, matchedAt) => {
      const first = Math.min(users[left].id, users[right].id);
      const second = Math.max(users[left].id, users[right].id);
      return upsertBy(models.Match, { userOneId: first, userTwoId: second }, { matchedAt, createdAt: matchedAt }, transaction);
    };
    await matchFor('aarav', 'kavya', new Date(now.getTime() - 10 * 86400000));
    await matchFor('aarav', 'ananya', new Date(now.getTime() - 20 * 86400000));
    await upsertBy(models.SavedProfile, { userId: users.aarav.id, savedUserId: users.neha.id }, {}, transaction);
    await upsertBy(models.Block, { blockerUserId: users.aarav.id, blockedUserId: users.tara.id }, {}, transaction);
    await upsertBy(models.Report, {
      reporterUserId: users.aarav.id,
      targetType: 'profile',
      targetId: String(users.tara.id),
      reason: 'spam',
    }, {
      reportedUserId: users.tara.id,
      notes: 'QA seed scenario: repeated promotional messages.',
      status: 'open',
    }, transaction);

    const conversationFor = async (targetKey, messages) => {
      const pair = [users.aarav.id, users[targetKey].id].sort((a, b) => a - b);
      const conversation = await upsertBy(models.Conversation, { pairKey: `${pair[0]}:${pair[1]}` }, { type: 'direct' }, transaction);
      const primaryMember = await upsertBy(models.ConversationParticipant, { conversationId: conversation.id, userId: users.aarav.id }, { joinedAt: new Date(now.getTime() - 12 * 86400000), draftText: null }, transaction);
      const otherMember = await upsertBy(models.ConversationParticipant, { conversationId: conversation.id, userId: users[targetKey].id }, { joinedAt: new Date(now.getTime() - 12 * 86400000), draftText: null }, transaction);
      const created = [];
      for (let index = 0; index < messages.length; index += 1) {
        const definition = messages[index];
        const sender = definition.mine ? users.aarav : users[targetKey];
        const [message] = await models.Message.findOrCreate({
          where: { conversationId: conversation.id, senderId: sender.id, text: definition.text },
          defaults: {
            conversationId: conversation.id,
            senderId: sender.id,
            type: 'text',
            text: definition.text,
            context: definition.context || null,
            createdAt: new Date(now.getTime() - (messages.length - index) * 20 * 60000),
            updatedAt: new Date(now.getTime() - (messages.length - index) * 20 * 60000),
          },
          transaction,
        });
        created.push(message);
      }
      const last = created.at(-1);
      await conversation.update({ lastMessageId: last.id, lastMessageAt: last.createdAt }, { transaction });
      await primaryMember.update({ lastReadMessageId: created[Math.max(0, created.length - 3)].id, lastReadAt: new Date(now.getTime() - 25 * 60000) }, { transaction });
      await otherMember.update({ lastReadMessageId: created[Math.max(0, created.length - 2)].id, lastReadAt: new Date(now.getTime() - 15 * 60000) }, { transaction });
      return conversation;
    };
    const kavyaConversation = await conversationFor('kavya', [
      { mine: false, text: 'Your neighbourhood café prompt made me smile.' },
      { mine: true, text: 'Then I need your most honest café recommendation.' },
      { mine: false, text: 'Deal. I know a quiet place near the old city.' },
      { mine: true, text: 'That sounds like a very good first plan.' },
    ]);
    const ananyaConversation = await conversationFor('ananya', [
      { mine: true, text: 'What documentary stayed with you after the credits?' },
      { mine: false, text: 'The one I am editing now, because I still do not know its ending.' },
      { mine: true, text: 'That answer has definitely earned a longer conversation.' },
      { mine: false, text: 'Coffee this weekend? I can tell you the non-spoiler version.' },
      { mine: true, text: 'Saturday afternoon works for me.' },
      { mine: false, text: 'Perfect. I will send the café location tomorrow.' },
    ]);

    const eventDefinitions = [
      { key: 'upcoming', title: 'AMORAA QA Coffee & Conversation', category: 'Coffee Meetup', startHours: 48, endHours: 51, capacity: 24, waitlistCapacity: 8, status: 'published', registrationOpen: true, image: 'coffee_meetup.png' },
      { key: 'full', title: 'AMORAA QA Intimate Garba Evening', category: 'Culture', startHours: 72, endHours: 76, capacity: 1, waitlistCapacity: 6, status: 'published', registrationOpen: true, image: 'garba_night.png' },
      { key: 'active', title: 'AMORAA QA Live Music Social', category: 'Live Music', startHours: -1, endHours: 2, capacity: 30, waitlistCapacity: 5, status: 'published', registrationOpen: true, image: 'live_music.png' },
      { key: 'past', title: 'AMORAA QA Old City Food Walk', category: 'Food Walk', startHours: -120, endHours: -116, capacity: 20, waitlistCapacity: 0, status: 'completed', registrationOpen: false, image: 'old_city_food_walk.png' },
      { key: 'cancelled', title: 'AMORAA QA Rooftop Mixer', category: 'Social Mixer', startHours: 96, endHours: 100, capacity: 40, waitlistCapacity: 10, status: 'cancelled', registrationOpen: false, image: 'startup_networking_mixer.png' },
    ];
    const events = {};
    for (const definition of eventDefinitions) {
      events[definition.key] = await upsertBy(models.Event, { title: definition.title, hostId: users.vihaan.id }, {
        description: `${definition.title} is realistic development-only data for exercising the existing event flows.`,
        category: definition.category,
        city: 'Ahmedabad',
        venueName: 'The Courtyard, Ahmedabad',
        address: 'University Road, Ahmedabad',
        latitude: 23.0395,
        longitude: 72.5660,
        startDateTime: new Date(now.getTime() + definition.startHours * 3600000),
        endDateTime: new Date(now.getTime() + definition.endHours * 3600000),
        capacity: definition.capacity,
        waitlistCapacity: definition.waitlistCapacity,
        status: definition.status,
        visibility: 'public',
        registrationOpen: definition.registrationOpen,
        waitlistEnabled: definition.waitlistCapacity > 0,
        heroImageUrl: `/uploads/e2e-test/${definition.image}`,
        price: definition.key === 'upcoming' ? 499 : 0,
        dressCode: definition.key === 'full' ? 'Festive traditional' : 'Smart casual',
        minAge: 21,
        maxAge: 40,
        language: 'English, Hindi, Gujarati',
        agenda: [{ time: '18:00', title: 'Welcome and introductions' }, { time: '18:30', title: 'Hosted conversation circles' }],
        facilities: ['Parking', 'Accessible entrance', 'Filtered water'],
        interests: ['Conversation', 'Community', definition.category],
        checkInOpensAt: definition.key === 'active' ? new Date(now.getTime() - 2 * 3600000) : null,
        checkInClosesAt: definition.key === 'active' ? new Date(now.getTime() + 2 * 3600000) : null,
      }, transaction);
    }

    const registration = async (eventKey, userKey, status = 'registered') => upsertBy(models.EventRegistration, { eventId: events[eventKey].id, userId: users[userKey].id }, {
      status,
      registeredAt: new Date(now.getTime() - 5 * 86400000),
      cancelledAt: status === 'cancelled' ? new Date(now.getTime() - 2 * 86400000) : null,
    }, transaction);
    await registration('upcoming', 'aarav');
    await registration('upcoming', 'kavya');
    await registration('full', 'kavya');
    await registration('active', 'aarav');
    await registration('past', 'aarav');
    await registration('cancelled', 'aarav', 'cancelled');
    await upsertBy(models.EventWaitlist, { eventId: events.full.id, userId: users.aarav.id }, { status: 'waiting', joinedAt: new Date(now.getTime() - 86400000), endedAt: null }, transaction);
    await upsertBy(models.EventCheckIn, { eventId: events.active.id, userId: users.aarav.id }, { checkedInAt: new Date(now.getTime() - 20 * 60000) }, transaction);
    await upsertBy(models.EventCheckIn, { eventId: events.past.id, userId: users.aarav.id }, { checkedInAt: new Date(now.getTime() - 119 * 3600000) }, transaction);
    await upsertBy(models.EventFeedback, { eventId: events.past.id, userId: users.aarav.id }, {
      rating: 5,
      venueRating: 4,
      hostRating: 5,
      safetyRating: 5,
      experienceRating: 5,
      feedbackText: 'Thoughtful pacing, a welcoming host, and a genuinely easy group to talk with.',
      recommend: true,
    }, transaction);
    for (const [senderKey, textValue] of [
      ['vihaan', 'Welcome everyone. The venue entrance is beside the courtyard café.'],
      ['kavya', 'Looking forward to meeting the group.'],
      ['aarav', 'Thanks for the details. See you there.'],
    ]) {
      await models.EventGroupMessage.findOrCreate({
        where: { eventId: events.upcoming.id, senderId: users[senderKey].id, text: textValue },
        defaults: { eventId: events.upcoming.id, senderId: users[senderKey].id, type: 'text', text: textValue },
        transaction,
      });
    }

    const notificationDefinitions = [
      ['like', 'Likes', 'Meera liked your profile', 'Your thoughtful travel prompt caught her attention.', false, { targetUserId: users.meera.id }],
      ['match', 'Matches', 'You matched with Kavya', 'Your shared interest in local cafés started something promising.', false, { targetUserId: users.kavya.id }],
      ['message', 'Messages', 'Ananya sent a message', 'Perfect. I will send the café location tomorrow.', false, { conversationId: ananyaConversation.id, targetUserId: users.ananya.id }],
      ['super_like', 'Super Likes', 'Your Super Like was delivered', 'Leela can now see that you are especially interested.', true, { targetUserId: users.leela.id }],
      ['event_reminder', 'Events', 'Coffee & Conversation is coming up', 'Your registration is confirmed for the upcoming meetup.', false, { eventId: events.upcoming.id, route: '/events' }],
      ['profile_view', 'Profile Views', 'Neha viewed your profile', 'Your profile made an impression this week.', true, { targetUserId: users.neha.id }],
      ['verification', 'Verification', 'Identity verification complete', 'Your verified status is visible on your profile.', true, { route: '/kyc-verification' }],
      ['security', 'Security', 'New development login', 'Your QA account signed in from the local testing environment.', true, {}],
      ['payment', 'Payments', 'AMORAA Gold is active', 'Your development membership is ready for testing.', true, { route: '/subscription' }],
      ['offer', 'Offers', 'A test-member offer is available', 'Explore the existing membership screen without a real payment.', false, { route: '/subscription' }],
    ];
    for (let index = 0; index < notificationDefinitions.length; index += 1) {
      const [type, category, title, message, isRead, data] = notificationDefinitions[index];
      await upsertBy(models.Notification, { userId: users.aarav.id, type, title }, {
        category,
        message,
        isRead,
        readAt: isRead ? new Date(now.getTime() - (index + 1) * 3600000) : null,
        data,
        deletedAt: null,
        createdAt: new Date(now.getTime() - index * 45 * 60000),
        updatedAt: new Date(now.getTime() - index * 45 * 60000),
      }, transaction);
    }
    await upsertBy(models.Notification, { userId: users.kavya.id, type: 'security', title: 'Kavya private QA notification' }, {
      category: 'Security',
      message: 'This row verifies notification ownership isolation.',
      isRead: false,
      readAt: null,
      data: {},
      deletedAt: null,
    }, transaction);

    const plan = await models.SubscriptionPlan.findByPk('amoraa_gold_monthly', { transaction });
    await upsertBy(models.Subscription, { userId: users.aarav.id }, {
      planId: plan.id,
      status: 'active',
      provider: 'qa_seed',
      providerCustomerId: 'qa_customer_aarav',
      providerSubscriptionId: 'qa_subscription_aarav',
      startedAt: new Date(now.getTime() - 30 * 86400000),
      currentPeriodStart: new Date(now.getTime() - 30 * 86400000),
      currentPeriodEnd: new Date(now.getTime() + 335 * 86400000),
      autoRenew: false,
      cancelAtPeriodEnd: false,
      cancelledAt: null,
      endedAt: null,
    }, transaction);
    const payment = await upsertBy(models.Payment, { userId: users.aarav.id, idempotencyKey: 'e2e:subscription:aarav' }, {
      planId: plan.id,
      productType: 'subscription',
      productReferenceId: plan.id,
      provider: 'qa_seed',
      providerOrderId: 'qa_order_subscription_aarav',
      providerPaymentId: 'qa_payment_subscription_aarav',
      amountMinor: plan.priceMinor,
      currency: plan.currency,
      status: 'paid',
      verifiedAt: new Date(now.getTime() - 30 * 86400000),
      metadata: { source: 'e2e_test_seed' },
    }, transaction);
    await upsertBy(models.PaymentEvent, { provider: 'qa_seed', providerEventId: 'qa_event_subscription_aarav' }, {
      paymentId: payment.id,
      eventType: 'payment.captured',
      payloadHash: 'e2e'.padEnd(64, '0'),
      payload: { source: 'e2e_test_seed', paymentId: String(payment.id) },
      status: 'processed',
      processedAt: new Date(now.getTime() - 30 * 86400000),
      errorMessage: null,
    }, transaction);

    const wallet = await upsertBy(models.Wallet, { userId: users.aarav.id }, { status: 'active', creditUnit: 'AMORAA_CREDITS', balance: 5701 }, transaction);
    await upsertBy(models.WalletTransaction, { walletId: wallet.id, idempotencyKey: 'e2e:wallet:initial-credit' }, {
      userId: users.aarav.id,
      type: 'adjustment',
      direction: 'credit',
      amount: 6000,
      referenceType: 'e2e_seed',
      referenceId: 'primary-wallet',
      balanceBefore: 0,
      balanceAfter: 6000,
      status: 'posted',
      description: 'Development-only starting balance for API testing',
    }, transaction);
    const giftWalletTransaction = await upsertBy(models.WalletTransaction, { walletId: wallet.id, idempotencyKey: 'e2e:gift:ananya' }, {
      userId: users.aarav.id,
      type: 'gift_spend',
      direction: 'debit',
      amount: 299,
      referenceType: 'gift',
      referenceId: 'rose_ritual',
      balanceBefore: 6000,
      balanceAfter: 5701,
      status: 'posted',
      description: 'Rose Ritual sent to Ananya',
    }, transaction);
    await upsertBy(models.GiftTransaction, { senderId: users.aarav.id, idempotencyKey: 'e2e:gift:ananya' }, {
      recipientId: users.ananya.id,
      giftId: 'rose_ritual',
      walletTransactionId: giftWalletTransaction.id,
      conversationId: ananyaConversation.id,
      priceAtPurchase: 299,
      creditUnit: 'AMORAA_CREDITS',
      status: 'sent',
      note: 'For the documentary recommendation.',
    }, transaction);
    await upsertBy(models.BoostEntitlement, { userId: users.aarav.id, idempotencyKey: 'e2e:boost:inventory' }, {
      productId: 'boost_starter_30',
      paymentId: null,
      walletTransactionId: null,
      source: 'admin',
      quantity: 3,
      remainingQuantity: 3,
      durationMinutes: 30,
      status: 'active',
      expiresAt: new Date(now.getTime() + 90 * 86400000),
    }, transaction);
    const historicalEntitlement = await upsertBy(models.BoostEntitlement, { userId: users.aarav.id, idempotencyKey: 'e2e:boost:history' }, {
      productId: 'boost_starter_30',
      source: 'admin',
      quantity: 1,
      remainingQuantity: 0,
      durationMinutes: 30,
      status: 'consumed',
      expiresAt: new Date(now.getTime() - 86400000),
    }, transaction);
    await upsertBy(models.Boost, { userId: users.aarav.id, idempotencyKey: 'e2e:boost:historical-activation' }, {
      boostEntitlementId: historicalEntitlement.id,
      startedAt: new Date(now.getTime() - 2 * 86400000),
      expiresAt: new Date(now.getTime() - 2 * 86400000 + 30 * 60000),
      active: false,
    }, transaction);

    await upsertBy(models.SavedProfile, { userId: users.kavya.id, savedUserId: users.aarav.id }, {}, transaction);
    await upsertBy(models.DiscoverFilterPreference, { userId: users.aarav.id }, {
      minAge: 22,
      maxAge: 40,
      maxDistanceKm: 100,
      verifiedOnly: true,
      onlineNow: false,
      hasPrompts: false,
      hasEventInterest: false,
    }, transaction);
  });

  console.log(`[Seed] E2E environment ready in '${process.env.DB_NAME}': ${personas.length} personas, 5 events, 2 seeded matches, 2 conversations, 10 primary-account notifications.`);
  console.log(`[Seed] Primary login: ${email('aarav')} / ${SEED_PASSWORD}`);
  console.log(`[Seed] Unverified OTP scenario: ${email('isha')} / OTP ${UNVERIFIED_OTP}`);
}

if (require.main === module) {
  seed().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  }).finally(async () => {
    try { await getSequelize().close(); } catch (_) { /* database was not initialized */ }
  });
}

module.exports = { personas, seed, SEED_PASSWORD, UNVERIFIED_OTP };
