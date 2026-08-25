const { StreamChat } = require('stream-chat');

const streamUserId = (userId) => `amora_user_${Number(userId)}`;
const channelIdForMatch = (matchId) => `match_${Number(matchId)}`;
function unavailable() { return Object.assign(new Error('Stream Chat is not configured on this server.'), { status: 503, code: 'STREAM_CHAT_NOT_CONFIGURED' }); }
function streamClient() {
  const apiKey = process.env.STREAM_API_KEY; const apiSecret = process.env.STREAM_API_SECRET;
  if (!apiKey || !apiSecret) throw unavailable();
  return { client: StreamChat.getInstance(apiKey, apiSecret), apiKey };
}
function imageFor(profile) { const photos = Array.isArray(profile?.photos) ? profile.photos : []; const image = photos[Number(profile?.primaryPhotoIndex || 0)] || photos[0]; return typeof image === 'string' && /^https?:\/\//.test(image) ? image : undefined; }
async function ensureUser(user, profile) {
  const { client } = streamClient(); const id = streamUserId(user.id);
  await client.upsertUser({ id, name: user.name, ...(imageFor(profile) ? { image: imageFor(profile) } : {}) });
  return id;
}
async function tokenFor(user, profile) { const { client, apiKey } = streamClient(); const userId = await ensureUser(user, profile); return { apiKey, userId, token: client.createToken(userId) }; }
const channelDataForMatch = (match, members, creatorUserId) => ({ members, created_by_id: streamUserId(creatorUserId), amora_match_id: String(match.id) });
const messageDataForAmoraMessage = (messageId, senderUserId, text) => ({ id: `amora_message_${String(messageId)}`, text, user_id: streamUserId(senderUserId), amora_message_id: String(messageId) });
async function channelForMatch(match, users, profiles, creatorUserId) {
  const { client } = streamClient(); const members = await Promise.all(users.map((user, index) => ensureUser(user, profiles[index]))); const channel = client.channel('messaging', channelIdForMatch(match.id), channelDataForMatch(match, members, creatorUserId)); await channel.create(); return { channelId: channel.id, channelType: 'messaging', members };
}
async function publishMessage(matchId, messageId, senderUserId, text) {
  const { client } = streamClient(); const channel = client.channel('messaging', channelIdForMatch(matchId)); await channel.sendMessage(messageDataForAmoraMessage(messageId, senderUserId, text));
}
module.exports = { streamUserId, channelIdForMatch, channelDataForMatch, messageDataForAmoraMessage, tokenFor, channelForMatch, publishMessage };
