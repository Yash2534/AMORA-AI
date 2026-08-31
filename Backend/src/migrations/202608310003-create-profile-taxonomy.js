const crypto = require('crypto');

const categories = [
  { key: 'education', label: 'Education', maximumSelections: null },
  { key: 'occupations', label: 'Occupation', maximumSelections: null },
  { key: 'religions', label: 'Religion', maximumSelections: null },
  { key: 'languages', label: 'Languages', maximumSelections: 10 },
  { key: 'interests', label: 'Interests', maximumSelections: 20 },
];
const categoryColumns = {
  education: 'education', occupations: 'profession', religions: 'religion',
  languages: 'languages', interests: 'interests',
};
const customCategories = new Set(['education', 'occupations', 'religions']);
const normalize = (value) => String(value || '').trim().replace(/\s+/g, ' ').toLocaleLowerCase('en-US');
const idFor = (category, label) => `taxonomy_${category}_${crypto.createHash('sha256').update(`${category}\0${normalize(label)}`).digest('hex').slice(0, 32)}`;
const valuesOf = (value) => {
  if (Array.isArray(value)) return value;
  if (typeof value === 'string') {
    try { return valuesOf(JSON.parse(value)); } catch (_) { return [value]; }
  }
  return value == null ? [] : [value];
};

module.exports = {
  async up(queryInterface, Sequelize) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.createTable('ProfileTaxonomyCategories', {
        key: { type: Sequelize.STRING(40), primaryKey: true },
        label: { type: Sequelize.STRING(120), allowNull: false },
        maximumSelections: { type: Sequelize.INTEGER.UNSIGNED, allowNull: true },
      }, { transaction });
      await queryInterface.createTable('ProfileTaxonomyOptions', {
        id: { type: Sequelize.STRING(80), primaryKey: true },
        categoryKey: { type: Sequelize.STRING(40), allowNull: false, references: { model: 'ProfileTaxonomyCategories', key: 'key' }, onUpdate: 'CASCADE', onDelete: 'RESTRICT' },
        label: { type: Sequelize.STRING(255), allowNull: false },
        normalizedLabel: { type: Sequelize.STRING(255), allowNull: false },
        allowsCustomValue: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false },
        isActive: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        sortOrder: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 0 },
      }, { transaction });
      await queryInterface.addConstraint('ProfileTaxonomyOptions', { fields: ['categoryKey', 'normalizedLabel'], type: 'unique', name: 'profile_taxonomy_option_category_label', transaction });
      await queryInterface.addIndex('ProfileTaxonomyOptions', ['categoryKey', 'isActive', 'sortOrder'], { name: 'profile_taxonomy_options_category_state_sort', transaction });
      await queryInterface.bulkInsert('ProfileTaxonomyCategories', categories, { transaction });

      const [profiles] = await queryInterface.sequelize.query(
        'SELECT `education`, `profession`, `religion`, `languages`, `interests` FROM `OnboardingProfiles`',
        { transaction },
      );
      const discovered = new Map();
      for (const category of categories) discovered.set(category.key, new Map());
      for (const profile of profiles) {
        for (const [category, column] of Object.entries(categoryColumns)) {
          for (const raw of valuesOf(profile[column])) {
            const label = String(raw || '').trim().replace(/\s+/g, ' ');
            if (label) discovered.get(category).set(normalize(label), label);
          }
        }
      }
      const options = [];
      for (const category of categories) {
        const labels = [...discovered.get(category.key).values()].sort((a, b) => a.localeCompare(b));
        labels.forEach((label, index) => options.push({
          id: idFor(category.key, label), categoryKey: category.key, label, normalizedLabel: normalize(label),
          allowsCustomValue: false, isActive: true, sortOrder: index + 1,
        }));
        if (customCategories.has(category.key)) options.push({
          id: idFor(category.key, 'Other'), categoryKey: category.key, label: 'Other', normalizedLabel: normalize('Other'),
          allowsCustomValue: true, isActive: true, sortOrder: labels.length + 1,
        });
      }
      if (options.length) await queryInterface.bulkInsert('ProfileTaxonomyOptions', options, { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },

  async down(queryInterface) {
    const transaction = await queryInterface.sequelize.transaction();
    try {
      await queryInterface.dropTable('ProfileTaxonomyOptions', { transaction });
      await queryInterface.dropTable('ProfileTaxonomyCategories', { transaction });
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  },
};
