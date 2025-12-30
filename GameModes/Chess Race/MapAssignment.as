// ============================================================================
// SQUARE RACE MODE - MAP ASSIGNMENT SYSTEM
// ============================================================================

namespace RaceMode {

namespace MapAssignment {

// 8x8 grid of map assignments (indexed as [row][col])
array<array<SquareMapData@>> boardMaps(8);

/**
 * Initializes the board maps grid
 */
void InitializeBoardMaps() {
    // Initialize 8x8 grid
    for (int row = 0; row < 8; row++) {
        boardMaps[row].Resize(8);
        for (int col = 0; col < 8; col++) {
            @boardMaps[row][col] = SquareMapData();
        }
    }
}

/**
 * Associates a Trackmania map with a specific chess board square
 *
 * @param row The row index (0-7, where 0 is rank 1)
 * @param col The column index (0-7, where 0 is file 'a')
 * @param tmxId The Trackmania Exchange map ID
 * @param mapName Display name of the map
 * @param mapUid Unique map identifier
 * @param thumbnailUrl URL to fetch the map thumbnail
 * @param authorTime Author medal time in milliseconds
 * @param difficulty Difficulty rating 1-5
 * @return true on success, false on invalid parameters
 */
bool AssignMapToSquare(int row, int col, int tmxId, const string &in mapName,
                       const string &in mapUid, const string &in thumbnailUrl,
                       int authorTime, int difficulty) {
    // TODO: Implement map assignment logic
    print("[ChessRace::MapAssignment] TODO: AssignMapToSquare(" + row + ", " + col + ", " + tmxId + ", " + mapName + ")");
    return false;
}

/**
 * Assigns maps from a specific mappack to all 64 board squares
 *
 * @param mappackId The TMX mappack ID to use (e.g., 7237 for Chess Race)
 */
void AssignMapsFromMappack(int mappackId) {
    print("[ChessRace::MapAssignment] Assigning maps from mappack " + mappackId + "...");

    // Use the modern /api/maps endpoint (Method Index 53)
    // Request only the fields we need for better performance
    string fields = "MapId,MapUid,Name";
    string tmxUrl = "https://trackmania.exchange/api/maps?mapPackId=" + mappackId + "&count=80&fields=" + fields;

    auto req = Net::HttpRequest();
    req.Url = tmxUrl;
    req.Method = Net::HttpMethod::Get;
    req.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
    req.Start();

    while (!req.Finished()) yield();

    if (req.ResponseCode() != 200) {
        print("[ChessRace::MapAssignment] Failed to fetch mappack from TMX: HTTP " + req.ResponseCode());
        // Always fall back to default mappack
        if (mappackId != 7237) {
            print("[ChessRace::MapAssignment] Falling back to default mappack (7237)");
            AssignMapsFromMappack(7237);
        } else {
            print("[ChessRace::MapAssignment] ERROR: Default mappack failed! Cannot continue.");
        }
        return;
    }

    auto response = Json::Parse(req.String());

    // /api/maps endpoint returns {Results: [...], More: bool} format
    Json::Value@ json;
    if (response.GetType() == Json::Type::Object && response.HasKey("Results")) {
        @json = response["Results"];
        bool hasMore = response.HasKey("More") ? bool(response["More"]) : false;
        if (hasMore) {
            print("[ChessRace::MapAssignment] Warning: Mappack has more than 100 maps, only using first 100");
        }
    } else {
        print("[ChessRace::MapAssignment] Invalid mappack response format (expected Results field)");
        // Always fall back to default mappack
        if (mappackId != 7237) {
            print("[ChessRace::MapAssignment] Falling back to default mappack (7237)");
            AssignMapsFromMappack(7237);
        } else {
            print("[ChessRace::MapAssignment] ERROR: Default mappack invalid! Cannot continue.");
        }
        return;
    }

    if (json.GetType() != Json::Type::Array) {
        print("[ChessRace::MapAssignment] Results is not an array");
        // Always fall back to default mappack
        if (mappackId != 7237) {
            print("[ChessRace::MapAssignment] Falling back to default mappack (7237)");
            AssignMapsFromMappack(7237);
        } else {
            print("[ChessRace::MapAssignment] ERROR: Default mappack results invalid! Cannot continue.");
        }
        return;
    }

    print("[ChessRace::MapAssignment] Mappack contains " + json.Length + " maps");

    // Check if mappack is empty and fall back to default
    if (json.Length == 0) {
        print("[ChessRace::MapAssignment] Mappack is empty!");
        // Always fall back to default mappack
        if (mappackId != 7237) {
            print("[ChessRace::MapAssignment] Falling back to default mappack (7237)");
            AssignMapsFromMappack(7237);
        } else {
            print("[ChessRace::MapAssignment] ERROR: Default mappack is empty! Cannot continue.");
        }
        return;
    }

    // Assign maps to squares (loop through mappack, wrapping if needed)
    int mapIndex = 0;
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {

            // Wrap around if mappack has fewer than 64 maps
            auto mapObj = json[mapIndex % json.Length];

            if (boardMaps[row][col] is null) {
                @boardMaps[row][col] = SquareMapData();
            }

            // /api/maps endpoint uses MapId, MapUid, Name
            int mapId = int(mapObj["MapId"]);
            boardMaps[row][col].tmxId = mapId;
            boardMaps[row][col].mapName = string(mapObj["Name"]);
            boardMaps[row][col].mapUid = string(mapObj["MapUid"]);
            boardMaps[row][col].thumbnailUrl = "https://trackmania.exchange/mapthumb/" + mapId;

            // AuthorTime not included in minimal field request, set to -1
            boardMaps[row][col].authorTime = -1;

            mapIndex++;
        }
    }

