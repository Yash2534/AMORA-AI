const computeCompatibilityScore = require('../utils/computeCompatibilityScore');

const normalized = (value) => Array.isArray(value)
  ? [...new Set(value.map((item) => String(item).trim().toLowerCase()).filter(Boolean))]
  : [];
const overlap = (left, right) => {
  const rightSet = new Set(normalized(right));
  return normalized(left).filter((value) => rightSet.has(value));
};

function compatibilityFor(viewer, candidate, explicitScore) {
  const score = Math.max(0, Math.min(100, Math.round(explicitScore ?? computeCompatibilityScore(viewer, candidate))));
  if (!viewer || !candidate) {
    return {
      score,
      method: 'deterministic_explainable_v1',
      label: 'Compatibility estimate',
      reasons: [],
      disclaimer: 'This estimate is based on the profile information currently available.',
    };
  }

  const reasons = [];
  const goals = overlap(viewer.relationshipGoals, candidate.relationshipGoals);
  if (goals.length) reasons.push({ factor: 'relationship_goal', label: 'You share a relationship goal', score: 100 });
  const interests = overlap(viewer.interests, candidate.interests);
  if (interests.length) reasons.push({ factor: 'interests', label: `You share ${interests.length} ${interests.length === 1 ? 'interest' : 'interests'}`, score: Math.min(100, 55 + interests.length * 10) });
  const languages = overlap(viewer.languages, candidate.languages);
  if (languages.length) reasons.push({ factor: 'languages', label: `You share ${languages.length} ${languages.length === 1 ? 'language' : 'languages'}`, score: Math.min(100, 65 + languages.length * 10) });
  const qualities = overlap(viewer.valuedQualities, candidate.valuedQualities);
  if (qualities.length) reasons.push({ factor: 'values', label: `You value ${qualities.length} of the same ${qualities.length === 1 ? 'quality' : 'qualities'}`, score: Math.min(100, 60 + qualities.length * 10) });
  if (viewer.communicationStyle && viewer.communicationStyle === candidate.communicationStyle) {
    reasons.push({ factor: 'communication_style', label: 'Your communication styles align', score: 90 });
  }
  const viewerLifestyle = viewer.lifestyle && typeof viewer.lifestyle === 'object' ? viewer.lifestyle : {};
  const candidateLifestyle = candidate.lifestyle && typeof candidate.lifestyle === 'object' ? candidate.lifestyle : {};
  const sharedLifestyle = Object.keys(viewerLifestyle).filter((key) => {
    const left = String(viewerLifestyle[key] || '').trim().toLowerCase();
    const right = String(candidateLifestyle[key] || '').trim().toLowerCase();
    return left && left === right;
  });
  if (sharedLifestyle.length) reasons.push({ factor: 'lifestyle', label: `You align on ${sharedLifestyle.length} lifestyle ${sharedLifestyle.length === 1 ? 'preference' : 'preferences'}`, score: Math.min(100, 60 + sharedLifestyle.length * 10) });

  return {
    score,
    method: 'deterministic_explainable_v1',
    label: 'Explainable compatibility estimate',
    reasons: reasons.slice(0, 6),
    disclaimer: 'This is a deterministic profile-based estimate, not a guarantee of relationship compatibility.',
  };
}

module.exports = { compatibilityFor };
