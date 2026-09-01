const crypto = require('crypto');
const { Op, fn, col, where: sequelizeWhere } = require('sequelize');
const { getModels } = require('../models');
const { calculateProfileCompletion } = require('./profileCompletionService');
const { ageFor } = require('./publicProfileService');
const { recordAudit } = require('./adminAuditService');
const { COMMUNICATION_STYLE_VALUES } = require('../constants/communicationStyles');
const { MAX_PROFILE_PHOTOS, store, publicPath, remove } = require('../utils/photoStorage');

const list = (value) => (Array.isArray(value) ? value : []);
const taxonomyCategories = new Set(['education', 'occupations', 'religions', 'languages', 'interests']);
const normalizeTaxonomy = (value) => String(value || '').trim().replace(/\s+/g, ' ').toLocaleLowerCase('en-US');
const taxonomyId = (category, value) => `taxonomy_${category}_${crypto.createHash('sha256').update(`${category}\0${normalizeTaxonomy(value)}`).digest('hex').slice(0, 32)}`;
const can = (request, permission) => (request.adminPermissions || new Set()).has(permission);

function apiError(status, code, message) {
  const error = new Error(message);
  error.status = status;
  error.code = code;
  return error;
}

function mediaUrl(request, value) {
  if (!value) return null;
  if (/^https?:\/\//i.test(value)) return value;
  return `${request.protocol}://${request.get('host')}${value}`;
}

function photoId(profileId, value) {
  return crypto.createHmac('sha256', process.env.ADMIN_JWT_SECRET)
    .update(String(profileId)).update('\0').update(value).digest('base64url').slice(0, 32);
}

function photoRows(request, profile) {
  const photos = list(profile.photos);
  return photos.map((value, index) => ({
    id: photoId(profile.id, value),
    photoId: photoId(profile.id, value),
    url: mediaUrl(request, value),
    displayOrder: index,
    isPrimary: index === Number(profile.primaryPhotoIndex || 0),
    updatedAt: profile.updatedAt,
  }));
}

function verificationStatus(user) {
  return user.identityVerification?.status || (user.identityVerifiedAt ? 'verified' : 'not_submitted');
}

function optionValue(category, value) {
  if (value == null || String(value).trim() === '') return null;
  const label = String(value).trim();
  return { optionId: taxonomyId(category, label), label };
}

function optionList(category, value) {
  return list(value).map((item) => optionValue(category, item)).filter(Boolean);
}

async function taxonomy(_request, category) {
  if (!taxonomyCategories.has(category)) return null;
  const { ProfileTaxonomyCategory, ProfileTaxonomyOption } = getModels();
  const row = await ProfileTaxonomyCategory.findByPk(category, {
    include: [{
      model: ProfileTaxonomyOption,
      as: 'options',
      required: false,
    }],
    order: [[{ model: ProfileTaxonomyOption, as: 'options' }, 'sortOrder', 'ASC'], [{ model: ProfileTaxonomyOption, as: 'options' }, 'label', 'ASC']],
  });
  if (!row) return null;
  return {
    category: row.key,
    label: row.label,
    maximumSelections: row.maximumSelections,
    items: row.options.map((option) => ({
      id: option.id,
      label: option.label,
      isActive: option.isActive,
      allowsCustomValue: option.allowsCustomValue,
    })),
  };
}

async function resolveTaxonomyOption(category, raw, field, transaction) {
  if (raw == null) return null;
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field}.`);
  }
  const optionId = typeof raw.optionId === 'string' ? raw.optionId.trim() : '';
  if (!optionId) throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field}.`);
  const { ProfileTaxonomyOption } = getModels();
  const option = await ProfileTaxonomyOption.findOne({
    where: { id: optionId, categoryKey: category, isActive: true },
    transaction,
  });
  if (!option) throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field} option.`);
  const customValue = typeof raw.customValue === 'string' ? raw.customValue.trim().replace(/\s+/g, ' ') : '';
  if (!option.allowsCustomValue) {
    if (customValue) throw apiError(422, 'VALIDATION_ERROR', `${field} does not accept a custom value.`);
    return option.label;
  }
  if (!customValue || customValue.length > 255) {
    throw apiError(422, 'VALIDATION_ERROR', `A valid custom ${field} is required.`);
  }
  const id = taxonomyId(category, customValue);
  await ProfileTaxonomyOption.findOrCreate({
    where: { id },
    defaults: {
      id,
      categoryKey: category,
      label: customValue,
      normalizedLabel: normalizeTaxonomy(customValue),
      allowsCustomValue: false,
      isActive: true,
      sortOrder: 100000,
    },
    transaction,
  });
  return customValue;
}

async function resolveTaxonomyList(category, raw, field, transaction) {
  if (!Array.isArray(raw)) throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field}.`);
  const ids = raw.map((value) => (typeof value === 'string' ? value.trim() : ''));
  if (ids.some((value) => !value) || new Set(ids).size !== ids.length) {
    throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field}.`);
  }
  const { ProfileTaxonomyCategory, ProfileTaxonomyOption } = getModels();
  const taxonomyCategory = await ProfileTaxonomyCategory.findByPk(category, { transaction });
  if (!taxonomyCategory) throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field} category.`);
  if (taxonomyCategory.maximumSelections != null && ids.length > taxonomyCategory.maximumSelections) {
    throw apiError(422, 'VALIDATION_ERROR', `${field} accepts at most ${taxonomyCategory.maximumSelections} selections.`);
  }
  if (!ids.length) return [];
  const options = await ProfileTaxonomyOption.findAll({
    where: { id: { [Op.in]: ids }, categoryKey: category, isActive: true },
    transaction,
  });
  if (options.length !== ids.length) throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field} option.`);
  const labels = new Map(options.map((option) => [option.id, option.label]));
  return ids.map((id) => labels.get(id));
}

function summary(request, profile) {
  const user = profile.User;
  const photos = list(profile.photos);
  const primaryIndex = Math.min(Number(profile.primaryPhotoIndex || 0), Math.max(0, photos.length - 1));
  return {
    profileId: String(profile.id),
    userId: String(profile.userId),
    displayName: user.name,
    thumbnailUrl: mediaUrl(request, photos[primaryIndex] || photos[0]),
    city: profile.city,
    profileStatus: profile.onboardingCompleted ? 'complete' : 'incomplete',
    verificationStatus: verificationStatus(user),
    completionPercentage: calculateProfileCompletion(user, profile).percentage,
    photoCount: photos.length,
    languageCount: list(profile.languages).length,
    interestCount: list(profile.interests).length,
    updatedAt: profile.updatedAt,
    createdAt: profile.createdAt,
  };
}

function userInclude(request, options = {}) {
  const { User, IdentityVerification } = getModels();
  return {
    model: User,
    required: true,
    where: options.userWhere,
    include: [{
      model: IdentityVerification,
      as: 'identityVerification',
      required: Boolean(options.verificationStatus && options.verificationStatus !== 'not_submitted'),
      ...(options.verificationStatus && options.verificationStatus !== 'not_submitted'
        ? { where: { status: options.verificationStatus } } : {}),
    }],
  };
}

async function profiles(request, page) {
  const { OnboardingProfile, User } = getModels();
  const profileWhere = {};
  const userWhere = {};
  if (request.query.search) userWhere.name = { [Op.like]: `%${String(request.query.search).trim()}%` };
  if (request.query.profileStatus) {
    profileWhere.onboardingCompleted = request.query.profileStatus === 'complete';
  }
  if (request.query.verificationStatus === 'not_submitted') {
    profileWhere['$User.identityVerification.id$'] = null;
  }
  if (request.query.hasPhotos != null) {
    const comparison = request.query.hasPhotos === 'true' ? Op.gt : Op.eq;
    profileWhere[Op.and] = [sequelizeWhere(fn('JSON_LENGTH', col('OnboardingProfile.photos')), { [comparison]: 0 })];
  }
  if (request.query.updatedFrom || request.query.updatedTo) {
    profileWhere.updatedAt = {};
    if (request.query.updatedFrom) profileWhere.updatedAt[Op.gte] = new Date(request.query.updatedFrom);
    if (request.query.updatedTo) profileWhere.updatedAt[Op.lte] = new Date(request.query.updatedTo);
  }
  if (request.query.registeredFrom || request.query.registeredTo) {
    userWhere.createdAt = {};
    if (request.query.registeredFrom) userWhere.createdAt[Op.gte] = new Date(request.query.registeredFrom);
    if (request.query.registeredTo) userWhere.createdAt[Op.lte] = new Date(request.query.registeredTo);
  }
  const direction = String(request.query.sortDirection || 'desc').toUpperCase();
  const sortBy = request.query.sortBy || 'updatedAt';
  const order = sortBy === 'displayName'
    ? [[User, 'name', direction], ['id', 'DESC']]
    : [[sortBy, direction], ['id', 'DESC']];
  const result = await OnboardingProfile.findAndCountAll({
    where: profileWhere,
    include: [userInclude(request, {
      userWhere,
      verificationStatus: request.query.verificationStatus,
    })],
    distinct: true,
    limit: page.pageSize,
    offset: page.offset,
    order,
  });
  return {
    items: result.rows.map((profile) => summary(request, profile)),
    pagination: {
      page: page.page,
      pageSize: page.pageSize,
      totalItems: result.count,
      totalPages: Math.ceil(result.count / page.pageSize),
    },
  };
}

async function findProfile(request, profileId, options = {}) {
  const { OnboardingProfile } = getModels();
  return OnboardingProfile.findByPk(profileId, {
    ...options,
    include: [userInclude(request)],
  });
}

function details(request, profile) {
  const completion = calculateProfileCompletion(profile.User, profile);
  return {
    summary: summary(request, profile),
    profileId: String(profile.id),
    about: profile.bio,
    age: ageFor(profile.birthDate),
    locationSummary: profile.city,
    photos: photoRows(request, profile),
    lifestyle: profile.lifestyle || {},
    languages: optionList('languages', profile.languages),
    ...(can(request, 'profiles.sensitiveFields.view') ? { religion: optionValue('religions', profile.religion) } : {}),
    interests: optionList('interests', profile.interests),
    education: optionValue('education', profile.education),
    occupation: optionValue('occupations', profile.profession),
    communicationStyle: profile.communicationStyle,
    iceBreaker: profile.iceBreaker,
    ...(can(request, 'profiles.verification.view') && profile.User.identityVerification ? {
      verification: {
        status: profile.User.identityVerification.status,
        verificationId: String(profile.User.identityVerification.id),
        type: 'identity',
        submittedAt: profile.User.identityVerification.submittedAt,
        reviewedAt: profile.User.identityVerification.reviewedAt,
        reasonSummary: profile.User.identityVerification.status === 'rejected'
          ? profile.User.identityVerification.rejectionReason : null,
      },
    } : {}),
    completion: { percentage: completion.percentage },
    capabilities: {
      canEdit: can(request, 'profiles.edit'),
      canUploadPhotos: can(request, 'profiles.photos.manage'),
      canRemovePhotos: can(request, 'profiles.photos.manage'),
      canReorderPhotos: can(request, 'profiles.photos.manage'),
      canSetPrimaryPhoto: can(request, 'profiles.photos.manage'),
    },
    version: profile.updatedAt.toISOString(),
  };
}

function scalar(value, field, maximum) {
  if (value == null) return null;
  if (typeof value !== 'string' || value.length > maximum) {
    throw apiError(422, 'VALIDATION_ERROR', `Invalid ${field}.`);
  }
  return value.trim();
}

async function update(request, profileId, values, expectedVersion) {
  const { OnboardingProfile } = getModels();
  const allowed = new Set(['about', 'city', 'lifestyle', 'languageIds', 'religion', 'interestIds', 'education', 'occupation', 'communicationStyle', 'iceBreaker']);
  const unknown = Object.keys(values).filter((key) => !allowed.has(key));
  if (unknown.length) throw apiError(422, 'VALIDATION_ERROR', `Unsupported profile fields: ${unknown.join(', ')}.`);
  if (Object.hasOwn(values, 'religion') && !can(request, 'profiles.sensitiveFields.view')) {
    throw apiError(403, 'PERMISSION_DENIED', 'Religion updates require sensitive profile permission.');
  }
  const result = await OnboardingProfile.sequelize.transaction(async (transaction) => {
    const profile = await OnboardingProfile.findByPk(profileId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!profile) return null;
    if (expectedVersion && expectedVersion.replaceAll('"', '') !== profile.updatedAt.toISOString()) {
      throw apiError(409, 'STALE_VERSION', 'The profile has changed. Refresh before saving.');
    }
    const patch = {};
    if (Object.hasOwn(values, 'about')) patch.bio = scalar(values.about, 'about', 5000);
    if (Object.hasOwn(values, 'city')) patch.city = scalar(values.city, 'city', 160);
    if (Object.hasOwn(values, 'education')) patch.education = await resolveTaxonomyOption('education', values.education, 'education', transaction);
    if (Object.hasOwn(values, 'occupation')) patch.profession = await resolveTaxonomyOption('occupations', values.occupation, 'occupation', transaction);
    if (Object.hasOwn(values, 'religion')) patch.religion = await resolveTaxonomyOption('religions', values.religion, 'religion', transaction);
    if (Object.hasOwn(values, 'iceBreaker')) patch.iceBreaker = scalar(values.iceBreaker, 'iceBreaker', 280);
    if (Object.hasOwn(values, 'communicationStyle')) {
      const communicationStyle = scalar(values.communicationStyle, 'communicationStyle', 80);
      if (communicationStyle && !COMMUNICATION_STYLE_VALUES.includes(communicationStyle)) {
        throw apiError(422, 'VALIDATION_ERROR', 'Invalid communicationStyle.');
      }
      patch.communicationStyle = communicationStyle || null;
    }
    if (Object.hasOwn(values, 'languageIds')) patch.languages = await resolveTaxonomyList('languages', values.languageIds, 'languages', transaction);
    if (Object.hasOwn(values, 'interestIds')) patch.interests = await resolveTaxonomyList('interests', values.interestIds, 'interests', transaction);
    if (Object.hasOwn(values, 'lifestyle')) {
      if (!values.lifestyle || typeof values.lifestyle !== 'object' || Array.isArray(values.lifestyle)) {
        throw apiError(422, 'VALIDATION_ERROR', 'Invalid lifestyle.');
      }
      patch.lifestyle = values.lifestyle;
    }
    const oldValue = Object.fromEntries(Object.keys(patch).map((key) => [key, profile[key]]));
    await profile.update(patch, { transaction });
    await recordAudit({
      request,
      administratorId: request.admin.id,
      action: 'admin.profiles.update',
      targetType: 'profile',
      targetId: profile.id,
      oldValue,
      newValue: patch,
      transaction,
    });
    return profile.id;
  });
  return result ? findProfile(request, result) : null;
}

function resolvePhoto(profile, id) {
  const photos = list(profile.photos);
  const index = photos.findIndex((value) => photoId(profile.id, value) === id);
  if (index < 0) throw apiError(404, 'NOT_FOUND', 'Profile photo not found.');
  return { photos, index, value: photos[index] };
}

async function uploadPhoto(request, profileId, file) {
  const { OnboardingProfile } = getModels();
  const existing = await OnboardingProfile.findByPk(profileId);
  if (!existing) return null;
  if (list(existing.photos).length >= MAX_PROFILE_PHOTOS) throw apiError(409, 'PHOTO_LIMIT_REACHED', `A maximum of ${MAX_PROFILE_PHOTOS} photos is allowed.`);
  const filename = await store(existing.userId, file);
  const value = publicPath(filename);
  try {
    await OnboardingProfile.sequelize.transaction(async (transaction) => {
      const profile = await OnboardingProfile.findByPk(profileId, { transaction, lock: transaction.LOCK.UPDATE });
      if (!profile) throw apiError(404, 'NOT_FOUND', 'Profile not found.');
      const photos = list(profile.photos);
      if (photos.length >= MAX_PROFILE_PHOTOS) throw apiError(409, 'PHOTO_LIMIT_REACHED', `A maximum of ${MAX_PROFILE_PHOTOS} photos is allowed.`);
      await profile.update({ photos: [...photos, value] }, { transaction });
      await recordAudit({ request, administratorId: request.admin.id, action: 'admin.profiles.photo_uploaded', targetType: 'profile', targetId: profile.id, metadata: { photoId: photoId(profile.id, value) }, transaction });
    });
  } catch (error) {
    remove(value);
    throw error;
  }
  return findProfile(request, profileId);
}

async function removePhoto(request, profileId, id) {
  const { OnboardingProfile } = getModels();
  const removed = await OnboardingProfile.sequelize.transaction(async (transaction) => {
    const profile = await OnboardingProfile.findByPk(profileId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!profile) return null;
    const resolved = resolvePhoto(profile, id);
    resolved.photos.splice(resolved.index, 1);
    let primaryPhotoIndex = Number(profile.primaryPhotoIndex || 0);
    if (!resolved.photos.length || primaryPhotoIndex === resolved.index) primaryPhotoIndex = 0;
    else if (primaryPhotoIndex > resolved.index) primaryPhotoIndex -= 1;
    await profile.update({ photos: resolved.photos, primaryPhotoIndex }, { transaction });
    await recordAudit({ request, administratorId: request.admin.id, action: 'admin.profiles.photo_removed', targetType: 'profile', targetId: profile.id, metadata: { photoId: id }, transaction });
    return resolved.value;
  });
  if (removed === null) return null;
  remove(removed);
  return findProfile(request, profileId);
}

async function reorderPhotos(request, profileId, ids) {
  const { OnboardingProfile } = getModels();
  const result = await OnboardingProfile.sequelize.transaction(async (transaction) => {
    const profile = await OnboardingProfile.findByPk(profileId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!profile) return null;
    const current = list(profile.photos);
    if (!Array.isArray(ids) || ids.length !== current.length || new Set(ids).size !== ids.length) {
      throw apiError(422, 'VALIDATION_ERROR', 'photoIds must contain every current photo exactly once.');
    }
    const byId = new Map(current.map((value) => [photoId(profile.id, value), value]));
    if (ids.some((id) => !byId.has(id))) throw apiError(409, 'STALE_VERSION', 'The profile photo collection has changed.');
    const primaryValue = current[Number(profile.primaryPhotoIndex || 0)];
    const photos = ids.map((id) => byId.get(id));
    await profile.update({ photos, primaryPhotoIndex: Math.max(0, photos.indexOf(primaryValue)) }, { transaction });
    await recordAudit({ request, administratorId: request.admin.id, action: 'admin.profiles.photos_reordered', targetType: 'profile', targetId: profile.id, metadata: { photoIds: ids }, transaction });
    return profile.id;
  });
  return result ? findProfile(request, result) : null;
}

async function setPrimaryPhoto(request, profileId, id) {
  const { OnboardingProfile } = getModels();
  const result = await OnboardingProfile.sequelize.transaction(async (transaction) => {
    const profile = await OnboardingProfile.findByPk(profileId, { transaction, lock: transaction.LOCK.UPDATE });
    if (!profile) return null;
    const resolved = resolvePhoto(profile, id);
    await profile.update({ primaryPhotoIndex: resolved.index }, { transaction });
    await recordAudit({ request, administratorId: request.admin.id, action: 'admin.profiles.primary_photo_changed', targetType: 'profile', targetId: profile.id, metadata: { photoId: id }, transaction });
    return profile.id;
  });
  return result ? findProfile(request, result) : null;
}

module.exports = {
  profiles,
  findProfile,
  details,
  photoRows,
  taxonomy,
  update,
  uploadPhoto,
  removePhoto,
  reorderPhotos,
  setPrimaryPhoto,
};
