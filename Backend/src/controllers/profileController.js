const { Op } = require('sequelize');
const { getModels } = require('../models');
const { activeAccountWhere, areUsersBlocked, matchPairWhere } = require('../services/accessControlService');
const { serializePublicProfile } = require('../services/publicProfileService');
const { COMMUNICATION_STYLE_VALUES } = require('../constants/communicationStyles');
const { calculateProfileCompletion } = require('../services/profileCompletionService');

const unavailable = (res) => res.status(404).json({ success: false, message: 'Profile is not available.', code: 'PROFILE_NOT_AVAILABLE', errors: [] });
const list = (value) => (Array.isArray(value) ? value : []);

function ownProfileJson(req, user, profile) {
  const photos = list(profile.photos);
  const publicUrl = (value) => value && /^https?:\/\//i.test(value)
    ? value
    : value ? `${req.protocol}://${req.get('host')}${value}` : value;
  const birthdate = profile.birthDate
    ? String(profile.birthDate).split('-').reverse().join('/')
    : '';
  return {
    name: user.name,
    email: user.email,
    phoneNumber: user.phoneNumber,
    birthdate,
    gender: profile.gender || '',
    bio: profile.bio || '',
    profession: profile.profession || '',
    company: profile.company || '',
    education: profile.education || '',
    location: profile.city || '',
    datingIntention: list(profile.relationshipGoals)[0] || '',
    interests: list(profile.interests),
    prompts: profile.prompts || {},
    lifestyle: profile.lifestyle || {},
    photos: photos.map(publicUrl),
    primaryPhotoIndex: photos.length ? Math.min(Number(profile.primaryPhotoIndex || 0), photos.length - 1) : 0,
    voicePrompt: publicUrl(profile.voicePromptUrl),
    videoPrompt: publicUrl(profile.videoPromptUrl),
    hometown: profile.hometown || '',
    valuedQualities: list(profile.valuedQualities),
    pronouns: list(profile.pronouns),
    sexuality: profile.sexuality || '',
    preferredTalkingHours: list(profile.preferredTalkingHours),
    loveLanguages: list(profile.loveLanguages),
    iceBreaker: profile.iceBreaker || '',
    communicationStyle: profile.communicationStyle || null,
    profileCompletion: calculateProfileCompletion(user, profile),
  };
}

exports.getOwnProfile = async (req, res, next) => {
  try {
    const { User, OnboardingProfile } = getModels();
    const user = await User.findByPk(req.user.sub, { attributes: ['id', 'name', 'email', 'phoneNumber'] });
    const [profile] = await OnboardingProfile.findOrCreate({ where: { userId: req.user.sub }, defaults: { userId: req.user.sub } });
    return res.json({ success: true, message: 'Own profile retrieved.', data: { profile: ownProfileJson(req, user, profile) } });
  } catch (error) { return next(error); }
};

