const { scoreCompatibility } = require('./matchEngineService');
const clamp = (value) => Math.max(0, Math.min(100, Math.round(value)));

// LOCAL is deliberately the only executable provider in this phase. Future
// third-party providers must receive this already-minimised structured shape,
// never a profile payload or private account data.
const PROVIDER = 'LOCAL';
const MAX_HIGHLIGHTS = 3;

function configuredProvider() {
  // External execution is intentionally unavailable until a separately
  // reviewed provider is added. A client can never select this value.
  const enabled = String(process.env.AI_MATCHING_ENABLED || 'true').toLowerCase() === 'true';
  const requested = String(process.env.AI_MATCH_PROVIDER || 'local').toUpperCase();
  const external = String(process.env.AI_EXTERNAL_PROVIDER_ENABLED || 'false').toLowerCase() === 'true';
  return enabled && requested === PROVIDER && !external ? PROVIDER : PROVIDER;
}

const levelFor = (score) => {
  if (score >= 90) return 'EXCELLENT';
  if (score >= 80) return 'STRONG';
  if (score >= 70) return 'GOOD';
  if (score >= 60) return 'POTENTIAL';
  return 'EXPLORATORY';
};

const labelFor = Object.freeze({
  interests: 'Shared interests',
  relationshipGoals: 'Relationship goals',
  communicationStyle: 'Communication style',
  languages: 'Shared language',
  city: 'Same city',
  smoking: 'Lifestyle preference',
  drinking: 'Lifestyle preference',
  weed: 'Lifestyle preference',
});

function localAiMatch(viewer, candidate, compatibility = null) {
  const base = compatibility || scoreCompatibility(viewer, candidate);
  const highlights = base.factors
    .filter((factor) => factor.available && factor.value > 0)
    .sort((left, right) => (right.weight * right.value) - (left.weight * left.value) || left.key.localeCompare(right.key))
    .slice(0, MAX_HIGHLIGHTS)
    .map((factor) => ({ type: factor.key.toUpperCase(), label: labelFor[factor.key], strength: clamp(factor.value * 100) }));
  const reasons = highlights.map((highlight) => {
    if (highlight.type === 'INTERESTS') return 'You both share several interests.';
    if (highlight.type === 'RELATIONSHIPGOALS') return 'You appear aligned on relationship goals.';
    if (highlight.type === 'COMMUNICATIONSTYLE') return 'Your communication preferences are compatible.';
    if (highlight.type === 'LANGUAGES') return 'You share a common language.';
    return 'Your lifestyle preferences are broadly aligned.';
  });
  // The AI score is an explainable presentation score. It never changes the
  // certified compatibility score or eligibility result.
  const score = clamp(base.score + Math.round((base.coverage - 50) * 0.08));
  const confidence = clamp(Math.round((base.coverage * 0.8) + (highlights.length / MAX_HIGHLIGHTS) * 20));
  return { aiMatchScore: score, aiConfidence: confidence, aiMatchLevel: levelFor(score), aiHighlights: highlights, aiReasons: reasons, provider: PROVIDER };
}

function rankCandidates(viewer, candidates) {
  return candidates.map((candidate) => ({ ...candidate, ...localAiMatch(viewer, candidate.profile || candidate, candidate.compatibility) }))
    .sort((left, right) => right.aiMatchScore - left.aiMatchScore || right.aiConfidence - left.aiConfidence || Number(left.userId || left.id) - Number(right.userId || right.id));
}

module.exports = { PROVIDER, configuredProvider, localAiMatch, rankCandidates, levelFor };
