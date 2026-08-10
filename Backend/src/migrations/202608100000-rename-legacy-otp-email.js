async function columns(queryInterface) {
  try {
    return await queryInterface.describeTable('OtpTokens');
  } catch (error) {
    if (error.original?.code === 'ER_NO_SUCH_TABLE') return null;
    throw error;
  }
}

module.exports = {
  async up(queryInterface) {
    const current = await columns(queryInterface);
    if (current?.email && !current.phoneNumber) {
      await queryInterface.renameColumn('OtpTokens', 'email', 'phoneNumber');
    }
  },

  async down() {
    // Intentionally data-preserving. This adoption migration can be a no-op on
    // databases that already used phoneNumber, so renaming it back is unsafe.
  },
};