exports.updateOwnProfile = async (req, res, next) => {
  try {
    const { User, OnboardingProfile } = getModels();
    let canonical;
    await User.sequelize.transaction(async (transaction) => {
      const user = await User.findByPk(req.user.sub, { attributes: ['id', 'name', 'email', 'phoneNumber'], transaction, lock: transaction.LOCK.UPDATE });
      const [profile] = await OnboardingProfile.findOrCreate({ where: { userId: req.user.sub }, defaults: { userId: req.user.sub }, transaction });
      if (Object.prototype.hasOwnProperty.call(req.body, 'name')) await user.update({ name: req.body.name.trim() }, { transaction });
      const mapping = {
        birthdate: 'birthDate', gender: 'gender', bio: 'bio', profession: 'profession', company: 'company', education: 'education',
        location: 'city', interests: 'interests', prompts: 'prompts', lifestyle: 'lifestyle', hometown: 'hometown',
        valuedQualities: 'valuedQualities', pronouns: 'pronouns', sexuality: 'sexuality', preferredTalkingHours: 'preferredTalkingHours',
        loveLanguages: 'loveLanguages', iceBreaker: 'iceBreaker', communicationStyle: 'communicationStyle',
      };
      const values = {};
      for (const [requestField, modelField] of Object.entries(mapping)) {
        if (!Object.prototype.hasOwnProperty.call(req.body, requestField)) continue;
        values[modelField] = typeof req.body[requestField] === 'string' ? req.body[requestField].trim() : req.body[requestField];
      }
      if (Object.prototype.hasOwnProperty.call(req.body, 'datingIntention')) {
        values.relationshipGoals = req.body.datingIntention.trim() ? [req.body.datingIntention.trim()] : [];
      }
      if (Object.prototype.hasOwnProperty.call(req.body, 'photos')) {
        const stored = list(profile.photos);
        const normalized = req.body.photos.map((value) => {
          try { return new URL(value).pathname; } catch (_) { return value; }
        });
        const normalizedSet = new Set(normalized);
        if (normalized.length !== stored.length
          || normalizedSet.size !== normalized.length
          || stored.some((value) => !normalizedSet.has(value))) {
          const error = new Error('Profile photos must reference the current authenticated upload set.');
          error.status = 400;
          error.code = 'VALIDATION_ERROR';
          throw error;
        }
        values.photos = normalized;
      }
      if (Object.prototype.hasOwnProperty.call(req.body, 'primaryPhotoIndex')) {
        const photoCount = (values.photos || list(profile.photos)).length;
        if (!photoCount || req.body.primaryPhotoIndex >= photoCount) {
          const error = new Error('primaryPhotoIndex must reference an uploaded photo.');
          error.status = 400;
          error.code = 'VALIDATION_ERROR';
          throw error;
        }
        values.primaryPhotoIndex = req.body.primaryPhotoIndex;
      }
      await profile.update(values, { transaction });
      canonical = { user, profile };
    });
    return res.json({ success: true, message: 'Profile updated.', data: { profile: ownProfileJson(req, canonical.user, canonical.profile) } });
  } catch (error) { return next(error); }
};

exports.getPublicProfile = async (req, res, next) => {
  try {
    const viewerUserId = Number(req.user.sub);
    const targetUserId = Number(req.params.userId);
    const { User, OnboardingProfile, DiscoverAction, Match, Subscription, SavedProfile } = getModels();
    const target = await User.findOne({
      where: activeAccountWhere({ id: targetUserId }),
      include: [
        { model: OnboardingProfile, required: true, where: { onboardingCompleted: true } },
        { model: Subscription, as: 'subscription', required: false, attributes: ['status', 'currentPeriodEnd'] },
      ],
    });
    if (!target || await areUsersBlocked(viewerUserId, targetUserId)) return unavailable(res);

    const [action, match, viewer, saved] = await Promise.all([
      DiscoverAction.findOne({ where: { actorUserId: viewerUserId, targetUserId }, attributes: ['action'] }),
      Match.findOne({ where: matchPairWhere(viewerUserId, targetUserId), attributes: ['id'] }),
      OnboardingProfile.findOne({ where: { userId: viewerUserId } }),
      SavedProfile.findOne({ where: { userId: viewerUserId, savedUserId: targetUserId }, attributes: ['id'] }),
    ]);
    const relationship = {
      liked: ['like', 'superLike'].includes(action?.action),
      superLiked: action?.action === 'superLike',
      blocked: false,
      matched: Boolean(match),
      matchId: match ? String(match.id) : null,
      saved: Boolean(saved),
    };
    return res.json({
      success: true,
      message: 'Public profile retrieved.',
      data: { profile: serializePublicProfile(req, target, target.OnboardingProfile, { viewer, relationship }) },
    });
  } catch (error) {
    return next(error);
  }
};

exports._test = { ownProfileJson, communicationStyles: COMMUNICATION_STYLE_VALUES };
