void LoadRaceMap(const string &in mapUid) {
    if (mapUid.Length == 0) {
        print("[Chess] Cannot load map - empty UID");
        return;
    }
    print("[Chess] Loading race map with UID: " + mapUid);
    // Try to load the map directly by UID
    // The PlayMap API might accept the UID directly, or we need to construct a proper URL
    // For now, we'll try the UID directly as many Openplanet plugins do
    print("[Chess] Attempting to load map by UID: " + mapUid);
    // Store the UID in a temporary variable for the coroutine
    tempMapUrl = mapUid;
    // Load the map using TrackMania's PlayMap function
    // The game mode for time attack is "TrackMania/TM_PlayMap_Local"
    startnew(LoadMapNow);
}