const REPORT_REASONS = [
  'fake_profile',
  'harassment',
  'inappropriate_photo',
  'scam',
  'spam',
  'other',
];
const REPORT_STATUSES = ['open', 'reviewing', 'resolved', 'dismissed'];
const REPORT_TARGET_TYPES = ['profile', 'event', 'message'];

module.exports = { REPORT_REASONS, REPORT_STATUSES, REPORT_TARGET_TYPES };
