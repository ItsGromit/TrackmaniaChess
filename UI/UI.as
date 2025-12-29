// ============================================================================
// MAIN UI
// ============================================================================
// Main UI entry point that coordinates all UI components
// ============================================================================

/**
 * Openplanet plugin entry point - called every frame
 * This is the function Openplanet looks for to render the plugin UI
 */
void Render() {
    MainMenu();
}

/**
 * Main menu rendering function - called every frame
 * Handles the main window and delegates to specific state renderers
 */
void MainMenu() {
    int windowFlags = windowResizeable ? 0 : UI::WindowFlags::NoResize;

    // Make title bar have same opacity as window background
    vec4 bgColor = UI::GetStyleColor(UI::Col::WindowBg);
    UI::PushStyleColor(UI::Col::TitleBg, bgColor);
    UI::PushStyleColor(UI::Col::TitleBgActive, bgColor);
    UI::PushStyleColor(UI::Col::TitleBgCollapsed, bgColor);

    if (UI::Begin("Chess Race Classic", showWindow, windowFlags)) {

        switch (GameManager::currentState) {
            case GameState::Menu:
                RenderMenuState();
                break;

            case GameState::Connecting:
                RenderConnectingState();
                break;

            case GameState::InQueue:
                RenderInQueueState();
                break;

            case GameState::InLobby:
                RenderInLobbyState();
                break;

            case GameState::Playing:
            case GameState::GameOver:
                RenderPlayingState();
                break;

            case GameState::RaceChallenge:
                // Race challenge UI is now in a separate window (see Main.as RenderRaceWindow)
                break;
        }
    }
    UI::End();

    // Pop the title bar style colors
    UI::PopStyleColor(3);

    // Render map filters popup window (independent of main window)
    Lobby::RenderMapFiltersWindow();
}
