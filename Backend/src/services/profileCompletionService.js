const list = (value) => (Array.isArray(value) ? value : []);
const filled = (value) => typeof value === 'string' && value.trim().length > 0;

function validAdultBirthDate(value) {
  if (!value) return false;
  const birth = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(birth.getTime()) || birth > new Date()) return false;
  const now = new Date();
  let age = now.getUTCFullYear() - birth.getUTCFullYear();
  if (now.getUTCMonth() < birth.getUTCMonth()
    || (now.getUTCMonth() === birth.getUTCMonth() && now.getUTCDate() < birth.getUTCDate())) age -= 1;
  return age >= 18;
}

function earned(completed, total, weight) {
  return Math.round((completed / total) * weight);
}

function calculateProfileCompletion(user, profile) {
  const lifestyle = profile.lifestyle && typeof profile.lifestyle === 'object' ? profile.lifestyle : {};
  const promptCount = Object.values(profile.prompts || {}).filter(filled).length;
  const sectionValues = [
    [Math.min(list(profile.photos).length, 2), 2, 15],
    [[filled(user.name), validAdultBirthDate(profile.birthDate), filled(profile.gender)].filter(Boolean).length, 3, 15],
    [[filled(profile.profession), filled(profile.education)].filter(Boolean).length, 2, 10],
    [[filled(profile.city), list(profile.relationshipGoals).some(filled)].filter(Boolean).length, 2, 10],
    [[filled(lifestyle.Height), filled(lifestyle.Languages), filled(lifestyle.Religion)].filter(Boolean).length, 3, 15],
    [filled(profile.bio) && profile.bio.trim().length >= 40 ? 1 : 0, 1, 10],
    [Math.min(list(profile.interests).filter(filled).length, 5), 5, 10],
    [Object.entries(lifestyle).some(([key, value]) => key !== 'Height' && key !== 'Languages' && key !== 'Religion' && filled(value)) ? 1 : 0, 1, 5],
    [promptCount > 0 ? 1 : 0, 1, 10],
  ];
  const percentage = sectionValues.reduce((total, [completed, count, weight]) => total + earned(completed, count, weight), 0);
  return { percentage: Math.max(0, Math.min(100, percentage)), complete: percentage === 100 };
}

module.exports = { calculateProfileCompletion };
