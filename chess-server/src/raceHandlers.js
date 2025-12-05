// raceHandlers.js - Race challenge handlers

const { games, raceChallenges } = require('./state');
const { send, broadcastPlayers } = require('./utils');

// Handle race_result message
function handleRaceResult(socket, msg) {
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
      const res = game.chess.move({
        from: challenge.from,
        to: challenge.to,
        promotion: challenge.promotion
      });
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
}

// Handle race_retire message
function handleRaceRetire(socket, msg) {
  const challenge = raceChallenges.get(msg.gameId);
  if (!challenge) return console.log('[Chess] No race challenge found for game:', msg.gameId);

  const game = games.get(msg.gameId);
  if (!game) return;

  console.log(`[Chess] Player retired from race: ${socket === challenge.defender ? 'defender' : 'attacker'}`);

  // Auto-forfeit: whoever retires loses
  const captureSucceeded = socket === challenge.defender; // If defender retires, attacker wins

  if (captureSucceeded) {
    // Apply the capture
    const res = game.chess.move({
      from: challenge.from,
      to: challenge.to,
      promotion: challenge.promotion
    });
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
}

module.exports = {
  handleRaceResult,
  handleRaceRetire
};
