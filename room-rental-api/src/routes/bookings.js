const express = require('express');
const { sequelize, Booking, Room, Property, User, RoomImage, Amenity, roomInclude } = require('../models');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { createNotification, bookingSnapshot } = require('../services/notifications');

const router = express.Router();

const bookingInclude = [
  {
    model: Room,
    as: 'room',
    paranoid: false,
    include: roomInclude.map((inc) => inc.as === 'property'
      ? { ...inc, paranoid: false, include: inc.include.map((nested) => ({ ...nested, paranoid: false })) }
      : inc),
  },
  { model: User, as: 'tenant', attributes: ['id', 'name', 'phone', 'email'], paranoid: false },
];

router.get('/my', authenticateToken, requireRole('tenant'), async (req, res) => {
  try {
    const bookings = await Booking.findAll({
      where: { tenant_id: req.user.id },
      include: bookingInclude,
      order: [['createdAt', 'DESC']],
    });
    return res.json({ bookings });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/owner', authenticateToken, requireRole('owner'), async (req, res) => {
  try {
    const bookings = await Booking.findAll({
      include: [
        { model: User, as: 'tenant', attributes: ['id', 'name', 'phone', 'email'], paranoid: false },
        {
          model: Room,
          as: 'room',
          paranoid: false,
          required: true,
          include: [
            { model: RoomImage, as: 'images' },
            { model: Amenity, as: 'amenities', through: { attributes: [] } },
            {
              model: Property,
              as: 'property',
              paranoid: false,
              required: true,
              where: { owner_id: req.user.id },
              include: [
                { model: User, as: 'owner', attributes: ['id', 'name', 'phone', 'email'], paranoid: false },
              ],
            },
          ],
        },
      ],
      order: [['createdAt', 'DESC']],
    });
    return res.json({ bookings });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.post('/', authenticateToken, requireRole('tenant'), async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { room_id } = req.body;
    if (!room_id) {
      await t.rollback();
      return res.status(400).json({ message: 'ກະລຸນາລະບຸຫ້ອງທີ່ຕ້ອງການຈອງ' });
    }

    const room = await Room.findByPk(room_id, {
      include: [{ model: Property, as: 'property' }],
      lock: t.LOCK.UPDATE,
      transaction: t,
    });
    if (!room || room.property.approval_status !== 'approved') {
      await t.rollback();
      return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ ຫຼື ຍັງບໍ່ໄດ້ຮັບການອະນຸມັດ' });
    }
    if (room.status !== 'available') {
      await t.rollback();
      return res.status(409).json({ message: 'ຫ້ອງນີ້ຖືກຈອງ ຫຼື ປ່ອຍເຊົ່າແລ້ວ' });
    }

    const booking = await Booking.create(
      { room_id: room.id, tenant_id: req.user.id, status: 'pending' },
      { transaction: t },
    );
    await room.update({ status: 'pending' }, { transaction: t });
    const tenant = await User.findByPk(req.user.id, { transaction: t });
    await createNotification(room.property.owner_id, 'booking_requested', {
      ...(await bookingSnapshot(booking, t)), tenant_name: tenant.name,
    }, { transaction: t });
    await t.commit();

    const full = await Booking.findByPk(booking.id, { include: bookingInclude });
    return res.status(201).json({ booking: full });
  } catch (err) {
    await t.rollback();
    return res.status(500).json({ message: err.message });
  }
});

async function loadOwnerBooking(id, ownerId, transaction) {
  const booking = await Booking.findByPk(id, {
    include: [
      {
        model: Room,
        as: 'room',
        include: [{ model: Property, as: 'property' }],
      },
    ],
    transaction,
    lock: transaction.LOCK.UPDATE,
  });
  if (!booking) return { error: { status: 404, message: 'ບໍ່ພົບການຈອງ' } };
  if (booking.room.property.owner_id !== ownerId) {
    return { error: { status: 403, message: 'ຈັດການໄດ້ສະເພາະການຈອງຂອງທີ່ພັກຕົນເອງ' } };
  }
  return { booking };
}

router.patch('/:id/confirm', authenticateToken, requireRole('owner'), async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { booking, error } = await loadOwnerBooking(req.params.id, req.user.id, t);
    if (error) {
      await t.rollback();
      return res.status(error.status).json({ message: error.message });
    }
    if (booking.status !== 'pending') {
      await t.rollback();
      return res.status(400).json({ message: 'ຢືນຢັນໄດ້ສະເພາະຄຳຂໍທີ່ລໍຖ້າຢູ່' });
    }
    await booking.update({ status: 'confirmed' }, { transaction: t });
    await booking.room.update({ status: 'rented' }, { transaction: t });
    const snapshot = await bookingSnapshot(booking, t);
    const owner = await User.findByPk(req.user.id, { transaction: t });
    await createNotification(booking.tenant_id, 'booking_confirmed', { ...snapshot, owner_name: owner.name }, { transaction: t });
    await t.commit();
    const full = await Booking.findByPk(booking.id, { include: bookingInclude });
    return res.json({ booking: full });
  } catch (err) {
    await t.rollback();
    return res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/reject', authenticateToken, requireRole('owner'), async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { booking, error } = await loadOwnerBooking(req.params.id, req.user.id, t);
    if (error) {
      await t.rollback();
      return res.status(error.status).json({ message: error.message });
    }
    if (booking.status !== 'pending') {
      await t.rollback();
      return res.status(400).json({ message: 'ປະຕິເສດໄດ້ສະເພາະຄຳຂໍທີ່ລໍຖ້າຢູ່' });
    }
    await booking.update({ status: 'rejected' }, { transaction: t });
    await booking.room.update({ status: 'available' }, { transaction: t });
    const snapshot = await bookingSnapshot(booking, t);
    const owner = await User.findByPk(req.user.id, { transaction: t });
    await createNotification(booking.tenant_id, 'booking_rejected', { ...snapshot, owner_name: owner.name }, { transaction: t });
    await t.commit();
    const full = await Booking.findByPk(booking.id, { include: bookingInclude });
    return res.json({ booking: full });
  } catch (err) {
    await t.rollback();
    return res.status(500).json({ message: err.message });
  }
});

router.patch('/:id/cancel', authenticateToken, requireRole('tenant'), async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const booking = await Booking.findByPk(req.params.id, {
      include: [{ model: Room, as: 'room', include: [{ model: Property, as: 'property' }] }],
      transaction: t,
      lock: t.LOCK.UPDATE,
    });
    if (!booking) {
      await t.rollback();
      return res.status(404).json({ message: 'ບໍ່ພົບການຈອງ' });
    }
    if (booking.tenant_id !== req.user.id) {
      await t.rollback();
      return res.status(403).json({ message: 'ຍົກເລີກໄດ້ສະເພາະການຈອງຂອງຕົນເອງ' });
    }
    if (booking.status !== 'pending') {
      await t.rollback();
      return res.status(400).json({ message: 'ຍົກເລີກໄດ້ສະເພາະຄຳຂໍທີ່ລໍຖ້າຢູ່' });
    }
    await booking.update({ status: 'cancelled' }, { transaction: t });
    await booking.room.update({ status: 'available' }, { transaction: t });
    const snapshot = await bookingSnapshot(booking, t);
    const tenant = await User.findByPk(req.user.id, { transaction: t });
    await createNotification(booking.room.property.owner_id, 'booking_cancelled_by_tenant', { ...snapshot, tenant_name: tenant.name }, { transaction: t });
    await t.commit();
    const full = await Booking.findByPk(booking.id, { include: bookingInclude });
    return res.json({ booking: full });
  } catch (err) {
    await t.rollback();
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;
