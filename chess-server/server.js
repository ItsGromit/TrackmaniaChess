// server.js (authoritative, raw TCP, NDJSON protocol)
const net = require('net');
const https = require('https');
const { Chess } = require('chess.js');

// ---------- State ----------
const games = new Map();     // gameId -> { white:Socket, black:Socket, chess:Chess, createdAt:number, raceChallenges:Map }
const lobbies = new Map();   // lobbyId -> { id, host:Socket, players:Socket[], playerNames:string[], password:string, open:boolean }
const clients = new Set();   // connected sockets
const lastOpponents = new Map(); // socket -> opponent socket (for rematch after game ends)
const raceChallenges = new Map(); // gameId -> { from, to, mapUid, mapName, defenderTime, defenderSocket, attackerSocket }

// ---------- Utils ----------
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
function broadcastPlayers(game, obj) {
  if (game.white) send(game.white, obj);
  if (game.black) send(game.black, obj);
}
function toAlgebra(s) { return s && typeof s === 'string' ? s : null; }

// Fetch a random short map from Trackmania Exchange
async function fetchRandomShortMap() {
  return new Promise((resolve) => {
    // Short maps (under 1 minute) from Trackmania Exchange
    const shortMaps = [
      { uid: '278818', name: 'Sprint Map 1' },
      { uid: '278817', name: 'Sprint Map 2' },
      { uid: '278431', name: 'Sprint Map 3' },
      { uid: '278804', name: 'Sprint Map 4' },
      { uid: '278788', name: 'Sprint Map 5' }
    ];

    const randomMap = shortMaps[Math.floor(Math.random() * shortMaps.length)];
    console.log(`[Chess] Selected random map: ${randomMap.name} (${randomMap.uid})`);
    resolve(randomMap);
  });
}

