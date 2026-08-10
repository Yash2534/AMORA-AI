require('../src/config/bootstrapEnv');
require('../src/config/env');
const { initializeDatabase, getSequelize } = require('../src/config/db');
const { getModels } = require('../src/models');

async function main() {
  if (process.env.NODE_ENV === 'production') throw new Error('Development Event seeding is disabled in production.');
  const hostId = Number(process.env.EVENT_SEED_HOST_ID);
  if (!hostId) throw new Error('Set EVENT_SEED_HOST_ID to an existing active development host user.');
  await initializeDatabase();
  const { User, Event } = getModels();
  const host = await User.findOne({ where: { id: hostId, accountStatus: 'active' } });
  if (!host) throw new Error('EVENT_SEED_HOST_ID must reference an active user.');
  const now = Date.now();
  const definitions = [
    ['AMORAA Dev Coffee Meetup', 48, 51, 30, 10, 'published'],
    ['AMORAA Dev Full Event', 72, 75, 1, 10, 'published'],
    ['AMORAA Dev Past Gathering', -72, -69, 20, 0, 'completed'],
  ];
  for (const [title, startHours, endHours, capacity, waitlistCapacity, status] of definitions) {
    const existing = await Event.findOne({ where: { title, hostId } });
    if (existing) continue;
    await Event.create({
      title,
      description: `${title} is controlled development data stored in MySQL.`,
      category: title.includes('Coffee') ? 'Coffee Meetup' : 'Workshop',
      city: 'Ahmedabad',
      venueName: 'AMORAA Development Venue',
      startDateTime: new Date(now + startHours * 60 * 60 * 1000),
      endDateTime: new Date(now + endHours * 60 * 60 * 1000),
      capacity,
      waitlistCapacity,
      status,
      visibility: 'public',
      registrationOpen: status === 'published',
      waitlistEnabled: waitlistCapacity > 0,
      hostId,
      price: 0,
      language: 'English, Gujarati',
      agenda: [{ time: '18:00', title: 'Welcome' }],
      facilities: ['Parking'],
      interests: ['Conversation'],
    });
  }
  console.log('[Seed] Development Events are available in MySQL.');
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
}).finally(async () => {
  try { await getSequelize().close(); } catch (_) { /* not initialized */ }
});
