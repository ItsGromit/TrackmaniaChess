// utils.js - Utility functions

const { lobbies, clients } = require('./state');

// Send a message to a client
function send(c, obj) {
  if (!c) {
    console.error('[Send] No socket provided');
    return;
  }
  try {
    const data = JSON.stringify(obj) + '\n';
    console.log(`[Send] Sending to ${c.id}:`, obj.type || 'unknown');
    c.write(data);
  } catch (e) {
    console.error('[Send] Write error:', e);
  }
}

// Broadcast message to both players in a game
function broadcastPlayers(game, obj) {
  if (game.white) send(game.white, obj);
  if (game.black) send(game.black, obj);
}

// Convert to algebraic notation
function toAlgebra(s) {
  return s && typeof s === 'string' ? s : null;
}

// Get list of lobbies for broadcast
function lobbyList() {
  const list = [];
  for (const [id, l] of lobbies.entries()) {
    list.push({
      id,
      title: l.title || "",  // Include title in lobby list
      hostId: l.host.id,
      players: l.players.length,
      open: l.open,
      hasPassword: !!l.password,
      playerNames: l.playerNames,
      raceMode: l.raceMode || "capture"  // Include race mode
    });
  }
  return list;
}

// Broadcast lobby list to all connected clients
function broadcastLobbyList() {
  const msg = { type: 'lobby_list', lobbies: lobbyList() };
  for (const c of clients) send(c, msg);
}

module.exports = {
  send,
  broadcastPlayers,
  toAlgebra,
  lobbyList,
  broadcastLobbyList
};
