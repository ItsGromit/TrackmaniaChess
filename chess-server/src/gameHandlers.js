// gameHandlers.js - Game-related message handlers

const { Chess } = require('chess.js');
const { games, lobbies, lastOpponents, raceChallenges, rematchRequests, rerollRequests } = require('./state');
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
  console.log(`[Chess] handleNewGame called - socket: ${socket.id}, gameId: ${msg.gameId}`);

  let game = games.get(msg.gameId);
  let opponent;

  if (game) {
    // Active game exists - use those players
    const isPlayer = (socket === game.white || socket === game.black);
    if (!isPlayer) {
      console.log(`[Chess] Error: Socket ${socket.id} is not a player in game ${msg.gameId}`);
      return;
    }
    opponent = (socket === game.white) ? game.black : game.white;
    console.log(`[Chess] Found active game - opponent: ${opponent.id}`);
  } else {
    // Game ended - use lastOpponents mapping
    opponent = lastOpponents.get(socket);
    if (!opponent) {
      console.log(`[Chess] Error: No opponent found for socket ${socket.id} in lastOpponents map`);
      return; // No opponent found for rematch
    }
    console.log(`[Chess] Game ended - found opponent from lastOpponents: ${opponent.id}`);
  }

  // Check if this socket has already sent a rematch request for this game
  const existingRequest = rematchRequests.get(socket);
  if (existingRequest && existingRequest.gameId === msg.gameId) {
    console.log(`[Chess] Socket ${socket.id} already sent a rematch request for game ${msg.gameId}`);
    send(socket, {
      type: 'error',
      code: 'REMATCH_ALREADY_SENT',
      message: 'You have already sent a rematch request for this game'
    });
    return;
  }

  // Store the rematch request
  rematchRequests.set(socket, { requester: socket, opponent: opponent, gameId: msg.gameId });
  console.log(`[Chess] Stored rematch request in map - requester: ${socket.id}, opponent: ${opponent.id}, gameId: ${msg.gameId}`);

  // Send rematch request to opponent
  send(opponent, {
    type: 'rematch_request',
    gameId: msg.gameId
  });
  console.log(`[Chess] Sent rematch_request message to opponent ${opponent.id}`);

  // Notify requester that request was sent
  send(socket, {
    type: 'rematch_sent',
    gameId: msg.gameId
  });
  console.log(`[Chess] Sent rematch_sent confirmation to requester ${socket.id}`);
  console.log(`[Chess] Rematch request completed successfully - ${socket.id} -> ${opponent.id} for game ${msg.gameId}`);
}

// Handle rematch response
function handleRematchResponse(socket, msg) {
  const { gameId, accept } = msg;
  console.log(`[Chess] handleRematchResponse called - socket: ${socket.id}, gameId: ${gameId}, accept: ${accept}`);

  // Find the rematch request where this socket is the opponent
  let request = null;
  for (const [requester, req] of rematchRequests) {
    if (req.opponent === socket && req.gameId === gameId) {
      request = req;
      console.log(`[Chess] Found matching rematch request from ${requester.id}`);
      break;
    }
  }

  if (!request) {
    console.log(`[Chess] Error: No rematch request found for socket ${socket.id} and game ${gameId}`);
    return send(socket, { type: 'error', code: 'NO_REMATCH_REQUEST' });
  }

  const requester = request.requester;
  const opponent = request.opponent;

  // Clear the request
  rematchRequests.delete(requester);
  console.log(`[Chess] Cleared rematch request from map for requester ${requester.id}`);

  if (!accept) {
    // Opponent declined
    console.log(`[Chess] Rematch declined by ${socket.id} - notifying both players`);
    send(requester, {
      type: 'rematch_declined',
      gameId: gameId
    });
    send(opponent, {
      type: 'rematch_declined',
      gameId: gameId
    });
    console.log(`[Chess] Rematch declined messages sent to ${requester.id} and ${opponent.id}`);
    return;
  }

  // Opponent accepted - start new game
  console.log(`[Chess] Rematch accepted by ${socket.id} (${opponent.id}) - starting new game with ${requester.id}`);

  const p1 = requester;
  const p2 = opponent;

  // Create new game with randomized teams
  const newGameId = Math.random().toString(36).slice(2, 9);
  console.log(`[Chess] Generated new game ID: ${newGameId}`);

  const chess = new Chess();

  // Randomly swap players
  const randomize = Math.random() < 0.5;
  const newWhite = randomize ? p1 : p2;
  const newBlack = randomize ? p2 : p1;
  console.log(`[Chess] Randomized colors (${randomize ? 'swapped' : 'not swapped'}) - White: ${newWhite.id}, Black: ${newBlack.id}`);

  const newGame = { white: newWhite, black: newBlack, chess, createdAt: Date.now() };
  games.set(newGameId, newGame);
  console.log(`[Chess] Created and stored new game ${newGameId}`);

  // Update lastOpponents for the new game
  lastOpponents.set(p1, p2);
  lastOpponents.set(p2, p1);
  console.log(`[Chess] Updated lastOpponents map for both players`);

  send(newWhite, {
    type: 'game_start',
    gameId: newGameId,
    isWhite: true,
    opponentId: newBlack.id,
    fen: chess.fen(),
    turn: 'w'
  });
  console.log(`[Chess] Sent game_start to white player ${newWhite.id}`);

  send(newBlack, {
    type: 'game_start',
    gameId: newGameId,
    isWhite: false,
    opponentId: newWhite.id,
    fen: chess.fen(),
    turn: 'w'
  });
  console.log(`[Chess] Sent game_start to black player ${newBlack.id}`);
  console.log(`[Chess] Rematch game creation completed successfully - Game ID: ${newGameId}`);
}

