const MATCH_ENGINE_VERSION = 'v3';
const SCORE_WEIGHTS = Object.freeze({
  intent: 25,
  values: 15,
  lifestyle: 15,
  communication: 15,
  interests: 10,
  personality: 10,
  preferences: 5,
  behavior: 5
});
const TOTAL_WEIGHT = Object.values(SCORE_WEIGHTS).reduce((sum, value) => sum + value, 0);

const normalise = (value) => (Array.isArray(value)
  ? [...new Set(value.map((item) => String(item).trim().toLowerCase()).filter(Boolean))]
  : []);
const overlap = (left, right) => {
  const rightSet = new Set(normalise(right));
  return normalise(left).filter((item) => rightSet.has(item));
};
const clamp = (value) => Math.max(0, Math.min(100, Math.round(value)));
const text = (value) => String(value || '').trim().toLowerCase();
const listFactor = (key, weight, viewer, candidate) => {
  const left = normalise(viewer); const right = normalise(candidate); const shared = overlap(left, right);
  return { key, weight, available: Boolean(left.length && right.length), value: left.length && right.length ? shared.length / Math.max(left.length, right.length) : 0, shared };
};
const exactFactor = (key, weight, viewer, candidate) => {
  const left = text(viewer); const right = text(candidate);
  return { key, weight, available: Boolean(left && right), value: left && right && left === right ? 1 : 0, shared: left && left === right ? [left] : [] };
};

// Optional factors participate only when both profiles supplied comparable
// data.  The resulting weighted score is normalised over available weights,
// so a missing optional field never acts as a negative signal.
function scoreCompatibility(viewer = {}, candidate = {}) {
  const factors = [
    listFactor('intent', SCORE_WEIGHTS.intent, viewer.intent || viewer.relationshipGoals, candidate.intent || candidate.relationshipGoals),
    listFactor('values', SCORE_WEIGHTS.values, viewer.values, candidate.values),
    listFactor('lifestyle', SCORE_WEIGHTS.lifestyle, viewer.lifestyle, candidate.lifestyle),
    exactFactor('communication', SCORE_WEIGHTS.communication, viewer.communication || viewer.communicationStyle, candidate.communication || candidate.communicationStyle),
    listFactor('interests', SCORE_WEIGHTS.interests, viewer.interests, candidate.interests),
    listFactor('personality', SCORE_WEIGHTS.personality, viewer.personality, candidate.personality),
    listFactor('preferences', SCORE_WEIGHTS.preferences, viewer.preferences, candidate.preferences),
    listFactor('behavior', SCORE_WEIGHTS.behavior, viewer.behavior, candidate.behavior),
  ];
  const availableWeight = factors.filter((factor) => factor.available).reduce((total, factor) => total + factor.weight, 0);
  const weightedValue = factors.reduce((total, factor) => total + factor.weight * factor.value, 0);
  const rawScore = availableWeight ? (weightedValue / availableWeight) * 100 : 50;
  const coverage = availableWeight / TOTAL_WEIGHT;
  
  let confidence = 'Low';
  if (coverage >= 0.8) confidence = 'High';
  else if (coverage >= 0.5) confidence = 'Medium';

  return { score: clamp(50 + ((rawScore - 50) * coverage)), rawScore: clamp(rawScore), coverage: clamp(coverage * 100), confidence, factors, availableWeight };
}

function compatibilityReasons(viewer, candidate) {
  const { factors } = scoreCompatibility(viewer, candidate);
  const reasons = [];
  
  const intent = factors.find((factor) => factor.key === 'intent');
  if (intent?.shared.length) reasons.push('Aligned on relationship goals');
  
  const values = factors.find((factor) => factor.key === 'values');
  if (values?.shared.length) reasons.push('Similar core values');

  const lifestyle = factors.find((factor) => factor.key === 'lifestyle');
  if (lifestyle?.shared.length) reasons.push('Compatible lifestyle choices');

  const communication = factors.find((factor) => factor.key === 'communication');
  if (communication?.value) reasons.push('Compatible communication styles');

  const interests = factors.find((factor) => factor.key === 'interests');
  if (interests?.shared.length) reasons.push(`${interests.shared.length} shared ${interests.shared.length === 1 ? 'interest' : 'interests'}`);

  if (text(viewer.city) && text(viewer.city) === text(candidate.city)) reasons.push('Same city');
  
  return reasons.slice(0, 6);
}

module.exports = { MATCH_ENGINE_VERSION, SCORE_WEIGHTS, TOTAL_WEIGHT, normalise, overlap, scoreCompatibility, compatibilityReasons };
