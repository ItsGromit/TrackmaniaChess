// ============================================================================
// NEW CHESS RACE MODE
// ============================================================================
// This is a new variant of the chess race mode where:
// - Each of the 64 chess board squares is assigned a specific Trackmania map
// - Map thumbnails are displayed on each square
// - Players race the map when selecting a square
// - Opponent checkpoint times are displayed in real-time during races
// ============================================================================

namespace NewRaceMode {

// ============================================================================
// DATA STRUCTURES
// ============================================================================

// Represents a map assigned to a chess board square
class SquareMapData {
    int tmxId = -1;                    // Trackmania Exchange map ID
    string mapName = "";               // Display name of the map
    string mapUid = "";                // Unique map identifier
    string thumbnailUrl = "";          // URL to map thumbnail image
    UI::Texture@ thumbnailTexture;     // Loaded thumbnail texture (null if not loaded)
    bool thumbnailLoading = false;     // Whether thumbnail is currently being fetched
    int authorTime = -1;               // Author time in milliseconds
    int difficulty = 0;                // Difficulty rating (1-5)

    SquareMapData() {}
}

// Stores opponent's checkpoint data during a race
class OpponentCheckpointData {
    array<int> checkpointTimes;        // Opponent's time at each checkpoint (milliseconds)
    int finalTime = -1;                // Final race time if finished
    bool hasFinished = false;          // Whether opponent finished the race
    int currentCheckpoint = 0;         // Current checkpoint index

    void Reset() {
        checkpointTimes.RemoveRange(0, checkpointTimes.Length);
        finalTime = -1;
        hasFinished = false;
        currentCheckpoint = 0;
    }
}

// ============================================================================
// GLOBAL STATE
// ============================================================================

// 8x8 grid of map assignments (indexed as [row][col])
array<array<SquareMapData@>> boardMaps(8);

// Current opponent checkpoint data
OpponentCheckpointData opponentData;

// Current race state
int selectedSquareRow = -1;
int selectedSquareCol = -1;
bool isRacingNewMode = false;

// ============================================================================
// MAP ASSIGNMENT SYSTEM
// ============================================================================

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
 *
 * TODO: Implement the following:
 * - Validate row/col bounds (0-7)
 * - Create new SquareMapData object
 * - Populate all fields from parameters
 * - Assign to boardMaps[row][col]
 * - Trigger thumbnail download for this square
 * - Log successful assignment
 * - Return true on success, false on invalid parameters
 */
bool AssignMapToSquare(int row, int col, int tmxId, const string &in mapName,
                       const string &in mapUid, const string &in thumbnailUrl,
                       int authorTime, int difficulty) {
    // TODO: Implement map assignment logic
    print("[NewRaceMode] TODO: AssignMapToSquare(" + row + ", " + col + ", " + tmxId + ", " + mapName + ")");
    return false;
}

/**
 * Assigns maps from a specific mappack to all 64 board squares
 *
 * @param mappackId The TMX mappack ID to use (e.g., 2823 for Training - Spring 2022)
 */
void AssignMapsFromMappack(int mappackId) {
    print("[NewRaceMode] Assigning maps from mappack " + mappackId + "...");

    string tmxUrl = "https://trackmania.exchange/api/mappack/get_mappack_tracks/" + mappackId;

    auto req = Net::HttpRequest();
    req.Url = tmxUrl;
    req.Method = Net::HttpMethod::Get;
    req.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
    req.Start();

    while (!req.Finished()) yield();

    if (req.ResponseCode() != 200) {
        print("[NewRaceMode] Failed to fetch mappack from TMX: HTTP " + req.ResponseCode());
        print("[NewRaceMode] Falling back to random campaign maps");
        AssignRandomMapsToBoard();
        return;
    }

    auto json = Json::Parse(req.String());
    if (json.GetType() != Json::Type::Array) {
        print("[NewRaceMode] Invalid mappack response format");
        print("[NewRaceMode] Falling back to random campaign maps");
        AssignRandomMapsToBoard();
        return;
    }

    print("[NewRaceMode] Mappack contains " + json.Length + " maps");

    // Assign maps to squares (loop through mappack, wrapping if needed)
    int mapIndex = 0;
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            if (json.Length == 0) {
                print("[NewRaceMode] Mappack is empty!");
                return;
            }

            // Wrap around if mappack has fewer than 64 maps
            auto mapObj = json[mapIndex % json.Length];

            if (boardMaps[row][col] is null) {
                @boardMaps[row][col] = SquareMapData();
            }

            boardMaps[row][col].tmxId = int(mapObj["TrackID"]);
            boardMaps[row][col].mapName = string(mapObj["TrackName"]);
            boardMaps[row][col].mapUid = string(mapObj["TrackUID"]);
            // Mappack API returns different thumbnail format
            boardMaps[row][col].thumbnailUrl = "https://trackmania.exchange/maps/screenshot/normal/" + tostring(int(mapObj["TrackID"]));
            boardMaps[row][col].authorTime = mapObj.HasKey("AuthorTime") ? int(mapObj["AuthorTime"]) : -1;

            mapIndex++;
        }
    }

    print("[NewRaceMode] Assigned " + mapIndex + " maps to board squares from mappack");
}

