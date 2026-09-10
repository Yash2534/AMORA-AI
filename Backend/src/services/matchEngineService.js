const MATCH_ENGINE_VERSION = 'v2';
const SCORE_WEIGHTS = Object.freeze({ interests: 35, relationshipGoals: 25, communicationStyle: 10, languages: 10, city: 5, smoking: 5, drinking: 5, weed: 5 });
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
    listFactor('interests', SCORE_WEIGHTS.interests, viewer.interests, candidate.interests),
    listFactor('relationshipGoals', SCORE_WEIGHTS.relationshipGoals, viewer.relationshipGoals, candidate.relationshipGoals),
    exactFactor('communicationStyle', SCORE_WEIGHTS.communicationStyle, viewer.communicationStyle, candidate.communicationStyle),
    listFactor('languages', SCORE_WEIGHTS.languages, viewer.languages, candidate.languages),
    exactFactor('city', SCORE_WEIGHTS.city, viewer.city, candidate.city),
    exactFactor('smoking', SCORE_WEIGHTS.smoking, viewer.smoking, candidate.smoking),
    exactFactor('drinking', SCORE_WEIGHTS.drinking, viewer.drinking, candidate.drinking),
    exactFactor('weed', SCORE_WEIGHTS.weed, viewer.weed, candidate.weed),
  ];
  const availableWeight = factors.filter((factor) => factor.available).reduce((total, factor) => total + factor.weight, 0);
  const weightedValue = factors.reduce((total, factor) => total + factor.weight * factor.value, 0);
  const rawScore = availableWeight ? (weightedValue / availableWeight) * 100 : 50;
  const coverage = availableWeight / TOTAL_WEIGHT;
  return { score: clamp(50 + ((rawScore - 50) * coverage)), rawScore: clamp(rawScore), coverage: clamp(coverage * 100), factors, availableWeight };
}

function compatibilityReasons(viewer, candidate) {
  const { factors } = scoreCompatibility(viewer, candidate);
  const reasons = [];
  const interests = factors.find((factor) => factor.key === 'interests');
  if (interests?.shared.length) reasons.push(`${interests.shared.length} shared ${interests.shared.length === 1 ? 'interest' : 'interests'}`);
  const goals = factors.find((factor) => factor.key === 'relationshipGoals');
  if (goals?.shared.length) reasons.push('Both prefer the same relationship goal');
  const style = factors.find((factor) => factor.key === 'communicationStyle');
  if (style?.value) reasons.push('Compatible communication styles');
  const languages = factors.find((factor) => factor.key === 'languages');
  if (languages?.shared.length) reasons.push('Shared language');
  if (factors.find((factor) => factor.key === 'city')?.value) reasons.push('Same city');
  for (const key of ['smoking', 'drinking', 'weed']) if (factors.find((factor) => factor.key === key)?.value) reasons.push(`Similar ${key} preference`);
  return reasons.slice(0, 6);
}

module.exports = { MATCH_ENGINE_VERSION, SCORE_WEIGHTS, TOTAL_WEIGHT, normalise, overlap, scoreCompatibility, compatibilityReasons };
