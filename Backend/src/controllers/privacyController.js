const { getModels } = require('../models');

// DPDP Notice Details as per Digital Personal Data Protection Act, 2023 & Rules 2025
const PRIVACY_NOTICE = {
  dataFiduciary: {
    name: 'Amoraa Technologies Pvt. Ltd.',
    address: 'Mumbai, Maharashtra, India',
    email: 'privacy@amoraa.app',
    dpoEmail: 'dpo@amoraa.app',
    grievanceOfficer: 'Data Protection Officer, Amoraa'
  },
  noticeVersion: '2025.1-DPDP',
  lastUpdated: '2025-01-01T00:00:00.000Z',
  purposes: [
    {
      code: 'TERMS_AND_PRIVACY',
      title: 'Core Platform Account & Authentication',
      description: 'Necessary for account creation, identity verification, and core service delivery under DPDP Act.',
      isMandatory: true
    },
    {
      code: 'PROFILE_MATCHING',
      title: 'Algorithmic Matchmaking & Recommendations',
      description: 'Used to process user preferences, location, and lifestyle choices for matchmaking.',
      isMandatory: false
    },
    {
      code: 'LOCATION_DISCOVERY',
      title: 'Location-Based Nearby Discovery',
      description: 'Used to suggest profiles nearby based on your current device location.',
      isMandatory: false
    },
    {
      code: 'MARKETING_PROMOTIONS',
      title: 'Promotional Offers & Event Notifications',
      description: 'Used to notify you about subscription discounts, premium features, and local events.',
      isMandatory: false
    },
    {
      code: 'ANALYTICS_METRICS',
      title: 'App Diagnostics & Quality Improvement',
      description: 'Aggregated diagnostic and usage analytics to improve app stability and security.',
      isMandatory: false
    }
  ],
  rights: [
    'Right to itemized notice and explicit consent',
    'Right to 1-click withdrawal of consent at any time',
    'Right to access your personal data and summary in machine-readable format',
    'Right to correction, completion, and updating of personal data',
    'Right to erasure / account deletion with full cascade purge',
    'Right to grievance redressal through Data Protection Officer (DPO)',
    'Right to nominate an individual in event of death or incapacity'
  ]
};

