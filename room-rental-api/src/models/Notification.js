const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

module.exports = sequelize.define('notifications', {
  id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
  user_id: { type: DataTypes.INTEGER, allowNull: false },
  type: { type: DataTypes.STRING(60), allowNull: false },
  data: { type: DataTypes.JSON, allowNull: false },
  is_read: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
}, {
  tableName: 'notifications',
  indexes: [{ fields: ['user_id', 'is_read', 'createdAt'] }],
});
