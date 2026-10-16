const express = require('express');
const { Op } = require('sequelize');
const { sequelize, Property, Room, Amenity, RoomImage, Booking, User, roomInclude } = require('../models');
const { authenticateToken, requireRole, optionalAuth } = require('../middleware/auth');
const { upload } = require('../middleware/upload');
const { deleteRoom, deleteImage } = require('./deletion');
const { createNotification, bookingSnapshot } = require('../services/notifications');

const router = express.Router();

router.delete('/:id', authenticateToken, requireRole('owner', 'admin'), deleteRoom);
router.delete('/:id/images/:imageId', authenticateToken, requireRole('owner', 'admin'), deleteImage);

router.put('/:id', authenticateToken, requireRole('owner'), async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const room = await Room.findByPk(req.params.id, {
      include: [{ model: Property, as: 'property' }], transaction, lock: transaction.LOCK.UPDATE,
    });
    if (!room || !room.property) {
      await transaction.rollback();
      return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
    }
    if (room.property.owner_id !== req.user.id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'ແກ້ໄຂໄດ້ສະເພາະຫ້ອງຂອງຕົນເອງ' });
    }
    if (room.property.deletedAt) {
      await transaction.rollback();
      return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
    }
    const { room_number, room_type, price, description, amenityIds, status } = req.body;
    if (typeof room_number !== 'string' || !room_number.trim() || typeof room_type !== 'string' || !room_type.trim() ||
        !Number.isFinite(Number(price)) || Number(price) <= 0 || !Array.isArray(amenityIds) ||
        !['available', 'rented', 'pending'].includes(status) ||
        (status === 'pending' && room.status !== 'pending')) {
      await transaction.rollback();
      return res.status(400).json({ message: 'ກະລຸນາກວດສອບຂໍ້ມູນຫ້ອງ' });
    }
    const duplicate = await Room.findOne({
      where: { property_id: room.property_id, room_number: room_number.trim(), id: { [Op.ne]: room.id } },
      transaction, lock: transaction.LOCK.UPDATE,
    });
    if (duplicate) {
      await transaction.rollback();
      return res.status(409).json({ message: 'ເລກຫ້ອງນີ້ມີແລ້ວໃນທີ່ພັກນີ້' });
    }
    const pending = await Booking.findOne({
      where: { room_id: room.id, status: 'pending' }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if ((pending || room.status === 'pending') && status !== room.status) {
      await transaction.rollback();
      return res.status(409).json({ message: 'ກະລຸນາຢືນຢັນ ຫຼື ປະຕິເສດຄຳຂໍຈອງກ່ອນ' });
    }
    const confirmed = await Booking.findOne({
      where: { room_id: room.id, status: 'confirmed' }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if (room.status === 'rented' && status === 'available' && confirmed) {
      if (req.body.confirm_cancel_booking !== true) {
        await transaction.rollback();
        return res.status(409).json({ message: 'ກະລຸນາຢືນຢັນການຍົກເລີກການຈອງກ່ອນ' });
      }
      await confirmed.update({ status: 'cancelled' }, { transaction });
      const owner = await User.findByPk(req.user.id, { transaction });
      await createNotification(confirmed.tenant_id, 'booking_cancelled_by_system', {
        ...(await bookingSnapshot(confirmed, transaction)), owner_name: owner.name,
      }, { transaction });
    }
    await room.update({
      room_number: room_number.trim(), room_type: room_type.trim(), price: Number(price),
      description: description == null ? null : String(description).trim(), status,
    }, { transaction });
    await attachAmenities(room, amenityIds, transaction);
    await transaction.commit();
    const updated = await Room.findByPk(room.id, { include: roomInclude });
    return res.json({ room: updated });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    if (err.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ message: 'ເລກຫ້ອງນີ້ມີແລ້ວໃນທີ່ພັກນີ້' });
    }
    return res.status(500).json({ message: err.message });
  }
});

function haversineKm(lat1, lon1, lat2, lon2) {
  if ([lat1, lon1, lat2, lon2].some((v) => v === null || v === undefined || v === '')) {
    return null;
  }
  const toRad = (d) => (Number(d) * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 10) / 10;
}

async function attachAmenities(room, amenityIds, transaction) {
  if (!Array.isArray(amenityIds)) return;
  const amenities = await Amenity.findAll({
    where: { id: amenityIds },
    transaction,
  });
  await room.setAmenities(amenities, { transaction });
}

