// config.js - Configuration constants

// Developer Blacklist Configuration
// Add authors you want to exclude from random map selection
const BLACKLISTED_AUTHORS = [
  // Example: 'BadMapMaker123'
];

// Add mappack IDs you want to exclude from random map selection
const BLACKLISTED_MAPPACKS = [
  7173
];

// Server configuration
// Use GAME_PORT for TCP server, PORT is reserved for HTTP (Railway requirement)
const TCP_PORT = Number(process.env.GAME_PORT || 29802);

// Stats logging interval (ms)
const STATS_INTERVAL = 50000;

module.exports = {
  BLACKLISTED_AUTHORS,
  BLACKLISTED_MAPPACKS,
  TCP_PORT,
  STATS_INTERVAL
};
