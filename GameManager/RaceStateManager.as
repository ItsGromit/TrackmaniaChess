// ============================================================================
// RACE STATE MANAGER
// ============================================================================
// Handles race state detection, DNF logic, and live time updates
// ============================================================================

namespace RaceStateManager {

// Track last UISequence for debug logging
SGamePlaygroundUIConfig::EUISequence lastSeq = SGamePlaygroundUIConfig::EUISequence::None;

// Track race time stability for finish detection
int stableRaceTime = -1;
int stableRaceTimeFrames = 0;

/**
 * Main update function for race state management
 * Call this every frame from the main Update loop
 */
void Update() {
    // Handle race state management
    if (GameManager::currentState == GameState::RaceChallenge && !playerFinishedRace) {
        // FIRST: Check if player finished the race (using TrackmaniaBingo's exact approach)
        // This must be checked BEFORE IsPlayerReady() because UISequence changes from Playing to Finish
        auto app = cast<CTrackMania>(GetApp());
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        auto playgroundScript = cast<CGamePlaygroundScript>(app.PlaygroundScript);

        // Check for race finish if we have valid playground
        if (playgroundScript !is null && playground !is null && playground.GameTerminals.Length > 0) {
            CGameTerminal@ terminal = playground.GameTerminals[0];
            auto seq = terminal.UISequence_Current;

            // Debug: Log UISequence changes
            if (seq != lastSeq) {
                print("[RaceDetection] UISequence changed to: " + tostring(seq));
                lastSeq = seq;
            }

            // Check UISequence FIRST before anything else (TrackmaniaBingo pattern)
            if (seq == SGamePlaygroundUIConfig::EUISequence::Finish) {
                print("[RaceDetection] Player in Finish state, attempting to retrieve ghost");

                CSmPlayer@ player = cast<CSmPlayer>(terminal.ControlledPlayer);
                if (player !is null && player.ScriptAPI !is null) {
                    CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);

                    // Retrieve ghost data (TrackmaniaBingo method)
                    auto ghost = cast<CSmArenaRulesMode>(playgroundScript).Ghost_RetrieveFromPlayer(playerScriptAPI);
                    print("[RaceDetection] Ghost retrieved: " + (ghost !is null ? "yes" : "null"));

                    if (ghost !is null && ghost.Result !is null) {
                        int finalTime = ghost.Result.Time;
                        print("[RaceDetection] Ghost result time: " + finalTime);

                        // Release ghost (TrackmaniaBingo does this)
                        playgroundScript.DataFileMgr.Ghost_Release(ghost.Id);

                        // Validate time (TrackmaniaBingo check: > 0 and < uint max)
                        if (finalTime > 0 && finalTime < 4294967295) {
                            print("[RaceDetection] Player finished race with time: " + finalTime + "ms (UISequence::Finish)");

                            playerFinishedRace = true;
                            playerRaceTime = finalTime;

                            // Send race result to server (if in network game)
                            if (gameId != "") {
                                Json::Value j = Json::Object();
                                j["type"] = "race_result";
                                j["gameId"] = gameId;
                                j["time"] = playerRaceTime;
                                SendJson(j);
                                print("[RaceDetection] Sent race_result to server: " + playerRaceTime + "ms");

                                // Send player back to main menu but keep race window open
                                auto app2 = cast<CTrackMania>(GetApp());
                                app2.BackToMainMenu();

                                // In network mode, keep race window open to show result
                                // Race window will stay up until server sends race_result message with both times
                            } else {
                                // In practice mode, send player back to main menu and keep race window open
                                print("[RaceDetection] Practice mode - showing race result");
                                auto app2 = cast<CTrackMania>(GetApp());
                                app2.BackToMainMenu();

                                // Keep race window open showing the player's time
                                // Player can manually close it or click continue to return to chess board
                            }

                            // Reset race tracking variables
                            raceStartedAt = 0;
                            lastPlayerStartTime = -1;
                            lastPlayerRaceTime = 0;

                            return;
                        } else {
                            print("[RaceDetection] finalTime validation failed: " + finalTime + " (must be > 0 and < 4294967295)");
                        }
                    } else {
                        if (ghost !is null) {
                            playgroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                        }
                        print("[RaceDetection] Ghost or Result is null");
                    }
                } else {
                    print("[RaceDetection] Player or ScriptAPI is null");
                }
            }
        }

        // SECOND: Check if player is ready to race (for ongoing race tracking)
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
                    auto app2 = cast<CTrackMania>(GetApp());
                    app2.BackToMainMenu();

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

            // Fallback: Check player's Score for completed race times
            // When a player finishes, their time appears in BestRaceTimes or PrevRaceTimes
            if (playground !is null && playground.GameTerminals.Length > 0) {
                auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
                if (player !is null && player.Score !is null) {
                    auto score = cast<CSmArenaScore>(player.Score);
                    if (score !is null) {
                        // Check if player has a recorded race time (indicates finish)
                        if (score.BestRaceTimes.Length > 0 && score.BestRaceTimes[0] > 0) {
                            int finalTime = int(score.BestRaceTimes[0]);

                            print("[RaceDetection] Player finished! BestRaceTime: " + finalTime + "ms");

                            playerFinishedRace = true;
                            playerRaceTime = finalTime;

                            // Send race result to server (if in network game)
                            if (gameId != "") {
                                Json::Value j = Json::Object();
                                j["type"] = "race_result";
                                j["gameId"] = gameId;
                                j["time"] = playerRaceTime;
                                SendJson(j);
                                print("[RaceDetection] Sent race_result to server: " + playerRaceTime + "ms");

                                // Send player back to main menu but keep race window open
                                auto app3 = cast<CTrackMania>(GetApp());
                                app3.BackToMainMenu();

                                // In network mode, keep race window open to show result
                                // Race window will stay up until server sends race_result message with both times
                            } else {
                                // In practice mode, send player back to main menu and keep race window open
                                print("[RaceDetection] Practice mode - showing DNF result");
                                auto app3 = cast<CTrackMania>(GetApp());
                                app3.BackToMainMenu();

                                // Keep race window open showing DNF
                                // Player can manually close it or click continue to return to chess board
                            }

                            // Reset race tracking variables
                            raceStartedAt = 0;
                            lastPlayerStartTime = -1;
                            lastPlayerRaceTime = 0;
                            stableRaceTime = -1;
                            stableRaceTimeFrames = 0;

                            return;
                        }
                    }
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