/**
 * Assigns random maps to all 64 board squares
 * Uses campaign maps (Nadeo official maps)
 */
void AssignRandomMapsToBoard() {
    print("[NewRaceMode] Assigning random campaign maps to all 64 squares...");

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
            print("[NewRaceMode] Failed to fetch maps from TMX (page " + page + "): HTTP " + req.ResponseCode());
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
            print("[NewRaceMode] Invalid TMX response format (page " + page + ")");
            continue;
        }

        if (json.GetType() != Json::Type::Array) {
            print("[NewRaceMode] Results is not an array (page " + page + ")");
            continue;
        }

        print("[NewRaceMode] Page " + page + " returned " + json.Length + " maps");

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
        print("[NewRaceMode] Warning: Only found " + allMaps.Length + " valid maps (need 64)");
    }

    // Assign maps to squares
    int mapIndex = 0;
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            if (mapIndex >= int(allMaps.Length)) {
                print("[NewRaceMode] Ran out of maps at square [" + row + ", " + col + "]");
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

    print("[NewRaceMode] Assigned " + mapIndex + " maps to board squares");
}

/**
 * Clears all map assignments from the board
 *
 * TODO: Implement the following:
 * - Iterate through all 64 squares
 * - Release thumbnail textures to free memory
 * - Reset SquareMapData objects to default state
 * - Cancel any ongoing thumbnail downloads
 */
void ClearBoardMaps() {
    // TODO: Implement board map clearing
    print("[NewRaceMode] TODO: ClearBoardMaps()");
}

/**
 * Retrieves the map data for a specific square
 *
 * @param row The row index (0-7)
 * @param col The column index (0-7)
 * @return Reference to SquareMapData, or null if invalid position
 */
SquareMapData@ GetSquareMap(int row, int col) {
    if (row < 0 || row >= 8 || col < 0 || col >= 8) {
        return null;
    }
    return boardMaps[row][col];
}

// ============================================================================
// THUMBNAIL RENDERING
// ============================================================================

/**
 * Downloads and caches a map thumbnail image
 *
 * @param squareData Reference to the square's map data
 *
 * TODO: Implement the following:
 * - Check if thumbnail already loaded (squareData.thumbnailTexture !is null)
 * - Set squareData.thumbnailLoading = true
 * - Fetch image from squareData.thumbnailUrl using HTTP request
 * - Convert image bytes to UI::Texture
 * - Assign texture to squareData.thumbnailTexture
 * - Set squareData.thumbnailLoading = false
 * - Handle errors gracefully (use placeholder on failure)
 * - Consider using async coroutine (startnew) for non-blocking load
 */
