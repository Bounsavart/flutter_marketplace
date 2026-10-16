const cron = require('node-cron');
const { Op } = require('sequelize');
const { sequelize, Booking, Room, Property, User } = require('../models');
const { createNotification, bookingSnapshot } = require('../services/notifications');

async function cancelExpiredBookings(now = new Date()) {
  const transaction = await sequelize.transaction();
  try {
    const expired = await Booking.findAll({
      where: { status: 'pending', createdAt: { [Op.lt]: new Date(now.getTime() - 24 * 60 * 60 * 1000) } },
      include: [{ model: Room, as: 'room', include: [{ model: Property, as: 'property', include: [{ model: User, as: 'owner' }] }] }],
      transaction, lock: transaction.LOCK.UPDATE,
    });
    for (const booking of expired) {
      await booking.update({ status: 'cancelled' }, { transaction });
      await booking.room.update({ status: 'available' }, { transaction });
      await createNotification(booking.tenant_id, 'booking_auto_cancelled', {
        ...(await bookingSnapshot(booking, transaction)),
        owner_name: booking.room.property.owner?.name || '',
      }, { transaction });
    }
    await transaction.commit();
    return expired.length;
  } catch (error) {
    if (!transaction.finished) await transaction.rollback();
    throw error;
  }
}

function startAutoCancelJob() {
  cron.schedule('0 * * * *', () => {
    cancelExpiredBookings().catch((error) => console.error('Auto-cancel job failed', error));
  });
}

module.exports = { cancelExpiredBookings, startAutoCancelJob };
