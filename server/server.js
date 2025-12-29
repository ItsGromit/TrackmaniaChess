// server.js (authoritative, raw TCP, NDJSON protocol)
const net = require('net');
const express = require('express');
const cors = require('cors');
const path = require('path');
const { TCP_PORT, STATS_INTERVAL } = require('./src/config');
const { clients, games, lobbies } = require('./src/state');
const { send } = require('./src/utils');
const { onMessage } = require('./src/messageRouter');
const { cleanupOnDisconnect } = require('./src/cleanup');

// ---------- HTTP server for static assets ----------
const app = express();
// Railway sets PORT for HTTP, we use it for assets
// For local development, defaults to 3000
const HTTP_PORT = Number(process.env.PORT || 3000);

// Enable CORS for all origins (needed for Openplanet plugin)
app.use(cors());

// Serve static files from the assets directory
app.use('/assets', express.static(path.join(__dirname, 'assets')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start HTTP server
app.listen(HTTP_PORT, () => {
  console.log(`HTTP asset server listening on port ${HTTP_PORT}`);
  console.log(`Assets available at: https://trackmaniachess.up.railway.app/assets/`);
});

// ---------- TCP server / NDJSON framing ----------
const server = net.createServer((socket) => {
  socket.id = Math.random().toString(36).slice(2, 9);
  socket.setEncoding('utf8');
  clients.add(socket);

  let buf = '';
  socket.on('data', (chunk) => {
    buf += chunk;
    let idx;
    while ((idx = buf.indexOf('\n')) !== -1) {
      const line = buf.slice(0, idx).trim();
      buf = buf.slice(idx + 1);
      if (!line) continue;
      try {
        onMessage(socket, JSON.parse(line));
      } catch (e) {
        send(socket, { type: 'error', code: 'BAD_JSON' });
      }
    }
  });

  socket.on('close', () => {
    clients.delete(socket);
    cleanupOnDisconnect(socket);
  });

  socket.on('error', (e) => {
    clients.delete(socket);
    cleanupOnDisconnect(socket);
  });

  // immediate hello
  send(socket, { type: 'hello', id: socket.id });
});

server.listen(TCP_PORT, () => {
  console.log(`Authoritative TCP chess server listening on ${TCP_PORT}`);
});
