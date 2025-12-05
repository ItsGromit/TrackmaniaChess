// gameHandlers.js - Game-related message handlers

const { Chess } = require('chess.js');
const { games, lobbies, lastOpponents, raceChallenges } = require('./state');
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

// Handle new_game message
function handleNewGame(socket, msg) {
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
    send(newWhite, {
      type: 'game_start',
      gameId: newGameId,
      isWhite: true,
      opponentId: newBlack ? newBlack.id : null,
      fen: chess.fen(),
      turn: 'w'
    });
  }
  if (newBlack) {
    send(newBlack, {
      type: 'game_start',
      gameId: newGameId,
      isWhite: false,
      opponentId: newWhite ? newWhite.id : null,
      fen: chess.fen(),
      turn: 'w'
    });
  }
}

module.exports = {
  handleMove,
  handleResign,
  handleNewGame
};
