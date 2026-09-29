const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const { calculateProfileCompletion } = require('../src/services/profileCompletionService');
const {
  ageFor,
  candidateAcceptsViewer,
  isDiscoverComplete,
  profileCompletionErrors,
  viewerAcceptsCandidate,
} = require('../src/services/discoverEligibilityPolicy');
const { scoreCompatibility } = require('../src/services/compatibilityScoringService');
const { distanceKm } = require('../src/utils/geoDistance');
const { pairKeyFor } = require('../src/services/conversationAccessService');
const { QA_USERS } = require('./manual-qa-users-fixture');
const { findQaUsers } = require('./manual-qa-users-store');

function invariant(value, message) {
  if (!value) throw new Error(`Manual QA validation failed: ${message}`);
}

const pairDirections = (firstId, secondId, firstKey, secondKey) => ({
  [Op.or]: [
    { [firstKey]: firstId, [secondKey]: secondId },
    { [firstKey]: secondId, [secondKey]: firstId },
  ],
});

async function validateManualQaUsers(models, config, transaction) {
  const users = await findQaUsers(models, transaction);
  invariant(users.krupa && users.yashu, 'both exact email accounts must exist');
  const ids = { krupa: Number(users.krupa.id), yashu: Number(users.yashu.id) };
  const profiles = {};
  const preferences = {};
  for (const key of ['krupa', 'yashu']) {
    const definition = QA_USERS[key];
    const user = users[key];
    invariant(user.name === definition.name, `${key} name must be deterministic`);
    invariant(user.accountStatus === 'active', `${key} must be active`);
    invariant(user.isVerified === true, `${key} must be verified`);
    if (config.passwords[key]) {
      invariant(await bcrypt.compare(config.passwords[key], user.passwordHash), `${key} login password`);
    }
    profiles[key] = await models.OnboardingProfile.findOne({
      where: { userId: user.id }, transaction,
    });
    preferences[key] = await models.DiscoverFilterPreference.findOne({
      where: { userId: user.id }, transaction,
    });
    invariant(profiles[key], `${key} profile must exist`);
    invariant(preferences[key], `${key} Discover preferences must exist`);
    const completion = calculateProfileCompletion(user, profiles[key]);
    invariant(completion.percentage === 100 && completion.complete, `${key} UI completion must be 100%`);
    invariant(isDiscoverComplete(profiles[key]), `${key} recommendation profile must be complete`);
    invariant(profileCompletionErrors(profiles[key]).length === 0, `${key} recommendation completion fields`);
    invariant(ageFor(profiles[key].birthDate) === definition.age, `${key} age must be ${definition.age}`);
    invariant(preferences[key].minAge === 25 && preferences[key].maxAge === 35, `${key} age range`);
    invariant(preferences[key].maxDistanceKm === 50, `${key} distance range`);
    invariant(preferences[key].minScore === 0, `${key} minimum score`);
    invariant(preferences[key].verifiedOnly === false && preferences[key].onlineNow === false, `${key} unrestricted flags`);
  }

  invariant(viewerAcceptsCandidate(profiles.krupa.interestedIn, profiles.yashu.gender), 'Krupa accepts Yashu gender');
  invariant(candidateAcceptsViewer(profiles.yashu.interestedIn, profiles.krupa.gender), 'Yashu accepts Krupa gender');
  invariant(viewerAcceptsCandidate(profiles.yashu.interestedIn, profiles.krupa.gender), 'Yashu accepts Krupa gender');
  invariant(candidateAcceptsViewer(profiles.krupa.interestedIn, profiles.yashu.gender), 'Krupa accepts Yashu gender');
  const krupaAge = ageFor(profiles.krupa.birthDate);
  const yashuAge = ageFor(profiles.yashu.birthDate);
  invariant(yashuAge >= preferences.krupa.minAge && yashuAge <= preferences.krupa.maxAge, 'Yashu age in Krupa range');
  invariant(krupaAge >= preferences.yashu.minAge && krupaAge <= preferences.yashu.maxAge, 'Krupa age in Yashu range');
  const distance = distanceKm(
    Number(profiles.krupa.matchLatitude), Number(profiles.krupa.matchLongitude),
    Number(profiles.yashu.matchLatitude), Number(profiles.yashu.matchLongitude),
  );
  invariant(distance <= preferences.krupa.maxDistanceKm, 'distance satisfies Krupa');
  invariant(distance <= preferences.yashu.maxDistanceKm, 'distance satisfies Yashu');

  const counts = {
    krupaToYashuAction: await models.DiscoverAction.count({ where: { actorUserId: ids.krupa, targetUserId: ids.yashu }, transaction }),
    yashuToKrupaAction: await models.DiscoverAction.count({ where: { actorUserId: ids.yashu, targetUserId: ids.krupa }, transaction }),
    match: await models.Match.count({ where: { userOneId: Math.min(ids.krupa, ids.yashu), userTwoId: Math.max(ids.krupa, ids.yashu) }, transaction }),
    block: await models.Block.count({ where: pairDirections(ids.krupa, ids.yashu, 'blockerUserId', 'blockedUserId'), transaction }),
    saved: await models.SavedProfile.count({ where: pairDirections(ids.krupa, ids.yashu, 'userId', 'savedUserId'), transaction }),
    rose: await models.RoseTransaction.count({ where: pairDirections(ids.krupa, ids.yashu, 'senderId', 'recipientId'), transaction }),
    report: await models.Report.count({ where: pairDirections(ids.krupa, ids.yashu, 'reporterUserId', 'reportedUserId'), transaction }),
    conversation: await models.Conversation.count({ where: { pairKey: pairKeyFor(ids.krupa, ids.yashu), type: 'direct' }, transaction }),
  };
  invariant(Object.values(counts).every((count) => count === 0), 'A/B relationship state must be empty');

  const compatibility = scoreCompatibility(profiles.krupa, profiles.yashu);
  return {
    userIds: ids,
    completion: { krupa: 100, yashu: 100 },
    ages: { krupa: krupaAge, yashu: yashuAge },
    distanceKm: Number(distance.toFixed(3)),
    compatibility: {
      score: compatibility.score,
      coverage: compatibility.coverage,
      factors: Object.keys(compatibility.factorBreakdown),
    },
    relationshipCounts: counts,
  };
}

module.exports = { validateManualQaUsers };
