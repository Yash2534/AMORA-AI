async function indexNames(queryInterface, tableName) {
  return new Set((await queryInterface.showIndex(tableName)).map((index) => index.name));
}

async function addIndex(queryInterface, tableName, fields, name) {
  if ((await indexNames(queryInterface, tableName)).has(name)) return;
  await queryInterface.addIndex(tableName, fields, { name });
}

async function removeIndex(queryInterface, tableName, name) {
  if (!(await indexNames(queryInterface, tableName)).has(name)) return;
  await queryInterface.removeIndex(tableName, name);
}

module.exports = {
  async up(queryInterface) {
    await addIndex(queryInterface, 'Payments', ['status', 'createdAt', 'id'], 'payments_admin_status_history');
    await addIndex(queryInterface, 'Payments', ['currency', 'createdAt', 'id'], 'payments_admin_currency_history');
    await addIndex(queryInterface, 'PaymentEvents', ['status', 'createdAt', 'id'], 'payment_events_admin_status_history');
  },

  async down(queryInterface) {
    await removeIndex(queryInterface, 'PaymentEvents', 'payment_events_admin_status_history');
    await removeIndex(queryInterface, 'Payments', 'payments_admin_currency_history');
    await removeIndex(queryInterface, 'Payments', 'payments_admin_status_history');
  },
};