router.get('/', optionalAuth, async (req, res) => {
  try {
    const { province, district, minPrice, maxPrice, q, lat, lng } = req.query;
    const where = {};
    const propertyWhere = { approval_status: 'approved' };

    if (req.user?.role === 'admin' && req.query.all === '1') {
      delete propertyWhere.approval_status;
    }
    if (province) propertyWhere.province = province;
    if (district) propertyWhere.district = district;
    if (minPrice || maxPrice) {
      where.price = {};
      if (minPrice) where.price[Op.gte] = Number(minPrice);
      if (maxPrice) where.price[Op.lte] = Number(maxPrice);
    }
    if (q) {
      where[Op.or] = [
        { room_number: { [Op.like]: `%${q}%` } },
        { room_type: { [Op.like]: `%${q}%` } },
        { description: { [Op.like]: `%${q}%` } },
      ];
    }

    const rooms = await Room.findAll({
      where,
      include: roomInclude.map((inc) =>
        inc.as === 'property' ? { ...inc, where: propertyWhere, required: true } : inc,
      ),
      order: [['createdAt', 'DESC']],
    });

    const payload = rooms.map((room) => {
      const json = room.toJSON();
      json.distance_km = haversineKm(lat, lng, json.property?.latitude, json.property?.longitude);
      return json;
    });
    return res.json({ rooms: payload });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/:id', optionalAuth, async (req, res) => {
  try {
    const room = await Room.findByPk(req.params.id, { include: roomInclude });
    if (!room || !room.property) return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ ຫຼື ທີ່ພັກຖືກລຶບແລ້ວ' });
    if (
      room.property.approval_status !== 'approved' &&
      req.user?.role !== 'admin' &&
      req.user?.id !== room.property.owner_id
    ) {
      return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
    }
    const json = room.toJSON();
    json.distance_km = haversineKm(
      req.query.lat,
      req.query.lng,
      json.property?.latitude,
      json.property?.longitude,
    );
    return res.json({ room: json });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/status', authenticateToken, requireRole('owner'), async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const room = await Room.findByPk(req.params.id, {
      include: [{ model: Property, as: 'property' }], transaction, lock: transaction.LOCK.UPDATE,
    });
    if (!room || !room.property) {
      await transaction.rollback();
      return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
    }
    if (room.property.owner_id !== req.user.id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'ແກ້ໄຂໄດ້ສະເພາະຫ້ອງຂອງຕົນເອງ' });
    }
    const { status } = req.body;
    if (!['available', 'rented'].includes(status)) {
      await transaction.rollback();
      return res.status(400).json({ message: 'ສະຖານະຫ້ອງບໍ່ຖືກຕ້ອງ' });
    }
    const pending = await Booking.findOne({
      where: { room_id: room.id, status: 'pending' }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if (pending || room.status === 'pending') {
      await transaction.rollback();
      return res.status(409).json({ message: 'ກະລຸນາຢືນຢັນ ຫຼື ປະຕິເສດຄຳຂໍຈອງກ່ອນ' });
    }
    const confirmed = await Booking.findOne({
      where: { room_id: room.id, status: 'confirmed' }, transaction, lock: transaction.LOCK.UPDATE,
    });
    if (room.status === 'rented' && status === 'available' && confirmed) {
      if (req.body.confirm_cancel_booking !== true) {
        await transaction.rollback();
        return res.status(409).json({ message: 'ກະລຸນາຢືນຢັນການຍົກເລີກການຈອງກ່ອນ' });
      }
      await confirmed.update({ status: 'cancelled' }, { transaction });
      const owner = await User.findByPk(req.user.id, { transaction });
      await createNotification(confirmed.tenant_id, 'booking_cancelled_by_system', {
        ...(await bookingSnapshot(confirmed, transaction)), owner_name: owner.name,
      }, { transaction });
    }
    await room.update({ status }, { transaction });
    await transaction.commit();
    return res.json({ room });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    return res.status(500).json({ message: err.message });
  }
});
router.post(
  '/:id/images',
  authenticateToken,
  requireRole('owner', 'admin'),
  upload.array('images', 8),
  async (req, res) => {
    try {
      const room = await Room.findByPk(req.params.id, {
        include: [{ model: Property, as: 'property' }],
      });
      if (!room || !room.property) return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
      if (req.user.role === 'owner' && room.property.owner_id !== req.user.id) {
        return res.status(403).json({ message: 'ອັບໂຫຼດໄດ້ສະເພາະຫ້ອງຂອງຕົນເອງ' });
      }
      if (!req.files?.length) {
        return res.status(400).json({ message: 'ກະລຸນາເລືອກໄຟລ໌ຮູບ' });
      }
      const created = await RoomImage.bulkCreate(
        req.files.map((file) => ({
          room_id: room.id,
          image_url: `/uploads/${file.filename}`,
        })),
      );
      return res.status(201).json({ images: created });
    } catch (err) {
      return res.status(500).json({ message: err.message });
    }
  },
);

module.exports = { router, attachAmenities };
