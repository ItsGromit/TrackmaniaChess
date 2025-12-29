void FetchDevRandomMap() {
    print("[Chess] Fetching random map from current campaign...");
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
    if (req.ResponseCode() != 200) {
        print("[Chess] ERROR: Failed to fetch campaign maps from TMX. HTTP code: " + req.ResponseCode());
        UI::ShowNotification("Chess", "Failed to fetch map from TMX", vec4(1,0.4,0.4,1), 4000);
        return;
    }
    // Parse response
    auto response = Json::Parse(req.String());
    if (response.GetType() != Json::Type::Object || !response.HasKey("results")) {
        print("[Chess] ERROR: Invalid TMX response");
        UI::ShowNotification("Chess", "Invalid TMX response", vec4(1,0.4,0.4,1), 4000);
        return;
    }
    auto results = response["results"];
    if (results.Length == 0) {
        print("[Chess] ERROR: No maps found in current campaign");
        UI::ShowNotification("Chess", "No maps found", vec4(1,0.4,0.4,1), 4000);
        return;
    }
    // Pick a random map from the results
    int randomIndex = Math::Rand(0, results.Length);
    auto mapData = results[randomIndex];
    int tmxId = int(mapData["TrackID"]);
    raceMapName = mapData.HasKey("GbxMapName") ? string(mapData["GbxMapName"]) : string(mapData["Name"]);
    print("[Chess] Re-rolled to new map: " + raceMapName + " (TMX ID: " + tmxId + ")");
    UI::ShowNotification("Chess", "Loading new map: " + raceMapName, vec4(0.2,0.8,0.2,1), 5000);
    // Download and load the new map from TMX
    DownloadAndLoadMapFromTMX(tmxId, raceMapName);
}