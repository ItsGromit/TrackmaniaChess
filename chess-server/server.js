// server.js (authoritative, raw TCP, NDJSON protocol)
const net = require('net');
const { Chess } = require('chess.js');

// ---------- State ----------
const games = new Map();     // gameId -> { white:Socket, black:Socket, chess:Chess, createdAt:number }
const lobbies = new Map();   // lobbyId -> { id, host:Socket, players:Socket[], playerNames:string[], password:string, open:boolean }
const clients = new Set();   // connected sockets

// ---------- Utils ----------
function send(c, obj) {
  if (!c) return;
  try { c.write(JSON.stringify(obj) + '\n'); } catch (e) { console.error('write error', e); }
}
function broadcastPlayers(game, obj) {
  if (game.white) send(game.white, obj);
  if (game.black) send(game.black, obj);
}
function toAlgebra(s) { return s && typeof s === 'string' ? s : null; }

// ---------- Message Handling ----------
function onMessage(socket, msg) {
  const { type } = msg || {};
  switch (type) {
    // ----- Lobby flows -----
    case 'create_lobby': {
      const id = (msg.roomCode || Math.random().toString(36).slice(2, 6)).toUpperCase();
      const lobby = { id, host: socket, players: [socket], playerNames: [msg.playerName || socket.id], password: msg.password || "", open: true };
      lobbies.set(id, lobby);
      send(socket, { type: 'lobby_created', lobbyId: id });
      broadcastLobbyList();
      break;
    }
    case 'list_lobbies': {
      send(socket, { type: 'lobby_list', lobbies: lobbyList() });
      break;
    }
    case 'join_lobby': {
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
        send(p, { type: 'lobby_update', lobbyId: l.id, players: l.players.map(x => x.id), playerNames: l.playerNames, hostId: l.host.id, password: !!l.password });
      }
      broadcastLobbyList();
      break;
    }
    case 'leave_lobby': {
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
          send(p, { type: 'lobby_update', lobbyId: l.id, players: l.players.map(x => x.id), playerNames: l.playerNames, hostId: l.host.id, password: !!l.password });
        }
      }
      broadcastLobbyList();
      break;
    }
    case 'start_game': {
      const l = lobbies.get(msg.lobbyId);
      if (!l) return;
      if (l.host !== socket) return;         // only host can start
      if (l.players.length < 1) return;      // need at least 1 player

      const gameId = Math.random().toString(36).slice(2, 9);
      const chess = new Chess();
      const p1 = l.players[0];
      const p2 = l.players.length >= 2 ? l.players[1] : null;
      const game = { white: p1, black: p2, chess, createdAt: Date.now() };
      games.set(gameId, game);

      send(p1, { type: 'game_start', gameId, isWhite: true, opponentId: p2 ? p2.id : null, fen: chess.fen(), turn: 'w' });
      if (p2) {
        send(p2, { type: 'game_start', gameId, isWhite: false, opponentId: p1.id, fen: chess.fen(), turn: 'w' });
      }

      lobbies.delete(l.id);
      broadcastLobbyList();
      break;
    }

    // ----- Gameplay -----
    case 'move': {
      const game = games.get(msg.gameId);
      if (!game) return send(socket, { type: 'error', code: 'GAME_NOT_FOUND' });

      const turnColor = game.chess.turn(); // 'w' | 'b'
      const seat = (socket === game.white) ? 'w' : (socket === game.black ? 'b' : null);
      if (seat == null) return send(socket, { type: 'error', code: 'NOT_IN_GAME' });
      if (seat !== turnColor) return send(socket, { type: 'error', code: 'NOT_YOUR_TURN' });

      // Accept algebraic squares (recommended). Example: from:'e2', to:'e4'
      const from = toAlgebra(msg.from);
      const to = toAlgebra(msg.to);
      const promotion = msg.promo || 'q';

      const res = game.chess.move({ from, to, promotion });
      if (!res) return send(socket, { type: 'error', code: 'ILLEGAL_MOVE' });

      const fen = game.chess.fen();
      const nextTurn = game.chess.turn();
      broadcastPlayers(game, { type: 'moved', gameId: msg.gameId, from, to, san: res.san, fen, turn: nextTurn });

      if (game.chess.isGameOver()) {
        let reason = 'draw', winner = null;
        if (game.chess.isCheckmate()) { reason = 'checkmate'; winner = (nextTurn === 'w' ? 'black' : 'white'); }
        else if (game.chess.isStalemate()) reason = 'stalemate';
        else if (game.chess.isThreefoldRepetition()) reason = 'threefold';
        else if (game.chess.isInsufficientMaterial()) reason = 'insufficient';
        broadcastPlayers(game, { type: 'game_over', gameId: msg.gameId, reason, winner });
        games.delete(msg.gameId);
      }
      break;
    }

    case 'resign': {
      const game = games.get(msg.gameId);
      if (!game) return;
      const winner = (socket === game.white) ? 'black' : 'white';
      broadcastPlayers(game, { type: 'game_over', gameId: msg.gameId, reason: 'resign', winner });
      games.delete(msg.gameId);
      break;
    }

    case 'new_game': {
      const game = games.get(msg.gameId);
      if (!game) return;
      // Only allow if both players agree or if it's a single player game
      const isPlayer = (socket === game.white || socket === game.black);
      if (!isPlayer) return;

      // End the current game
      games.delete(msg.gameId);

      // Create new game with randomized teams
      const p1 = game.white;
      const p2 = game.black;
      const newGameId = Math.random().toString(36).slice(2, 9);
      const chess = new Chess();

      let newWhite, newBlack;

      if (p2) {
        // Two players: randomly swap them
        const randomize = Math.random() < 0.5;
        newWhite = randomize ? p1 : p2;
        newBlack = randomize ? p2 : p1;
      } else {
        // Single player: randomly assign them to white or black
        const assignWhite = Math.random() < 0.5;
        newWhite = assignWhite ? p1 : null;
        newBlack = assignWhite ? null : p1;
        // For single player, they always play as one color, so just randomize which
        if (assignWhite) {
          newWhite = p1;
          newBlack = null;
        } else {
          newWhite = null;
          newBlack = p1;
        }
      }

      const newGame = { white: newWhite, black: newBlack, chess, createdAt: Date.now() };
      games.set(newGameId, newGame);

      if (newWhite) {
        send(newWhite, { type: 'game_start', gameId: newGameId, isWhite: true, opponentId: newBlack ? newBlack.id : null, fen: chess.fen(), turn: 'w' });
      }
      if (newBlack) {
        send(newBlack, { type: 'game_start', gameId: newGameId, isWhite: false, opponentId: newWhite ? newWhite.id : null, fen: chess.fen(), turn: 'w' });
      }
      break;
    }

    default:
      send(socket, { type: 'error', code: 'UNKNOWN_TYPE', seen: type });
  }
}

