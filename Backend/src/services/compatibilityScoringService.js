const { MATCH_ENGINE_VERSION } = require('./matchEngineContract');

const MATCH_FACTORS = Object.freeze([
  Object.freeze({ key: 'interests', weight: 35, type: 'list', maxItems: 20 }),
  Object.freeze({ key: 'relationshipGoals', weight: 25, type: 'list', maxItems: 30 }),
  Object.freeze({ key: 'communicationStyle', weight: 10, type: 'scalar' }),
  Object.freeze({ key: 'languages', weight: 10, type: 'list', maxItems: 30 }),
  Object.freeze({ key: 'city', weight: 5, type: 'scalar' }),
  Object.freeze({ key: 'smoking', weight: 5, type: 'scalar' }),
  Object.freeze({ key: 'drinking', weight: 5, type: 'scalar' }),
  Object.freeze({ key: 'weed', weight: 5, type: 'scalar' }),
]);
const SCORE_WEIGHTS = Object.freeze(Object.fromEntries(MATCH_FACTORS.map(({ key, weight }) => [key, weight])));
const TOTAL_WEIGHT = MATCH_FACTORS.reduce((sum, factor) => sum + factor.weight, 0);

const text = (value) => typeof value === 'string' ? value.trim().toLowerCase() : '';
const usableText = (value) => text(value) === 'prefer not to say' ? '' : text(value);
const normalise = (value, maximumItems = Number.POSITIVE_INFINITY) => (Array.isArray(value)
  ? [...new Set(value.slice(0, maximumItems).map(usableText).filter(Boolean))]
  : []);
const publicSharedValues = (values) => [...new Set(values
  .map((value) => value.replace(/[\u0000-\u001f\u007f-\u009f]/g, '').trim())
  .filter(Boolean))];
const overlap = (left, right, maximumItems = Number.POSITIVE_INFINITY) => {
  const rightSet = new Set(normalise(right, maximumItems));
  return normalise(left, maximumItems).filter((item) => rightSet.has(item));
};
// Remove sub-picosecond binary floating-point drift before applying the
// product's mathematical round-to-nearest rule (SQL ROUND already behaves on
// the exact decimal expression).
const clamp = (value) => Math.max(0, Math.min(100, Math.round(value + 1e-10)));

function normalizeProfile(profile = {}) {
  const source = profile || {};
  return Object.fromEntries(MATCH_FACTORS.map((factor) => [
    factor.key,
    factor.type === 'list'
      ? normalise(source[factor.key], factor.maxItems)
      : usableText(source[factor.key]),
  ]));
}

function listFactor(definition, viewer, candidate) {
  const left = viewer[definition.key];
  const right = candidate[definition.key];
  const rightSet = new Set(right);
  const intersection = left.filter((item) => rightSet.has(item));
  const shared = publicSharedValues(intersection);
  const available = Boolean(left.length && right.length);
  const agreement = available ? intersection.length / Math.max(left.length, right.length) : 0;
  return {
    key: definition.key,
    weight: definition.weight,
    type: definition.type,
    available,
    value: agreement,
    agreement,
    shared,
    sharedValues: shared,
  };
}

function exactFactor(definition, viewer, candidate) {
  const left = viewer[definition.key];
  const right = candidate[definition.key];
  const available = Boolean(left && right);
  const agreement = available && left === right ? 1 : 0;
  const shared = agreement ? [left] : [];
  return {
    key: definition.key,
    weight: definition.weight,
    type: definition.type,
    available,
    value: agreement,
    agreement,
    shared,
    sharedValues: shared,
  };
}

