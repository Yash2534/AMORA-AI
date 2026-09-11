module.exports = {
  async up(queryInterface) {
    await queryInterface.sequelize.query('ALTER TABLE `ConsentEvents` MODIFY `documentVersionId` BIGINT UNSIGNED NULL');
  },
  async down(queryInterface) {
    const [rows] = await queryInterface.sequelize.query("SELECT COUNT(*) AS count FROM `ConsentEvents` WHERE `documentVersionId` IS NULL");
    if (Number(rows[0]?.count || 0) > 0) throw new Error('Cannot restore required document versions while optional consent evidence exists.');
    await queryInterface.sequelize.query('ALTER TABLE `ConsentEvents` MODIFY `documentVersionId` BIGINT UNSIGNED NOT NULL');
  },
};
