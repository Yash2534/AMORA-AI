const { getModels } = require('../models');
const { validCoordinates } = require('../utils/geoDistance');

function publicLocationState(profile) {
  return {
    locationAvailable: validCoordinates(profile?.matchLatitude, profile?.matchLongitude),
    locationUpdatedAt: profile?.locationUpdatedAt || null,
  };
}

exports.get = async (req, res, next) => {
  try {
    const { OnboardingProfile } = getModels();
    const profile = await OnboardingProfile.findOne({ where: { userId: req.user.sub } });
    return res.json({
      success: true,
      message: 'Match location status retrieved.',
      data: { location: publicLocationState(profile) },
    });
  } catch (error) { return next(error); }
};

exports.update = async (req, res, next) => {
  try {
    const { OnboardingProfile } = getModels();
    const [profile] = await OnboardingProfile.findOrCreate({
      where: { userId: req.user.sub },
      defaults: { userId: req.user.sub },
    });
    await profile.update({
      matchLatitude: Number(req.body.latitude),
      matchLongitude: Number(req.body.longitude),
      locationUpdatedAt: new Date(),
    });
    return res.json({
      success: true,
      message: 'Current location enabled for distance matching.',
      data: { location: publicLocationState(profile) },
    });
  } catch (error) { return next(error); }
};

exports.clear = async (req, res, next) => {
  try {
    const { OnboardingProfile } = getModels();
    const profile = await OnboardingProfile.findOne({ where: { userId: req.user.sub } });
    if (profile) {
      await profile.update({ matchLatitude: null, matchLongitude: null, locationUpdatedAt: null });
    }
    return res.json({
      success: true,
      message: 'Distance matching location cleared.',
      data: { location: publicLocationState(profile) },
    });
  } catch (error) { return next(error); }
};

exports._test = { publicLocationState };
