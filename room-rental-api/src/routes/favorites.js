const express = require('express');
const { Favorite, Room, roomInclude } = require('../models');
const { authenticateToken, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/my', authenticateToken, requireRole('tenant'), async (req, res) => {
  try {
    const favorites = await Favorite.findAll({
      where: { tenant_id: req.user.id },
      include: [{ model: Room, as: 'room', required: true, include: roomInclude.map((inc) => inc.as === 'property' ? { ...inc, required: true } : inc) }],
      order: [['createdAt', 'DESC']],
    });
    return res.json({ favorites });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.get('/:roomId', authenticateToken, requireRole('tenant'), async (req, res) => {
  try {
    const roomId = Number(req.params.roomId);
    const existing = await Favorite.findOne({
      where: { tenant_id: req.user.id, room_id: roomId },
    });
    if (req.query.check === '1') {
      return res.json({ favorited: Boolean(existing), favorite: existing });
    }
    if (existing) {
      return res.json({ favorite: existing, favorited: true });
    }
    const room = await Room.findByPk(roomId);
    if (!room) return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
    const favorite = await Favorite.create({
      tenant_id: req.user.id,
      room_id: roomId,
    });
    return res.status(201).json({ favorite, favorited: true });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.post('/:roomId', authenticateToken, requireRole('tenant'), async (req, res) => {
  try {
    const roomId = Number(req.params.roomId);
    const room = await Room.findByPk(roomId);
    if (!room) return res.status(404).json({ message: 'ບໍ່ພົບຫ້ອງ' });
    const [favorite] = await Favorite.findOrCreate({
      where: { tenant_id: req.user.id, room_id: roomId },
      defaults: { tenant_id: req.user.id, room_id: roomId },
    });
    return res.status(201).json({ favorite, favorited: true });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

router.delete('/:roomId', authenticateToken, requireRole('tenant'), async (req, res) => {
  try {
    const favorite = await Favorite.findOne({ where: { room_id: Number(req.params.roomId) } });
    if (!favorite) return res.status(404).json({ message: 'ບໍ່ພົບລາຍການທີ່ມັກ' });
    if (favorite.tenant_id !== req.user.id) return res.status(403).json({ message: 'ທ່ານສາມາດລຶບລາຍການມັກຂອງຕົນເອງເທົ່ານັ້ນ' });
    const deleted = await favorite.destroy();
    if (!deleted) return res.status(404).json({ message: 'ບໍ່ພົບລາຍການທີ່ມັກ' });
    return res.json({ favorited: false });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;
