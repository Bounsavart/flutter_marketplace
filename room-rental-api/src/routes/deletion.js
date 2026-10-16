const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { sequelize, Booking, Room, Property, Favorite, RoomImage, RoomAmenity } = require('../models');
const { createNotification, bookingSnapshot } = require('../services/notifications');

const ACTIVE = ['pending', 'confirmed'];
const blockedMessage = 'ບໍ່ສາມາດລຶບໄດ້ ເນື່ອງຈາກຍັງມີການຈອງທີ່ລໍຖ້າ ຫຼື ຢືນຢັນແລ້ວ';

async function activeBookings(roomIds, transaction) {
  return Booking.findAll({ where: { room_id: roomIds, status: { [Op.in]: ACTIVE } }, transaction, lock: transaction.LOCK.UPDATE,
    include: [{ model: Room, as: 'room', paranoid: false, include: [{ model: Property, as: 'property', paranoid: false,
      include: [{ model: require('../models').User, as: 'owner', paranoid: false }] }] },
      { model: require('../models').User, as: 'tenant', paranoid: false }],
  });
}

async function cancelBookings(bookings, transaction) {
  for (const booking of bookings) {
    const snapshot = await bookingSnapshot(booking, transaction);
    await createNotification(booking.tenant_id, 'booking_cancelled_by_system', {
      ...snapshot,
    }, { transaction });
  }
  const ids = bookings.map((b) => b.id);
  if (ids.length) await Booking.update({ status: 'cancelled' }, { where: { id: ids }, transaction });
  const roomIds = [...new Set(bookings.map((b) => b.room_id))];
  if (roomIds.length) await Room.update({ status: 'available' }, { where: { id: roomIds }, transaction });
  return bookings.length;
}

async function deleteRoomTree(room, transaction) {
  await Favorite.destroy({ where: { room_id: room.id }, transaction });
  await RoomAmenity.destroy({ where: { room_id: room.id }, transaction });
  const images = await RoomImage.findAll({ where: { room_id: room.id }, transaction });
  for (const image of images) {
    const relative = image.image_url.replace(/^\/+/, '');
    if (relative.startsWith('uploads/')) {
      const file = path.resolve(__dirname, '../../', relative);
      const uploadDir = path.resolve(__dirname, '../../uploads');
      if (file.startsWith(uploadDir + path.sep) && fs.existsSync(file)) fs.unlinkSync(file);
    }
  }
  await RoomImage.destroy({ where: { room_id: room.id }, transaction });
  await room.destroy({ transaction });
}

async function deletePropertyTree(property, transaction) {
  const rooms = await Room.findAll({ where: { property_id: property.id }, transaction, lock: transaction.LOCK.UPDATE });
  for (const room of rooms) await deleteRoomTree(room, transaction);
  await property.destroy({ transaction });
}

async function deleteRoom(req, res) {
  const transaction = await sequelize.transaction();
  try {
    const room = await Room.findByPk(req.params.id, { include: [{ model: Property, as: 'property' }], transaction, lock: transaction.LOCK.UPDATE });
    if (!room) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' }); }
    const admin = req.user.role === 'admin';
    if (!admin && room.property.owner_id !== req.user.id) { await transaction.rollback(); return res.status(403).json({ message: 'ທ່ານສາມາດລຶບໄດ້ສະເພາະຫ້ອງຂອງຕົນເອງ' }); }
    const bookings = await activeBookings([room.id], transaction);
    if (!admin && bookings.length) { await transaction.rollback(); return res.status(409).json({ message: blockedMessage }); }
    if (admin) await cancelBookings(bookings, transaction);
    await deleteRoomTree(room, transaction);
    await transaction.commit();
    return res.json({ deleted: true, cancelledBookings: admin ? bookings.length : 0 });
  } catch (err) { await transaction.rollback(); return res.status(500).json({ message: err.message }); }
}

async function deleteProperty(req, res) {
  const transaction = await sequelize.transaction();
  try {
    const property = await Property.findByPk(req.params.id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!property) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' }); }
    const admin = req.user.role === 'admin';
    if (!admin && property.owner_id !== req.user.id) { await transaction.rollback(); return res.status(403).json({ message: 'ທ່ານສາມາດລຶບໄດ້ສະເພາະທີ່ພັກຂອງຕົນເອງ' }); }
    const rooms = await Room.findAll({ where: { property_id: property.id }, transaction, lock: transaction.LOCK.UPDATE });
    const bookings = await activeBookings(rooms.map((r) => r.id), transaction);
    if (!admin && bookings.length) { await transaction.rollback(); return res.status(409).json({ message: blockedMessage }); }
    if (admin) await cancelBookings(bookings, transaction);
    await deletePropertyTree(property, transaction);
    await transaction.commit();
    return res.json({ deleted: true, cancelledBookings: admin ? bookings.length : 0 });
  } catch (err) { await transaction.rollback(); return res.status(500).json({ message: err.message }); }
}

async function deleteImage(req, res) {
  const transaction = await sequelize.transaction();
  try {
    const image = await RoomImage.findByPk(req.params.imageId, { include: [{ model: Room, include: [{ model: Property, as: 'property' }] }], transaction });
    if (!image) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບຮູບພາບ' }); }
    if (!image.room || image.room.id !== Number(req.params.id)) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບຮູບພາບໃນຫ້ອງນີ້' }); }
    if (req.user.role === 'owner' && image.room.property.owner_id !== req.user.id) { await transaction.rollback(); return res.status(403).json({ message: 'ທ່ານສາມາດລຶບຮູບຂອງຫ້ອງຕົນເອງເທົ່ານັ້ນ' }); }
    const relative = image.image_url.replace(/^\/+/, '');
    if (relative.startsWith('uploads/')) {
      const file = path.resolve(__dirname, '../../', relative);
      const dir = path.resolve(__dirname, '../../uploads');
      if (file.startsWith(dir + path.sep) && fs.existsSync(file)) fs.unlinkSync(file);
    }
    await image.destroy({ transaction });
    await transaction.commit();
    return res.json({ deleted: true });
  } catch (err) { await transaction.rollback(); return res.status(500).json({ message: err.message }); }
}

module.exports = { ACTIVE, blockedMessage, activeBookings, cancelBookings, deleteRoomTree, deletePropertyTree, deleteRoom, deleteProperty, deleteImage };
