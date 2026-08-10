require('../src/config/bootstrapEnv');
require('../src/config/env');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');

const plans = [
  { id: 'amoraa_plus_monthly', name: 'AMORAA Plus', displayName: 'AMORAA Plus Monthly', description: 'A calmer way to meet more compatible people.', priceMinor: 119900, currency: 'INR', billingPeriod: 'month', billingInterval: 1, features: ['Unlimited likes', 'See who liked you', 'Advanced intent filters', '3 Super Likes each week'], entitlements: { premium: true, advancedDiscoverFilters: true }, trialDays: 0, active: true, sortOrder: 10 },
  { id: 'amoraa_gold_monthly', name: 'AMORAA Gold', displayName: 'AMORAA Gold Monthly', description: 'Premium visibility for more intentional conversations.', priceMinor: 199900, currency: 'INR', billingPeriod: 'month', billingInterval: 1, features: ['Priority profiles', 'Read receipts', 'Incognito browsing', 'Boost discount'], entitlements: { premium: true, advancedDiscoverFilters: true, readReceipts: true }, trialDays: 0, offerText: 'Most popular', active: true, sortOrder: 20 },
  { id: 'amoraa_platinum_monthly', name: 'AMORAA Platinum', displayName: 'AMORAA Platinum Monthly', description: 'The most complete AMORAA experience for intentional dating.', priceMinor: 349900, currency: 'INR', billingPeriod: 'month', billingInterval: 1, features: ['Top visibility', 'Unlimited Super Likes', 'Video date access', 'Premium events', 'Concierge match signals'], entitlements: { premium: true, advancedDiscoverFilters: true, readReceipts: true, premiumEvents: true }, trialDays: 0, active: true, sortOrder: 30 },
];
const walletProducts = [
  { id: 'credits_100', type: 'top_up', name: '100 AMORAA Credits', description: 'Starter credit pack', credits: 100, priceMinor: 10000, currency: 'INR', active: true, sortOrder: 10 },
  { id: 'credits_500', type: 'top_up', name: '500 AMORAA Credits', description: 'Popular credit pack', credits: 500, priceMinor: 49900, currency: 'INR', active: true, sortOrder: 20 },
  { id: 'credits_1000', type: 'top_up', name: '1,000 AMORAA Credits', description: 'Best-value credit pack', credits: 1000, priceMinor: 89900, currency: 'INR', active: true, sortOrder: 30 },
  { id: 'credits_2500', type: 'top_up', name: '2,500 AMORAA Credits', description: 'VIP credit pack', credits: 2500, priceMinor: 199900, currency: 'INR', active: true, sortOrder: 40 },
  { id: 'redeem_boost_30', type: 'redemption', name: '30-minute Profile Boost', description: 'Redeem credits for one server-authorized boost', credits: 299, redemptionKind: 'boost', grantQuantity: 1, durationMinutes: 30, active: true, sortOrder: 100 },
];
const boosts = [
  { id: 'boost_starter_30', name: 'Starter Boost', description: 'One 30-minute profile visibility boost', quantity: 1, durationMinutes: 30, priceMinor: 29900, walletCost: 299, currency: 'INR', active: true, sortOrder: 10 },
  { id: 'boost_peak_60', name: 'Peak Boost', description: 'One 60-minute profile visibility boost', quantity: 1, durationMinutes: 60, priceMinor: 49900, walletCost: 499, currency: 'INR', active: true, sortOrder: 20 },
  { id: 'boost_vip_120', name: 'VIP Evening Boost', description: 'One 120-minute profile visibility boost', quantity: 1, durationMinutes: 120, priceMinor: 89900, walletCost: 899, currency: 'INR', active: true, sortOrder: 30 },
];
const gifts = [
  { id: 'rose_ritual', name: 'Rose Ritual', type: 'rose', description: 'A romantic rose note with AMORAA styling.', priceCredits: 299, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 10 },
  { id: 'coffee_date_pass', name: 'Coffee Date Pass', type: 'gift', description: 'A warm invite for a verified cafe date.', priceCredits: 399, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 20 },
  { id: 'artisan_box', name: 'Artisan Box', type: 'gift', description: 'Small-batch chocolate with a personal note.', priceCredits: 499, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 30 },
  { id: 'bookstore_token', name: 'Bookstore Token', type: 'gift', description: 'For readers and thoughtful first dates.', priceCredits: 599, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 40 },
  { id: 'weekend_spark', name: 'Weekend Spark', type: 'gift', description: 'A travel-inspired digital gift.', priceCredits: 999, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 50 },
  { id: 'fine_dining_invite', name: 'Fine Dining Invite', type: 'gift', description: 'A premium dinner invitation for an intentional date.', priceCredits: 1999, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 60 },
  { id: 'heart_burst', name: 'Heart Burst', type: 'gift', description: 'Lightweight virtual affection.', priceCredits: 99, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 70 },
  { id: 'garba_glow', name: 'Garba Glow', type: 'gift', description: 'Festival-season gift card.', priceCredits: 699, creditUnit: 'AMORAA_CREDITS', active: true, sortOrder: 80 },
];

async function run() {
  await initializeDatabase(); const { SubscriptionPlan, WalletProduct, BoostProduct, Gift } = getModels();
  for (const value of plans) await SubscriptionPlan.upsert(value);
  for (const value of walletProducts) await WalletProduct.upsert(value);
  for (const value of boosts) await BoostProduct.upsert(value);
  for (const value of gifts) await Gift.upsert(value);
  console.log(`[Seed] Monetization catalog ready: ${plans.length} plans, ${walletProducts.length} wallet products, ${boosts.length} boost products, ${gifts.length} gifts.`);
  await getSequelize().close();
}
if (require.main === module) run().catch((error) => { console.error(error); process.exit(1); });
module.exports = { run, plans, walletProducts, boosts, gifts };
