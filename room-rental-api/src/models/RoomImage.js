const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const RoomImage = sequelize.define(
  'room_images',
  {
    id: { type: DataTypes.INTEGER, autoIncrement: true, primaryKey: true },
    room_id: { type: DataTypes.INTEGER, allowNull: false },
    image_url: { type: DataTypes.STRING(500), allowNull: false },
  },
  { tableName: 'room_images' },
);

module.exports = RoomImage;
