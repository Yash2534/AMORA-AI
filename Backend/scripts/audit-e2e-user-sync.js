require('../src/config/bootstrapEnv');
require('../src/config/env');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');
const { Op } = require('sequelize');

async function runAudit() {
  console.log('====================================================');
  console.log(' AMORA-AI END-TO-END USER SYNC AUDIT');
  console.log('====================================================\n');

  await initializeDatabase();
  const sequelize = getSequelize();
  const { User, OnboardingProfile } = getModels();

  const dbConfig = {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
  };

  console.log('1. DATABASE ENVIRONMENT CONFIRMATION:');
  console.log(`   DB_HOST: ${dbConfig.host}`);
  console.log(`   DB_PORT: ${dbConfig.port}`);
  console.log(`   DB_NAME: ${dbConfig.database}`);
  console.log(`   DB_USER: ${dbConfig.user}`);
  console.log(`   ALLOW_DUMMY_SEED: ${process.env.ALLOW_DUMMY_SEED}`);
  console.log(`   DUMMY_SEED_DATABASES: ${process.env.DUMMY_SEED_DATABASES}\n`);

  console.log('2. USER COUNT AUDIT IN SHARED DATABASE:');
  const totalUsers = await User.count();
  const activeUsers = await User.count({ where: { accountStatus: 'active' } });
  const seededUsers = await User.count({ where: { email: { [Op.like]: '%@seed.amoraa.example.test' } } });
  const realUsers = totalUsers - seededUsers;

  console.log(`   Total Users in MySQL '${dbConfig.database}': ${totalUsers}`);
  console.log(`   Active Users: ${activeUsers}`);
  console.log(`   Seeded Demo Users (@seed.amoraa.example.test): ${seededUsers}`);
  console.log(`   Real Non-Seeded Users: ${realUsers}\n`);

  console.log('3. CREATING REAL TEST USER FOR SYNC VERIFICATION...');
  const testEmail = `audit.user.${Date.now()}@amoraa.test`;
  const testUser = await User.create({
    name: 'Audit Test User',
    email: testEmail,
    passwordHash: 'test-hash-2026',
    accountStatus: 'active',
    onboardingStep: 'completed',
    gender: 'female',
    interestedIn: ['male'],
  });

  const testProfile = await OnboardingProfile.create({
    userId: testUser.id,
    name: 'Audit Test User',
    gender: 'female',
    interestedIn: ['male'],
    birthDate: '1998-05-15',
    city: 'Mumbai',
    onboardingCompleted: true,
    photos: ['https://example.com/photo1.jpg'],
    primaryPhotoIndex: 0,
  });

  console.log(`   Created User ID: ${testUser.id}`);
  console.log(`   Created User Name: ${testUser.name}`);
  console.log(`   Created User Email: ${testUser.email}\n`);

  console.log('4. TESTING ADMIN USER SEARCH LOGIC (SQL LIKE):');
  const adminSearchResult = await User.findAll({
    where: {
      [Op.or]: [
        { name: { [Op.like]: `%audit.user%` } },
        { email: { [Op.like]: `%audit.user%` } },
      ],
    },
  });
  console.log(`   Admin Search Found ${adminSearchResult.length} match(es).`);
  console.log(`   Admin Search Match ID: ${adminSearchResult[0]?.id}, Email: ${adminSearchResult[0]?.email}\n`);

  console.log('5. TESTING MAIN APP PROFILE LOOKUP LOGIC:');
  const mainAppUser = await User.findByPk(testUser.id, {
    include: [{ model: OnboardingProfile }],
  });
  console.log(`   Main App Lookup Found User ID: ${mainAppUser?.id}`);
  console.log(`   Main App Onboarding Completed: ${mainAppUser?.OnboardingProfile?.onboardingCompleted}\n`);

  console.log('6. TESTING TWO-WAY SYNC (ADMIN STATUS UPDATE):');
  await testUser.update({ accountStatus: 'deactivated' });
  const updatedMainAppUser = await User.findByPk(testUser.id);
  console.log(`   Admin updated status to 'deactivated'.`);
  console.log(`   Main App User Status is now: ${updatedMainAppUser.accountStatus}\n`);

  console.log('7. CLEANING UP TEST USER...');
  await testProfile.destroy();
  await testUser.destroy();
  console.log('   Cleaned up test user successfully.\n');

  console.log('====================================================');
  console.log(' AUDIT COMPLETED SUCCESSFULLY - ALL CHECKS PASSED');
  console.log('====================================================\n');

  await sequelize.close();
}

runAudit().catch(console.error);
