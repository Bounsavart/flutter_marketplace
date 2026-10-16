const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Room = sequelize.define(
  'rooms',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    property_id: { type: DataTypes.INTEGER, allowNull: false },
    room_number: { type: DataTypes.STRING(40), allowNull: false },
    room_type: { type: DataTypes.STRING(80), allowNull: false },
    price: { type: DataTypes.DECIMAL(12, 2), allowNull: false },
    status: {
      type: DataTypes.ENUM('available', 'pending', 'rented'),
      allowNull: false,
      defaultValue: 'available',
    },
    description: { type: DataTypes.TEXT, allowNull: true },
  },
  { tableName: 'rooms', paranoid: true },
);

module.exports = Room;
