const { getModels } = require('../models');

const fields = [
  'newMatches', 'messages', 'eventReminders', 'paymentsAndMembership', 'offers',
  'pushEnabled', 'emailEnabled', 'smsEnabled', 'quietHoursEnabled', 'quietStart', 'quietEnd',
];

function payload(row) {
  const value = row.toJSON();
  return Object.fromEntries([...fields, 'safetyUpdates'].map((field) => [field, value[field]]));
}

async function own(userId) {
  const { NotificationPreference } = getModels();
  const [row] = await NotificationPreference.findOrCreate({ where: { userId }, defaults: { userId } });
  return row;
}

exports.get = async (req, res, next) => {
  try {
    return res.json({ success: true, message: 'Notification preferences retrieved.', data: { preferences: payload(await own(req.user.sub)) } });
  } catch (error) { return next(error); }
};

exports.update = async (req, res, next) => {
  try {
    const row = await own(req.user.sub);
    const values = {};
    for (const field of fields) if (Object.prototype.hasOwnProperty.call(req.body, field)) values[field] = req.body[field];
    values.safetyUpdates = true;
    await row.update(values);
    return res.json({ success: true, message: 'Notification preferences updated.', data: { preferences: payload(row) } });
  } catch (error) { return next(error); }
};
