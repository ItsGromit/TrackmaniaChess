void FetchPracticeModeRaceMap() {
    print("[Chess] Fetching random campaign map for practice race...");
    // Store the values for the race challenge
    string savedCaptureFrom = captureFrom;
    string savedCaptureTo = captureTo;
    bool savedIsDefender = isDefender;
    // Use MXRandom approach: fetch a random page to get variety
    // Each page has up to 100 maps, use random offset for true randomness
    int randomPage = Math::Rand(0, 10);  // 10 pages = up to 1000 maps pool
    int pageSize = 100;
    // Fetch from current campaign by searching for Nadeo maps with campaign tag
    // Random order ensures we get different maps each time
    string tmxUrl = "https://trackmania.exchange/mapsearch2/search?api=on&authorlogin=nadeo&tags=23&limit=" + pageSize + "&page=" + randomPage + "&random=1";
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
                print("[Chess] TMX returned " + results.Length + " maps");
                // Filter maps using comprehensive criteria
                array<Json::Value@> validMaps;
                for (uint i = 0; i < results.Length; i++) {
                    auto mapData = results[i];
                    string mapName = mapData.HasKey("GbxMapName") ? string(mapData["GbxMapName"]) : string(mapData["Name"]);
                    int awardCount = mapData.HasKey("AwardCount") ? int(mapData["AwardCount"]) : 0;
                    // Strip Trackmania formatting codes ($ followed by 1-3 characters)
                    string cleanName = mapName;
                    while (cleanName.Contains("$")) {
                        int dollarPos = cleanName.IndexOf("$");
                        if (dollarPos >= 0 && dollarPos < int(cleanName.Length) - 1) {
                            // Remove $ and up to 3 following characters
                            int charsToRemove = Math::Min(4, int(cleanName.Length) - dollarPos);
                            cleanName = cleanName.SubStr(0, dollarPos) + cleanName.SubStr(dollarPos + charsToRemove);
                        } else {
                            break;
                        }
                    }
                    string lowerMapName = cleanName.ToLower();
                    // Filter out low-quality/problematic maps
                    bool shouldFilter = false;
                    // Kacky and LOL maps
                    if (lowerMapName.Contains("kacky") || lowerMapName.Contains("lol")) {
                        shouldFilter = true;
                    }
                    // Low-effort maps with excessive awards (likely troll maps)
                    if (awardCount > 15) {
                        print("[Chess] Filtering out high award count map: " + cleanName + " (awards: " + awardCount + ")");
                        shouldFilter = true;
                    }
                    // Common problematic keywords
                    if (lowerMapName.Contains("impossible") || lowerMapName.Contains("trash") ||
                        lowerMapName.Contains("awful") || lowerMapName.Contains("garbage") ||
                        lowerMapName.Contains("rmc") || lowerMapName.Contains("rms") || lowerMapName.Contains("rmt")) {
                        print("[Chess] Filtering out low-quality map: " + cleanName);
                        shouldFilter = true;
                    }
                    if (shouldFilter) {
                        continue;
                    }
                    validMaps.InsertLast(mapData);
                }
                if (validMaps.Length == 0) {
                    // No valid maps in this batch, try a different random page
                    print("[Chess] No valid maps on page " + randomPage + ", retrying with different page");
                    startnew(FetchPracticeModeRaceMap);
                    return;
                }
                print("[Chess] " + validMaps.Length + " valid maps found on page " + randomPage);
                // Pick a random map from the filtered list
                int randomIndex = Math::Rand(0, validMaps.Length);
                auto mapData = validMaps[randomIndex];
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
    // Simulate receiving a race_challenge message, preserving the actual move coordinates
    raceMapName = testMapName;
    captureFrom = savedCaptureFrom;
    captureTo = savedCaptureTo;
    isDefender = savedIsDefender;
    defenderTime = -1;
    // Reset race state - timer will start when map loads
    playerFinishedRace = false;
    playerRaceTime = -1;
    playerDNF = false;
    raceStartedAt = 0;
    print("[Chess] Practice Race - Map: " + raceMapName + ", Move: " + captureFrom + " to " + captureTo + ", You are: " + (isDefender ? "Defender" : "Attacker"));
    GameManager::currentState = GameState::RaceChallenge;
    // Download and load the map from TMX
    DownloadAndLoadMapFromTMX(tmxId, testMapName);
}