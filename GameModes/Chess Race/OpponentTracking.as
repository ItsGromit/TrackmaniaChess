// ============================================================================
// SQUARE RACE MODE - OPPONENT TRACKING
// ============================================================================

namespace RaceMode {

namespace OpponentTracking {

// Current opponent checkpoint data
RaceMode::OpponentCheckpointData opponentData;

/**
 * Resets opponent data
 */
void ResetOpponentData() {
    opponentData.Reset();
}

/**
 * Processes incoming checkpoint data from opponent
 *
 * @param checkpointIndex The checkpoint number (0-based)
 * @param time The opponent's time at this checkpoint in milliseconds
 */
void ReceiveOpponentCheckpoint(int checkpointIndex, int time) {
    // TODO: Implement checkpoint reception
    print("[ChessRace::OpponentTracking] TODO: ReceiveOpponentCheckpoint(CP" + checkpointIndex + ", " + time + "ms)");

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
 */
void ReceiveOpponentFinish(int finalTime) {
    // TODO: Implement opponent finish reception
    print("[ChessRace::OpponentTracking] TODO: ReceiveOpponentFinish(" + finalTime + "ms)");

    opponentData.finalTime = finalTime;
    opponentData.hasFinished = true;
}

/**
 * Renders opponent's checkpoint times during active race
 */
void RenderOpponentCheckpoints() {
    // TODO: Implement opponent checkpoint rendering
    if (!isRacingSquareMode) return;

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

} // namespace OpponentTracking

} // namespace ChessRace
