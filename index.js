const express = require('express');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const alertsFile = path.join(__dirname, 'alerts.json');
let alerts = [];

try {
  if (fs.existsSync(alertsFile)) {
    alerts = JSON.parse(fs.readFileSync(alertsFile, 'utf8'));
  }
} catch (error) {
  console.warn('Could not read alerts.json, starting with empty alert list:', error);
}

const saveAlerts = () => {
  try {
    fs.writeFileSync(alertsFile, JSON.stringify(alerts, null, 2), 'utf8');
  } catch (error) {
    console.error('Failed to save alerts:', error);
  }
};

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
});

io.on('connection', (socket) => {
  console.log('Client connected', socket.id);
  socket.emit('alerts', alerts);
  socket.emit('server-status', { message: 'Offline hub ready' });

  socket.on('new-alert', (data) => {
    const alert = {
      id: Date.now().toString(),
      reporter: data.reporter || 'Unknown',
      location: data.location || 'Unknown location',
      message: data.message || '',
      type: data.type || 'SOS',
      timestamp: new Date().toISOString(),
    };
    alerts.unshift(alert);
    saveAlerts();
    io.emit('alert-received', alert);
    io.emit('alerts', alerts);
    console.log('New alert received:', alert);
  });

  socket.on('disconnect', (reason) => {
    console.log('Client disconnected', socket.id, reason);
  });
});

app.get('/alerts', (req, res) => {
  return res.json(alerts);
});

app.post('/alerts', (req, res) => {
  const { reporter, location, message, type } = req.body;
  if (!reporter || !location || !message) {
    return res.status(400).json({ error: 'reporter, location, and message are required' });
  }

  const alert = {
    id: Date.now().toString(),
    reporter,
    location,
    message,
    type: type || 'SOS',
    timestamp: new Date().toISOString(),
  };
  alerts.unshift(alert);
  saveAlerts();
  io.emit('alert-received', alert);
  io.emit('alerts', alerts);
  return res.status(201).json(alert);
});

const PORT = 3001;
const HOST = '0.0.0.0'; // Hotspot IP - change if different
server.listen(PORT, HOST, () => {
  console.log(`ReliefNet offline hub listening at http://${HOST}:${PORT}`);
  console.log('Connect phones to WiFi: ReliefNetHub, password: reliefnet2026');
});
