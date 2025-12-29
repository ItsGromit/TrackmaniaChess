// server.js (authoritative, raw TCP, NDJSON protocol)
const net = require('net');
const { TCP_PORT, STATS_INTERVAL } = require('./src/config');
const { clients, games, lobbies } = require('./src/state');
const { send } = require('./src/utils');
const { onMessage } = require('./src/messageRouter');
const { cleanupOnDisconnect } = require('./src/cleanup');

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
