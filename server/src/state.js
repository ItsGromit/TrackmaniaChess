// state.js - Game state management

// State storage
const games = new Map();     // gameId -> { white:Socket, black:Socket, chess:Chess, createdAt:number, mapFilters:Object }
const lobbies = new Map();   // lobbyId -> { id, host:Socket, players:Socket[], playerNames:string[], password:string, open:boolean, mapFilters:Object }
const clients = new Set();   // connected sockets
const validatedClients = new Set(); // sockets that passed version check
const lastOpponents = new Map(); // socket -> opponent socket (for rematch after game ends)
const raceChallenges = new Map(); // gameId -> { from, to, tmxId, mapName, defenderTime, defenderSocket, attackerSocket }
const rematchRequests = new Map(); // socket -> { requester:Socket, opponent:Socket, gameId:string }
const rerollRequests = new Map(); // socket -> { requester:Socket, opponent:Socket, gameId:string }

module.exports = {
  games,
  lobbies,
  clients,
  validatedClients,
  lastOpponents,
  raceChallenges,
  rematchRequests,
  rerollRequests
};
