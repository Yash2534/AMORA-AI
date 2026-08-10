async function columnNames(queryInterface, tableName) {
  const columns = await queryInterface.describeTable(tableName);
  return new Set(Object.keys(columns).map((column) => column.toLowerCase()));
}

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await columnNames(queryInterface, 'EventFeedback');
    const additions = [
      ['mediaOriginalName', { type: Sequelize.STRING, allowNull: true }],
      ['mediaStoragePath', { type: Sequelize.STRING, allowNull: true }],
      ['mediaMimeType', { type: Sequelize.STRING, allowNull: true }],
      ['mediaSizeBytes', { type: Sequelize.INTEGER.UNSIGNED, allowNull: true }],
    ];
    for (const [name, definition] of additions) {
      if (!columns.has(name.toLowerCase())) await queryInterface.addColumn('EventFeedback', name, definition);
    }
  },

  async down() {
    // Feedback media references are retained to avoid orphaning audit data.
  },
};
