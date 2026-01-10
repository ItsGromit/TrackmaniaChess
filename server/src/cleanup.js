// cleanup.js - Cleanup handlers for disconnects

const { lobbies, games, lastOpponents, validatedClients } = require('./state');
const { send, broadcastPlayers } = require('./utils');

// Cleanup on client disconnect
function cleanupOnDisconnect(sock) {
  // Remove from validated clients
  validatedClients.delete(sock);

  // remove from lobbies
  for (const [id, l] of [...lobbies.entries()]) {
    if (l.players.includes(sock)) {
      l.players = l.players.filter(p => p !== sock);
      l.playerNames = l.playerNames.filter((_, i) => l.players[i] != null);
      if (l.players.length === 0) {
        lobbies.delete(id);
      } else {
        if (l.host === sock) l.host = l.players[0];
        l.open = l.players.length < 2;
        for (const p of l.players) {
          send(p, {
            type: 'lobby_update',
            lobbyId: l.id,
            players: l.players.map(x => x.id),
            playerNames: l.playerNames,
            hostId: l.host.id,
            password: !!l.password,
            mapFilters: l.mapFilters,
            raceMode: l.raceMode
          });
        }
      }
    }
  }

  // end any games they're in
  for (const [gid, g] of [...games.entries()]) {
    if (g.white === sock || g.black === sock) {
      const winner = (g.white === sock) ? 'black' : 'white';
      broadcastPlayers(g, {
        type: 'game_over',
        gameId: gid,
        reason: 'disconnect',
        winner
      });
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

module.exports = {
  cleanupOnDisconnect
};