// Handle re-roll request
async function handleRerollRequest(socket, msg) {
  const { gameId } = msg;
  console.log(`[Chess] handleRerollRequest called - socket: ${socket.id}, gameId: ${gameId}`);

  // Find the race challenge for this game
  const challenge = raceChallenges.get(gameId);
  if (!challenge) {
    console.log(`[Chess] Error: No race challenge found for game ${gameId}`);
    return send(socket, { type: 'error', code: 'NO_RACE_CHALLENGE' });
  }

  // Check if this socket is part of the race challenge
  const isPlayer = (socket === challenge.attacker || socket === challenge.defender);
  if (!isPlayer) {
    console.log(`[Chess] Error: Socket ${socket.id} is not a player in race challenge for game ${gameId}`);
    return send(socket, { type: 'error', code: 'NOT_IN_RACE' });
  }

  const opponent = (socket === challenge.attacker) ? challenge.defender : challenge.attacker;
  console.log(`[Chess] Found opponent for re-roll: ${opponent.id}`);

  // Check if this socket has already sent a re-roll request for this game
  const existingRequest = rerollRequests.get(socket);
  if (existingRequest && existingRequest.gameId === gameId) {
    console.log(`[Chess] Socket ${socket.id} already sent a re-roll request for game ${gameId}`);
    return send(socket, { type: 'error', code: 'REROLL_ALREADY_SENT' });
  }

  // Store the re-roll request
  rerollRequests.set(socket, { requester: socket, opponent: opponent, gameId: gameId });
  console.log(`[Chess] Stored re-roll request in map - requester: ${socket.id}, opponent: ${opponent.id}, gameId: ${gameId}`);

  // Send re-roll request to opponent
  send(opponent, {
    type: 'reroll_request',
    gameId: gameId
  });
  console.log(`[Chess] Sent reroll_request message to opponent ${opponent.id}`);

  // Notify requester that request was sent
  send(socket, {
    type: 'reroll_sent',
    gameId: gameId
  });
  console.log(`[Chess] Sent reroll_sent confirmation to requester ${socket.id}`);
}

// Handle re-roll response
async function handleRerollResponse(socket, msg) {
  const { gameId, accept } = msg;
  console.log(`[Chess] handleRerollResponse called - socket: ${socket.id}, gameId: ${gameId}, accept: ${accept}`);

  // Find the re-roll request where this socket is the opponent
  let request = null;
  for (const [requester, req] of rerollRequests) {
    if (req.opponent === socket && req.gameId === gameId) {
      request = req;
      console.log(`[Chess] Found matching re-roll request from ${requester.id}`);
      break;
    }
  }

  if (!request) {
    console.log(`[Chess] Error: No re-roll request found for socket ${socket.id} and game ${gameId}`);
    return send(socket, { type: 'error', code: 'NO_REROLL_REQUEST' });
  }

  const requester = request.requester;
  const opponent = request.opponent;

  // Clear the request
  rerollRequests.delete(requester);
  console.log(`[Chess] Cleared re-roll request from map for requester ${requester.id}`);

  if (!accept) {
    // Opponent declined
    console.log(`[Chess] Re-roll declined by ${socket.id} - notifying both players`);
    send(requester, {
      type: 'reroll_declined',
      gameId: gameId
    });
    send(opponent, {
      type: 'reroll_declined',
      gameId: gameId
    });
    console.log(`[Chess] Re-roll declined messages sent to ${requester.id} and ${opponent.id}`);
    return;
  }

  // Opponent accepted - get a new random map
  console.log(`[Chess] Re-roll accepted by ${socket.id} - fetching new map`);

  const game = games.get(gameId);
  const map = await fetchRandomShortMap(game ? game.mapFilters || {} : {});
  console.log(`[Chess] Fetched new map: ${map.name} (UID: ${map.uid})`);

  // Update the race challenge with the new map
  const challenge = raceChallenges.get(gameId);
  if (challenge) {
    challenge.mapUid = map.uid;
    challenge.mapName = map.name;
    console.log(`[Chess] Updated race challenge with new map`);
  }

  // Notify both players about the new map
  send(requester, {
    type: 'reroll_approved',
    gameId: gameId,
    mapUid: map.uid,
    mapName: map.name
  });

  send(opponent, {
    type: 'reroll_approved',
    gameId: gameId,
    mapUid: map.uid,
    mapName: map.name
  });

  console.log(`[Chess] Re-roll approved messages sent to both players with new map`);
}

module.exports = {
  handleMove,
  handleResign,
  handleNewGame,
  handleRematchResponse,
  handleRerollRequest,
  handleRerollResponse
};
