async function tableExists(queryInterface, name) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === name.toLowerCase());
}

async function columnExists(queryInterface, table, column) {
  if (!(await tableExists(queryInterface, table))) return false;
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

async function addColumn(queryInterface, table, column, definition) {
  if (!(await columnExists(queryInterface, table, column))) {
    await queryInterface.addColumn(table, column, definition);
  }
}

async function removeColumn(queryInterface, table, column) {
  if (!(await columnExists(queryInterface, table, column))) return;
  const references = await queryInterface.getForeignKeyReferencesForTable(table);
  for (const reference of references.filter((item) => item.columnName?.toLowerCase() === column.toLowerCase())) {
    if (reference.constraintName) await queryInterface.removeConstraint(table, reference.constraintName);
  }
  await queryInterface.removeColumn(table, column);
}

async function addIndex(queryInterface, table, fields, options) {
  const indexes = await queryInterface.showIndex(table);
  if (!indexes.some((index) => index.name === options.name)) {
    await queryInterface.addIndex(table, fields, options);
  }
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'IdentityVerificationReasons'))) {
      await queryInterface.createTable('IdentityVerificationReasons', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        code: { type: Sequelize.STRING(80), allowNull: false, unique: true },
        action: { type: Sequelize.ENUM('reject', 'request_resubmission'), allowNull: false },
        label: { type: Sequelize.STRING(160), allowNull: false },
        allowsDetail: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        requiresDetail: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        allowedItems: { type: Sequelize.JSON, allowNull: true },
        isActive: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sortOrder: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('IdentityVerificationReasons', ['action', 'isActive', 'sortOrder', 'id'], {
        name: 'identity_verification_reasons_active_action',
      });
    }

    if (await tableExists(queryInterface, 'IdentityVerifications')) {
      await queryInterface.changeColumn('IdentityVerifications', 'status', {
        type: Sequelize.ENUM('pending', 'under_review', 'verified', 'rejected', 'resubmission_requested'),
        allowNull: false,
        defaultValue: 'pending',
      });
      await addColumn(queryInterface, 'IdentityVerifications', 'reviewerAdministratorId', {
        type: Sequelize.BIGINT.UNSIGNED,
        allowNull: true,
        references: { model: 'Administrators', key: 'id' },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL',
      });
      await addColumn(queryInterface, 'IdentityVerifications', 'reviewVersion', {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: false,
        defaultValue: 1,
      });
      await addColumn(queryInterface, 'IdentityVerifications', 'submissionVersion', {
        type: Sequelize.INTEGER.UNSIGNED,
        allowNull: false,
        defaultValue: 1,
      });
      await addColumn(queryInterface, 'IdentityVerifications', 'reviewReasonCode', {
        type: Sequelize.STRING(80),
        allowNull: true,
      });
      await addColumn(queryInterface, 'IdentityVerifications', 'resubmissionItems', {
        type: Sequelize.JSON,
        allowNull: true,
      });
      await addIndex(queryInterface, 'IdentityVerifications', ['reviewerAdministratorId', 'reviewedAt', 'id'], {
        name: 'identity_verifications_reviewer_history',
      });
      await addIndex(queryInterface, 'IdentityVerifications', ['status', 'updatedAt', 'id'], {
        name: 'identity_verifications_status_updated',
      });
    }

    if (!(await tableExists(queryInterface, 'IdentityVerificationDecisionEvents'))) {
      await queryInterface.createTable('IdentityVerificationDecisionEvents', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        verificationId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: false,
          references: { model: 'IdentityVerifications', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'CASCADE',
        },
        administratorId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: true,
          references: { model: 'Administrators', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'SET NULL',
        },
        action: { type: Sequelize.ENUM('approve', 'reject', 'request_resubmission'), allowNull: false },
        fromStatus: {
          type: Sequelize.ENUM('pending', 'under_review', 'verified', 'rejected', 'resubmission_requested'),
          allowNull: false,
        },
        toStatus: {
          type: Sequelize.ENUM('pending', 'under_review', 'verified', 'rejected', 'resubmission_requested'),
          allowNull: false,
        },
        reasonId: {
          type: Sequelize.BIGINT.UNSIGNED,
          allowNull: true,
          references: { model: 'IdentityVerificationReasons', key: 'id' },
          onUpdate: 'CASCADE',
          onDelete: 'RESTRICT',
        },
        reasonCodeSnapshot: { type: Sequelize.STRING(80), allowNull: true },
        reasonLabelSnapshot: { type: Sequelize.STRING(160), allowNull: true },
        reasonDetail: { type: Sequelize.STRING(500), allowNull: true },
        requiredItems: { type: Sequelize.JSON, allowNull: true },
        internalNote: { type: Sequelize.STRING(500), allowNull: true },
        submissionVersion: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        idempotencyKey: { type: Sequelize.STRING(160), allowNull: false, unique: true },
        requestHash: { type: Sequelize.CHAR(64), allowNull: false },
        responseSnapshot: { type: Sequelize.JSON, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('IdentityVerificationDecisionEvents', ['verificationId', 'createdAt', 'id'], {
        name: 'identity_verification_decisions_history',
      });
      await queryInterface.addIndex('IdentityVerificationDecisionEvents', ['administratorId', 'createdAt', 'id'], {
        name: 'identity_verification_decisions_reviewer',
      });
      await queryInterface.addIndex('IdentityVerificationDecisionEvents', ['action', 'createdAt', 'id'], {
        name: 'identity_verification_decisions_action',
      });
    }
  },

  async down(queryInterface, Sequelize) {
    if (await tableExists(queryInterface, 'IdentityVerificationDecisionEvents')) {
      await queryInterface.dropTable('IdentityVerificationDecisionEvents');
    }
    if (await tableExists(queryInterface, 'IdentityVerifications')) {
      await queryInterface.sequelize.query(
        "UPDATE `IdentityVerifications` SET `status` = 'rejected' WHERE `status` = 'resubmission_requested'",
      );
      for (const column of ['resubmissionItems', 'reviewReasonCode', 'submissionVersion', 'reviewVersion', 'reviewerAdministratorId']) {
        await removeColumn(queryInterface, 'IdentityVerifications', column);
      }
      for (const indexName of ['identity_verifications_reviewer_history', 'identity_verifications_status_updated']) {
        const indexes = await queryInterface.showIndex('IdentityVerifications');
        if (indexes.some((index) => index.name === indexName)) await queryInterface.removeIndex('IdentityVerifications', indexName);
      }
      await queryInterface.changeColumn('IdentityVerifications', 'status', {
        type: Sequelize.ENUM('pending', 'under_review', 'verified', 'rejected'),
        allowNull: false,
        defaultValue: 'pending',
      });
    }
    if (await tableExists(queryInterface, 'IdentityVerificationReasons')) {
      await queryInterface.dropTable('IdentityVerificationReasons');
    }
  },
};
