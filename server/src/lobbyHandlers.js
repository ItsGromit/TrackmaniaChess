// lobbyHandlers.js - Lobby-related message handlers

const { Chess } = require('chess.js');
const { lobbies, games, lastOpponents } = require('./state');
const { send, broadcastLobbyList } = require('./utils');

// Handle create_lobby message
function handleCreateLobby(socket, msg) {
  const id = msg.lobbyId || msg.roomCode || Math.random().toString(36).slice(2, 9).toUpperCase();
  const lobby = {
    id,
    title: msg.title || "",  // Store the lobby title
    host: socket,
    players: [socket],
    playerNames: [msg.playerName || socket.id],
    password: msg.password || "",
    open: true,
    raceMode: msg.raceMode || "capture",  // Store race mode
    mapFilters: {}, // Initialize with empty filters (will use defaults)
    mappackId: msg.mappackId || 7237 // Store mappack ID for Chess Race mode (default to 7237)
  };
  lobbies.set(id, lobby);
  console.log(`[Lobby] Created lobby ${id}${lobby.title ? ` (${lobby.title})` : ''} [${lobby.raceMode}]${lobby.raceMode === 'square' ? ` (mappack: ${lobby.mappackId})` : ''} for socket ${socket.id}, sending confirmation...`);
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
      title: l.title || "",  // Include title in lobby list
      hostId: l.host.id,
      players: l.players.length,
      open: l.open,
      hasPassword: !!l.password,
      playerNames: l.playerNames,
      raceMode: l.raceMode || "capture"  // Include race mode
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

  // Failsafe: Ensure maximum 2 players in a lobby
  if (!l.players.includes(socket)) {
    if (l.players.length >= 2) {
      return send(socket, { type: 'error', code: 'LOBBY_FULL', message: 'Lobby is full (maximum 2 players)' });
    }
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
  if (l.players.length !== 2) {
    // Game requires exactly 2 players
    send(socket, {
      type: 'error',
      code: 'INVALID_PLAYER_COUNT',
      message: 'Need exactly 2 players to start the game'
    });
    return;
  }

  const gameId = Math.random().toString(36).slice(2, 9);
  const chess = new Chess();
  const p1 = l.players[0];
  const p2 = l.players[1];

  // Randomly assign colors
  const p1IsWhite = Math.random() < 0.5;
  const white = p1IsWhite ? p1 : p2;
  const black = p1IsWhite ? p2 : p1;

  const game = { white, black, chess, createdAt: Date.now(), mapFilters: l.mapFilters || {} };
  games.set(gameId, game);

  // Store opponents for rematch
  if (p1 && p2) {
    lastOpponents.set(p1, p2);
    lastOpponents.set(p2, p1);
  }

  send(p1, {
    type: 'game_start',
    gameId,
    isWhite: p1IsWhite,
    opponentId: p2.id,
    fen: chess.fen(),
    turn: 'w',
    raceMode: l.raceMode,
    mappackId: l.mappackId
  });
  send(p2, {
    type: 'game_start',
    gameId,
    isWhite: !p1IsWhite,
    opponentId: p1.id,
    fen: chess.fen(),
    turn: 'w',
    raceMode: l.raceMode,
    mappackId: l.mappackId
  });

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
