// ============================================================================
// RACE STATE MANAGER
// ============================================================================
// Handles race state detection, DNF logic, and live time updates
// ============================================================================

namespace RaceStateManager {

/**
 * Main update function for race state management
 * Call this every frame from the main Update loop
 */
void Update() {
    // Handle race state management
    if (GameManager::currentState == GameState::RaceChallenge && !playerFinishedRace) {
        // Check if player is ready to race
        if (IsPlayerReady()) {
            int currentStartTime = GetPlayerStartTime();
            int currentRaceTime = GetCurrentRaceTime();

            // Detect if player used "Give Up" (full restart)
            // When player uses "Give Up", their race time resets to ~0
            // When player respawns to checkpoint, time stays roughly the same or goes forward
            if (raceStartedAt > 0 && lastPlayerRaceTime > 1000) {  // Only check if they've been racing for more than 1 second
                // If race time reset to near 0 (less than 200ms), player used "Give Up"
                if (currentRaceTime < 200) {
                    print("[RaceDetection] Player used Give Up (race time reset from " + lastPlayerRaceTime + "ms to " + currentRaceTime + "ms) - triggering DNF");

                    // Mark as DNF
                    playerDNF = true;
                    playerFinishedRace = true;

                    // Send DNF to server if in network game
                    if (gameId != "") {
                        Json::Value j = Json::Object();
                        j["type"] = "dnf";
                        j["gameId"] = gameId;
                        SendJson(j);
                    }

                    // Force player back to menu and exit race state
                    auto app = cast<CTrackMania>(GetApp());
                    if (app.RootMap !is null) {
                        app.BackToMainMenu();
                    }

                    // Exit race challenge state and reopen chess window
                    GameManager::currentState = GameState::Playing;
                    raceStartedAt = 0;
                    lastPlayerStartTime = -1;
                    lastPlayerRaceTime = 0;
                    return;
                }
            }

            // Track start time and race time
            lastPlayerStartTime = currentStartTime;
            lastPlayerRaceTime = currentRaceTime;

            if (raceStartedAt == 0) {
                // Player is now ready and in the race
                raceStartedAt = 1;
                print("[RaceDetection] Player is ready, race started");

                // Send race_started message to server
                if (gameId != "") {
                    Json::Value j = Json::Object();
                    j["type"] = "race_started";
                    j["gameId"] = gameId;
                    SendJson(j);
                    print("[RaceDetection] Sent race_started to server");
                }
            }

            // Send periodic race time updates (every 100ms)
            if (gameId != "") {
                uint64 now = Time::Now;
                if (now - lastRaceUpdateSent >= 100) {
                    int currentTime = GetCurrentRaceTime();
                    Json::Value j = Json::Object();
                    j["type"] = "race_time_update";
                    j["gameId"] = gameId;
                    j["time"] = currentTime;
                    SendJson(j);
                    lastRaceUpdateSent = now;
                }
            }
        } else if (raceStartedAt > 0) {
            // Player was racing but is no longer ready (left playground entirely)
            if (!IsInPlayground()) {
                print("[RaceDetection] Player left playground - triggering DNF");

                // Mark as DNF
                playerDNF = true;
                playerFinishedRace = true;

                // Send DNF to server if in network game
                if (gameId != "") {
                    Json::Value j = Json::Object();
                    j["type"] = "dnf";
                    j["gameId"] = gameId;
                    SendJson(j);
                }

                // Exit race challenge state and reopen chess window
                GameManager::currentState = GameState::Playing;
                raceStartedAt = 0;
                lastPlayerStartTime = -1;
                lastPlayerRaceTime = 0;
            }
        }
    }
}

} // namespace RaceStateManager
