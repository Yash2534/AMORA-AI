async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

const timestamps = (Sequelize) => ({
  createdAt: { type: Sequelize.DATE, allowNull: false },
  updatedAt: { type: Sequelize.DATE, allowNull: false },
});

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'Users'))) {
      await queryInterface.createTable('Users', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        name: { type: Sequelize.STRING, allowNull: false },
        email: { type: Sequelize.STRING, allowNull: false, unique: true },
        phoneNumber: { type: Sequelize.STRING, allowNull: false, defaultValue: '' },
        passwordHash: { type: Sequelize.STRING, allowNull: true },
        authProvider: { type: Sequelize.ENUM('local', 'google'), allowNull: false, defaultValue: 'local' },
        googleId: { type: Sequelize.STRING, allowNull: true, unique: true },
        isVerified: { type: Sequelize.BOOLEAN, allowNull: true, defaultValue: false },
        termsAcceptedAt: { type: Sequelize.DATE, allowNull: true },
        ...timestamps(Sequelize),
      });
    }

    if (!(await tableExists(queryInterface, 'OtpTokens'))) {
      await queryInterface.createTable('OtpTokens', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        phoneNumber: { type: Sequelize.STRING, allowNull: false },
        codeHash: { type: Sequelize.STRING, allowNull: false },
        purpose: { type: Sequelize.ENUM('account_verification', 'password_reset'), allowNull: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        attempts: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        consumed: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        ...timestamps(Sequelize),
      });
    }

    if (!(await tableExists(queryInterface, 'RefreshTokens'))) {
      await queryInterface.createTable('RefreshTokens', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        tokenHash: { type: Sequelize.STRING, allowNull: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        createdByIp: { type: Sequelize.STRING, allowNull: true },
        ...timestamps(Sequelize),
      });
    }

    if (!(await tableExists(queryInterface, 'OnboardingProfiles'))) {
      await queryInterface.createTable('OnboardingProfiles', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, unique: true, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        birthDate: { type: Sequelize.DATEONLY, allowNull: true },
        gender: { type: Sequelize.STRING, allowNull: true },
        customGender: { type: Sequelize.STRING, allowNull: false, defaultValue: '' },
        interestedIn: { type: Sequelize.JSON, allowNull: false },
        relationshipGoals: { type: Sequelize.JSON, allowNull: false },
        city: { type: Sequelize.STRING, allowNull: true },
        preferredDistance: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 50 },
        profession: { type: Sequelize.STRING, allowNull: true },
        company: { type: Sequelize.STRING, allowNull: true },
        education: { type: Sequelize.STRING, allowNull: true },
        bio: { type: Sequelize.TEXT, allowNull: true },
        hometown: { type: Sequelize.STRING, allowNull: false, defaultValue: '' },
        interests: { type: Sequelize.JSON, allowNull: false },
        lifestyle: { type: Sequelize.JSON, allowNull: false },
        prompts: { type: Sequelize.JSON, allowNull: false },
        pronouns: { type: Sequelize.JSON, allowNull: false },
        sexuality: { type: Sequelize.STRING, allowNull: false, defaultValue: '' },
        valuedQualities: { type: Sequelize.JSON, allowNull: false },
        loveLanguages: { type: Sequelize.JSON, allowNull: false },
        preferredTalkingHours: { type: Sequelize.JSON, allowNull: false },
        photos: { type: Sequelize.JSON, allowNull: false },
        primaryPhotoIndex: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        voicePromptUrl: { type: Sequelize.STRING, allowNull: true },
        videoPromptUrl: { type: Sequelize.STRING, allowNull: true },
        personality: { type: Sequelize.STRING, allowNull: true },
        travelPreference: { type: Sequelize.STRING, allowNull: true },
        musicTaste: { type: Sequelize.STRING, allowNull: true },
        foodPreference: { type: Sequelize.STRING, allowNull: true },
        weekendPlan: { type: Sequelize.STRING, allowNull: true },
        petPreference: { type: Sequelize.STRING, allowNull: true },
        coffeePreference: { type: Sequelize.STRING, allowNull: true },
        height: { type: Sequelize.STRING, allowNull: true },
        fitnessLevel: { type: Sequelize.STRING, allowNull: true },
        children: { type: Sequelize.STRING, allowNull: true },
        smoking: { type: Sequelize.STRING, allowNull: true },
        drinking: { type: Sequelize.STRING, allowNull: true },
        weed: { type: Sequelize.STRING, allowNull: true },
        community: { type: Sequelize.STRING, allowNull: true },
        religion: { type: Sequelize.STRING, allowNull: true },
        familyValues: { type: Sequelize.STRING, allowNull: true },
        loveLanguage: { type: Sequelize.STRING, allowNull: true },
        languages: { type: Sequelize.JSON, allowNull: false },
        greenFlags: { type: Sequelize.JSON, allowNull: false },
        redFlags: { type: Sequelize.JSON, allowNull: false },
        dateIdeas: { type: Sequelize.JSON, allowNull: false },
        stage: { type: Sequelize.ENUM('age', 'gender', 'interestedIn', 'relationshipGoal', 'location', 'starterProfile', 'profileCompletion', 'photos', 'complete'), allowNull: false, defaultValue: 'age' },
        onboardingCompleted: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        ...timestamps(Sequelize),
      });
    }

    if (!(await tableExists(queryInterface, 'DiscoverActions'))) {
      await queryInterface.createTable('DiscoverActions', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        actorUserId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        targetUserId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        action: { type: Sequelize.ENUM('pass', 'like', 'superLike'), allowNull: false },
        ...timestamps(Sequelize),
      });
      await queryInterface.addIndex('DiscoverActions', ['actorUserId', 'targetUserId'], { unique: true, name: 'discover_actions_actor_user_id_target_user_id' });
    }

    if (!(await tableExists(queryInterface, 'Matches'))) {
      await queryInterface.createTable('Matches', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userOneId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        userTwoId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        matchedAt: { type: Sequelize.DATE, allowNull: false },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('Matches', ['userOneId', 'userTwoId'], { unique: true, name: 'matches_user_one_id_user_two_id' });
    }

    if (!(await tableExists(queryInterface, 'Boosts'))) {
      await queryInterface.createTable('Boosts', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        startedAt: { type: Sequelize.DATE, allowNull: false },
        expiresAt: { type: Sequelize.DATE, allowNull: false },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        ...timestamps(Sequelize),
      });
    }

    if (!(await tableExists(queryInterface, 'DiscoverFilterPreferences'))) {
      await queryInterface.createTable('DiscoverFilterPreferences', {
        id: { type: Sequelize.INTEGER, autoIncrement: true, primaryKey: true },
        userId: { type: Sequelize.INTEGER, allowNull: false, unique: true, references: { model: 'Users', key: 'id' }, onDelete: 'CASCADE' },
        minAge: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 18 },
        maxAge: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 45 },
        maxDistanceKm: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 80 },
        minScore: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        city: { type: Sequelize.STRING, allowNull: true },
        minHeight: { type: Sequelize.INTEGER, allowNull: true },
        hometown: { type: Sequelize.JSON, allowNull: false },
        datingIntentions: { type: Sequelize.JSON, allowNull: false },
        lifestyleTags: { type: Sequelize.JSON, allowNull: false },
        education: { type: Sequelize.STRING, allowNull: true },
        profession: { type: Sequelize.STRING, allowNull: true },
        community: { type: Sequelize.STRING, allowNull: true },
        religion: { type: Sequelize.STRING, allowNull: true },
        languages: { type: Sequelize.JSON, allowNull: false },
        pronouns: { type: Sequelize.JSON, allowNull: false },
        sexuality: { type: Sequelize.STRING, allowNull: true },
        qualities: { type: Sequelize.JSON, allowNull: false },
        preferredTalkingHours: { type: Sequelize.JSON, allowNull: false },
        loveLanguages: { type: Sequelize.JSON, allowNull: false },
        smoking: { type: Sequelize.STRING, allowNull: true },
        drinking: { type: Sequelize.STRING, allowNull: true },
        weed: { type: Sequelize.STRING, allowNull: true },
        verifiedOnly: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        onlineNow: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        hasPrompts: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        hasEventInterest: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        ...timestamps(Sequelize),
      });
    }
  },

  async down() {
    // Intentionally non-destructive: this baseline adopts existing production tables
    // and must never drop them during a rollback.
  },
};
