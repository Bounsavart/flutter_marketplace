const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Favorite = sequelize.define(
  'favorites',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    tenant_id: { type: DataTypes.INTEGER, allowNull: false },
    room_id: { type: DataTypes.INTEGER, allowNull: false },
  },
  {
    tableName: 'favorites',
    indexes: [{ unique: true, fields: ['tenant_id', 'room_id'] }],
  },
);

module.exports = Favorite;
