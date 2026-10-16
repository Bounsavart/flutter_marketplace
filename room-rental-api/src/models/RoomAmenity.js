const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const RoomAmenity = sequelize.define(
  'room_amenities',
  {
    room_id: { type: DataTypes.INTEGER, primaryKey: true },
    amenity_id: { type: DataTypes.INTEGER, primaryKey: true },
  },
  { tableName: 'room_amenities', timestamps: false },
);

module.exports = RoomAmenity;
