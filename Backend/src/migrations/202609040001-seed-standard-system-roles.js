module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const now = new Date();
      const systemRoles = [
        {
          key: 'operations_admin',
          name: 'Operations Admin',
          description: 'System role for managing user accounts, profiles, events, and platform operations.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => m === 'users' || m === 'events' || m === 'profiles' || k.startsWith('dashboard.') || k.startsWith('analytics.users.'),
        },
        {
          key: 'finance_admin',
          name: 'Finance Admin',
          description: 'System role for managing revenue, payouts, membership plans, refunds, and financial metrics.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => m === 'financial' || m === 'memberships' || k.startsWith('analytics.revenue.') || k.startsWith('revenue.'),
        },
        {
          key: 'support_admin',
          name: 'Support Agent',
          description: 'System role for handling customer tickets, user support, account recovery, and notes.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => m === 'users' || m === 'support' || k.includes('notes') || k.includes('loginHistory') || k.includes('sessions'),
        },
        {
          key: 'verification_officer',
          name: 'Verification Officer',
          description: 'System role for inspecting identity documents, Aadhaar/Selfie comparisons, and KYC approvals.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => m === 'verifications' || k.startsWith('verification') || k.startsWith('profile.verification'),
        },
        {
          key: 'content_admin',
          name: 'Trust & Safety Admin',
          description: 'System role for chat moderation, report cases, user safety reviews, and content enforcement.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => m === 'safety' || m === 'chat' || m === 'reports' || k.includes('moderate') || k.includes('suspend'),
        },
        {
          key: 'analyst',
          name: 'Analyst',
          description: 'System role with read-only access to analytics, metrics, conversion funnels, and reporting.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => k.startsWith('analytics.') || k.endsWith('.view') || k.endsWith('.read'),
        },
        {
          key: 'technical_admin',
          name: 'Technical Admin',
          description: 'System role for managing system settings, technical configuration, and audit logs.',
          isSystem: true,
          isActive: true,
          moduleFilter: (m, k) => m === 'systemSettings' || m === 'audit' || k.startsWith('systemSettings.'),
        },
      ];

      // Fetch existing permissions
      const [permissions] = await queryInterface.sequelize.query(
        'SELECT `id`, `key`, `module` FROM `AdminPermissions`',
        { transaction },
      );

      for (const roleDef of systemRoles) {
        // Insert or ignore into AdminRoles
        const [existingRoles] = await queryInterface.sequelize.query(
          'SELECT `id` FROM `AdminRoles` WHERE `key` = ?',
          { replacements: [roleDef.key], transaction },
        );

        let roleId;
        if (existingRoles.length > 0) {
          roleId = existingRoles[0].id;
        } else {
          await queryInterface.bulkInsert('AdminRoles', [{
            key: roleDef.key,
            name: roleDef.name,
            description: roleDef.description,
            isSystem: roleDef.isSystem,
            isActive: roleDef.isActive,
            version: 1,
            createdAt: now,
            updatedAt: now,
          }], { transaction });

          const [newRole] = await queryInterface.sequelize.query(
            'SELECT `id` FROM `AdminRoles` WHERE `key` = ?',
            { replacements: [roleDef.key], transaction },
          );
          roleId = newRole[0].id;
        }

        // Filter permissions matching role filter
        const matchedPermissions = permissions.filter((p) => roleDef.moduleFilter(p.module, p.key));
        if (matchedPermissions.length > 0) {
          for (const perm of matchedPermissions) {
            await queryInterface.sequelize.query(
              'INSERT IGNORE INTO `AdminRolePermissions` (`roleId`, `permissionId`, `createdAt`, `updatedAt`) VALUES (?, ?, ?, ?)',
              { replacements: [roleId, perm.id, now, now], transaction },
            );
          }
        }
      }

      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    const keys = ['operations_admin', 'finance_admin', 'support_admin', 'verification_officer', 'content_admin', 'analyst', 'technical_admin'];
    const [roles] = await queryInterface.sequelize.query(
      'SELECT `id` FROM `AdminRoles` WHERE `key` IN (?)',
      { replacements: [keys] },
    );
    if (roles.length > 0) {
      const ids = roles.map((r) => r.id);
      await queryInterface.bulkDelete('AdminRolePermissions', { roleId: ids });
      await queryInterface.bulkDelete('AdminRoles', { key: keys });
    }
  },
};
