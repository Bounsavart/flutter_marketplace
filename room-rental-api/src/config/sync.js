const { DataTypes } = require('sequelize');
const sequelize = require('./database');

async function syncDatabase() {
  const queryInterface = sequelize.getQueryInterface();
  for (const table of ['users', 'properties', 'rooms']) {
    if (!(await queryInterface.tableExists(table))) continue;
    const columns = await queryInterface.describeTable(table);
    if (!columns.deletedAt) {
      await queryInterface.addColumn(table, 'deletedAt', {
        type: DataTypes.DATE,
        allowNull: true,
      });
    }
  }
  await sequelize.sync();
}

module.exports = { syncDatabase };