// ---------- Message Handling ----------
async function onMessage(socket, msg) {
  const { type } = msg || {};
  switch (type) {
    // ----- Lobby flows -----
    case 'create_lobby': {
      // Generate random 5-letter room code
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      let id = '';
      for (let i = 0; i < 5; i++) {
        id += chars.charAt(Math.floor(Math.random() * chars.length));
      }

      const lobby = { id, host: socket, players: [socket], playerNames: [msg.playerName || socket.id], password: msg.password || "", open: true };
      lobbies.set(id, lobby);
      console.log(`[Lobby] Created lobby ${id} for socket ${socket.id}, sending confirmation...`);
      const confirmation = { type: 'lobby_created', lobbyId: id };
      console.log('[Lobby] Sending confirmation:', JSON.stringify(confirmation));
      send(socket, confirmation);
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

      // Store opponents for rematch
      if (p1 && p2) {
        lastOpponents.set(p1, p2);
        lastOpponents.set(p2, p1);
      }

      send(p1, { type: 'game_start', gameId, isWhite: true, opponentId: p2 ? p2.id : null, fen: chess.fen(), turn: 'w' });
      if (p2) {
        send(p2, { type: 'game_start', gameId, isWhite: false, opponentId: p1.id, fen: chess.fen(), turn: 'w' });
      }

      // Keep the lobby alive for rematches instead of deleting it
      // Mark the lobby as "in game" so it doesn't show in the lobby list
      l.open = false;
      broadcastLobbyList();
      console.log(`[Stats] Active games: ${games.size}, Open lobbies: ${lobbies.size}, Connected clients: ${clients.size}`);
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

      // Check if this is a capture BEFORE making the move
      const targetSquare = game.chess.get(to);
      const isCapture = targetSquare && targetSquare.color !== turnColor;

      if (isCapture) {
        // Trigger a race challenge instead of immediate capture
        console.log(`[Chess] Capture detected: ${from} -> ${to}, triggering race challenge`);

        // Get a random map
        const map = await fetchRandomShortMap();

        // Store the pending capture
        const challenge = {
          from,
          to,
          promotion,
          mapUid: map.uid,
          mapName: map.name,
          attacker: socket,
          defender: (socket === game.white) ? game.black : game.white,
          defenderTime: null,
          attackerTime: null,
          gameId: msg.gameId
        };

        raceChallenges.set(msg.gameId, challenge);

        // Notify both players
        send(challenge.defender, {
          type: 'race_challenge',
          mapUid: map.uid,
          mapName: map.name,
          isDefender: true,
          from,
          to
        });

        send(challenge.attacker, {
          type: 'race_challenge',
          mapUid: map.uid,
          mapName: map.name,
          isDefender: false,
          from,
          to
        });

        break;
      }

      // Not a capture, process normally
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

        // Store opponents for rematch before deleting game
        if (game.white && game.black) {
          lastOpponents.set(game.white, game.black);
          lastOpponents.set(game.black, game.white);

          // Find the lobby for these players and reopen it
          for (const [lid, lobby] of lobbies) {
            if (lobby.players.includes(game.white) || lobby.players.includes(game.black)) {
              lobby.open = false; // Keep closed to prevent new players joining during rematch
              break;
            }
          }
        }
        games.delete(msg.gameId);
      }
      break;
    }

    case 'resign': {
      const game = games.get(msg.gameId);
      if (!game) return;
      const winner = (socket === game.white) ? 'black' : 'white';
      broadcastPlayers(game, { type: 'game_over', gameId: msg.gameId, reason: 'resign', winner });

      // Store opponents for rematch before deleting game
      if (game.white && game.black) {
        lastOpponents.set(game.white, game.black);
        lastOpponents.set(game.black, game.white);

        // Find the lobby for these players and keep it closed for rematch
        for (const [, lobby] of lobbies) {
          if (lobby.players.includes(game.white) || lobby.players.includes(game.black)) {
            lobby.open = false; // Keep closed to prevent new players joining during rematch
            break;
          }
        }
      }
      games.delete(msg.gameId);
      break;
    }

    case 'race_result': {
      const challenge = raceChallenges.get(msg.gameId);
      if (!challenge) return console.log('[Chess] No race challenge found for game:', msg.gameId);

      const game = games.get(msg.gameId);
      if (!game) return;

      const time = msg.time;
      console.log(`[Chess] Race result received: ${time}ms from ${socket === challenge.defender ? 'defender' : 'attacker'}`);

      // Store the time
      if (socket === challenge.defender) {
        challenge.defenderTime = time;
        // Notify attacker that defender finished
        send(challenge.attacker, { type: 'race_defender_finished', time });
      } else if (socket === challenge.attacker) {
        challenge.attackerTime = time;
      }

      // If both have finished, determine winner
      if (challenge.defenderTime !== null && challenge.attackerTime !== null) {
        const captureSucceeded = challenge.attackerTime < challenge.defenderTime;
        console.log(`[Chess] Race complete - Attacker: ${challenge.attackerTime}ms, Defender: ${challenge.defenderTime}ms, Capture ${captureSucceeded ? 'succeeded' : 'failed'}`);

        if (captureSucceeded) {
          // Attacker won, apply the capture
          const res = game.chess.move({ from: challenge.from, to: challenge.to, promotion: challenge.promotion });
          if (res) {
            const fen = game.chess.fen();
            const nextTurn = game.chess.turn();
            broadcastPlayers(game, {
              type: 'race_result',
              captureSucceeded: true,
              fen,
              turn: nextTurn
            });
          }
        } else {
          // Defender won, capture fails - board stays the same
          const fen = game.chess.fen();
          const turn = game.chess.turn();
          broadcastPlayers(game, {
            type: 'race_result',
            captureSucceeded: false,
            fen,
            turn
          });
        }

        // Clean up challenge
        raceChallenges.delete(msg.gameId);
      }
      break;
    }

    case 'race_retire': {
      const challenge = raceChallenges.get(msg.gameId);
      if (!challenge) return console.log('[Chess] No race challenge found for game:', msg.gameId);

      const game = games.get(msg.gameId);
      if (!game) return;

      console.log(`[Chess] Player retired from race: ${socket === challenge.defender ? 'defender' : 'attacker'}`);

      // Auto-forfeit: whoever retires loses
      const captureSucceeded = socket === challenge.defender; // If defender retires, attacker wins

      if (captureSucceeded) {
        // Apply the capture
        const res = game.chess.move({ from: challenge.from, to: challenge.to, promotion: challenge.promotion });
        if (res) {
          const fen = game.chess.fen();
          const nextTurn = game.chess.turn();
          broadcastPlayers(game, {
            type: 'race_result',
            captureSucceeded: true,
            fen,
            turn: nextTurn
          });
        }
      } else {
        // Capture fails
        const fen = game.chess.fen();
        const turn = game.chess.turn();
        broadcastPlayers(game, {
          type: 'race_result',
          captureSucceeded: false,
          fen,
          turn
        });
      }

      // Clean up challenge
      raceChallenges.delete(msg.gameId);
      break;
    }

    case 'new_game': {
      let game = games.get(msg.gameId);
      let p1, p2;

      if (game) {
        // Active game exists - use those players
        const isPlayer = (socket === game.white || socket === game.black);
        if (!isPlayer) return;
        p1 = game.white;
        p2 = game.black;
        // End the current game
        games.delete(msg.gameId);
      } else {
        // Game ended - use lastOpponents mapping
        p1 = socket;
        p2 = lastOpponents.get(socket);
        if (!p2) return; // No opponent found for rematch
      }

      // Create new game with randomized teams
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

      // Update lastOpponents for the new game
      if (p1 && p2) {
        lastOpponents.set(p1, p2);
        lastOpponents.set(p2, p1);
      }

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
// Use PORT for TCP server (Railway's main exposed port)
const TCP_PORT = Number(process.env.PORT || 29802);
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

server.listen(TCP_PORT, () => {
  console.log(`Authoritative TCP chess server listening on ${TCP_PORT}`);
});

setInterval(() => {
  console.log(`[Stats] Active games: ${games.size}, Open lobbies: ${lobbies.size}, Connected clients: ${clients.size}`);
}, 50000);

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
  // end any games they're in
  for (const [gid, g] of [...games.entries()]) {
    if (g.white === sock || g.black === sock) {
      const winner = (g.white === sock) ? 'black' : 'white';
      broadcastPlayers(g, { type: 'game_over', gameId: gid, reason: 'disconnect', winner });
      games.delete(gid);
    }
  }
  // clean up lastOpponents mappings
  const opponent = lastOpponents.get(sock);
  if (opponent) {
    lastOpponents.delete(opponent); // Remove opponent's reference to this socket
  }
  lastOpponents.delete(sock);
}
