void FetchTestRaceMap() {
    print("[Chess] Fetching random campaign map for test race...");
    // Fetch from current campaign by searching for Nadeo maps with campaign tag
    // Exclude Kacky (tag 37) and LOL (tag 29)
    string tmxUrl = "https://trackmania.exchange/mapsearch2/search?api=on&authorlogin=nadeo&tags=23&etags=37,29&limit=25&order=TrackID&orderdir=DESC";
    auto req = Net::HttpRequest();
    req.Url = tmxUrl;
    req.Method = Net::HttpMethod::Get;
    req.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
    req.Start();
    // Wait for request to complete
    while (!req.Finished()) {
        yield();
    }
    int tmxId = -1;
    string testMapName;
    if (req.ResponseCode() == 200) {
        // Parse response
        auto response = Json::Parse(req.String());
        if (response.GetType() == Json::Type::Object && response.HasKey("results")) {
            auto results = response["results"];
            if (results.Length > 0) {
                // Pick a random map from the campaign
                int randomIndex = Math::Rand(0, results.Length);
                auto mapData = results[randomIndex];
                tmxId = int(mapData["TrackID"]);
                testMapName = mapData.HasKey("GbxMapName") ? string(mapData["GbxMapName"]) : string(mapData["Name"]);
                print("[Chess] Selected campaign map: " + testMapName + " (TMX ID: " + tmxId + ")");
            } else {
                print("[Chess] No campaign maps found, cannot start test race");
                UI::ShowNotification("Chess", "No campaign maps found", vec4(1,0.4,0.4,1), 4000);
                return;
            }
        } else {
            print("[Chess] Invalid TMX response, cannot start test race");
            UI::ShowNotification("Chess", "Invalid TMX response", vec4(1,0.4,0.4,1), 4000);
            return;
        }
    } else {
        print("[Chess] Failed to fetch from TMX (HTTP " + req.ResponseCode() + "), cannot start test race");
        UI::ShowNotification("Chess", "Failed to fetch from TMX", vec4(1,0.4,0.4,1), 4000);
        return;
    }
    // Simulate receiving a race_challenge message
    raceMapName = testMapName;
    isDefender = (Math::Rand(0, 2) == 0); // Random attacker/defender
    captureFrom = "e2";
    captureTo = "e4";
    defenderTime = -1;
    // Reset race state - timer will start when map loads
    playerFinishedRace = false;
    playerRaceTime = -1;
    playerDNF = false;
    raceStartedAt = 0;
    print("[Chess] Test Race - Map: " + raceMapName + ", You are: " + (isDefender ? "Defender" : "Attacker"));
    GameManager::currentState = GameState::RaceChallenge;
    // Download and load the map from TMX
    DownloadAndLoadMapFromTMX(tmxId, testMapName);
}