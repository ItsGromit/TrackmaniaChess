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
  const isDefender = socket === challenge.defender;
  const isAttacker = socket === challenge.attacker;

  console.log(`[Chess] Race result received: ${time}ms from ${isDefender ? 'defender' : 'attacker'}`);

  // Check if player has already submitted a time
  if (isDefender && challenge.defenderTime !== null) {
    console.log('[Chess] Defender already submitted a time, ignoring duplicate');
    return;
  }
  if (isAttacker && challenge.attackerTime !== null) {
    console.log('[Chess] Attacker already submitted a time, ignoring duplicate');
    return;
  }

  // Store the time (first submission only)
  if (isDefender) {
    challenge.defenderTime = time;
    // Notify attacker that defender finished
    send(challenge.attacker, { type: 'race_defender_finished', time });
  } else if (isAttacker) {
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

  const isDefender = socket === challenge.defender;
  const isAttacker = socket === challenge.attacker;

  console.log(`[Chess] Player retired from race: ${isDefender ? 'defender' : 'attacker'}`);

  // Check if player has already submitted a time or retired
  if (isDefender && challenge.defenderTime !== null) {
    console.log('[Chess] Defender already submitted a time/retired, ignoring');
    return;
  }
  if (isAttacker && challenge.attackerTime !== null) {
    console.log('[Chess] Attacker already submitted a time/retired, ignoring');
    return;
  }

  // Mark player as DNF with max time (essentially infinite)
  if (isDefender) {
    challenge.defenderTime = Number.MAX_SAFE_INTEGER;
  } else if (isAttacker) {
    challenge.attackerTime = Number.MAX_SAFE_INTEGER;
  }

  // Check if both players are done (either finished or retired)
  if (challenge.defenderTime !== null && challenge.attackerTime !== null) {
    // Determine winner: lower time wins (DNF = MAX_SAFE_INTEGER)
    const captureSucceeded = challenge.attackerTime < challenge.defenderTime;
    console.log(`[Chess] Race complete - Attacker: ${challenge.attackerTime === Number.MAX_SAFE_INTEGER ? 'DNF' : challenge.attackerTime + 'ms'}, Defender: ${challenge.defenderTime === Number.MAX_SAFE_INTEGER ? 'DNF' : challenge.defenderTime + 'ms'}, Capture ${captureSucceeded ? 'succeeded' : 'failed'}`);

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
}

module.exports = {
  handleRaceResult,
  handleRaceRetire
};
