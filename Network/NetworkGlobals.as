Net::Socket@ sock;
bool isConnected = false;
[Setting category="Network" name="Server host"] string serverHost = "yamanote.proxy.rlwy.net";
[Setting category="Network" name="Server port"] uint serverPort = 36621;
// =================
// Network variables
// =================

string playerId;
string currentLobbyId;
string currentLobbyPassword;
string currentLobbyRaceMode = "capture"; // Track the current lobby's race mode
array<string> currentLobbyPlayerNames; // Track players in current lobby
string gameId;
bool isWhite = false;
bool isHost = false;

// ================
// Map Filter variables
// ================
int mapFilterAuthorTimeMax = 300; // No real limit by default (5 minutes max)
int mapFilterAuthorTimeMin = 0;
array<string> mapFilterSelectedTags;
array<string> mapFilterBlacklistedTags = {"Kacky", "LOL"}; // Default blacklist
bool mapFiltersChanged = false;
bool useTagWhitelist = false; // Default to blacklist mode with Kacky and LOL excluded

// ==============
// Race variables
// ==============
int raceMapTmxId = -1;
string raceMapName = "";
bool isDefender = false;
int defenderTime = -1;
string captureFrom = "";
string captureTo = "";
int activeMappackId = 7237; // Mappack ID received from server for current game

// Live race tracking
int opponentRaceTime = -1;          // Opponent's current race time (-1 if not racing)
bool opponentIsRacing = false;       // Whether opponent is currently racing
uint64 lastRaceUpdateSent = 0;       // Last time we sent a race update (throttle to avoid spam)
int lastPlayerStartTime = -1;        // Track player's last start time to detect restarts
int lastPlayerRaceTime = 0;          // Track last race time to detect if time went backwards (full restart)

// Race result tracking (to keep results window open after returning to board)
bool showRaceResults = false;        // Whether to show race results window
bool lastRaceCaptureSucceeded = false; // Whether the last race capture succeeded
int lastRacePlayerTime = -1;         // Player's final time in last race
int lastRaceOpponentTime = -1;       // Opponent's final time in last race
bool lastRacePlayerWasDefender = false; // Whether player was defender in last race

const array<string> FILES = {"a", "b", "c", "d", "e", "f", "g", "h"};

array<Lobby> lobbies;

string _buf;

string tempMapUrl = "";