    print("[ChessRace::MapAssignment] Assigned " + mapIndex + " maps to board squares from mappack");
}

/**
 * Assigns random maps to all 64 board squares
 * Uses campaign maps (Nadeo official maps)
 */
void AssignRandomMapsToBoard() {
    print("[ChessRace::MapAssignment] Assigning random campaign maps to all 64 squares...");

    // Fetch maps in batches to get 64 unique maps
    array<Json::Value@> allMaps;

    for (int page = 0; page < 8; page++) {
        int randomPage = Math::Rand(0, 10);
        string tmxUrl = "https://trackmania.exchange/mapsearch2/search?api=on&authorlogin=nadeo&tags=23&limit=100&page=" + randomPage + "&random=1";

        auto req = Net::HttpRequest();
        req.Url = tmxUrl;
        req.Method = Net::HttpMethod::Get;
        req.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
        req.Start();

        while (!req.Finished()) yield();

        if (req.ResponseCode() != 200) {
            print("[ChessRace::MapAssignment] Failed to fetch maps from TMX (page " + page + "): HTTP " + req.ResponseCode());
            continue;
        }

        auto response = Json::Parse(req.String());

        // Handle both direct array response and object with "results" key
        Json::Value@ json;
        if (response.GetType() == Json::Type::Object && response.HasKey("results")) {
            @json = response["results"];
        } else if (response.GetType() == Json::Type::Array) {
            @json = response;
        } else {
            print("[ChessRace::MapAssignment] Invalid TMX response format (page " + page + ")");
            continue;
        }

        if (json.GetType() != Json::Type::Array) {
            print("[ChessRace::MapAssignment] Results is not an array (page " + page + ")");
            continue;
        }

        print("[ChessRace::MapAssignment] Page " + page + " returned " + json.Length + " maps");

        // Filter and collect maps
        for (uint i = 0; i < json.Length; i++) {
            auto mapObj = json[i];

            string mapName = string(mapObj["GbxMapName"]);
            int awardCount = int(mapObj["AwardCount"]);

            // Strip formatting codes for filtering
            string cleanName = mapName;
            while (cleanName.Contains("$")) {
                int dollarPos = cleanName.IndexOf("$");
                if (dollarPos >= 0 && dollarPos < int(cleanName.Length) - 1) {
                    int charsToRemove = Math::Min(4, int(cleanName.Length) - dollarPos);
                    cleanName = cleanName.SubStr(0, dollarPos) + cleanName.SubStr(dollarPos + charsToRemove);
                } else {
                    break;
                }
            }
            string lowerMapName = cleanName.ToLower();

            // Apply quality filters
            bool shouldFilter = false;
            if (lowerMapName.Contains("kacky") || lowerMapName.Contains("lol")) {
                shouldFilter = true;
            }
            if (awardCount > 15) {
                shouldFilter = true;
            }
            if (lowerMapName.Contains("impossible") || lowerMapName.Contains("trash") ||
                lowerMapName.Contains("awful") || lowerMapName.Contains("garbage") ||
                lowerMapName.Contains("rmc") || lowerMapName.Contains("rms") || lowerMapName.Contains("rmt")) {
                shouldFilter = true;
            }

            if (!shouldFilter) {
                allMaps.InsertLast(mapObj);
                if (allMaps.Length >= 64) break;
            }
        }

        if (allMaps.Length >= 64) break;
    }

    if (allMaps.Length < 64) {
        print("[ChessRace::MapAssignment] Warning: Only found " + allMaps.Length + " valid maps (need 64)");
    }

    // Assign maps to squares
    int mapIndex = 0;
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            if (mapIndex >= int(allMaps.Length)) {
                print("[ChessRace::MapAssignment] Ran out of maps at square [" + row + ", " + col + "]");
                break;
            }

            auto mapObj = allMaps[mapIndex];

            if (boardMaps[row][col] is null) {
                @boardMaps[row][col] = SquareMapData();
            }

            boardMaps[row][col].tmxId = int(mapObj["TrackID"]);
            boardMaps[row][col].mapName = string(mapObj["GbxMapName"]);
            boardMaps[row][col].mapUid = string(mapObj["TrackUID"]);
            boardMaps[row][col].thumbnailUrl = "https://trackmania.exchange" + string(mapObj["ThumbnailUrl"]);
            boardMaps[row][col].authorTime = int(mapObj["AuthorTime"]);

            mapIndex++;
        }
    }

    print("[ChessRace::MapAssignment] Assigned " + mapIndex + " maps to board squares");
}

/**
 * Clears all map assignments from the board
 */
void ClearBoardMaps() {
    // TODO: Implement board map clearing
    print("[ChessRace::MapAssignment] TODO: ClearBoardMaps()");
}

/**
 * Retrieves the map data for a specific square
 *
 * @param row The row index (0-7)
 * @param col The column index (0-7)
 * @return Reference to SquareMapData, or null if invalid position
 */
RaceMode::SquareMapData@ GetSquareMap(int row, int col) {
    if (row < 0 || row >= 8 || col < 0 || col >= 8) {
        return null;
    }
    return boardMaps[row][col];
}

} // namespace MapAssignment

} // namespace ChessRace
