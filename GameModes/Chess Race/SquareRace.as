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
 */
void InitializeAndAssignMaps() {
    InitializeChessRace();

    // Use mappack if configured, otherwise use random campaign maps
    if (useSpecificMappack && squareRaceMappackId > 0) {
        MapAssignment::AssignMapsFromMappack(squareRaceMappackId);
    } else {
        MapAssignment::AssignRandomMapsToBoard();
    }
}

} // namespace ChessRace
