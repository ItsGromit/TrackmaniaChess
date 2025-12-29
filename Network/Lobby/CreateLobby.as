void CreateLobby(const string &in roomTitle = "", const string &in password = "", const string &in playerName = "") {
    Json::Value j = Json::Object();
    j["type"] = "create_lobby";
    // Always generate random 5-letter room code
    string code = "";
    const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (uint i = 0; i < 5; i++) {
        uint index = Math::Rand(0, chars.Length);
        code += chars.SubStr(index, 1);
    }
    j["lobbyId"] = code;
    // Add room title if provided
    if (roomTitle.Length > 0) {
        j["title"] = roomTitle;
    }
    if (password.Length > 0) j["password"] = password;
    // Get local player name
    string name = playerName.Length > 0 ? playerName : GetLocalPlayerName();
    j["playerName"] = name;
    // Send race mode selection
    string raceMode = currentRaceMode == RaceMode::SquareRace ? "square" : "capture";
    j["raceMode"] = raceMode;
    currentLobbyRaceMode = raceMode; // Store locally
    print("[Chess] Creating lobby - RoomCode: " + code + ", Title: " + (roomTitle.Length > 0 ? roomTitle : "(none)") + ", HasPassword: " + (password.Length > 0 ? "yes" : "no") + ", Player: " + name + ", Mode: " + (currentRaceMode == RaceMode::SquareRace ? "Chess Race" : "Capture Race"));
    SendJson(j);
}