class Lobby {
    string  id;
    string  title = "";  // Display name for the lobby
    string  hostId;
    int     players;
    bool    open;
    bool    hasPassword;
    string  password;
    array<string> playerNames;
    string  raceMode = "capture";  // "square" or "capture"
}