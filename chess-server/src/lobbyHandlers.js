// lobbyHandlers.js - Lobby-related message handlers

const { Chess } = require('chess.js');
const { lobbies, games, lastOpponents } = require('./state');
const { send, broadcastLobbyList } = require('./utils');

// Handle create_lobby message
function handleCreateLobby(socket, msg) {
  const id = msg.lobbyId || msg.roomCode || Math.random().toString(36).slice(2, 9).toUpperCase();
  const lobby = {
    id,
    host: socket,
    players: [socket],
    playerNames: [msg.playerName || socket.id],
    password: msg.password || "",
    open: true,
    mapFilters: {} // Initialize with empty filters (will use defaults)
  };
  lobbies.set(id, lobby);
  console.log(`[Lobby] Created lobby ${id} for socket ${socket.id}, sending confirmation...`);
  const confirmation = { type: 'lobby_created', lobbyId: id };
  console.log('[Lobby] Sending confirmation:', JSON.stringify(confirmation));
  send(socket, confirmation);
  broadcastLobbyList();
}

// Handle list_lobbies message
function handleListLobbies(socket, msg) {
  const lobbyList = [];
  for (const [id, l] of lobbies.entries()) {
    lobbyList.push({
      id,
      hostId: l.host.id,
      players: l.players.length,
      open: l.open,
      hasPassword: !!l.password,
      playerNames: l.playerNames
    });
  }
  send(socket, { type: 'lobby_list', lobbies: lobbyList });
}

// Handle join_lobby message
function handleJoinLobby(socket, msg) {
  const l = lobbies.get(msg.lobbyId);
  if (!l) return send(socket, { type: 'lobby_error', message: 'Lobby not found' });
  if (!l.open) return send(socket, { type: 'lobby_error', message: 'Lobby closed' });
  if (l.password && l.password !== (msg.password || "")) return send(socket, { type: 'lobby_error', message: 'Incorrect password' });
  if (!l.players.includes(socket)) {
    l.players.push(socket);
    l.playerNames.push(msg.playerName || socket.id);
  }
  l.open = l.players.length < 2;
  // notify lobby members
  for (const p of l.players) {
    send(p, {
      type: 'lobby_update',
      lobbyId: l.id,
      players: l.players.map(x => x.id),
      playerNames: l.playerNames,
      hostId: l.host.id,
      password: !!l.password,
      mapFilters: l.mapFilters
    });
  }
  broadcastLobbyList();
}

// Handle leave_lobby message
function handleLeaveLobby(socket, msg) {
  const l = lobbies.get(msg.lobbyId);
  if (!l) return;
  l.players = l.players.filter(p => p !== socket);
  l.playerNames = l.playerNames.filter((_, i) => l.players[i] != null);
  if (l.players.length === 0) {
    lobbies.delete(l.id);
  } else {
    if (l.host === socket) l.host = l.players[0];
    l.open = l.players.length < 2;
    for (const p of l.players) {
      send(p, {
        type: 'lobby_update',
        lobbyId: l.id,
        players: l.players.map(x => x.id),
        playerNames: l.playerNames,
        hostId: l.host.id,
        password: !!l.password,
        mapFilters: l.mapFilters
      });
    }
  }
  broadcastLobbyList();
}

// Handle set_map_filters message
function handleSetMapFilters(socket, msg) {
  const l = lobbies.get(msg.lobbyId);
  if (!l) return send(socket, { type: 'lobby_error', message: 'Lobby not found' });
  if (l.host !== socket) return send(socket, { type: 'error', message: 'Only host can set map filters' });

  // Update the lobby's map filters
  l.mapFilters = msg.filters || {};
  console.log(`[Lobby] Updated map filters for lobby ${msg.lobbyId}:`, l.mapFilters);

  // Notify all players in the lobby
  for (const p of l.players) {
    send(p, { type: 'map_filters_updated', lobbyId: l.id, filters: l.mapFilters });
  }
}

// Handle get_map_filters message
function handleGetMapFilters(socket, msg) {
  const l = lobbies.get(msg.lobbyId);
  if (!l) return send(socket, { type: 'lobby_error', message: 'Lobby not found' });
  send(socket, { type: 'map_filters', lobbyId: l.id, filters: l.mapFilters });
}

// Handle start_game message
function handleStartGame(socket, msg) {
  const l = lobbies.get(msg.lobbyId);
  if (!l) return;
  if (l.host !== socket) return; // only host can start
  if (l.players.length < 1) return; // need at least 1 player

  const gameId = Math.random().toString(36).slice(2, 9);
  const chess = new Chess();
  const p1 = l.players[0];
  const p2 = l.players.length >= 2 ? l.players[1] : null;
  const game = { white: p1, black: p2, chess, createdAt: Date.now(), mapFilters: l.mapFilters || {} };
  games.set(gameId, game);

  // Store opponents for rematch
  if (p1 && p2) {
    lastOpponents.set(p1, p2);
    lastOpponents.set(p2, p1);
  }

  send(p1, {
    type: 'game_start',
    gameId,
    isWhite: true,
    opponentId: p2 ? p2.id : null,
    fen: chess.fen(),
    turn: 'w'
  });
  if (p2) {
    send(p2, {
      type: 'game_start',
      gameId,
      isWhite: false,
      opponentId: p1.id,
      fen: chess.fen(),
      turn: 'w'
    });
  }

  // Keep the lobby alive for rematches instead of deleting it
  // Mark the lobby as "in game" so it doesn't show in the lobby list
  l.open = false;
  broadcastLobbyList();
  console.log(`[Stats] Active games: ${games.size}, Open lobbies: ${lobbies.size}`);
}

module.exports = {
  handleCreateLobby,
  handleListLobbies,
  handleJoinLobby,
  handleLeaveLobby,
  handleSetMapFilters,
  handleGetMapFilters,
  handleStartGame
};