function scoreCompatibility(viewer = {}, candidate = {}) {
  const normalizedViewer = normalizeProfile(viewer);
  const normalizedCandidate = normalizeProfile(candidate);
  const factors = MATCH_FACTORS.map((definition) => (
    definition.type === 'list'
      ? listFactor(definition, normalizedViewer, normalizedCandidate)
      : exactFactor(definition, normalizedViewer, normalizedCandidate)
  ));
  const availableWeight = factors
    .filter((factor) => factor.available)
    .reduce((total, factor) => total + factor.weight, 0);
  const weightedAgreement = factors.reduce(
    (total, factor) => total + factor.weight * factor.agreement,
    0,
  );
  const rawScoreValue = availableWeight ? (weightedAgreement / availableWeight) * 100 : 50;
  const coverageFraction = availableWeight / TOTAL_WEIGHT;
  const score = clamp(50 + ((rawScoreValue - 50) * coverageFraction));
  const rawScore = clamp(rawScoreValue);
  const coverage = clamp(coverageFraction * 100);

  let confidence = 'Low';
  if (coverageFraction >= 0.8) confidence = 'High';
  else if (coverageFraction >= 0.5) confidence = 'Medium';

  const breakdown = factors.map((factor) => ({
    ...factor,
    contribution: factor.weight * factor.agreement,
    weightedAgreement: factor.weight * factor.agreement,
    maximumContribution: factor.available ? factor.weight : 0,
    netContribution: factor.available ? factor.weight * (factor.agreement - 0.5) : 0,
  }));
  return {
    score,
    rawScore,
    coverage,
    compatibilityScore: score,
    compatibilityRawScore: rawScore,
    compatibilityCoverage: coverage,
    confidence,
    factors: breakdown,
    availableWeight,
    weightedAgreement,
    factorBreakdown: Object.fromEntries(breakdown.map((factor) => [factor.key, factor])),
    positiveFactors: breakdown.filter((factor) => factor.netContribution > 0),
    neutralFactors: breakdown.filter((factor) => factor.netContribution === 0),
    negativeFactors: breakdown.filter((factor) => factor.netContribution < 0),
  };
}

function compatibilityReasonsFromFactors(compatibility) {
  const factors = Array.isArray(compatibility?.factors) ? compatibility.factors : [];
  const reasons = [];
  const interests = factors.find((factor) => factor.key === 'interests');
  if (interests?.shared.length) reasons.push(`${interests.shared.length} shared ${interests.shared.length === 1 ? 'interest' : 'interests'}`);
  const goals = factors.find((factor) => factor.key === 'relationshipGoals');
  if (goals?.shared.length) reasons.push('Both prefer the same relationship goal');
  const style = factors.find((factor) => factor.key === 'communicationStyle');
  if (style?.agreement) reasons.push('Compatible communication styles');
  const languages = factors.find((factor) => factor.key === 'languages');
  if (languages?.shared.length) reasons.push('Shared language');
  if (factors.find((factor) => factor.key === 'city')?.agreement) reasons.push('Same city');
  for (const key of ['smoking', 'drinking', 'weed']) {
    if (factors.find((factor) => factor.key === key)?.agreement) reasons.push(`Similar ${key} preference`);
  }
  return reasons.slice(0, 6);
}

function compatibilityReasons(viewer, candidate) {
  return compatibilityReasonsFromFactors(scoreCompatibility(viewer, candidate));
}

