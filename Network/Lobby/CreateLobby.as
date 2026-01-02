void CreateLobby(const string &in roomTitle = "", const string &in password = "", const string &in raceModeOverride = "", const string &in playerName = "") {
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
    // Send race mode selection - use override if provided, otherwise use current global mode
    string raceMode;
    if (raceModeOverride.Length > 0) {
        raceMode = raceModeOverride;
        // Update currentRaceMode to match
        currentRaceMode = (raceModeOverride == "square") ? RaceMode::SquareRace : RaceMode::CaptureRace;
    } else {
        raceMode = currentRaceMode == RaceMode::SquareRace ? "square" : "capture";
    }
    j["raceMode"] = raceMode;
    currentLobbyRaceMode = raceMode; // Store locally

    // Send mappack ID for Chess Race mode
    if (currentRaceMode == RaceMode::SquareRace) {
        j["mappackId"] = squareRaceMappackId;
        print("[Chess] Creating lobby - RoomCode: " + code + ", Title: " + (roomTitle.Length > 0 ? roomTitle : "(none)") + ", HasPassword: " + (password.Length > 0 ? "yes" : "no") + ", Player: " + name + ", Mode: Chess Race, Mappack: " + squareRaceMappackId);
    } else {
        print("[Chess] Creating lobby - RoomCode: " + code + ", Title: " + (roomTitle.Length > 0 ? roomTitle : "(none)") + ", HasPassword: " + (password.Length > 0 ? "yes" : "no") + ", Player: " + name + ", Mode: Capture Race");
    }
    SendJson(j);
}