void DownloadThumbnail(SquareMapData@ squareData) {
    // TODO: Implement thumbnail download
    if (squareData is null) return;
    print("[NewRaceMode] TODO: DownloadThumbnail for " + squareData.mapName);
}

/**
 * Renders a map thumbnail on a chess board square
 *
 * @param row The row index (0-7)
 * @param col The column index (0-7)
 * @param squareSize The size of the square in pixels
 * @param squarePos The screen position of the square (top-left corner)
 *
 * TODO: Implement the following:
 * - Get SquareMapData for this position
 * - If no map assigned, show default chess square (no thumbnail)
 * - If thumbnailTexture exists, render it over the square:
 *   - Use UI::DrawImage or ImGui image rendering
 *   - Fit thumbnail within square bounds (preserve aspect ratio or stretch)
 *   - Apply semi-transparent overlay so pieces are still visible
 * - If thumbnailLoading, show loading spinner or placeholder
 * - If thumbnail failed to load, show error icon or solid color
 * - Consider rendering map name as tooltip on hover
 */
void RenderMapThumbnail(int row, int col, float squareSize, vec2 squarePos) {
    // TODO: Implement thumbnail rendering
    // This will be called from UI.as BoardRender() function for each square
}

/**
 * Preloads thumbnails for all assigned maps
 *
 * TODO: Implement the following:
 * - Iterate through all 64 board squares
 * - For each square with assigned map, start thumbnail download
 * - Limit concurrent downloads to avoid overwhelming the system (max 8 at once)
 * - Use a queue system for downloading
 * - Update UI progress indicator during batch download
 */
void PreloadAllThumbnails() {
    // TODO: Implement batch thumbnail preloading
    print("[NewRaceMode] TODO: PreloadAllThumbnails()");
}

/**
 * Clears all cached thumbnails to free memory
 *
 * TODO: Implement the following:
 * - Iterate through all SquareMapData objects
 * - Release texture resources (set thumbnailTexture = null)
 * - Reset loading flags
 * - Force garbage collection if needed
 */
void ClearThumbnailCache() {
    // TODO: Implement thumbnail cache clearing
    print("[NewRaceMode] TODO: ClearThumbnailCache()");
}

// ============================================================================
// RACE MODE CORE LOGIC
// ============================================================================

// Global variables to pass capture square coordinates to the coroutine
int pendingCaptureRow = -1;
int pendingCaptureCol = -1;

/**
 * Wrapper function for startnew to fetch square race map
 * Sets global pending coordinates first
 */
void FetchSquareRaceMapWrapper() {
    if (pendingCaptureRow >= 0 && pendingCaptureCol >= 0) {
        FetchSquareRaceMap(pendingCaptureRow, pendingCaptureCol);
        pendingCaptureRow = -1;
        pendingCaptureCol = -1;
    }
}

/**
 * Loads the map assigned to a specific square for a capture race
 * This is called when a capture move is made in Square Race mode
 *
 * @param row The row of the capture destination square
 * @param col The column of the capture destination square
 */
void FetchSquareRaceMap(int row, int col) {
    print("[NewRaceMode] FetchSquareRaceMap for square [" + row + ", " + col + "]");

    SquareMapData@ mapData = GetSquareMap(row, col);
    if (mapData is null || mapData.tmxId == -1) {
        print("[NewRaceMode] Error: No map assigned to square [" + row + ", " + col + "]");
        // Fallback to random map
        Network::FetchPracticeModeRaceMap();
        return;
    }

    // Use the assigned map for this square
    print("[NewRaceMode] Loading assigned map: " + mapData.mapName + " (TMX ID: " + mapData.tmxId + ")");

    // Set the race map details (these are used by the race UI)
    Network::raceMapTmxId = mapData.tmxId;
    Network::raceMapName = mapData.mapName;

    // Download and load the map
    Network::DownloadAndLoadMapFromTMX(mapData.tmxId, mapData.mapName);

    // Reset race state
    playerFinishedRace = false;
    playerRaceTime = -1;
    playerDNF = false;
}

