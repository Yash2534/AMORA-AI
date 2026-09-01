const settings = [
  ['default_min_age', 18],
  ['default_max_age', 45],
  ['default_max_distance_km', 80],
  ['default_minimum_score', 0],
  ['online_now_window_minutes', 5],
];
const filters = [
  ['min_age', 'minAge', 'Minimum age', 'number', 1, 1, 1, 1, null, 18, 99, 0],
  ['max_age', 'maxAge', 'Maximum age', 'number', 1, 1, 1, 2, null, 18, 99, 0],
  ['max_distance_km', 'maxDistanceKm', 'Maximum distance', 'number', 1, 1, 0, 3, null, 1, 500, 0],
  ['minimum_score', 'minScore', 'Minimum compatibility score', 'number', 1, 1, 0, 4, null, 0, 100, 0],
  ['city', 'city', 'City', 'text', 1, 1, 0, 5, null, null, null, 0],
  ['minimum_height', 'minHeight', 'Minimum height', 'number', 1, 1, 0, 6, null, 0, 300, 0],
  ['hometown', 'hometown', 'Hometown', 'multiple_selection', 1, 1, 0, 7, 10, null, null, 0],
  ['dating_intentions', 'datingIntentions', 'Dating intentions', 'multiple_selection', 1, 1, 0, 8, 10, null, null, 0],
  ['lifestyle_tags', 'lifestyleTags', 'Lifestyle', 'multiple_selection', 1, 1, 0, 9, 10, null, null, 0],
  ['education', 'education', 'Education', 'single_selection', 1, 1, 0, 10, 1, null, null, 0],
  ['profession', 'profession', 'Occupation', 'single_selection', 1, 1, 0, 11, 1, null, null, 0],
  ['community', 'community', 'Community', 'single_selection', 1, 1, 0, 12, 1, null, null, 1],
  ['religion', 'religion', 'Religion', 'single_selection', 1, 1, 0, 13, 1, null, null, 1],
  ['languages', 'languages', 'Languages', 'multiple_selection', 1, 1, 0, 14, 10, null, null, 0],
  ['pronouns', 'pronouns', 'Pronouns', 'multiple_selection', 1, 1, 0, 15, 5, null, null, 1],
  ['sexuality', 'sexuality', 'Sexuality', 'single_selection', 1, 1, 0, 16, 1, null, null, 1],
  ['qualities', 'qualities', 'Valued qualities', 'multiple_selection', 1, 1, 0, 17, 10, null, null, 0],
  ['preferred_talking_hours', 'preferredTalkingHours', 'Preferred talking hours', 'multiple_selection', 1, 1, 0, 18, 10, null, null, 0],
  ['love_languages', 'loveLanguages', 'Love languages', 'multiple_selection', 1, 1, 0, 19, 10, null, null, 0],
  ['communication_styles', 'communicationStyles', 'Communication styles', 'multiple_selection', 1, 1, 0, 20, 10, null, null, 0],
  ['smoking', 'smoking', 'Smoking', 'single_selection', 1, 1, 0, 21, 1, null, null, 0],
  ['drinking', 'drinking', 'Drinking', 'single_selection', 1, 1, 0, 22, 1, null, null, 0],
  ['weed', 'weed', 'Cannabis', 'single_selection', 1, 1, 0, 23, 1, null, null, 0],
  ['verified_only', 'verifiedOnly', 'Verified profiles only', 'boolean', 1, 1, 0, 24, null, null, null, 0],
  ['online_now', 'onlineNow', 'Online now', 'boolean', 1, 1, 0, 25, null, null, null, 0],
  ['has_prompts', 'hasPrompts', 'Has prompts', 'boolean', 1, 1, 0, 26, null, null, null, 0],
  ['event_interest', 'hasEventInterest', 'Has event interest', 'boolean', 1, 1, 0, 27, null, null, null, 0],
];

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('AdminDiscoverSettings', {
        key: { type: Sequelize.STRING(80), primaryKey: true },
        value: { type: Sequelize.JSON, allowNull: false },
        version: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
        updatedByAdministratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      }, { transaction });
      await queryInterface.createTable('AdminDiscoverFilterFields', {
        id: { type: Sequelize.STRING(80), primaryKey: true },
        key: { type: Sequelize.STRING(80), allowNull: false, unique: true },
        label: { type: Sequelize.STRING(120), allowNull: false },
        type: { type: Sequelize.STRING(40), allowNull: false },
        enabled: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        visible: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        required: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        displayOrder: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false },
        maximumSelections: { type: Sequelize.INTEGER.UNSIGNED, allowNull: true },
        minimumValue: { type: Sequelize.DECIMAL(10, 2), allowNull: true },
        maximumValue: { type: Sequelize.DECIMAL(10, 2), allowNull: true },
        sensitive: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        editable: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        version: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 1 },
        updatedByAdministratorId: { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, references: { model: 'Administrators', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
        updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      }, { transaction });
      await queryInterface.addIndex('AdminDiscoverFilterFields', ['enabled', 'visible', 'displayOrder'], { name: 'admin_discover_filters_state_order', transaction });
      await queryInterface.bulkInsert('AdminDiscoverSettings', settings.map(([key, value]) => ({ key, value: JSON.stringify(value), version: 1, updatedAt: new Date() })), { transaction });
      await queryInterface.bulkInsert('AdminDiscoverFilterFields', filters.map(([id, key, label, type, enabled, visible, required, displayOrder, maximumSelections, minimumValue, maximumValue, sensitive]) => ({ id, key, label, type, enabled, visible, required, displayOrder, maximumSelections, minimumValue, maximumValue, sensitive, editable: true, version: 1, updatedAt: new Date() })), { transaction });
      await transaction.commit();
    } catch (error) { await transaction.rollback(); throw error; }
  },
  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.dropTable('AdminDiscoverFilterFields', { transaction });
      await queryInterface.dropTable('AdminDiscoverSettings', { transaction });
      await transaction.commit();
    } catch (error) { await transaction.rollback(); throw error; }
  },
};
