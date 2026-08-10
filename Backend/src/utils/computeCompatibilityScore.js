const values = (value) => Array.isArray(value) ? value.map((item) => String(item).trim().toLowerCase()).filter(Boolean) : [];
const shared = (left, right) => values(left).filter((value) => values(right).includes(value)).length;

// This is deliberately deterministic and based only on currently collected onboarding data.
module.exports = (viewer, candidate) => {
  const interests = shared(viewer.interests, candidate.interests);
  const goals = shared(viewer.relationshipGoals, candidate.relationshipGoals);
  const languages = shared(viewer.languages, candidate.languages);
  const qualities = shared(viewer.valuedQualities, candidate.valuedQualities);
  return Math.max(0, Math.min(100, Math.round(55 + Math.min(interests * 6, 24) + Math.min(goals * 10, 10) + Math.min(languages * 4, 6) + Math.min(qualities * 3, 5))));
};
