// One technical version for eligibility, compatibility, ranking, and cursor
// semantics. Changing any of those contracts must intentionally bump this
// value so previously issued cursors fail closed.
const MATCH_ENGINE_VERSION = 'v2';
const RECOMMENDATION_CURSOR_VERSION = 1;
const MATCH_RANKING_VERSION = `${MATCH_ENGINE_VERSION}:cursor-${RECOMMENDATION_CURSOR_VERSION}`;

module.exports = {
  MATCH_ENGINE_VERSION,
  MATCH_RANKING_VERSION,
  RECOMMENDATION_CURSOR_VERSION,
};
