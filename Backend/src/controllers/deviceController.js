const { getModels } = require('../models');

exports.register = async (req, res, next) => {
  try {
    const { UserDevice } = getModels();
    const [device, created] = await UserDevice.findOrCreate({
      where: { pushToken: req.body.pushToken },
      defaults: {
        userId: req.user.sub,
        pushToken: req.body.pushToken,
        platform: req.body.platform,
        installationId: req.body.installationId || null,
        active: true,
        lastSeenAt: new Date(),
      },
    });
    if (!created) await device.update({ userId: req.user.sub, platform: req.body.platform, installationId: req.body.installationId || device.installationId, active: true, invalidatedAt: null, lastSeenAt: new Date() });
    return res.status(created ? 201 : 200).json({ success: true, message: created ? 'Device registered.' : 'Device registration refreshed.', data: { device: { id: String(device.id), platform: device.platform, active: device.active } } });
  } catch (error) { return next(error); }
};

exports.remove = async (req, res, next) => {
  try {
    const { UserDevice } = getModels();
    const device = await UserDevice.findOne({ where: { userId: req.user.sub, pushToken: req.body.pushToken } });
    if (device) await device.update({ active: false, invalidatedAt: new Date() });
    return res.json({ success: true, message: 'Device unregistered.', data: { removed: Boolean(device) } });
  } catch (error) { return next(error); }
};
