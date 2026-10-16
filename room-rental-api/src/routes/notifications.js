const express = require('express');
const { Op } = require('sequelize');
const { Notification } = require('../models');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();
router.use(authenticateToken);

router.get('/', async (req, res) => {
  try {
    const limit = Math.min(100, Math.max(1, Number.parseInt(req.query.limit, 10) || 20));
    const where = { user_id: req.user.id };
    if (req.query.before) where.id = { [Op.lt]: Number(req.query.before) };
    const notifications = await Notification.findAll({ where, limit, order: [['createdAt', 'DESC'], ['id', 'DESC']] });
    return res.json({ notifications, nextBefore: notifications.length === limit ? notifications.at(-1).id : null });
  } catch (err) { return res.status(500).json({ message: 'ບໍ່ສາມາດໂຫຼດການແຈ້ງເຕືອນໄດ້' }); }
});

router.get('/unread-count', async (req, res) => {
  try { return res.json({ count: await Notification.count({ where: { user_id: req.user.id, is_read: false } }) }); }
  catch (_err) { return res.status(500).json({ message: 'ບໍ່ສາມາດໂຫຼດການແຈ້ງເຕືອນໄດ້' }); }
});

router.patch('/read-all', async (req, res) => {
  try {
    await Notification.update({ is_read: true }, { where: { user_id: req.user.id, is_read: false } });
    return res.json({ updated: true });
  } catch (_err) { return res.status(500).json({ message: 'ບໍ່ສາມາດແກ້ໄຂການແຈ້ງເຕືອນໄດ້' }); }
});

router.patch('/:id/read', async (req, res) => {
  try {
    const item = await Notification.findByPk(req.params.id);
    if (!item) return res.status(404).json({ message: 'ບໍ່ພົບການແຈ້ງເຕືອນ' });
    if (item.user_id !== req.user.id) return res.status(403).json({ message: 'ບໍ່ມີສິດເຂົ້າເຖິງ' });
    if (!item.is_read) await item.update({ is_read: true });
    return res.json({ notification: item });
  } catch (_err) { return res.status(500).json({ message: 'ບໍ່ສາມາດແກ້ໄຂການແຈ້ງເຕືອນໄດ້' }); }
});

module.exports = router;
