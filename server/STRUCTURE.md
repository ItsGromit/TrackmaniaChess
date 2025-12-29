# Server Structure

The chess server has been refactored into a modular architecture for better organization and maintainability.

## File Organization

### Main Entry Point
- **server.js** - TCP server setup and NDJSON protocol handling

### Source Modules (`/src`)

#### Configuration
- **config.js** - Server configuration constants and blacklists
  - Blacklisted authors/mappacks
  - Port configuration
  - Stats interval

#### State Management
- **state.js** - Centralized game state
  - Active games map
  - Lobbies map
  - Connected clients
  - Last opponents tracking
  - Race challenges

#### Utilities
- **utils.js** - Common utility functions
  - `send()` - Send message to client
  - `broadcastPlayers()` - Broadcast to game players
  - `toAlgebra()` - Convert to algebraic notation
  - `lobbyList()` - Get lobby list
  - `broadcastLobbyList()` - Broadcast lobby list to all clients

#### Services
- **mapService.js** - TrackmaniaExchange API integration
  - `fetchRandomShortMap()` - Fetch random map with filters
  - Fallback map handling

#### Message Handlers
- **messageRouter.js** - Routes incoming messages to appropriate handlers
- **lobbyHandlers.js** - Lobby management
  - Create/join/leave lobby
  - Start game
  - Map filter management
- **gameHandlers.js** - Game logic
  - Move handling
  - Resign
  - New game/rematch
- **raceHandlers.js** - Race challenge mechanics
  - Race result processing
  - Retirement handling

#### Cleanup
- **cleanup.js** - Client disconnect handling
  - Lobby cleanup
  - Game termination
  - State cleanup

## Benefits

1. **Modularity** - Each file has a single, clear responsibility
2. **Maintainability** - Easy to locate and update specific functionality
3. **Testability** - Individual modules can be tested in isolation
4. **Readability** - Reduced file size makes code easier to understand
5. **Reusability** - Functions can be imported where needed

## Module Dependencies

```
server.js
├── config.js
├── state.js
├── utils.js
│   └── state.js
├── messageRouter.js
│   ├── lobbyHandlers.js
│   │   ├── state.js
│   │   └── utils.js
│   ├── gameHandlers.js
│   │   ├── state.js
│   │   ├── utils.js
│   │   └── mapService.js
│   └── raceHandlers.js
│       ├── state.js
│       └── utils.js
└── cleanup.js
    ├── state.js
    └── utils.js
```
