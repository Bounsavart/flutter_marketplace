const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Property = sequelize.define(
  'properties',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    owner_id: { type: DataTypes.INTEGER, allowNull: false },
    name: { type: DataTypes.STRING(160), allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: true },
    province: { type: DataTypes.STRING(80), allowNull: false },
    district: { type: DataTypes.STRING(80), allowNull: false },
    address: { type: DataTypes.STRING(255), allowNull: false },
    latitude: { type: DataTypes.DECIMAL(10, 7), allowNull: true },
    longitude: { type: DataTypes.DECIMAL(10, 7), allowNull: true },
    approval_status: {
      type: DataTypes.ENUM('pending', 'approved', 'rejected'),
      allowNull: false,
      defaultValue: 'pending',
    },
  },
  { tableName: 'properties', paranoid: true },
);

module.exports = Property;