// ---------- TCP server / NDJSON framing ----------
const PORT = process.env.PORT || process.env.TCP_PORT || 29802; // Railway often injects PORT
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
      try { onMessage(socket, JSON.parse(line)); }
      catch (e) { send(socket, { type: 'error', code: 'BAD_JSON' }); }
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

  // immediate hello optional
  send(socket, { type: 'hello', id: socket.id });
});

server.listen(PORT, () => {
  console.log(`Authoritative TCP chess server listening on ${PORT}`);
});

// ---------- Helpers ----------
function lobbyList() {
  const list = [];
  for (const [id, l] of lobbies.entries()) {
    list.push({ id, hostId: l.host.id, players: l.players.length, open: l.open, hasPassword: !!l.password, playerNames: l.playerNames });
  }
  return list;
}
function broadcastLobbyList() {
  const msg = { type: 'lobby_list', lobbies: lobbyList() };
  for (const c of clients) send(c, msg);
}
function cleanupOnDisconnect(sock) {
  // remove from lobbies
  for (const [id, l] of [...lobbies.entries()]) {
    if (l.players.includes(sock)) {
      l.players = l.players.filter(p => p !== sock);
      l.playerNames = l.playerNames.filter((_, i) => l.players[i] != null);
      if (l.players.length === 0) lobbies.delete(id);
      else {
        if (l.host === sock) l.host = l.players[0];
        l.open = l.players.length < 2;
        for (const p of l.players) send(p, { type: 'lobby_update', lobbyId: l.id, players: l.players.map(x => x.id), playerNames: l.playerNames, hostId: l.host.id, password: !!l.password });
      }
    }
  }
  // end any games they’re in
  for (const [gid, g] of [...games.entries()]) {
    if (g.white === sock || g.black === sock) {
      const winner = (g.white === sock) ? 'black' : 'white';
      broadcastPlayers(g, { type: 'game_over', gameId: gid, reason: 'disconnect', winner });
      games.delete(gid);
    }
  }
}
