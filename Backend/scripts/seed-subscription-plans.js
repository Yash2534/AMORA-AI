require('../src/config/bootstrapEnv');
require('../src/config/env');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');

const plans = [
  { id: 'amoraa_plus_monthly', name: 'AMORAA Plus', displayName: 'AMORAA Plus Monthly', description: 'A calmer way to meet more compatible people.', priceMinor: 119900, currency: 'INR', billingPeriod: 'month', billingInterval: 1, features: ['Unlimited likes', 'See who liked you', 'Advanced intent filters', '3 Super Likes each week'], entitlements: { premium: true, advancedDiscoverFilters: true }, trialDays: 0, active: true, sortOrder: 10 },
  { id: 'amoraa_gold_monthly', name: 'AMORAA Gold', displayName: 'AMORAA Gold Monthly', description: 'Premium tools for more intentional conversations.', priceMinor: 199900, currency: 'INR', billingPeriod: 'month', billingInterval: 1, features: ['Priority recommendations', 'Read receipts', 'Incognito browsing', 'Premium event access'], entitlements: { premium: true, advancedDiscoverFilters: true, readReceipts: true, premiumEvents: true }, trialDays: 0, offerText: 'Most popular', active: true, sortOrder: 20 },
  { id: 'amoraa_platinum_monthly', name: 'AMORAA Platinum', displayName: 'AMORAA Platinum Monthly', description: 'The most complete AMORAA experience for intentional dating.', priceMinor: 349900, currency: 'INR', billingPeriod: 'month', billingInterval: 1, features: ['Unlimited Super Likes', 'Read receipts', 'Incognito browsing', 'Premium events', 'Concierge match signals'], entitlements: { premium: true, advancedDiscoverFilters: true, readReceipts: true, premiumEvents: true }, trialDays: 0, active: true, sortOrder: 30 },
];

async function run() {
  await initializeDatabase();
  const { SubscriptionPlan } = getModels();
  for (const value of plans) await SubscriptionPlan.upsert(value);
  console.log(`[Seed] Subscription catalog ready: ${plans.length} plans.`);
  await getSequelize().close();
}

if (require.main === module) run().catch((error) => { console.error(error); process.exit(1); });
module.exports = { run, plans };
