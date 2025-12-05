// messageRouter.js - Routes messages to appropriate handlers

const lobbyHandlers = require('./lobbyHandlers');
const gameHandlers = require('./gameHandlers');
const raceHandlers = require('./raceHandlers');
const { send } = require('./utils');

// Main message router
async function onMessage(socket, msg) {
  const { type } = msg || {};

  switch (type) {
    // Lobby flows
    case 'create_lobby':
      return lobbyHandlers.handleCreateLobby(socket, msg);
    case 'list_lobbies':
      return lobbyHandlers.handleListLobbies(socket, msg);
    case 'join_lobby':
      return lobbyHandlers.handleJoinLobby(socket, msg);
    case 'leave_lobby':
      return lobbyHandlers.handleLeaveLobby(socket, msg);
    case 'set_map_filters':
      return lobbyHandlers.handleSetMapFilters(socket, msg);
    case 'get_map_filters':
      return lobbyHandlers.handleGetMapFilters(socket, msg);
    case 'start_game':
      return lobbyHandlers.handleStartGame(socket, msg);

    // Gameplay
    case 'move':
      return await gameHandlers.handleMove(socket, msg);
    case 'resign':
      return gameHandlers.handleResign(socket, msg);
    case 'new_game':
      return gameHandlers.handleNewGame(socket, msg);

    // Race challenges
    case 'race_result':
      return raceHandlers.handleRaceResult(socket, msg);
    case 'race_retire':
      return raceHandlers.handleRaceRetire(socket, msg);

    default:
      send(socket, { type: 'error', code: 'UNKNOWN_TYPE', seen: type });
  }
}

module.exports = {
  onMessage
};
