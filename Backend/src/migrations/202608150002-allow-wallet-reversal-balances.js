async function tableExists(queryInterface, tableName) {
  const tables = await queryInterface.showAllTables();
  return tables.some((table) => String(table).toLowerCase() === tableName.toLowerCase());
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (await tableExists(queryInterface, 'Wallets')) {
      await queryInterface.changeColumn('Wallets', 'balance', { type: Sequelize.BIGINT, allowNull: false, defaultValue: 0 });
    }
    if (await tableExists(queryInterface, 'WalletTransactions')) {
      await queryInterface.changeColumn('WalletTransactions', 'balanceBefore', { type: Sequelize.BIGINT, allowNull: false });
      await queryInterface.changeColumn('WalletTransactions', 'balanceAfter', { type: Sequelize.BIGINT, allowNull: false });
    }
  },
  async down() {
    // Signed balances are retained because provider reversals may legitimately
    // place a frozen wallet below zero; converting back could corrupt audit data.
  },
};
