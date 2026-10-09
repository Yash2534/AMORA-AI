const fs = require('fs');
const path = require('path');
const { getModels } = require('../models');
const { activeAccountWhere, areUsersBlocked } = require('../services/accessControlService');
const { filenameFromReference, uploadDirectory } = require('../utils/photoStorage');

const unavailable = (res) => res.status(404).json({
  success: false,
  message: 'Media is not available.',
  code: 'MEDIA_NOT_AVAILABLE',
  errors: [],
});

exports.profilePhoto = async (req, res, next) => {
  try {
    const viewerId = Number(req.user.sub);
    const ownerId = Number(req.params.userId);
    const filename = String(req.params.filename || '');
    if (!/^[a-zA-Z0-9._-]{1,180}$/.test(filename) || path.basename(filename) !== filename) return unavailable(res);

    const { User, OnboardingProfile } = getModels();
    const owner = await User.findOne({
      where: activeAccountWhere({ id: ownerId }),
      include: [{
        model: OnboardingProfile,
        required: true,
        ...(viewerId === ownerId ? {} : { where: { onboardingCompleted: true } }),
        attributes: ['photos'],
      }],
      attributes: ['id'],
    });
    if (!owner || (viewerId !== ownerId && await areUsersBlocked(viewerId, ownerId))) return unavailable(res);
    const allowed = new Set((owner.OnboardingProfile.photos || []).map(filenameFromReference).filter(Boolean));
    if (!allowed.has(filename)) return unavailable(res);

    const filePath = path.resolve(uploadDirectory, filename);
    if (path.dirname(filePath) !== path.resolve(uploadDirectory)) return unavailable(res);
    const stat = await fs.promises.stat(filePath).catch(() => null);
    if (!stat?.isFile()) return unavailable(res);
    res.set({
      'Cache-Control': 'private, no-store',
      'Content-Security-Policy': "default-src 'none'; sandbox",
      'X-Content-Type-Options': 'nosniff',
    });
    return res.sendFile(filename, { root: uploadDirectory, dotfiles: 'deny' });
  } catch (error) {
    return next(error);
  }
};
