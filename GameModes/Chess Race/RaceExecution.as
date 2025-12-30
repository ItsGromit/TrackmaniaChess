// ============================================================================
// SQUARE RACE MODE - RACE EXECUTION
// ============================================================================

namespace RaceMode {

namespace RaceExecution {

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
 * This is called when a capture move is attempted in Chess Race mode
 *
 * IMPORTANT: Races only happen on capture attempts (attacker vs defender).
 * The map loaded is the one assigned to the destination square (where the capture would occur).
 *
 * @param row The row of the capture destination square
 * @param col The column of the capture destination square
 */
void FetchSquareRaceMap(int row, int col) {
    print("[ChessRace::RaceExecution] FetchSquareRaceMap for square [" + row + ", " + col + "]");

    SquareMapData@ mapData = MapAssignment::GetSquareMap(row, col);
    if (mapData is null || mapData.tmxId == -1) {
        print("[ChessRace::RaceExecution] Error: No map assigned to square [" + row + ", " + col + "]");
        // Fallback to random map
        FetchPracticeModeRaceMap();
        return;
    }

    // Use the assigned map for this square
    print("[ChessRace::RaceExecution] Loading assigned map: " + mapData.mapName + " (TMX ID: " + mapData.tmxId + ")");

    // Set the race map details (these are used by the race UI)
    raceMapTmxId = mapData.tmxId;
    raceMapName = mapData.mapName;

    // Reset race state
    playerFinishedRace = false;
    playerRaceTime = -1;
    playerDNF = false;
    raceStartedAt = 0;

    // Set game state to RaceChallenge (this triggers the race UI)
    GameManager::currentState = GameState::RaceChallenge;

    // Download and load the map
    DownloadAndLoadMapFromTMX(mapData.tmxId, mapData.mapName);
}

/**
 * Executes the race mode when a player selects a square
 *
 * @param row The row of the selected square
 * @param col The column of the selected square
 */
void ExecuteRaceMode(int row, int col) {
    // TODO: Implement race execution
    print("[ChessRace::RaceExecution] TODO: ExecuteRaceMode(" + row + ", " + col + ")");

    SquareMapData@ mapData = MapAssignment::GetSquareMap(row, col);
    if (mapData is null) {
        print("[ChessRace::RaceExecution] Error: No map assigned to square [" + row + ", " + col + "]");
        return;
    }

    // TODO: Continue implementation
    selectedSquareRow = row;
    selectedSquareCol = col;
    isRacingSquareMode = true;
}

/**
 * Handles race completion for the local player
 *
 * @param finalTime Player's final race time in milliseconds
 */
void HandleRaceCompletion(int finalTime) {
    // TODO: Implement race completion handling
    print("[ChessRace::RaceExecution] TODO: HandleRaceCompletion(" + finalTime + "ms)");
}

/**
 * Handles player giving up / DNF during race
 */
void HandleRaceDNF() {
    // TODO: Implement DNF handling
    print("[ChessRace::RaceExecution] TODO: HandleRaceDNF()");
}

/**
 * Updates race state each frame (called from main Update loop)
 */
void UpdateRaceState() {
    // TODO: Implement race state updates
    if (!isRacingSquareMode) return;

    // TODO: Add frame-by-frame race monitoring logic
}

} // namespace RaceExecution

} // namespace ChessRace
