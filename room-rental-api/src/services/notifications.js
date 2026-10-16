const { Notification, User, Room, Property, Booking } = require('../models');

const socketsByUser = new Map();

function attachSocket(userId, socket) {
  if (!socketsByUser.has(userId)) socketsByUser.set(userId, new Set());
  const sockets = socketsByUser.get(userId);
  sockets.add(socket);
  socket.once('close', () => {
    sockets.delete(socket);
    if (!sockets.size) socketsByUser.delete(userId);
  });
}

async function push(userId, notification) {
  const sockets = socketsByUser.get(Number(userId));
  if (!sockets?.size) return;
  const user = await User.findByPk(userId);
  if (!user) {
    for (const socket of sockets) socket.close(1008, 'account unavailable');
    return;
  }
  const message = JSON.stringify({ type: 'notification', notification });
  for (const socket of sockets) if (socket.readyState === 1) socket.send(message);
}

async function createNotification(userId, type, data, { transaction } = {}) {
  const notification = await Notification.create({ user_id: userId, type, data, is_read: false }, { transaction });
  const payload = notification.toJSON();
  if (transaction) transaction.afterCommit(() => { void push(userId, payload).catch(() => {}); });
  else await push(userId, payload);
  return notification;
}

async function bookingSnapshot(booking, transaction) {
  const row = await Booking.findByPk(booking.id || booking, {
    transaction,
    include: [
      { model: Room, as: 'room', paranoid: false, include: [{ model: Property, as: 'property', paranoid: false,
        include: [{ model: User, as: 'owner', paranoid: false, attributes: ['id', 'name'] }] }] },
      { model: User, as: 'tenant', paranoid: false, attributes: ['id', 'name'] },
    ],
  });
  if (!row?.room) return { booking_id: row?.id || booking.id || booking };
  return {
    booking_id: row.id, room_id: row.room.id, property_id: row.room.property?.id || null,
    room_number: row.room.room_number, property_name: row.room.property?.name || '',
    owner_name: row.room.property?.owner?.name || '', tenant_name: row.tenant?.name || '',
  };
}

module.exports = { attachSocket, createNotification, bookingSnapshot };
