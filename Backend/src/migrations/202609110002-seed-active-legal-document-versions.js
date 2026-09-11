const crypto = require('crypto');

// This is the approved copy already presented by the AMORAA Flutter legal
// screens on 31 July 2026. It is stored with the version so a later UI
// change cannot alter what a member accepted.
const terms = `Eligibility and account responsibility\nYou must be at least 18 years old and legally able to enter an agreement. Keep your account details accurate, protect your sign-in credentials, and tell us promptly if you believe your account has been misused.\n\nRespectful and authentic participation\nUse current, authentic information and photos. Harassment, impersonation, hate, coercion, scams, unsolicited commercial activity, and content that exploits or endangers another person are not permitted.\n\nMatches and recommendations\nCompatibility scores and AI-assisted recommendations are guidance based on available profile signals. They do not guarantee attraction, compatibility, identity, conduct, or relationship outcomes.\n\nSubscriptions and purchases\nPaid features, prices, billing periods, renewal terms, and cancellation options are shown before purchase. Store-provider and applicable refund rules continue to apply.\n\nSafety and enforcement\nYou remain responsible for decisions about meeting and communicating. AMORAA may review reports and restrict or remove access when necessary to protect members, comply with law, or enforce these terms.\n\nService availability and changes\nFeatures may evolve, be interrupted, or become unavailable. We aim to provide a reliable experience but cannot promise uninterrupted access or that every error will be corrected immediately.\n\nEnding your account\nYou may stop using the service or request account deletion through the available account controls. Certain records may be retained where required for safety, fraud prevention, dispute resolution, or law.`;

const privacy = `Information you provide\nThis can include account details, profile answers, photos, preferences, verification submissions, support requests, and content you choose to share in conversations or events.\n\nInformation created through use\nWe may process app interactions, device and diagnostic information, approximate location where enabled, safety reports, purchase status, and recommendation signals needed to operate the experience.\n\nHow information is used\nInformation is used to provide profiles and messaging, personalize recommendations, support verification and safety, prevent abuse, deliver requested communications, maintain the app, and meet legal obligations.\n\nSharing and visibility\nProfile information is visible according to your settings. Information may also be processed by vetted service providers or disclosed when required for safety, legal compliance, or a corporate transaction.\n\nYour choices\nYou can edit profile information, manage notification and visibility preferences, block profiles, and use available controls to request access, correction, export, or deletion of personal information.\n\nSecurity and retention\nWe use administrative and technical safeguards appropriate to the information handled. Data is retained only as long as needed for the purposes described, including safety, fraud, billing, and legal needs.\n\nUpdates and contact\nMaterial policy changes will be communicated through an appropriate in-app or account channel. Contact support@amora.ai with privacy questions or requests.`;

const hash = (value) =>
  crypto
    .createHash('sha256')
    .update(value)
    .digest('hex');

const baseline = [
  ['TERMS_OF_SERVICE', '2026-07-31', terms],
  ['PRIVACY_POLICY', '2026-07-31', privacy],
];

module.exports = {
  async up(queryInterface, Sequelize) {
    const table = 'LegalDocumentVersions';

    const description =
      await queryInterface.describeTable(table);

    /*
     * MySQL does not allow:
     *
     * LONGTEXT NOT NULL DEFAULT ''
     *
     * Add the column as nullable first. This also makes the migration safe if
     * LegalDocumentVersions already contains historical rows.
     */
    if (!description.content) {
      await queryInterface.addColumn(
        table,
        'content',
        {
          type: Sequelize.TEXT('long'),
          allowNull: true,
        },
      );
    }

    const now = new Date();

    for (const [
      documentKey,
      version,
      content,
    ] of baseline) {
      /*
       * If the baseline version already exists from an earlier deployment,
       * populate its content rather than creating a duplicate.
       *
       * Only the exact known version is backfilled. We do not invent content
       * for unknown historical legal-document versions.
       */
      await queryInterface.bulkUpdate(
        table,
        {
          content,
          contentHash: hash(content),
          updatedAt: now,
        },
        {
          documentKey,
          version,
          content: null,
        },
      );

      /*
       * Check whether there is already a currently active legal document for
       * this document type.
       */
      const [existing] =
        await queryInterface.sequelize.query(
          `SELECT
             \`id\`,
             \`version\`,
             \`content\`
           FROM \`LegalDocumentVersions\`
           WHERE \`documentKey\` = ?
             AND \`status\` = 'ACTIVE'
             AND \`effectiveAt\` <= ?
             AND (
               \`retiredAt\` IS NULL
               OR \`retiredAt\` > ?
             )
           LIMIT 1`,
          {
            replacements: [
              documentKey,
              now,
              now,
            ],
          },
        );

      /*
       * Seed the approved baseline only when no currently active document
       * exists.
       */
      if (!existing.length) {
        await queryInterface.bulkInsert(
          table,
          [
            {
              documentKey,
              version,
              contentHash: hash(content),
              content,
              publishedAt: now,
              effectiveAt: now,
              retiredAt: null,
              status: 'ACTIVE',
              createdAt: now,
              updatedAt: now,
            },
          ],
        );
      }
    }

    /*
     * Enforce NOT NULL only when every existing legal version has content.
     *
     * If historical rows exist without recoverable content, do not invent
     * legal text for them. The active baseline documents above still have
     * valid content.
     */
    const [nullRows] =
      await queryInterface.sequelize.query(
        `SELECT COUNT(*) AS \`count\`
         FROM \`LegalDocumentVersions\`
         WHERE \`content\` IS NULL`,
      );

    const remainingNullContent =
      Number(nullRows[0]?.count || 0);

    if (remainingNullContent === 0) {
      await queryInterface.changeColumn(
        table,
        'content',
        {
          type: Sequelize.TEXT('long'),
          allowNull: false,
        },
      );
    } else {
      console.warn(
        `[Migration] LegalDocumentVersions contains ${remainingNullContent} historical row(s) without recoverable content. The content column remains nullable to preserve existing evidence.`,
      );
    }
  },

  async down() {
    /*
     * Intentionally do not remove the content column.
     *
     * Legal-document content may represent evidence of the exact terms or
     * privacy notice a member accepted. A migration rollback must not destroy
     * that evidence.
     */
  },
};