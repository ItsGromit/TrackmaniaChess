void DownloadAndLoadMapFromTMX(int tmxId, const string &in mapName = "") {
    print("[Chess] Loading map from TMX ID: " + tmxId + (mapName.Length > 0 ? " (" + mapName + ")" : ""));
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
    auto maniaTitleAPI = app.ManiaTitleControlScriptAPI;
    if (maniaTitleAPI !is null) {
        // Load map directly from TMX URL without saving to disk
        // This is what MXRandom and other plugins do
        string mapUrl = "https://trackmania.exchange/maps/download/" + tmxId;
        print("[Chess] Loading map from URL: " + mapUrl);
        maniaTitleAPI.PlayMap(mapUrl, "TrackMania/TM_PlayMap_Local", "");
        sleep(3000);
        auto result = cast<CSmArenaClient>(app.CurrentPlayground);
        if (result !is null) {
            print("[Chess] SUCCESS: Map loaded from TMX!");
        } else {
            print("[Chess] Map loading - please wait...");
        }
    }
}