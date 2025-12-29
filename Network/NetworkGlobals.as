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

const array<string> FILES = {"a", "b", "c", "d", "e", "f", "g", "h"};

array<Lobby> lobbies;

string _buf;

string tempMapUrl = "";