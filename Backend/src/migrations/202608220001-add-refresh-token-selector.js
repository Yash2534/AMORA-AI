async function columnExists(queryInterface, tableName, columnName) {
  const columns = await queryInterface.describeTable(tableName);
  return Object.prototype.hasOwnProperty.call(columns, columnName);
}

async function indexExists(queryInterface, tableName, indexName) {
  return (await queryInterface.showIndex(tableName)).some((index) => index.name === indexName);
}

module.exports = {
  async up(queryInterface, Sequelize) {
    if (!(await columnExists(queryInterface, 'RefreshTokens', 'tokenSelector'))) {
      await queryInterface.addColumn('RefreshTokens', 'tokenSelector', {
        type: Sequelize.STRING(32),
        allowNull: true,
        after: 'userId',
      });
    }
    if (!(await indexExists(queryInterface, 'RefreshTokens', 'refresh_tokens_token_selector_unique'))) {
      await queryInterface.addIndex('RefreshTokens', ['tokenSelector'], {
        unique: true,
        name: 'refresh_tokens_token_selector_unique',
      });
    }
  },

  async down(queryInterface) {
    if (await indexExists(queryInterface, 'RefreshTokens', 'refresh_tokens_token_selector_unique')) {
      await queryInterface.removeIndex('RefreshTokens', 'refresh_tokens_token_selector_unique');
    }
    if (await columnExists(queryInterface, 'RefreshTokens', 'tokenSelector')) {
      await queryInterface.removeColumn('RefreshTokens', 'tokenSelector');
    }
  },
};
