const { scoreCompatibility, SCORE_WEIGHTS, TOTAL_WEIGHT, normalise } = require('./matchEngineService');
const clamp = (value) => Number.isFinite(value) ? Math.max(0, Math.min(100, Math.round(value))) : 0;
const PROVIDER = 'LOCAL';
const MAX_HIGHLIGHTS = 3;

// No external provider is executable. Environment/client flags cannot enable one.
const configuredProvider = () => PROVIDER;
const levelFor = (score) => score >= 90 ? 'EXCELLENT' : score >= 80 ? 'STRONG' : score >= 70 ? 'GOOD' : score >= 60 ? 'POTENTIAL' : 'EXPLORATORY';
const labels = Object.freeze({ relationshipGoals: 'Relationship goals', communicationStyle: 'Communication style', interests: 'Shared interests', languages: 'Shared languages', smoking: 'Lifestyle alignment', drinking: 'Lifestyle alignment', weed: 'Lifestyle alignment', city: 'Same city' });
const priority = ['relationshipGoals', 'communicationStyle', 'interests', 'languages', 'smoking', 'drinking', 'weed', 'city'];
const styles = Object.freeze({ frequent_texting: 'frequent texting', occasional_texting: 'occasional texting', calls: 'calls', voice_notes: 'voice notes', deep_conversations: 'deep conversations', light_fun_conversations: 'light, fun conversations' });
const readable = (value) => value.replace(/[_-]+/g, ' ');
// Only public profile factor values; never private preferences or free-text bio.
const displayValues = (shared) => shared.filter((value) => value.length <= 60 && !/[\u0000-\u001f<>@]/.test(value)).sort();

function reasonFor(factor) {
  const values = displayValues(factor.shared);
  if (!values.length) return null;
  if (factor.key === 'relationshipGoals') return `You share a relationship goal: ${values.slice(0, 2).map(readable).join(' and ')}.`;
  if (factor.key === 'communicationStyle') return styles[values[0]] ? `You both prefer ${styles[values[0]]}.` : null;
  if (factor.key === 'interests') return `You share ${factor.shared.length} ${factor.shared.length === 1 ? 'interest' : 'interests'}, including ${values.slice(0, 3).map(readable).join(', ')}.`;
  if (factor.key === 'languages') return `You both speak ${values.slice(0, 3).map(readable).join(' and ')}.`;
  if (['smoking', 'drinking', 'weed'].includes(factor.key)) return 'Some of your stated lifestyle choices align.';
  if (factor.key === 'city') return `You both live in ${values[0].replace(/\b\w/g, (letter) => letter.toUpperCase())}.`;
  return null;
}

// Internal LOCAL contract: current factor keys, canonical weights, shared values.
// This is not an external provider payload.
function evidenceFor(base) {
  return priority.map((key) => {
    const factor = Array.isArray(base.factors) ? base.factors.find((item) => item?.key === key) : null;
    const available = factor?.available === true && Number.isFinite(factor.value);
    return { key, weight: SCORE_WEIGHTS[key], available, value: available ? Math.max(0, Math.min(1, factor.value)) : 0, shared: available ? normalise(factor.shared) : [] };
  });
}

function localAiMatch(viewer, candidate, compatibility = null) {
  const base = compatibility || scoreCompatibility(viewer, candidate);
  const factors = evidenceFor(base);
  const availableWeight = factors.filter((factor) => factor.available).reduce((sum, factor) => sum + factor.weight, 0);
  const coverage = 100 * availableWeight / TOTAL_WEIGHT;
  const support = 100 * factors.reduce((sum, factor) => sum + factor.weight * factor.value, 0) / TOTAL_WEIGHT;
  // Retain the existing 80/20 budget; use ALL evidence, not UI highlight count.
  // An evidence-support index, never a statistical probability.
  const aiConfidence = clamp(0.8 * coverage + 0.2 * support);
  const aiReasons = [];
  const aiHighlights = [];
  for (const factor of factors) {
    if (!factor.available || factor.value <= 0) continue;
    const reason = reasonFor(factor);
    if (!reason || aiReasons.includes(reason)) continue;
    aiReasons.push(reason);
    aiHighlights.push({ type: factor.key.toUpperCase(), label: labels[factor.key], strength: clamp(100 * factor.value) });
    if (aiReasons.length === MAX_HIGHLIGHTS) break;
  }
  if (!aiReasons.length) aiReasons.push('Explore this profile to learn more about each other.');
  const score = Number.isFinite(base.score) ? clamp(base.score) : 50;
  const aiMatchScore = clamp(score + Math.round((coverage - 50) * 0.08));
  return { aiMatchScore, aiConfidence, aiConfidenceLevel: aiConfidence >= 80 ? 'High' : aiConfidence >= 50 ? 'Medium' : 'Low', aiMatchLevel: levelFor(aiMatchScore), aiHighlights, aiReasons, provider: PROVIDER };
}

function rankCandidates(viewer, candidates) {
  return candidates.map((candidate) => ({ ...candidate, ...localAiMatch(viewer, candidate.profile || candidate, candidate.compatibility) }))
    .sort((left, right) => right.aiMatchScore - left.aiMatchScore || right.aiConfidence - left.aiConfidence || Number(left.userId || left.id) - Number(right.userId || right.id));
}

module.exports = { PROVIDER, configuredProvider, localAiMatch, rankCandidates, levelFor };
