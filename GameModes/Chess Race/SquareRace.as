// ============================================================================
// CHESS RACE MODE
// ============================================================================
// In Chess Race mode:
// - Each of the 64 chess board squares is assigned a specific Trackmania map
// - Map thumbnails are displayed on each square
// - Players race ONLY when a capture is attempted (attacker vs defender)
// - The map used is the one assigned to the destination square being captured
// - Winner of the race gets the piece (even if they were defending)
// - Opponent checkpoint times are displayed in real-time during races
// ============================================================================

namespace RaceMode {

// Current race state
int selectedSquareRow = -1;
int selectedSquareCol = -1;
bool isRacingSquareMode = false;

// ============================================================================
// INITIALIZATION
// ============================================================================

/**
 * Initializes the Chess Race mode system
 */
void InitializeChessRace() {
    print("[ChessRace] Initializing Chess Race mode...");

    MapAssignment::InitializeBoardMaps();
    OpponentTracking::ResetOpponentData();
    isRacingSquareMode = false;

    print("[ChessRace] Initialization complete");
}

/**
 * Initializes and assigns maps (async version for use with startnew)
 * Used for practice mode where client assigns its own maps
 */
void InitializeAndAssignMaps() {
    InitializeChessRace();

    // Use the mappack ID received from the server (stored in activeMappackId)
    // This ensures both players have the same map assignments
    MapAssignment::AssignMapsFromMappack(activeMappackId);
    print("[ChessRace] Initializing maps from server-specified mappack: " + activeMappackId);

    // Preload thumbnails if enabled
    if (showThumbnails) {
        ThumbnailRendering::PreloadAllThumbnails();
    }
}

/**
 * Applies server-assigned board maps (synchronous version)
 * Used for multiplayer where server assigns maps to ensure sync
 */
void ApplyServerBoardMapsSync(const Json::Value &in boardMapsJson) {
    InitializeChessRace();

    print("[ChessRace] Applying server-assigned board maps...");
    MapAssignment::ApplyServerBoardMaps(boardMapsJson);

    // Preload thumbnails if enabled (async)
    if (showThumbnails) {
        startnew(ThumbnailRendering::PreloadAllThumbnails);
    }
}

} // namespace ChessRace
