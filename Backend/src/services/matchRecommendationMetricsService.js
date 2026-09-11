const crypto = require('crypto');
const { getModels } = require('../models');

const SCORE_BANDS = Object.freeze([
  { key: '0_20', min: 0, max: 20 },
  { key: '21_40', min: 21, max: 40 },
  { key: '41_60', min: 41, max: 60 },
  { key: '61_80', min: 61, max: 80 },
  { key: '81_100', min: 81, max: 100 },
]);
const COVERAGE_BUCKETS = Object.freeze([
  { key: 'low', min: 0, max: 33 },
  { key: 'medium', min: 34, max: 66 },
  { key: 'high', min: 67, max: 100 },
]);

const bucketFor = (value, buckets) => buckets.find((bucket) => value >= bucket.min && value <= bucket.max)?.key || null;
const pairKey = (viewerId, candidateId) => `${Number(viewerId)}:${Number(candidateId)}`;
const timestamp = (value) => new Date(value || 0).getTime();
const latestFirst = (left, right) => timestamp(right.createdAt) - timestamp(left.createdAt) || Number(right.id) - Number(left.id);

function latestQualifyingImpression(impressions, viewerId, candidateId, outcomeAt) {
  return impressions
    .filter((impression) => (
      Number(impression.viewerUserId) === Number(viewerId)
      && Number(impression.candidateUserId) === Number(candidateId)
      && timestamp(impression.createdAt) <= timestamp(outcomeAt)
    ))
    .sort(latestFirst)[0] || null;
}

function attributedRecord(outcome, impression) {
  return {
    outcomeType: outcome.type,
    outcomeId: outcome.id,
    viewerId: Number(impression.viewerUserId),
    candidateId: Number(impression.candidateUserId),
    outcomeAt: outcome.at,
    selectedImpressionId: Number(impression.id),
    selectedImpressionAt: impression.createdAt,
    rankingVersion: impression.rankingVersion,
    experimentId: impression.experimentId,
    variant: impression.variant,
    compatibilityScore: Number(impression.score),
    compatibilityCoverage: Number(impression.coverage),
    scoreBand: bucketFor(Number(impression.score), SCORE_BANDS),
    coverageBucket: bucketFor(Number(impression.coverage), COVERAGE_BUCKETS),
  };
}

// Builds attribution from the complete impression universe.  All downstream
// summaries filter these normalized records; they must never re-attribute from
// an experiment, score, or coverage subset.
function buildAttributedOutcomes(impressions, { actions, roses, matches }) {
  const outcomes = [];

  for (const action of actions) {
    if (action.action !== 'like' && action.action !== 'superLike') continue;
    outcomes.push({
      type: action.action,
      id: `${action.action}:${pairKey(action.actorUserId, action.targetUserId)}`,
      viewerId: action.actorUserId,
      candidateId: action.targetUserId,
      at: action.createdAt,
    });
  }
  for (const rose of roses) {
    outcomes.push({
      type: 'rose',
      id: `rose:${Number(rose.id)}`,
      viewerId: rose.senderId,
      candidateId: rose.recipientId,
      at: rose.createdAt,
    });
  }
  for (const match of matches) {
    outcomes.push({
      type: 'match',
      id: `match:${Math.min(Number(match.userOneId), Number(match.userTwoId))}:${Math.max(Number(match.userOneId), Number(match.userTwoId))}`,
      match,
      at: match.matchedAt,
    });
  }

  const uniqueOutcomes = [...new Map(outcomes.map((outcome) => [outcome.id, outcome])).values()];
  const attributed = [];

  for (const outcome of uniqueOutcomes) {
    let impression;
    if (outcome.type === 'match') {
      const { userOneId, userTwoId } = outcome.match;
      const candidates = impressions
        .filter((candidate) => (
          timestamp(candidate.createdAt) <= timestamp(outcome.at)
          && (
            (Number(candidate.viewerUserId) === Number(userOneId) && Number(candidate.candidateUserId) === Number(userTwoId))
            || (Number(candidate.viewerUserId) === Number(userTwoId) && Number(candidate.candidateUserId) === Number(userOneId))
          )
        ))
        .sort(latestFirst);
      impression = candidates[0] || null;
    } else {
      impression = latestQualifyingImpression(impressions, outcome.viewerId, outcome.candidateId, outcome.at);
    }
    if (impression) attributed.push(attributedRecord(outcome, impression));
  }
  return attributed;
}

async function loadAggregationData() {
  const { MatchRecommendationEvent, DiscoverAction, RoseTransaction, Match } = getModels();
  const [events, actions, roses, matches] = await Promise.all([
    MatchRecommendationEvent.findAll({ raw: true }),
    DiscoverAction.findAll({ raw: true }),
    RoseTransaction.findAll({ where: { status: 'sent' }, raw: true }),
    Match.findAll({ raw: true }),
  ]);
  return { events, actions, roses, matches };
}

function matchesContext(row, filters) {
  return (
    (filters.experimentId === undefined || row.experimentId === filters.experimentId)
    && (filters.variant === undefined || row.variant === filters.variant)
  );
}

const average = (rows, key) => rows.length ? rows.reduce((sum, row) => sum + Number(row[key] || 0), 0) / rows.length : 0;
const outcomeCount = (outcomes, type) => outcomes.filter((outcome) => outcome.outcomeType === type).length;

