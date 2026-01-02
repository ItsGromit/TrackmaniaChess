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
 * [DEPRECATED] Client-side map assignment removed
 * All map assignments now come from the server for perfect multiplayer sync
 * This function should never be called - server provides maps via ApplyServerBoardMaps()
 */
void AssignMapsFromMappack(int) {
    error("[ChessRace::MapAssignment] ERROR: Client-side map assignment is deprecated!");
    error("[ChessRace::MapAssignment] Maps should be assigned by the server, not the client.");
    error("[ChessRace::MapAssignment] Check that the server is sending boardMaps in game_start message.");
}

/**
 * [DEPRECATED] Client-side random map assignment removed
 * All map assignments now come from the server
 */
void AssignRandomMapsToBoard() {
    error("[ChessRace::MapAssignment] ERROR: Client-side random map assignment is deprecated!");
    error("[ChessRace::MapAssignment] Maps should be assigned by the server, not the client.");
}

/**
 * Clears all map assignments from the board
 */
void ClearBoardMaps() {
    // TODO: Implement board map clearing
    print("[ChessRace::MapAssignment] TODO: ClearBoardMaps()");
}

/**
 * Apply server-assigned board maps (for multiplayer sync)
 * The server sends an array of 64 map objects with tmxId and mapName
 */
void ApplyServerBoardMaps(const Json::Value &in boardMapsJson) {
    if (boardMapsJson.GetType() != Json::Type::Array) {
        warn("[MapAssignment] Invalid boardMaps format from server - expected Array, got " + tostring(boardMapsJson.GetType()));
        return;
    }

    uint arrayLength = boardMapsJson.Length;
    print("[MapAssignment] Applying " + arrayLength + " server-assigned maps...");

    if (arrayLength == 0) {
        warn("[MapAssignment] Server sent empty boardMaps array!");
        return;
    }

    int mapsApplied = 0;
    for (uint i = 0; i < arrayLength && i < 64; i++) {
        int row = i / 8;
        int col = i % 8;

        Json::Value mapObj = boardMapsJson[i];
        Json::Type objType = mapObj.GetType();

        if (objType != Json::Type::Object) {
            warn("[MapAssignment] Position " + i + " is not an object (type: " + tostring(objType) + "), skipping");
            continue;
        }

        // Check if required fields exist
        if (!mapObj.HasKey("tmxId") || !mapObj.HasKey("mapName")) {
            warn("[MapAssignment] Position " + i + " missing required fields (tmxId or mapName)");
            continue;
        }

        // Ensure square data exists
        if (boardMaps[row][col] is null) {
            @boardMaps[row][col] = RaceMode::SquareMapData();
        }

        // Apply server-assigned data
        int tmxId = int(mapObj["tmxId"]);
        string mapName = string(mapObj["mapName"]);

        boardMaps[row][col].tmxId = tmxId;
        boardMaps[row][col].mapName = mapName;
        boardMaps[row][col].thumbnailUrl = "https://trackmania.exchange/mapthumb/" + tmxId;

        // Log first few assignments and last one for debugging
        if (i < 3 || i == 63) {
            print("[MapAssignment] Position " + i + " (row " + row + ", col " + col + "): " + mapName + " (TMX " + tmxId + ")");
        }

        mapsApplied++;
    }

    print("[MapAssignment] Successfully applied " + mapsApplied + "/" + arrayLength + " server-assigned maps to board");

    // Verify a few random squares to ensure data persisted
    if (mapsApplied > 0) {
        print("[MapAssignment] Verification - Square [0,0]: " + (boardMaps[0][0] !is null ? boardMaps[0][0].mapName : "NULL"));
        print("[MapAssignment] Verification - Square [3,4]: " + (boardMaps[3][4] !is null ? boardMaps[3][4].mapName : "NULL"));
        print("[MapAssignment] Verification - Square [7,7]: " + (boardMaps[7][7] !is null ? boardMaps[7][7].mapName : "NULL"));
    }
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
