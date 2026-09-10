module.exports = (viewer, candidate) => require('../services/matchEngineService').scoreCompatibility(viewer, candidate).score;