function buildSummary(rows, attributedOutcomes) {
  const impressions = rows.filter((row) => row.eventType === 'impression');
  const noResults = rows.filter((row) => row.eventType === 'no_result');
  const denominator = impressions.length;
  const rate = (type) => denominator ? outcomeCount(attributedOutcomes, type) / denominator : 0;
  const scopedOutcomes = (field, key) => attributedOutcomes.filter((outcome) => outcome[field] === key);

  const report = {
    impressions: denominator,
    uniqueCandidates: new Set(impressions.map((impression) => impression.candidateUserId)).size,
    noResultCount: noResults.length,
    noResultRate: rows.length ? noResults.length / rows.length : 0,
    averageScore: average(impressions, 'score'),
    averageCoverage: average(impressions, 'coverage'),
    paginationDepth: impressions.reduce((depth, impression) => Math.max(depth, Number(impression.page)), 0),
    sparseExposureCount: impressions.filter((impression) => Number(impression.coverage) <= 33).length,
  };

  for (const [type, field] of [['like', 'Likes'], ['superLike', 'SuperLikes'], ['rose', 'Roses'], ['match', 'Matches']]) {
    report[`observed${field}`] = outcomeCount(attributedOutcomes, type);
    report[`${type}Rate`] = rate(type);
  }

  report.scoreBands = SCORE_BANDS.map((band) => {
    const bandImpressions = impressions.filter((impression) => bucketFor(Number(impression.score), SCORE_BANDS) === band.key);
    const bandOutcomes = scopedOutcomes('scoreBand', band.key);
    return {
      ...band,
      impressions: bandImpressions.length,
      observedLikes: outcomeCount(bandOutcomes, 'like'),
      likeRate: bandImpressions.length ? outcomeCount(bandOutcomes, 'like') / bandImpressions.length : 0,
      observedSuperLikes: outcomeCount(bandOutcomes, 'superLike'),
      superLikeRate: bandImpressions.length ? outcomeCount(bandOutcomes, 'superLike') / bandImpressions.length : 0,
      observedRoses: outcomeCount(bandOutcomes, 'rose'),
      roseRate: bandImpressions.length ? outcomeCount(bandOutcomes, 'rose') / bandImpressions.length : 0,
      observedMatches: outcomeCount(bandOutcomes, 'match'),
      matchRate: bandImpressions.length ? outcomeCount(bandOutcomes, 'match') / bandImpressions.length : 0,
      averageCoverage: average(bandImpressions, 'coverage'),
    };
  });

  report.coverageBuckets = COVERAGE_BUCKETS.map((bucket) => {
    const bucketImpressions = impressions.filter((impression) => bucketFor(Number(impression.coverage), COVERAGE_BUCKETS) === bucket.key);
    const bucketOutcomes = scopedOutcomes('coverageBucket', bucket.key);
    return {
      ...bucket,
      impressions: bucketImpressions.length,
      averageScore: average(bucketImpressions, 'score'),
      observedLikes: outcomeCount(bucketOutcomes, 'like'),
      observedSuperLikes: outcomeCount(bucketOutcomes, 'superLike'),
      observedRoses: outcomeCount(bucketOutcomes, 'rose'),
      observedMatches: outcomeCount(bucketOutcomes, 'match'),
    };
  });
  return report;
}

function globalAttribution(data) {
  const impressions = data.events.filter((event) => event.eventType === 'impression');
  return buildAttributedOutcomes(impressions, data);
}

async function summary(filters = {}) {
  const data = await loadAggregationData();
  const rows = data.events.filter((event) => matchesContext(event, filters));
  const impressionIds = new Set(rows.filter((event) => event.eventType === 'impression').map((event) => Number(event.id)));
  const outcomes = globalAttribution(data).filter((outcome) => impressionIds.has(outcome.selectedImpressionId));
  return buildSummary(rows, outcomes);
}

async function summaryByExperiment() {
  const data = await loadAggregationData();
  const globallyAttributedOutcomes = globalAttribution(data);
  const groups = [...new Set(data.events
    .filter((event) => event.experimentId && event.variant)
    .map((event) => JSON.stringify([event.experimentId, event.variant])))];

  return groups.map((group) => {
    const [experimentId, variant] = JSON.parse(group);
    const rows = data.events.filter((event) => event.experimentId === experimentId && event.variant === variant);
    const impressionIds = new Set(rows.filter((event) => event.eventType === 'impression').map((event) => Number(event.id)));
    const outcomes = globallyAttributedOutcomes.filter((outcome) => impressionIds.has(outcome.selectedImpressionId));
    return { experimentId, variant, metrics: buildSummary(rows, outcomes) };
  });
}

function assignment(config, userId) {
  if (!config?.enabled) return { variant: 'control', experimentId: null };
  if (!/^[a-z0-9_-]{1,80}$/i.test(config.id || '') || !Number.isInteger(config.allocation) || config.allocation < 0 || config.allocation > 100) {
    throw Object.assign(new Error('Invalid experiment configuration.'), { code: 'INVALID_EXPERIMENT_CONFIG' });
  }
  return {
    experimentId: config.id,
    variant: crypto.createHash('sha256').update(`${config.id}:${Number(userId)}`).digest()[0] % 100 < config.allocation ? 'variant' : 'control',
  };
}

function configuredAssignment(userId) {
  if (process.env.MATCH_ENGINE_EXPERIMENT_ENABLED !== 'true') return assignment(null, userId);
  let config;
  try { config = JSON.parse(process.env.MATCH_ENGINE_EXPERIMENT_CONFIG || '{}'); } catch (_) {
    throw Object.assign(new Error('Invalid experiment configuration.'), { code: 'INVALID_EXPERIMENT_CONFIG' });
  }
  return assignment({ ...config, enabled: true }, userId);
}

module.exports = {
  SCORE_BANDS,
  COVERAGE_BUCKETS,
  bucketFor,
  buildAttributedOutcomes,
  summary,
  summaryByExperiment,
  assignment,
  configuredAssignment,
};