// GET /api/v1/privacy/notice
exports.getPrivacyNotice = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      data: PRIVACY_NOTICE
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/privacy/consents
exports.getConsents = async (req, res, next) => {
  try {
    const { UserConsent } = getModels();
    const userId = req.user.id;

    const consents = await UserConsent.findAll({
      where: { userId },
      order: [['updatedAt', 'DESC']]
    });

    return res.status(200).json({
      success: true,
      data: consents
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/privacy/consents/update
exports.updateConsent = async (req, res, next) => {
  try {
    const { UserConsent } = getModels();
    const userId = req.user.id;
    const { purposeCode, granted } = req.body;

    if (!purposeCode) {
      return res.status(400).json({ success: false, message: 'purposeCode is required.' });
    }

    const validPurposes = PRIVACY_NOTICE.purposes.map(p => p.code);
    if (!validPurposes.includes(purposeCode)) {
      return res.status(400).json({ success: false, message: `Invalid purposeCode: ${purposeCode}` });
    }

    let consent = await UserConsent.findOne({ where: { userId, purposeCode } });
    const status = granted ? 'granted' : 'withdrawn';
    const now = new Date();

    if (consent) {
      consent.status = status;
      if (granted) {
        consent.grantedAt = now;
      } else {
        consent.withdrawnAt = now;
      }
      consent.ipAddress = req.ip || req.headers['x-forwarded-for'] || null;
      consent.userAgent = req.headers['user-agent'] || null;
      await consent.save();
    } else {
      consent = await UserConsent.create({
        userId,
        purposeCode,
        consentVersion: PRIVACY_NOTICE.noticeVersion,
        status,
        grantedAt: granted ? now : null,
        withdrawnAt: granted ? null : now,
        ipAddress: req.ip || req.headers['x-forwarded-for'] || null,
        userAgent: req.headers['user-agent'] || null
      });
    }

    return res.status(200).json({
      success: true,
      message: `Consent for ${purposeCode} updated to ${status}.`,
      data: consent
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/privacy/consents/withdraw (1-Click Withdrawal)
exports.withdrawConsent = async (req, res, next) => {
  try {
    const { UserConsent } = getModels();
    const userId = req.user.id;
    const { purposeCode } = req.body;

    if (!purposeCode) {
      return res.status(400).json({ success: false, message: 'purposeCode is required for withdrawal.' });
    }

    const [consent] = await UserConsent.findOrCreate({
      where: { userId, purposeCode },
      defaults: {
        userId,
        purposeCode,
        consentVersion: PRIVACY_NOTICE.noticeVersion,
        status: 'withdrawn',
        withdrawnAt: new Date(),
        ipAddress: req.ip || req.headers['x-forwarded-for'] || null,
        userAgent: req.headers['user-agent'] || null
      }
    });

    consent.status = 'withdrawn';
    consent.withdrawnAt = new Date();
    consent.ipAddress = req.ip || req.headers['x-forwarded-for'] || null;
    consent.userAgent = req.headers['user-agent'] || null;
    await consent.save();

    return res.status(200).json({
      success: true,
      message: `Consent for ${purposeCode} has been withdrawn successfully as per DPDP Act Section 6(4).`,
      data: consent
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/privacy/data-export (Right to Access - Section 11)
exports.requestDataExport = async (req, res, next) => {
  try {
    const { User, OnboardingProfile, IdentityVerification, Subscription, Payment, UserConsent, DataAccessRequest } = getModels();
    const userId = req.user.id;

    // Fetch complete user profile data
    const user = await User.findByPk(userId, {
      attributes: { exclude: ['passwordHash', 'tokenVersion'] }
    });
    const profile = await OnboardingProfile.findOne({ where: { userId } });
    const verification = await IdentityVerification.findOne({
      where: { userId },
      attributes: ['status', 'requestedAt', 'decidedAt']
    });
    const consents = await UserConsent.findAll({ where: { userId } });
    const subscription = await Subscription.findOne({ where: { userId } });
    const payments = await Payment.findAll({ where: { userId }, attributes: ['id', 'amount', 'currency', 'status', 'createdAt'] });

    const exportBundle = {
      exportMetadata: {
        formatVersion: '1.0-DPDP',
        exportedAt: new Date().toISOString(),
        dataFiduciary: 'Amoraa Technologies Pvt. Ltd.'
      },
      account: user ? user.toJSON() : null,
      onboardingProfile: profile ? profile.toJSON() : null,
      identityVerification: verification ? verification.toJSON() : null,
      consents: consents.map(c => c.toJSON()),
      subscription: subscription ? subscription.toJSON() : null,
      paymentHistory: payments.map(p => p.toJSON())
    };

    const requestNumber = `DPDP-EXP-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const dataAccessReq = await DataAccessRequest.create({
      requestNumber,
      userId,
      status: 'completed',
      exportData: JSON.stringify(exportBundle),
      requestedAt: new Date(),
      completedAt: new Date()
    });

    return res.status(200).json({
      success: true,
      message: 'Machine-readable personal data export compiled successfully under DPDP Act Section 11.',
      data: {
        requestNumber: dataAccessReq.requestNumber,
        requestedAt: dataAccessReq.requestedAt,
        exportBundle
      }
    });
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/privacy/grievances (Right to Grievance Redressal - Section 13)
exports.submitGrievance = async (req, res, next) => {
  try {
    const { PrivacyGrievance } = getModels();
    const userId = req.user ? req.user.id : null;
    const { name, email, phoneNumber, category, subject, description } = req.body;

    if (!name || !email || !category || !subject || !description) {
      return res.status(400).json({
        success: false,
        message: 'name, email, category, subject, and description are required.'
      });
    }

    const ticketNumber = `DPDP-GRV-${new Date().toISOString().slice(0,10).replace(/-/g,'')}-${Math.floor(1000 + Math.random() * 9000)}`;

    const grievance = await PrivacyGrievance.create({
      ticketNumber,
      userId,
      name,
      email,
      phoneNumber: phoneNumber || null,
      category,
      subject,
      description,
      status: 'open'
    });

    return res.status(201).json({
      success: true,
      message: 'Grievance ticket created successfully. DPO will respond within mandatory timeframe.',
      data: {
        ticketNumber: grievance.ticketNumber,
        category: grievance.category,
        subject: grievance.subject,
        status: grievance.status,
        createdAt: grievance.createdAt
      }
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/privacy/grievances/:ticketNumber
exports.getGrievanceStatus = async (req, res, next) => {
  try {
    const { PrivacyGrievance } = getModels();
    const { ticketNumber } = req.params;

    const grievance = await PrivacyGrievance.findOne({
      where: { ticketNumber },
      attributes: ['ticketNumber', 'category', 'subject', 'status', 'resolutionNotes', 'createdAt', 'resolvedAt']
    });

    if (!grievance) {
      return res.status(404).json({ success: false, message: 'Grievance ticket not found.' });
    }

    return res.status(200).json({
      success: true,
      data: grievance
    });
  } catch (err) {
    next(err);
  }
};

// ---------------------------------------------------------------------------
// ADMIN / DPO CONTROLLERS (For Admin Web DPDP Management)
// ---------------------------------------------------------------------------

// GET /api/v1/admin/privacy/grievances
exports.adminGetGrievances = async (req, res, next) => {
  try {
    const { PrivacyGrievance, Administrator } = getModels();
    const { status, category, search } = req.query;

    const where = {};
    if (status) where.status = status;
    if (category) where.category = category;

    const grievances = await PrivacyGrievance.findAll({
      where,
      include: [
        { model: Administrator, as: 'assignedAdministrator', attributes: ['id', 'email', 'name'] }
      ],
      order: [['createdAt', 'DESC']]
    });

    return res.status(200).json({
      success: true,
      data: grievances
    });
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/admin/privacy/grievances/:id
exports.adminUpdateGrievance = async (req, res, next) => {
  try {
    const { PrivacyGrievance } = getModels();
    const { id } = req.params;
    const { status, resolutionNotes, assignedAdministratorId } = req.body;

    const grievance = await PrivacyGrievance.findByPk(id);
    if (!grievance) {
      return res.status(404).json({ success: false, message: 'Grievance ticket not found.' });
    }

    if (status) grievance.status = status;
    if (resolutionNotes !== undefined) grievance.resolutionNotes = resolutionNotes;
    if (assignedAdministratorId !== undefined) grievance.assignedAdministratorId = assignedAdministratorId;

    if (status === 'resolved' || status === 'rejected') {
      grievance.resolvedAt = new Date();
    }

    await grievance.save();

    return res.status(200).json({
      success: true,
      message: 'Grievance ticket updated successfully.',
      data: grievance
    });
  } catch (err) {
    next(err);
  }
};
