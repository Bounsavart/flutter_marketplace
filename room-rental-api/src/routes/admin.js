const express = require('express');
const { Op } = require('sequelize');
const { sequelize, User, Property, Room, Booking, Favorite } = require('../models');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { activeBookings, cancelBookings, deletePropertyTree } = require('./deletion');
const { createNotification } = require('../services/notifications');

const router = express.Router();

router.use(authenticateToken, requireRole('admin'));

router.get('/stats', async (_req, res) => {
  try {
    const [users, owners, tenants, properties, pendingProperties, rooms, bookings] =
      await Promise.all([
        User.count(),
        User.count({ where: { role: 'owner' } }),
        User.count({ where: { role: 'tenant' } }),
        Property.count(),
        Property.count({ where: { approval_status: 'pending' } }),
        Room.count(),
        Booking.count(),
      ]);
    return res.json({
      stats: { users, owners, tenants, properties, pendingProperties, rooms, bookings },
    });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.delete('/users/:id', async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const user = await User.findByPk(req.params.id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບຜູ້ໃຊ້' }); }
    if (user.id === req.user.id || user.role === 'admin') { await transaction.rollback(); return res.status(403).json({ message: 'ບໍ່ສາມາດລຶບບັນຊີຜູ້ດູແລລະບົບໄດ້' }); }
    let cancelledBookings = 0;
    if (user.role === 'tenant') {
      const bookings = await Booking.findAll({ where: { tenant_id: user.id, status: ['pending', 'confirmed'] }, transaction, lock: transaction.LOCK.UPDATE });
      cancelledBookings = await cancelBookings(bookings, transaction);
      await Favorite.destroy({ where: { tenant_id: user.id }, transaction });
    } else if (user.role === 'owner') {
      const properties = await Property.findAll({ where: { owner_id: user.id }, transaction, lock: transaction.LOCK.UPDATE });
      const rooms = await Room.findAll({ where: { property_id: properties.map((p) => p.id) }, transaction, lock: transaction.LOCK.UPDATE });
      const bookings = await activeBookings(rooms.map((r) => r.id), transaction);
      cancelledBookings = await cancelBookings(bookings, transaction);
      for (const property of properties) await deletePropertyTree(property, transaction);
      await Favorite.destroy({ where: { room_id: rooms.map((r) => r.id) }, transaction });
    }
    await user.destroy({ transaction });
    await transaction.commit();
    return res.json({ deleted: true, cancelledBookings });
  } catch (err) { await transaction.rollback(); return res.status(500).json({ message: err.message }); }
});

router.get('/users', async (req, res) => {
  try {
    const { role, q } = req.query;
    const where = {};
    if (role) where.role = role;
    if (q) {
      where[Op.or] = [
        { name: { [Op.like]: `%${q}%` } },
        { email: { [Op.like]: `%${q}%` } },
        { phone: { [Op.like]: `%${q}%` } },
      ];
    }
    const users = await User.findAll({
      where,
      attributes: ['id', 'name', 'email', 'phone', 'role', 'createdAt'],
      order: [['createdAt', 'DESC']],
    });
    return res.json({ users });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/properties/pending', async (_req, res) => {
  try {
    const properties = await Property.findAll({
      where: { approval_status: 'pending' },
      include: [
        { model: User, as: 'owner', attributes: ['id', 'name', 'email', 'phone'] },
        { model: Room, as: 'rooms' },
      ],
      order: [['createdAt', 'ASC']],
    });
    return res.json({ properties });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.patch('/properties/:id/approve', async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const property = await Property.findByPk(req.params.id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!property) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' }); }
    if (property.approval_status !== 'pending') { await transaction.rollback(); return res.status(409).json({ message: 'ທີ່ພັກນີ້ຖືກພິຈາລະນາແລ້ວ' }); }
    await property.update({ approval_status: 'approved' }, { transaction });
    await createNotification(property.owner_id, 'property_approved', { property_id: property.id, property_name: property.name }, { transaction });
    await transaction.commit();
    return res.json({ property });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    return res.status(500).json({ message: err.message });
  }
});

router.patch('/properties/:id/reject', async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const property = await Property.findByPk(req.params.id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!property) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບທີ່ພັກ' }); }
    if (property.approval_status !== 'pending') { await transaction.rollback(); return res.status(409).json({ message: 'ທີ່ພັກນີ້ຖືກພິຈາລະນາແລ້ວ' }); }
    await property.update({ approval_status: 'rejected' }, { transaction });
    await createNotification(property.owner_id, 'property_rejected', { property_id: property.id, property_name: property.name }, { transaction });
    await transaction.commit();
    return res.json({ property });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    return res.status(500).json({ message: err.message });
  }
});
module.exports = router;
