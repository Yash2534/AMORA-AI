const crypto = require('crypto'); const { getModels } = require('../models'); const { MATCH_ENGINE_VERSION } = require('./matchEngineService');
const enabled = () => process.env.MATCH_ENGINE_TELEMETRY_ENABLED === 'true';
async function recordDiscover({ viewerUserId, page, profiles, experiment }) {
  if (!enabled()) return { recorded: 0 };
  const requestId = crypto.randomUUID(); const { MatchRecommendationEvent } = getModels();
  if (!profiles.length) { await MatchRecommendationEvent.create({ viewerUserId, eventType: 'no_result', rankingVersion: MATCH_ENGINE_VERSION, requestId, page, noResultReason: 'eligible_candidates_empty', experimentId:experiment?.experimentId,variant:experiment?.variant }); return { recorded: 1 }; }
  await MatchRecommendationEvent.bulkCreate(profiles.map((profile, index) => ({ viewerUserId, candidateUserId: Number(profile.id), eventType: 'impression', rankingVersion: MATCH_ENGINE_VERSION, requestId, page, position: index + 1, score: profile.compatibilityScore, coverage: profile.compatibilityCoverage, experimentId:experiment?.experimentId,variant:experiment?.variant })));
  return { recorded: profiles.length };
}
module.exports = { enabled, recordDiscover };
