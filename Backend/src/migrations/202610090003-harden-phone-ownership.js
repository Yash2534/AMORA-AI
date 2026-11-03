const { normalizeIndianMobile } = require('../utils/phoneNumber');

const UNIQUE_INDEX = 'users_phone_identity_unique';

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const [users] = await queryInterface.sequelize.query(
        'SELECT `id`, `phoneNumber` FROM `Users` WHERE `phoneNumber` IS NOT NULL AND TRIM(`phoneNumber`) <> \'\'',
        { transaction },
      );
      const ownership = new Map();
      for (const user of users) {
        const normalized = normalizeIndianMobile(user.phoneNumber) || String(user.phoneNumber).trim();
        const prior = ownership.get(normalized);
        if (prior && prior !== Number(user.id)) {
          throw new Error('Cannot add phone ownership constraint while duplicate normalized phone ownership exists.');
        }
        ownership.set(normalized, Number(user.id));
        if (normalized !== user.phoneNumber) {
          await queryInterface.sequelize.query(
            'UPDATE `Users` SET `phoneNumber` = :phoneNumber WHERE `id` = :id',
            { replacements: { phoneNumber: normalized, id: user.id }, transaction },
          );
        }
      }

      const columns = await queryInterface.describeTable('Users');
      if (!columns.phoneIdentity) {
        await queryInterface.sequelize.query(
          'ALTER TABLE `Users` ADD COLUMN `phoneIdentity` VARCHAR(64) '
            + 'GENERATED ALWAYS AS (NULLIF(TRIM(`phoneNumber`), \'\')) STORED',
          { transaction },
        );
      }
      const indexes = await queryInterface.showIndex('Users', { transaction });
      if (!indexes.some((index) => index.name === UNIQUE_INDEX)) {
        await queryInterface.addIndex('Users', ['phoneIdentity'], {
          name: UNIQUE_INDEX,
          unique: true,
          transaction,
        });
      }
      await queryInterface.changeColumn('OtpTokens', 'purpose', {
        type: Sequelize.ENUM('account_verification', 'password_reset', 'account_deletion', 'phone_change'),
        allowNull: false,
      }, { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      const indexes = await queryInterface.showIndex('Users', { transaction });
      if (indexes.some((index) => index.name === UNIQUE_INDEX)) {
        await queryInterface.removeIndex('Users', UNIQUE_INDEX, { transaction });
      }
      const columns = await queryInterface.describeTable('Users');
      if (columns.phoneIdentity) await queryInterface.removeColumn('Users', 'phoneIdentity', { transaction });
      await queryInterface.bulkDelete('OtpTokens', { purpose: 'phone_change' }, { transaction });
      await queryInterface.changeColumn('OtpTokens', 'purpose', {
        type: Sequelize.ENUM('account_verification', 'password_reset', 'account_deletion'),
        allowNull: false,
      }, { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
