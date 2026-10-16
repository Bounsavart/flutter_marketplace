const express = require('express');
const { Amenity } = require('../models');

const router = express.Router();

router.get('/', async (_req, res) => {
  try {
    const amenities = await Amenity.findAll({ order: [['name', 'ASC']] });
    return res.json({ amenities });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;
