const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Booking = sequelize.define(
  'bookings',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    room_id: { type: DataTypes.INTEGER, allowNull: false },
    tenant_id: { type: DataTypes.INTEGER, allowNull: false },
    status: {
      type: DataTypes.ENUM('pending', 'confirmed', 'rejected', 'cancelled'),
      allowNull: false,
      defaultValue: 'pending',
    },
  },
  { tableName: 'bookings' },
);

module.exports = Booking;