/**
 * Executes the race mode when a player selects a square
 *
 * @param row The row of the selected square
 * @param col The column of the selected square
 *
 * TODO: Implement the following:
 * - Validate that square has an assigned map
 * - Store selected square position (selectedSquareRow, selectedSquareCol)
 * - Set isRacingNewMode = true
 * - Reset opponent checkpoint data (opponentData.Reset())
 * - Download the map if not already cached locally
 * - Load the map in Trackmania
 * - Transition GameState to appropriate racing state
 * - Initialize player spawn position
 * - Send race start notification to opponent (in multiplayer)
 * - Start listening for opponent checkpoint updates
 * - Begin race timer
 */
void ExecuteRaceMode(int row, int col) {
    // TODO: Implement race execution
    print("[NewRaceMode] TODO: ExecuteRaceMode(" + row + ", " + col + ")");

    SquareMapData@ mapData = GetSquareMap(row, col);
    if (mapData is null) {
        print("[NewRaceMode] Error: No map assigned to square [" + row + ", " + col + "]");
        return;
    }

    // TODO: Continue implementation
    selectedSquareRow = row;
    selectedSquareCol = col;
    isRacingNewMode = true;
}

/**
 * Handles race completion for the local player
 *
 * @param finalTime Player's final race time in milliseconds
 *
 * TODO: Implement the following:
 * - Record player's final time
 * - Send final time to opponent (in multiplayer)
 * - Wait for opponent to finish (or timeout after X seconds)
 * - Compare times to determine winner
 * - Apply chess move/action based on result (TBD: what happens when you win/lose?)
 * - Show race result UI
 * - Return to chess board view
 * - Reset race state (isRacingNewMode = false)
 */
void HandleRaceCompletion(int finalTime) {
    // TODO: Implement race completion handling
    print("[NewRaceMode] TODO: HandleRaceCompletion(" + finalTime + "ms)");
}

/**
 * Handles player giving up / DNF during race
 *
 * TODO: Implement the following:
 * - Mark player as DNF
 * - Send DNF notification to opponent
 * - Determine race result (opponent wins if they finish)
 * - Handle double-DNF scenario (use default rule: attacker wins)
 * - Return to chess board
 * - Show appropriate message to player
 */
void HandleRaceDNF() {
    // TODO: Implement DNF handling
    print("[NewRaceMode] TODO: HandleRaceDNF()");
}

/**
 * Updates race state each frame (called from main Update loop)
 *
 * TODO: Implement the following:
 * - Check if player crossed a checkpoint (read from CSmScriptPlayer)
 * - Send checkpoint time to opponent when reached
 * - Check if player finished race (BestRaceTimes[0] > 0)
 * - Check if player returned to menu (CurrentPlayground is null = DNF)
 * - Update local race timer display
 * - Process incoming opponent checkpoint updates
 */
void UpdateRaceState() {
    // TODO: Implement race state updates
    if (!isRacingNewMode) return;

    // TODO: Add frame-by-frame race monitoring logic
}

// ============================================================================
// OPPONENT TIME DISPLAY
// ============================================================================

/**
 * Renders opponent's checkpoint times during active race
 *
 * TODO: Implement the following:
 * - Display a UI panel on screen during race (non-intrusive position)
 * - Show opponent's name/identifier
 * - List each checkpoint with opponent's time
 * - Highlight current checkpoint opponent is on
 * - Show time delta (ahead/behind) compared to player's checkpoints
 * - Use color coding: green if player ahead, red if behind
 * - Show final time if opponent finished
 * - Update display in real-time as new checkpoint data arrives
 * - Consider showing ghost car position indicator
 */
