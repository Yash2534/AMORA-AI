async function columns(queryInterface) {
  return queryInterface.describeTable('Users');
}

async function addColumn(queryInterface, Sequelize, name, definition) {
  if ((await columns(queryInterface))[name]) return;
  await queryInterface.addColumn('Users', name, definition(Sequelize));
}

async function indexNames(queryInterface) {
  return new Set((await queryInterface.showIndex('Users')).map((index) => index.name));
}

module.exports = {
  async up(queryInterface, Sequelize) {
    await addColumn(queryInterface, Sequelize, 'accountStatus', (types) => ({ type: types.ENUM('active', 'deactivated', 'deleted'), allowNull: false, defaultValue: 'active' }));
    await addColumn(queryInterface, Sequelize, 'deactivatedAt', (types) => ({ type: types.DATE, allowNull: true }));
    await addColumn(queryInterface, Sequelize, 'deletedAt', (types) => ({ type: types.DATE, allowNull: true }));
    await addColumn(queryInterface, Sequelize, 'tokenVersion', (types) => ({ type: types.INTEGER, allowNull: false, defaultValue: 0 }));
    await addColumn(queryInterface, Sequelize, 'deletionReason', (types) => ({ type: types.STRING, allowNull: true }));
    await addColumn(queryInterface, Sequelize, 'deletionDetails', (types) => ({ type: types.TEXT, allowNull: true }));
    if (!(await indexNames(queryInterface)).has('users_account_status')) {
      await queryInterface.addIndex('Users', ['accountStatus', 'id'], { name: 'users_account_status' });
    }
  },

  async down(queryInterface) {
    const names = await indexNames(queryInterface);
    if (names.has('users_account_status')) await queryInterface.removeIndex('Users', 'users_account_status');
    // Lifecycle columns retain compliance/account-history data and are intentionally not removed.
  },
};
