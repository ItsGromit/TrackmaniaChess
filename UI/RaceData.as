// ============================================================================
// RACE DATA HELPER
// ============================================================================
// Provides easy access to current race time
// ============================================================================

uint PlaygroundGameTime() {
    auto app = GetApp();
    auto playgroundScript = app.Network.PlaygroundInterfaceScriptHandler;

    if (playgroundScript is null) return uint(-1);

    return uint(playgroundScript.GameTime);
}

bool IsPlayerReady() {
    auto app = cast<CTrackMania>(GetApp());
    auto playground = cast<CGamePlayground>(app.CurrentPlayground);

    if (playground is null || playground.GameTerminals.Length == 0) {
        return false;
    }

    CGameTerminal@ terminal = playground.GameTerminals[0];
    if (terminal is null) {
        return false;
    }

    if (terminal.UISequence_Current != SGamePlaygroundUIConfig::EUISequence::Playing) {
        return false;
    }

    auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
    uint gametime = PlaygroundGameTime();

    if (player is null || player.StartTime < 0 || player.StartTime > int(gametime) || player.ScriptAPI is null) {
        return false;
    }

    auto script = cast<CSmScriptPlayer>(player.ScriptAPI);
    if (script.Post == 0) {
        return false;
    }

    return true;
}

/**
 * Gets the current race time in milliseconds
 * Returns 0 if not in a race or if data is not available
 */
int GetCurrentRaceTime() {
    auto app = cast<CTrackMania>(GetApp());
    auto playground = cast<CGamePlayground>(app.CurrentPlayground);

    if (playground is null || playground.GameTerminals.Length == 0) {
        return 0;
    }

    auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
    if (player is null) {
        return 0;
    }

    // If player has finished, return their finished time from Score
    if (player.Score !is null) {
        auto score = cast<CSmArenaScore>(player.Score);
        if (score !is null && score.BestRaceTimes.Length > 0 && score.BestRaceTimes[0] > 0) {
            return int(score.BestRaceTimes[0]);
        }
    }

    // Otherwise, calculate ongoing race time
    if (player.ScriptAPI is null) {
        return 0;
    }

    uint gametime = PlaygroundGameTime();
    if (player.StartTime < 0 || player.StartTime > int(gametime)) {
        return 0;
    }

    // Calculate race time as current game time minus player start time
    int raceTime = int(gametime) - player.StartTime;

    return raceTime;
}

/**
 * Checks if the player is currently in a race (playground exists)
 */
bool IsInPlayground() {
    auto app = cast<CTrackMania>(GetApp());
    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    return playground !is null;
}

/**
 * Gets the player's current StartTime (for detecting restarts)
 * Returns -1 if not available
 */
int GetPlayerStartTime() {
    auto app = cast<CTrackMania>(GetApp());
    auto playground = cast<CGamePlayground>(app.CurrentPlayground);

    if (playground is null || playground.GameTerminals.Length == 0) {
        return -1;
    }

    auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
    if (player is null) {
        return -1;
    }

    return player.StartTime;
}

