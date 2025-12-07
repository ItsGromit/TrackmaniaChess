// gameHandlers.js - Game-related message handlers

const { Chess } = require('chess.js');
const { games, lobbies, lastOpponents, raceChallenges, rematchRequests } = require('./state');
const { send, broadcastPlayers, toAlgebra } = require('./utils');
const { fetchRandomShortMap } = require('./mapService');

// Handle move message
async function handleMove(socket, msg) {
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

    // Get a random map using the game's filters
    const map = await fetchRandomShortMap(game.mapFilters || {});

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

    return;
  }

  // Not a capture, process normally
  const res = game.chess.move({ from, to, promotion });
  if (!res) return send(socket, { type: 'error', code: 'ILLEGAL_MOVE' });

  const fen = game.chess.fen();
  const nextTurn = game.chess.turn();
  broadcastPlayers(game, {
    type: 'moved',
    gameId: msg.gameId,
    from,
    to,
    san: res.san,
    fen,
    turn: nextTurn
  });

  if (game.chess.isGameOver()) {
    let reason = 'draw', winner = null;
    if (game.chess.isCheckmate()) {
      reason = 'checkmate';
      winner = (nextTurn === 'w' ? 'black' : 'white');
    } else if (game.chess.isStalemate()) {
      reason = 'stalemate';
    } else if (game.chess.isThreefoldRepetition()) {
      reason = 'threefold';
    } else if (game.chess.isInsufficientMaterial()) {
      reason = 'insufficient';
    }
    broadcastPlayers(game, {
      type: 'game_over',
      gameId: msg.gameId,
      reason,
      winner
    });

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
}

// Handle resign message
function handleResign(socket, msg) {
  const game = games.get(msg.gameId);
  if (!game) return;
  const winner = (socket === game.white) ? 'black' : 'white';
  broadcastPlayers(game, {
    type: 'game_over',
    gameId: msg.gameId,
    reason: 'resign',
    winner
  });

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
}

// Handle new_game message (rematch request)
function handleNewGame(socket, msg) {
  let game = games.get(msg.gameId);
  let opponent;

  if (game) {
    // Active game exists - use those players
    const isPlayer = (socket === game.white || socket === game.black);
    if (!isPlayer) return;
    opponent = (socket === game.white) ? game.black : game.white;
  } else {
    // Game ended - use lastOpponents mapping
    opponent = lastOpponents.get(socket);
    if (!opponent) return; // No opponent found for rematch
  }

  // Store the rematch request
  rematchRequests.set(socket, { requester: socket, opponent: opponent, gameId: msg.gameId });

  // Send rematch request to opponent
  send(opponent, {
    type: 'rematch_request',
    gameId: msg.gameId
  });

  // Notify requester that request was sent
  send(socket, {
    type: 'rematch_sent',
    gameId: msg.gameId
  });

  console.log(`[Chess] Rematch request sent from ${socket.id} to ${opponent.id}`);
}

// Handle rematch response
function handleRematchResponse(socket, msg) {
  const { gameId, accept } = msg;

  // Find the rematch request where this socket is the opponent
  let request = null;
  for (const [requester, req] of rematchRequests) {
    if (req.opponent === socket && req.gameId === gameId) {
      request = req;
      break;
    }
  }

  if (!request) {
    return send(socket, { type: 'error', code: 'NO_REMATCH_REQUEST' });
  }

  const requester = request.requester;
  const opponent = request.opponent;

  // Clear the request
  rematchRequests.delete(requester);

  if (!accept) {
    // Opponent declined
    send(requester, {
      type: 'rematch_declined',
      gameId: gameId
    });
    send(opponent, {
      type: 'rematch_declined',
      gameId: gameId
    });
    console.log(`[Chess] Rematch declined by ${socket.id}`);
    return;
  }

  // Opponent accepted - start new game
  console.log(`[Chess] Rematch accepted by ${socket.id}, starting new game`);

  const p1 = requester;
  const p2 = opponent;

  // Create new game with randomized teams
  const newGameId = Math.random().toString(36).slice(2, 9);
  const chess = new Chess();

  // Randomly swap players
  const randomize = Math.random() < 0.5;
  const newWhite = randomize ? p1 : p2;
  const newBlack = randomize ? p2 : p1;

  const newGame = { white: newWhite, black: newBlack, chess, createdAt: Date.now() };
  games.set(newGameId, newGame);

  // Update lastOpponents for the new game
  lastOpponents.set(p1, p2);
  lastOpponents.set(p2, p1);

  send(newWhite, {
    type: 'game_start',
    gameId: newGameId,
    isWhite: true,
    opponentId: newBlack.id,
    fen: chess.fen(),
    turn: 'w'
  });

  send(newBlack, {
    type: 'game_start',
    gameId: newGameId,
    isWhite: false,
    opponentId: newWhite.id,
    fen: chess.fen(),
    turn: 'w'
  });
}

module.exports = {
  handleMove,
  handleResign,
  handleNewGame,
  handleRematchResponse
};
