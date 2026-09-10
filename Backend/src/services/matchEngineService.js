// Phase 1 deterministic match-engine configuration.  These are the only
// compatibility weights used by Discover; no account, message, KYC, report,
// verification or subscription data participates in this calculation.
const SCORE_WEIGHTS = Object.freeze({
  interests: 55,
  relationshipGoals: 30,
  communicationStyle: 15,
});

const normalise = (value) => (Array.isArray(value)
  ? [...new Set(value.map((item) => String(item).trim().toLowerCase()).filter(Boolean))]
  : []);
const overlap = (left, right) => {
  const rightSet = new Set(normalise(right));
  return normalise(left).filter((item) => rightSet.has(item));
};
const clamp = (value) => Math.max(0, Math.min(100, Math.round(value)));

// Optional factors participate only when both profiles supplied comparable
// data.  The resulting weighted score is normalised over available weights,
// so a missing optional field never acts as a negative signal.
function scoreCompatibility(viewer, candidate) {
  const factors = [];
  const interests = overlap(viewer?.interests, candidate?.interests);
  const viewerInterests = normalise(viewer?.interests);
  const candidateInterests = normalise(candidate?.interests);
  if (viewerInterests.length && candidateInterests.length) {
    factors.push({ key: 'interests', weight: SCORE_WEIGHTS.interests,
      value: interests.length / Math.max(viewerInterests.length, candidateInterests.length), shared: interests });
  }
  const goals = overlap(viewer?.relationshipGoals, candidate?.relationshipGoals);
  const viewerGoals = normalise(viewer?.relationshipGoals);
  const candidateGoals = normalise(candidate?.relationshipGoals);
  if (viewerGoals.length && candidateGoals.length) {
    factors.push({ key: 'relationshipGoals', weight: SCORE_WEIGHTS.relationshipGoals,
      value: goals.length / Math.max(viewerGoals.length, candidateGoals.length), shared: goals });
  }
  const viewerStyle = String(viewer?.communicationStyle || '').trim().toLowerCase();
  const candidateStyle = String(candidate?.communicationStyle || '').trim().toLowerCase();
  if (viewerStyle && candidateStyle) {
    factors.push({ key: 'communicationStyle', weight: SCORE_WEIGHTS.communicationStyle,
      value: viewerStyle === candidateStyle ? 1 : 0, shared: viewerStyle === candidateStyle ? [viewerStyle] : [] });
  }
  const availableWeight = factors.reduce((total, factor) => total + factor.weight, 0);
  const weightedValue = factors.reduce((total, factor) => total + factor.weight * factor.value, 0);
  return { score: availableWeight ? clamp((weightedValue / availableWeight) * 100) : 0, factors, availableWeight };
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
  return reasons;
}

module.exports = { SCORE_WEIGHTS, normalise, overlap, scoreCompatibility, compatibilityReasons };
