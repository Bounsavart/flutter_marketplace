const express = require('express');
const { sequelize, User, Booking, Room, Property, Favorite } = require('../models');
const { Op } = require('sequelize');
const { authenticateToken, requireRole } = require('../middleware/auth');
const { blockedMessage, deletePropertyTree } = require('./deletion');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const router = express.Router();

router.delete('/me', authenticateToken, requireRole('tenant', 'owner'), async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const user = await User.findByPk(req.user.id, { transaction, lock: transaction.LOCK.UPDATE });
    if (!user) { await transaction.rollback(); return res.status(404).json({ message: 'ບໍ່ພົບບັນຊີ' }); }
    const ownedRooms = user.role === 'owner'
      ? await Room.findAll({ include: [{ association: 'property', where: { owner_id: user.id } }], transaction })
      : [];
    const active = await Booking.findAll({
      where: { status: { [Op.in]: ['pending', 'confirmed'] }, ...(user.role === 'tenant' ? { tenant_id: user.id } : { room_id: ownedRooms.map((r) => r.id) }) },
      transaction, lock: transaction.LOCK.UPDATE,
    });
    if (active.length) { await transaction.rollback(); return res.status(409).json({ message: blockedMessage }); }
    if (user.role === 'tenant') await Favorite.destroy({ where: { tenant_id: user.id }, transaction });
    if (user.role === 'owner') {
      const properties = await Property.findAll({ where: { owner_id: user.id }, transaction });
      for (const property of properties) await deletePropertyTree(property, transaction);
    }
    await user.destroy({ transaction });
    await transaction.commit();
    return res.json({ deleted: true });
  } catch (err) { await transaction.rollback(); return res.status(500).json({ message: err.message }); }
});

function signToken(user) {
  return jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: '7d',
  });
}

function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    createdAt: user.createdAt,
  };
}

router.post('/register', async (req, res) => {
  try {
    const { name, email, phone, password, role } = req.body;
    if (!name || !email || !password || !role) {
      return res.status(400).json({ message: 'ກະລຸນາປ້ອນຊື່, ອີເມວ, ລະຫັດຜ່ານ ແລະ ບົດບາດ' });
    }
    if (!['tenant', 'owner'].includes(role)) {
      return res.status(400).json({ message: 'ສະໝັກໄດ້ສະເພາະຜູ້ເຊົ່າ ຫຼື ເຈົ້າຂອງຫ້ອງ' });
    }
    const exists = await User.findOne({ where: { email } });
    if (exists) {
      return res.status(409).json({ message: 'ອີເມວນີ້ຖືກໃຊ້ແລ້ວ' });
    }
    const password_hash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, phone, password_hash, role });
    return res.status(201).json({
      token: signToken(user),
      user: publicUser(user),
    });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ message: 'ກະລຸນາປ້ອນອີເມວ ແລະ ລະຫັດຜ່ານ' });
    }
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(401).json({ message: 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ' });
    }
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ message: 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ' });
    }
    return res.json({ token: signToken(user), user: publicUser(user) });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id);
    if (!user) return res.status(404).json({ message: 'ບໍ່ພົບຜູ້ໃຊ້' });

    let extra = {};
    if (user.role === 'tenant') {
      extra = {
        favoriteCount: await Favorite.count({ where: { tenant_id: user.id } }),
        bookingCount: await Booking.count({ where: { tenant_id: user.id } }),
      };
    }

    return res.json({ user: { ...publicUser(user), ...extra } });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;
