const sequelize = require('../config/database');
const User = require('./User');
const Property = require('./Property');
const Room = require('./Room');
const RoomImage = require('./RoomImage');
const Amenity = require('./Amenity');
const RoomAmenity = require('./RoomAmenity');
const Booking = require('./Booking');
const Favorite = require('./Favorite');
const Notification = require('./Notification');

User.hasMany(Property, { foreignKey: 'owner_id', as: 'properties' });
Property.belongsTo(User, { foreignKey: 'owner_id', as: 'owner' });

Property.hasMany(Room, { foreignKey: 'property_id', as: 'rooms' });
Room.belongsTo(Property, { foreignKey: 'property_id', as: 'property' });

Room.hasMany(RoomImage, { foreignKey: 'room_id', as: 'images' });
RoomImage.belongsTo(Room, { foreignKey: 'room_id' });

Room.belongsToMany(Amenity, {
  through: RoomAmenity,
  foreignKey: 'room_id',
  otherKey: 'amenity_id',
  as: 'amenities',
});
Amenity.belongsToMany(Room, {
  through: RoomAmenity,
  foreignKey: 'amenity_id',
  otherKey: 'room_id',
  as: 'rooms',
});

Room.hasMany(Booking, { foreignKey: 'room_id', as: 'bookings' });
Booking.belongsTo(Room, { foreignKey: 'room_id', as: 'room' });
User.hasMany(Booking, { foreignKey: 'tenant_id', as: 'bookings' });
Booking.belongsTo(User, { foreignKey: 'tenant_id', as: 'tenant' });

User.hasMany(Favorite, { foreignKey: 'tenant_id', as: 'favorites' });
Favorite.belongsTo(User, { foreignKey: 'tenant_id' });
Room.hasMany(Favorite, { foreignKey: 'room_id' });
Favorite.belongsTo(Room, { foreignKey: 'room_id', as: 'room' });

User.hasMany(Notification, { foreignKey: 'user_id', as: 'notifications' });
Notification.belongsTo(User, { foreignKey: 'user_id', as: 'user' });

const roomInclude = [
  { model: RoomImage, as: 'images' },
  { model: Amenity, as: 'amenities', through: { attributes: [] } },
  {
    model: Property,
    as: 'property',
    include: [
      { model: User, as: 'owner', attributes: ['id', 'name', 'phone', 'email'] },
    ],
  },
];

module.exports = {
  sequelize,
  User,
  Property,
  Room,
  RoomImage,
  Amenity,
  RoomAmenity,
  Booking,
  Favorite,
  Notification,
  roomInclude,
};
