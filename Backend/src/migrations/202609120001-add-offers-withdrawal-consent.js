module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.sequelize.query('ALTER TABLE `ConsentEvents` MODIFY `documentVersionId` BIGINT UNSIGNED NULL');
    await queryInterface.changeColumn('ConsentEvents', 'purpose', {
      type: Sequelize.ENUM('TERMS_OF_SERVICE_ACCEPTANCE', 'PRIVACY_POLICY_ACKNOWLEDGEMENT', 'OFFERS_NOTIFICATIONS'), allowNull: false,
    });
  },
  async down(queryInterface, Sequelize) {
    const [rows] = await queryInterface.sequelize.query("SELECT COUNT(*) AS count FROM `ConsentEvents` WHERE `purpose` = 'OFFERS_NOTIFICATIONS' OR `documentVersionId` IS NULL");
    if (Number(rows[0]?.count || 0) > 0) throw new Error('Cannot remove P1.4 consent schema while withdrawal evidence exists.');
    await queryInterface.changeColumn('ConsentEvents', 'purpose', {
      type: Sequelize.ENUM('TERMS_OF_SERVICE_ACCEPTANCE', 'PRIVACY_POLICY_ACKNOWLEDGEMENT'), allowNull: false,
    });
    await queryInterface.sequelize.query('ALTER TABLE `ConsentEvents` MODIFY `documentVersionId` BIGINT UNSIGNED NOT NULL');
  },
};
