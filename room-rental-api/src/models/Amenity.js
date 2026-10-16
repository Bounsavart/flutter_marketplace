const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Amenity = sequelize.define(
  'amenities',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    name: { type: DataTypes.STRING(80), allowNull: false, unique: true },
  },
  { tableName: 'amenities' },
);

module.exports = Amenity;