function sqlCompatibilityExpressions(sequelize, viewer, { profileAlias = 'OnboardingProfile' } = {}) {
  const quote = (value) => sequelize.getQueryInterface().queryGenerator.quoteIdentifier(value);
  const column = (name) => `${quote(profileAlias)}.${quote(name)}`;
  const normalizedViewer = normalizeProfile(viewer);
  const components = MATCH_FACTORS.map((definition) => {
    const viewerValue = normalizedViewer[definition.key];
    if (definition.type === 'scalar') {
      if (!viewerValue) return { weighted: '0', available: '0' };
      const candidateValue = `LOWER(TRIM(${column(definition.key)}))`;
      const available = `(${column(definition.key)} IS NOT NULL AND ${candidateValue} NOT IN ('', 'prefer not to say'))`;
      return {
        weighted: `(CASE WHEN ${available} AND ${candidateValue} = ${sequelize.escape(viewerValue)} THEN ${definition.weight} ELSE 0 END)`,
        available: `(CASE WHEN ${available} THEN ${definition.weight} ELSE 0 END)`,
      };
    }
    if (!viewerValue.length) return { weighted: '0', available: '0' };
    const source = `(CASE WHEN JSON_VALID(${column(definition.key)}) AND JSON_TYPE(${column(definition.key)}) = 'ARRAY' THEN ${column(definition.key)} ELSE JSON_ARRAY() END)`;
    const indexAlias = quote(`score_${definition.key}_indices`);
    const databaseMajor = Number.parseInt(String(sequelize.options?.databaseVersion || ''), 10);
    const mariaDb = Number.isFinite(databaseMajor) && databaseMajor >= 10;
    // The supported local MariaDB 10.4 runtime has sequence tables but no
    // JSON_TABLE. The documented MySQL 8 runtime uses JSON_TABLE. Both sources
    // feed the exact same normalization/count expression below.
    const indexSource = mariaDb
      ? `seq_0_to_${definition.maxItems - 1}`
      : `JSON_TABLE(${source}, '$[*]' COLUMNS (${quote('itemIndex')} FOR ORDINALITY))`;
    const indexColumn = `${indexAlias}.${quote(mariaDb ? 'seq' : 'itemIndex')}`;
    const zeroBasedIndex = mariaDb ? indexColumn : `(${indexColumn} - 1)`;
    const extracted = `JSON_EXTRACT(${source}, CONCAT('$[', ${zeroBasedIndex}, ']'))`;
    const item = `(CASE WHEN JSON_TYPE(${extracted}) = 'STRING' THEN LOWER(TRIM(JSON_UNQUOTE(${extracted}))) ELSE NULL END)`;
    const usable = `${item} IS NOT NULL AND ${item} NOT IN ('', 'prefer not to say')`;
    const boundedIndex = mariaDb ? '' : `${indexColumn} <= ${definition.maxItems} AND `;
    const count = (extra = '') => `(SELECT COUNT(DISTINCT ${item}) FROM ${indexSource} AS ${indexAlias} WHERE ${boundedIndex}${usable}${extra})`;
    const candidateCount = count();
    const sharedCount = count(` AND ${item} IN (${viewerValue.map((value) => sequelize.escape(value)).join(', ')})`);
    return {
      weighted: `(${definition.weight} * (${sharedCount} / GREATEST(${viewerValue.length}, ${candidateCount})))`,
      available: `(CASE WHEN ${candidateCount} > 0 THEN ${definition.weight} ELSE 0 END)`,
    };
  });
  const weightedAgreement = components.map((component) => component.weighted).join(' + ');
  const availableWeight = components.map((component) => component.available).join(' + ');
  const rawScore = `(CASE WHEN (${availableWeight}) > 0 THEN 100 * (${weightedAgreement}) / (${availableWeight}) ELSE 50 END)`;
  const coverage = `LEAST(100, GREATEST(0, ROUND(100 * (${availableWeight}) / ${TOTAL_WEIGHT})))`;
  const score = `LEAST(100, GREATEST(0, ROUND(50 + (${weightedAgreement}) - ((${availableWeight}) / 2))))`;
  return { score, rawScore, coverage, availableWeight: `(${availableWeight})`, weightedAgreement: `(${weightedAgreement})` };
}

module.exports = {
  MATCH_ENGINE_VERSION,
  MATCH_FACTORS,
  SCORE_WEIGHTS,
  TOTAL_WEIGHT,
  compatibilityReasons,
  compatibilityReasonsFromFactors,
  normalizeProfile,
  normalise,
  overlap,
  scoreCompatibility,
  sqlCompatibilityExpressions,
  usableText,
};
