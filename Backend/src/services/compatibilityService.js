const { overlap, scoreCompatibility, compatibilityReasons } = require('./matchEngineService');

function compatibilityFor(viewer, candidate, explicitScore) {
  const score = Math.max(0, Math.min(100, Math.round(explicitScore ?? scoreCompatibility(viewer, candidate).score)));
  if (!viewer || !candidate) {
    return {
      score,
      method: 'deterministic_explainable_v1',
      label: 'Compatibility estimate',
      reasons: [],
      disclaimer: 'This estimate is based on the profile information currently available.',
    };
  }

  const reasonLabels = compatibilityReasons(viewer, candidate);
  const reasons = reasonLabels.map((label) => {
    if (label.includes('shared interest')) return { factor: 'interests', label: `You share ${label.replace(' shared', '')}`, score };
    if (label.includes('relationship')) return { factor: 'relationship_goal', label: 'You share a relationship goal', score };
    if (label.includes('communication')) return { factor: 'communication_style', label: 'Your communication styles align', score };
    if (label.includes('language')) return { factor: 'languages', label, score };
    if (label.includes('city')) return { factor: 'city', label, score };
    return { factor: 'lifestyle', label, score };
  });

  return {
    score,
    method: 'deterministic_explainable_v1',
    label: 'Explainable compatibility estimate',
    reasons: reasons.slice(0, 6),
    disclaimer: 'This is a deterministic profile-based estimate, not a guarantee of relationship compatibility.',
  };
}

module.exports = { compatibilityFor };
