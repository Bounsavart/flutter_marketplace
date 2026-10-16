const express = require('express');
const { sequelize, Property, Room, User, roomInclude } = require('../models');
const { createNotification } = require('../services/notifications');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { attachAmenities } = require('./rooms');
const { deleteProperty } = require('./deletion');

const router = express.Router();

router.delete('/:id', authenticateToken, requireRole('owner', 'admin'), deleteProperty);

const ownerInclude = [
  {
    model: Room,
    as: 'rooms',
    include: roomInclude.filter((inc) => inc.as !== 'property'),
  },
];

router.get('/', authenticateToken, async (req, res) => {
  try {
    const where = { approval_status: 'approved' };
    if (req.user.role === 'admin' && req.query.all === '1') {
      delete where.approval_status;
    }
    const properties = await Property.findAll({
      where,
      include: [
        ...ownerInclude,
        { model: User, as: 'owner', attributes: ['id', 'name', 'phone', 'email'] },
      ],
      order: [['createdAt', 'DESC']],
    });
    return res.json({ properties });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/my', authenticateToken, requireRole('owner'), async (req, res) => {
  try {
    const properties = await Property.findAll({
      where: { owner_id: req.user.id },
      include: ownerInclude,
      order: [['createdAt', 'DESC']],
    });
    return res.json({ properties });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const property = await Property.findByPk(req.params.id, {
      include: [
        ...ownerInclude,
        { model: User, as: 'owner', attributes: ['id', 'name', 'phone', 'email'] },
      ],
    });
    if (!property) return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' });

    const isOwner = property.owner_id === req.user.id;
    const isAdmin = req.user.role === 'admin';
    if (property.approval_status !== 'approved' && !isOwner && !isAdmin) {
      return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' });
    }
    return res.json({ property });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.post('/', authenticateToken, requireRole('owner'), async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const { name, description, province, district, address, latitude, longitude, room } = req.body;
    if (!name || !province || !district || !address) {
      await transaction.rollback();
      return res.status(400).json({ message: 'ກະລຸນາປ້ອນຊື່, ແຂວງ, ເມືອງ ແລະ ທີ່ຢູ່' });
    }

    const property = await Property.create({
      owner_id: req.user.id,
      name,
      description,
      province,
      district,
      address,
      latitude: latitude || null,
      longitude: longitude || null,
      approval_status: 'pending',
    }, { transaction });

    if (room?.room_number && room?.room_type && room?.price != null) {
      const createdRoom = await Room.create({
        property_id: property.id,
        room_number: room.room_number,
        room_type: room.room_type,
        price: room.price,
        description: room.description || null,
        status: 'available',
      }, { transaction });
      await attachAmenities(createdRoom, room.amenityIds, transaction);
    }

    const admins = await User.findAll({ where: { role: 'admin' }, transaction });
    for (const admin of admins) await createNotification(admin.id, 'property_pending_review', { property_id: property.id, property_name: property.name }, { transaction });
    await transaction.commit();
    const full = await Property.findByPk(property.id, { include: ownerInclude });
    return res.status(201).json({ property: full });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    return res.status(500).json({ message: err.message });
  }
});

router.patch('/:id', authenticateToken, requireRole('owner', 'admin'), async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const property = await Property.findByPk(req.params.id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!property) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' }); }
    if (req.user.role === 'owner' && property.owner_id !== req.user.id) {
      await transaction.rollback();
      return res.status(403).json({ message: 'ແກ້ໄຂໄດ້ສະເພາະທີ່ພັກຂອງຕົນເອງ' });
    }

    const fields = ['name', 'description', 'province', 'district', 'address', 'latitude', 'longitude'];
    const updates = {};
    const wasPending = property.approval_status === 'pending';

    for (const key of fields) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    if (req.user.role === 'owner' && Object.keys(updates).length > 0) {
      updates.approval_status = 'pending';
    }
    await property.update(updates, { transaction });
    if (updates.approval_status === 'pending' && !wasPending) {
      const admins = await User.findAll({ where: { role: 'admin' }, transaction });
      for (const admin of admins) await createNotification(admin.id, 'property_pending_review', { property_id: property.id, property_name: property.name }, { transaction });
    }
    await transaction.commit();
    const full = await Property.findByPk(property.id, { include: ownerInclude });
    return res.json({ property: full });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    return res.status(500).json({ message: err.message });
  }
});

router.post('/:id/rooms', authenticateToken, requireRole('owner'), async (req, res) => {
  try {
    const property = await Property.findByPk(req.params.id);
    if (!property) return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' });
    if (property.owner_id !== req.user.id) {
      return res.status(403).json({ message: 'ເພີ່ມຫ້ອງໄດ້ສະເພາະທີ່ພັກຂອງຕົນເອງ' });
    }
    const { room_number, room_type, price, description, amenityIds } = req.body;
    if (!room_number || !room_type || price == null) {
      return res.status(400).json({ message: 'ກະລຸນາປ້ອນເລກຫ້ອງ, ປະເພດ ແລະ ລາຄາ' });
    }
    const room = await Room.create({
      property_id: property.id,
      room_number,
      room_type,
      price,
      description: description || null,
      status: 'available',
    });
    await attachAmenities(room, amenityIds);
    const full = await Room.findByPk(room.id, { include: roomInclude });
    return res.status(201).json({ room: full });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;