void RenderOpponentCheckpoints() {
    // TODO: Implement opponent checkpoint rendering
    if (!isRacingNewMode) return;

    UI::SetNextWindowSize(300, 400, UI::Cond::Appearing);
    UI::SetNextWindowPos(50, 50, UI::Cond::Appearing);

    if (UI::Begin("Opponent Progress", UI::WindowFlags::NoCollapse)) {
        UI::Text("Opponent: [TODO: Name]");
        UI::Separator();

        if (opponentData.hasFinished) {
            UI::Text("Finished: " + opponentData.finalTime + "ms");
        } else {
            UI::Text("Current CP: " + opponentData.currentCheckpoint);
        }

        UI::NewLine();
        UI::Text("Checkpoints:");

        for (uint i = 0; i < opponentData.checkpointTimes.Length; i++) {
            UI::Text("CP " + (i + 1) + ": " + opponentData.checkpointTimes[i] + "ms");
            // TODO: Add delta calculation and color coding
        }

        if (opponentData.checkpointTimes.Length == 0) {
            UI::TextDisabled("No checkpoint data yet...");
        }
    }
    UI::End();
}

/**
 * Processes incoming checkpoint data from opponent
 *
 * @param checkpointIndex The checkpoint number (0-based)
 * @param time The opponent's time at this checkpoint in milliseconds
 *
 * TODO: Implement the following:
 * - Validate checkpoint index
 * - Store time in opponentData.checkpointTimes[checkpointIndex]
 * - Update opponentData.currentCheckpoint
 * - Trigger UI refresh to show new data
 * - Play sound effect or visual notification when opponent hits CP
 * - Consider interpolation for smooth ghost car movement
 */
void ReceiveOpponentCheckpoint(int checkpointIndex, int time) {
    // TODO: Implement checkpoint reception
    print("[NewRaceMode] TODO: ReceiveOpponentCheckpoint(CP" + checkpointIndex + ", " + time + "ms)");

    // Ensure array is large enough
    while (opponentData.checkpointTimes.Length <= uint(checkpointIndex)) {
        opponentData.checkpointTimes.InsertLast(-1);
    }

    opponentData.checkpointTimes[checkpointIndex] = time;
    opponentData.currentCheckpoint = checkpointIndex;
}

/**
 * Processes opponent finishing the race
 *
 * @param finalTime Opponent's final race time in milliseconds
 *
 * TODO: Implement the following:
 * - Store finalTime in opponentData.finalTime
 * - Set opponentData.hasFinished = true
 * - Update UI to show opponent finished
 * - If player also finished, trigger race result comparison
 * - Show congratulations or defeat message
 */
void ReceiveOpponentFinish(int finalTime) {
    // TODO: Implement opponent finish reception
    print("[NewRaceMode] TODO: ReceiveOpponentFinish(" + finalTime + "ms)");

    opponentData.finalTime = finalTime;
    opponentData.hasFinished = true;
}

// ============================================================================
// INITIALIZATION
// ============================================================================

/**
 * Initializes the new race mode system
 *
 * TODO: Implement the following:
 * - Initialize boardMaps array (8x8 grid of SquareMapData objects)
 * - Reset opponent data
 * - Clear any existing race state
 * - Register network message handlers for opponent updates
 */
void InitializeNewRaceMode() {
    print("[NewRaceMode] Initializing new race mode...");

    // Initialize 8x8 grid
    for (int row = 0; row < 8; row++) {
        boardMaps[row].Resize(8);
        for (int col = 0; col < 8; col++) {
            @boardMaps[row][col] = SquareMapData();
        }
    }

    opponentData.Reset();
    isRacingNewMode = false;

    print("[NewRaceMode] Initialization complete");
}

/**
 * Initializes and assigns maps (async version for use with startnew)
 */
void InitializeAndAssignMaps() {
    InitializeNewRaceMode();

    // Use mappack if configured, otherwise use random campaign maps
    if (useSpecificMappack && squareRaceMappackId > 0) {
        AssignMapsFromMappack(squareRaceMappackId);
    } else {
        AssignRandomMapsToBoard();
    }
}

} // namespace NewRaceMode
