// ============================================================================
// RACE WINDOW UI
// ============================================================================
// Displays race information when a race challenge is active
// ============================================================================

/**
 * Renders the race window when in RaceChallenge state
 */
void RenderRaceWindow() {
    UI::SetNextWindowSize(400, 300, UI::Cond::FirstUseEver);
    UI::SetNextWindowPos(100, 100, UI::Cond::FirstUseEver);

    int windowFlags = UI::WindowFlags::NoCollapse;

    // Make title bar have same opacity as window background
    vec4 bgColor = UI::GetStyleColor(UI::Col::WindowBg);
    UI::PushStyleColor(UI::Col::TitleBg, bgColor);
    UI::PushStyleColor(UI::Col::TitleBgActive, bgColor);
    UI::PushStyleColor(UI::Col::TitleBgCollapsed, bgColor);

    if (UI::Begin("Race Challenge", windowFlags)) {
        UI::Text(themeSectionLabelColor + "\\$f80Race Information");
        UI::Separator();

        // Map information
        UI::NewLine();
        UI::Text("Map: \\$fff" + raceMapName);
        if (raceMapTmxId > 0) {
            UI::Text("TMX ID: \\$fff" + raceMapTmxId);
        }

        UI::NewLine();
        UI::Separator();

        // Role information
        UI::Text("Your Role: \\$fff" + (isDefender ? "Defender" : "Attacker"));
        if (isDefender) {
            UI::TextWrapped(themeWarningTextColor + "You are defending! Race to set the time to beat.");
        } else {
            UI::TextWrapped(themeWarningTextColor + "You are attacking! Beat the defender's time to capture.");
        }

        UI::NewLine();
        UI::Separator();

        // Show opponent's status and time
        UI::Text(themeSectionLabelColor + "\\$f80Opponent");
        if (opponentIsRacing && opponentRaceTime >= 0) {
            // Opponent is currently racing - show live time
            int oppSeconds = opponentRaceTime / 1000;
            int oppMilliseconds = opponentRaceTime % 1000;
            UI::Text(themeSuccessTextColor + "Racing: \\$fff" + oppSeconds + "." + Text::Format("%03d", oppMilliseconds) + "s");
        } else if (!isDefender && defenderTime > 0) {
            // Attacker view: show defender's finished time
            int defSeconds = defenderTime / 1000;
            int defMilliseconds = defenderTime % 1000;
            UI::Text("Finished: \\$fff" + defSeconds + "." + Text::Format("%03d", defMilliseconds) + "s");
        } else {
            // Opponent hasn't started yet
            UI::TextDisabled("Not racing");
        }

        UI::NewLine();
        UI::Separator();

        // Race status
        if (raceStartedAt > 0) {
            UI::Text(themeSectionLabelColor + "\\$f80Your Race");
            UI::Text(themeSuccessTextColor + "Active");

            // Show the actual in-game race time
            int elapsedMs = GetCurrentRaceTime();
            int seconds = elapsedMs / 1000;
            int milliseconds = elapsedMs % 1000;
            UI::Text("Time: \\$fff" + seconds + "." + Text::Format("%03d", milliseconds) + "s");

            // Show comparison to opponent if they're racing or have finished
            int compareTime = opponentIsRacing ? opponentRaceTime : defenderTime;
            if (compareTime > 0) {
                int diff = elapsedMs - compareTime;
                if (diff < 0) {
                    // You're ahead
                    int diffSeconds = (-diff) / 1000;
                    int diffMilliseconds = (-diff) % 1000;
                    UI::Text(themeSuccessTextColor + "Ahead by: " + diffSeconds + "." + Text::Format("%03d", diffMilliseconds) + "s");
                } else if (diff > 0) {
                    // You're behind
                    int diffSeconds = diff / 1000;
                    int diffMilliseconds = diff % 1000;
                    UI::Text(themeWarningTextColor + "Behind by: " + diffSeconds + "." + Text::Format("%03d", diffMilliseconds) + "s");
                } else {
                    // Tied
                    UI::Text("\\$fffExactly tied!");
                }
            }
        } else {
            UI::Text(themeSectionLabelColor + "\\$f80Your Race");
            UI::TextDisabled("Not started");
            UI::TextDisabled("Load into the map to begin");
        }

        UI::NewLine();

        // Manual finish button
        if (!playerFinishedRace && raceStartedAt > 0) {
            UI::Separator();
            UI::TextWrapped(themeWarningTextColor + "After finishing, click the button below to submit your time:");
            UI::NewLine();
            if (UI::Button("Submit Finish Time")) {
                int currentTime = GetCurrentRaceTime();
                if (currentTime > 0) {
                    print("[RaceDetection] Manual finish - submitting time: " + currentTime + "ms");

                    playerFinishedRace = true;
                    playerRaceTime = currentTime;

                    // Send race result to server (if in network game)
                    if (gameId != "") {
                        Json::Value j = Json::Object();
                        j["type"] = "race_result";
                        j["gameId"] = gameId;
                        j["time"] = playerRaceTime;
                        SendJson(j);
                        print("[RaceDetection] Sent race_result to server: " + playerRaceTime + "ms");
                    } else {
                        // In practice mode, exit immediately
                        GameManager::currentState = GameState::Playing;
                    }
                }
            }
        }

        // Results
        if (playerFinishedRace) {
            UI::NewLine();
            UI::Separator();
            UI::Text(themeSectionLabelColor + "\\$f80Race Complete");

            if (playerDNF) {
                UI::Text(themeWarningTextColor + "DNF (Did Not Finish)");
            } else if (playerRaceTime > 0) {
                int seconds = playerRaceTime / 1000;
                int milliseconds = playerRaceTime % 1000;
                UI::Text("Your Time: \\$fff" + seconds + "." + Text::Format("%03d", milliseconds) + "s");
            }
        }
    }
    UI::End();

    // Pop the title bar style colors
    UI::PopStyleColor(3);
}
