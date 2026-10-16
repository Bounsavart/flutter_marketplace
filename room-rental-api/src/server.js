require('dotenv').config();

const express = require('express');
const http = require('http');
const jwt = require('jsonwebtoken');
const WebSocket = require('ws');
const cors = require('cors');
const path = require('path');
const { sequelize } = require('./models');
const { syncDatabase } = require('./config/sync');
const authRoutes = require('./routes/auth');
const propertyRoutes = require('./routes/properties');
const { router: roomRoutes } = require('./routes/rooms');
const bookingRoutes = require('./routes/bookings');
const favoriteRoutes = require('./routes/favorites');
const adminRoutes = require('./routes/admin');
const amenityRoutes = require('./routes/amenities');
const notificationRoutes = require('./routes/notifications');
const { attachSocket } = require('./services/notifications');
const { User } = require('./models');
const { startAutoCancelJob } = require('./jobs/autoCancel');

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/api/health', (_req, res) => res.json({ ok: true }));
app.use('/api/auth', authRoutes);
app.use('/api/properties', propertyRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/favorites', favoriteRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/amenities', amenityRoutes);
app.use('/api/notifications', notificationRoutes);

app.use((err, _req, res, _next) => {
  res.status(400).json({ message: err.message || 'ເກີດຂໍ້ຜິດພາດ' });
});

async function start() {
  await sequelize.authenticate();
  await syncDatabase();
  const server = http.createServer(app);
  const wss = new WebSocket.Server({ server, path: '/ws' });
  wss.on('connection', (socket) => {
    let authenticated = false;
    const authTimeout = setTimeout(() => socket.close(1008, 'authentication required'), 5000);
    socket.on('message', async (raw) => {
      if (authenticated) return;
      try {
        const auth = JSON.parse(raw.toString());
        if (auth.type !== 'auth' || typeof auth.token !== 'string') throw new Error('invalid auth');
        const claims = jwt.verify(auth.token, process.env.JWT_SECRET);
        const user = await User.findByPk(claims.id);
        if (!user) throw new Error('account unavailable');
        authenticated = true;
        clearTimeout(authTimeout);
        socket.userId = user.id;
        attachSocket(user.id, socket);
        socket.send(JSON.stringify({ type: 'authenticated' }));
      } catch (_err) { clearTimeout(authTimeout); socket.close(1008, 'invalid authentication'); }
    });
    socket.on('pong', () => { socket.isAlive = true; });
    socket.isAlive = true;
  });
  const heartbeat = setInterval(() => {
    for (const socket of wss.clients) {
      if (!socket.isAlive) { socket.terminate(); continue; }
      socket.isAlive = false;
      socket.ping();
    }
  }, 30000);
  server.on('close', () => clearInterval(heartbeat));
  startAutoCancelJob();
  server.listen(port, '0.0.0.0', () => {
    console.log(`Room rental API running on http://localhost:${port}`);
  });
}

start().catch((err) => {
  console.error('Failed to start API', err);
  process.exit(1);
});
