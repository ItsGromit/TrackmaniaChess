// ============================================================================
// UI GAME STATES
// ============================================================================
// Handles rendering of different game states (Connecting, InQueue, InLobby)
// ============================================================================

/**
 * Renders the Connecting state UI
 */
void RenderConnectingState() {
    float barHeight = 30.0f;
    vec2 lockCursor = UI::GetCursorPos();

    RenderLockButton("connecting", barHeight);

    // Reset cursor and add dummy invisible item to maintain bar height
    UI::SetCursorPos(lockCursor);
    UI::Dummy(vec2(0, barHeight));

    UI::NewLine();

    UI::Text("Connecting to server...");
}

/**
 * Renders the InQueue state UI (Deprecated)
 */
void RenderInQueueState() {
    float barHeight = 30.0f;
    vec2 lockCursor = UI::GetCursorPos();

    RenderLockButton("queue", barHeight);

    // Reset cursor and add dummy invisible item to maintain bar height
    UI::SetCursorPos(lockCursor);
    UI::Dummy(vec2(0, barHeight));

    UI::NewLine();

    // Show create lobby page or lobby list
    if (Lobby::isCreatingLobby) {
        Lobby::RenderCreateLobbyPage();
    } else {
        // Render create lobby UI
        Lobby::RenderCreateLobby();

        // Show lobby list
        Lobby::RenderLobbyList();
    }

    if (StyledButton("Back to Menu")) {
        GameManager::currentState = GameState::Menu;
        Lobby::isCreatingLobby = false;  // Reset state when going back
    }
}

/**
 * Renders the InLobby state UI
 */
void RenderInLobbyState() {
    float lockButtonWidth = 30.0f;
    float barHeight = 30.0f;
    vec2 contentAvail = UI::GetContentRegionAvail();
    vec2 lockCursor = UI::GetCursorPos();

    // Lock button at right
    RenderLockButton("lobby", barHeight);

    // Reset cursor and add "Lobby" label as a button-style element
    UI::SetCursorPos(lockCursor);
    UI::PushStyleColor(UI::Col::Button, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
    UI::Button("Lobby", vec2(80.0f, barHeight));
    UI::PopStyleColor(3);

    UI::NewLine();

    // Render the current lobby details
    Lobby::RenderCurrentLobby();
}
