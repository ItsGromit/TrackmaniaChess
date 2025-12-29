void LoadMapNow() {
    string mapUid = tempMapUrl;
    tempMapUrl = "";
    print("[Chess] Starting map load coroutine with UID: " + mapUid);
    auto app = cast<CTrackMania>(GetApp());
    if (app is null) {
        print("[Chess] Error: Could not get app instance for loading");
        return;
    }
    // Check if we're already in a map
    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    if (playground !is null) {
        print("[Chess] Currently in a map, returning to menu first");
        app.BackToMainMenu();
        // Wait for menu transition
        for (int i = 0; i < 100; i++) {
            yield();
            auto check = cast<CSmArenaClient>(app.CurrentPlayground);
            if (check is null) {
                print("[Chess] Successfully returned to menu");
                break;
            }
        }
        sleep(1000);
    }
    // Try to find the map in the local file system or campaign
    print("[Chess] Searching for map with UID: " + mapUid);
    auto menuManager = app.MenuManager;
    if (menuManager is null) {
        print("[Chess] ERROR: MenuManager is null");
        return;
    }
    CGameCtnChallengeInfo@ mapInfo = null;
    auto campaignInfos = menuManager.ChallengeInfosCampaign;
    // Search for the map in campaigns
    if (campaignInfos.Length > 0) {
        print("[Chess] Searching through " + campaignInfos.Length + " campaign maps");
        for (uint i = 0; i < campaignInfos.Length; i++) {
            auto info = campaignInfos[i];
            if (info.MapUid == mapUid) {
                @mapInfo = info;
                print("[Chess] Found map: " + info.Name);
                break;
            }
        }
    }
    // If map not found locally, download it from TrackmaniaExchange
    if (mapInfo is null) {
        print("[Chess] Map not found locally, searching TrackmaniaExchange...");
        // First, search TMX for the map by UID
        string searchUrl = "https://trackmania.exchange/mapsearch2/search?api=on&trackuid=" + mapUid;
        print("[Chess] Searching TMX: " + searchUrl);
        auto searchReq = Net::HttpRequest();
        searchReq.Url = searchUrl;
        searchReq.Method = Net::HttpMethod::Get;
        searchReq.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
        searchReq.Start();
        // Wait for search to complete
        while (!searchReq.Finished()) {
            yield();
        }
        if (searchReq.ResponseCode() != 200) {
            print("[Chess] ERROR: TMX search failed. HTTP code: " + searchReq.ResponseCode());
            print("[Chess] Cannot download map without TMX ID");
            return;
        }
        // Parse the search results
        auto searchResult = Json::Parse(searchReq.String());
        if (searchResult.GetType() != Json::Type::Object || !searchResult.HasKey("results")) {
            print("[Chess] ERROR: Invalid TMX search response");
            return;
        }
        auto results = searchResult["results"];
        if (results.Length == 0) {
            print("[Chess] ERROR: Map not found on TrackmaniaExchange");
            print("[Chess] The map might be a campaign/official map or not uploaded to TMX");
            return;
        }
        // Get the first result (should be exact match by UID)
        auto mapData = results[0];
        int tmxId = int(mapData["TrackID"]);
        string mapName = string(mapData["GbxMapName"]);
        print("[Chess] Found map on TMX: " + mapName + " (ID: " + tmxId + ")");
        // Download the map from TMX
        string downloadUrl = "https://trackmania.exchange/maps/download/" + tmxId;
        print("[Chess] Downloading from: " + downloadUrl);
        auto downloadReq = Net::HttpRequest();
        downloadReq.Url = downloadUrl;
        downloadReq.Method = Net::HttpMethod::Get;
        downloadReq.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
        downloadReq.Start();
        // Wait for download to complete
        while (!downloadReq.Finished()) {
            yield();
        }
        if (downloadReq.ResponseCode() == 200) {
            string mapFileData = downloadReq.String();
            print("[Chess] Map downloaded successfully (" + mapFileData.Length + " bytes)");
            // Save the map to a temporary location
            string tempMapPath = IO::FromUserGameFolder("Maps/Downloaded/" + mapUid + ".Map.Gbx");
            // Create directory if it doesn't exist
            string dir = IO::FromUserGameFolder("Maps/Downloaded/");
            if (!IO::FolderExists(dir)) {
                IO::CreateFolder(dir);
                print("[Chess] Created download directory: " + dir);
            }
            // Write the map file
            IO::File file;
            file.Open(tempMapPath, IO::FileMode::Write);
            file.Write(mapFileData);
            file.Close();
            print("[Chess] Map saved to: " + tempMapPath);
            // Now try to load the downloaded map
            auto maniaTitleAPI = app.ManiaTitleControlScriptAPI;
            if (maniaTitleAPI !is null) {
                print("[Chess] Loading downloaded map...");
                maniaTitleAPI.PlayMap(tempMapPath, "TrackMania/TM_PlayMap_Local", "");
                sleep(3000);
                auto result = cast<CSmArenaClient>(app.CurrentPlayground);
                if (result !is null) {
                    print("[Chess] SUCCESS: Downloaded map loaded!");
                } else {
                    print("[Chess] Map loading - please wait...");
                }
            }
        } else {
            print("[Chess] ERROR: Failed to download map from TMX. HTTP code: " + downloadReq.ResponseCode());
            print("[Chess] The download might have been blocked or the map is unavailable");
        }
        return;
    }
    // If we found the map locally, load it directly
    print("[Chess] Loading map from local files: " + mapInfo.FileName);
    app.BackToMainMenu();
    yield();
    auto maniaTitleAPI = app.ManiaTitleControlScriptAPI;
    if (maniaTitleAPI !is null) {
        maniaTitleAPI.PlayMap(mapInfo.FileName, "TrackMania/TM_PlayMap_Local", "");
        // Wait and verify
        sleep(3000);
        auto result = cast<CSmArenaClient>(app.CurrentPlayground);
        if (result !is null) {
            print("[Chess] SUCCESS: Map loaded!");
        } else {
            print("[Chess] Map loading - please wait...");
        }
    }
}