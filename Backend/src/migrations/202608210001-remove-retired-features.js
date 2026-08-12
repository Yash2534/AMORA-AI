async function tableExists(queryInterface, name) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === name.toLowerCase());
}

async function columnExists(queryInterface, table, column) {
  if (!(await tableExists(queryInterface, table))) return false;
  const columns = await queryInterface.describeTable(table);
  return Object.keys(columns).some((name) => name.toLowerCase() === column.toLowerCase());
}

async function removeColumn(queryInterface, table, column) {
  if (!(await columnExists(queryInterface, table, column))) return;
  const references = await queryInterface.getForeignKeyReferencesForTable(table);
  for (const reference of references.filter((item) => item.columnName?.toLowerCase() === column.toLowerCase())) {
    if (reference.constraintName) await queryInterface.removeConstraint(table, reference.constraintName);
  }
  await queryInterface.removeColumn(table, column);
}

async function dropTable(queryInterface, table) {
  if (await tableExists(queryInterface, table)) await queryInterface.dropTable(table);
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await tableExists(queryInterface, 'RoseTransactions'))) {
      await queryInterface.createTable('RoseTransactions', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        senderId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        recipientId: { type: Sequelize.INTEGER, allowNull: false, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'CASCADE' },
        conversationId: { type: Sequelize.INTEGER, allowNull: true, references: { model: 'Conversations', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        idempotencyKey: { type: Sequelize.STRING(100), allowNull: false },
        status: { type: Sequelize.ENUM('sent', 'reversed'), allowNull: false, defaultValue: 'sent' },
        note: { type: Sequelize.STRING(280), allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false },
        updatedAt: { type: Sequelize.DATE, allowNull: false },
      });
      await queryInterface.addIndex('RoseTransactions', ['senderId', 'idempotencyKey'], { unique: true, name: 'rose_transactions_sender_idempotency_unique' });
      await queryInterface.addIndex('RoseTransactions', ['recipientId', 'createdAt', 'id'], { name: 'rose_transactions_recipient_history' });
    }

    if (await tableExists(queryInterface, 'GiftTransactions')) {
      await queryInterface.sequelize.query(`
        INSERT IGNORE INTO \`RoseTransactions\`
          (\`id\`, \`senderId\`, \`recipientId\`, \`conversationId\`, \`idempotencyKey\`, \`status\`, \`note\`, \`createdAt\`, \`updatedAt\`)
        SELECT \`id\`, \`senderId\`, \`recipientId\`, \`conversationId\`, \`idempotencyKey\`,
          CASE WHEN \`status\` = 'sent' THEN 'sent' ELSE 'reversed' END,
          \`note\`, \`createdAt\`, \`updatedAt\`
        FROM \`GiftTransactions\` WHERE \`giftId\` = 'rose_ritual'
      `);
    }

    if (await tableExists(queryInterface, 'Notifications')) {
      await queryInterface.sequelize.query(`
        UPDATE \`Notifications\`
        SET \`type\` = 'rose_received',
            \`data\` = JSON_REMOVE(
              JSON_SET(COALESCE(\`data\`, JSON_OBJECT()), '$.roseTransactionId', JSON_UNQUOTE(JSON_EXTRACT(\`data\`, '$.giftTransactionId'))),
              '$.giftTransactionId', '$.giftType', '$.giftName'
            ),
            \`dedupeKey\` = REPLACE(\`dedupeKey\`, 'gift:', 'rose:')
        WHERE \`type\` = 'gift_received'
          AND JSON_UNQUOTE(JSON_EXTRACT(\`data\`, '$.giftType')) = 'rose'
      `);
      if (await tableExists(queryInterface, 'NotificationDeliveries')) {
        await queryInterface.sequelize.query(`DELETE delivery FROM \`NotificationDeliveries\` delivery INNER JOIN \`Notifications\` notification ON notification.id = delivery.notificationId WHERE notification.type = 'gift_received'`);
      }
      await queryInterface.sequelize.query(`DELETE FROM \`Notifications\` WHERE \`type\` = 'gift_received'`);
    }

    if (await tableExists(queryInterface, 'Payments')) {
      if (await tableExists(queryInterface, 'PaymentEvents')) {
        await queryInterface.sequelize.query(`DELETE eventRow FROM \`PaymentEvents\` eventRow INNER JOIN \`Payments\` payment ON payment.id = eventRow.paymentId WHERE payment.productType <> 'subscription'`);
      }
      await queryInterface.sequelize.query(`DELETE FROM \`Payments\` WHERE \`productType\` <> 'subscription'`);
      await queryInterface.changeColumn('Payments', 'productType', { type: Sequelize.ENUM('subscription'), allowNull: false });
    }

    if (await tableExists(queryInterface, 'EventRegistrations')) {
      await queryInterface.sequelize.query(`UPDATE \`EventRegistrations\` SET \`status\` = 'registered' WHERE \`status\` = 'promoted'`);
      await queryInterface.changeColumn('EventRegistrations', 'status', { type: Sequelize.ENUM('registered', 'cancelled'), allowNull: false, defaultValue: 'registered' });
    }

    for (const table of [
      'Boosts', 'BoostEntitlements', 'BoostProducts',
      'GiftTransactions', 'Gifts',
      'WalletTransactions', 'Wallets', 'WalletProducts',
      'EventFeedback', 'EventCheckIns', 'EventGroupMessages', 'EventWaitlist',
      'ReportEvidence',
    ]) await dropTable(queryInterface, table);

    for (const column of ['waitlistCapacity', 'waitlistEnabled', 'checkInOpensAt', 'checkInClosesAt']) {
      await removeColumn(queryInterface, 'Events', column);
    }

    for (const column of [
      'voicePromptUrl', 'videoPromptUrl', 'personality', 'travelPreference', 'musicTaste',
      'foodPreference', 'weekendPlan', 'petPreference', 'coffeePreference', 'fitnessLevel',
      'children', 'familyValues', 'loveLanguage', 'greenFlags', 'redFlags', 'dateIdeas',
    ]) await removeColumn(queryInterface, 'OnboardingProfiles', column);

    await removeColumn(queryInterface, 'IdentityVerifications', 'reviewerUserId');
    await removeColumn(queryInterface, 'IdentityVerifications', 'reviewNote');
    await removeColumn(queryInterface, 'Users', 'role');
  },

  async down() {
    throw new Error('The retired-feature removal migration is intentionally irreversible because it deletes out-of-scope production data. Restore from a verified backup instead.');
  },
};
