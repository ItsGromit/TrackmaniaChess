// ============================================================================
// MAIN UI
// ============================================================================
// Main UI entry point that coordinates all UI components
// ============================================================================
/**
 * Main menu rendering function - called every frame
 * Handles the main window and delegates to specific state renderers
 */
void MainMenu() {
    int windowFlags = windowResizeable ? 0 : UI::WindowFlags::NoResize;

    // Apply theme window background color
    UI::PushStyleColor(UI::Col::WindowBg, themeWindowBgColor);

    // Make title bar have same opacity as window background
    UI::PushStyleColor(UI::Col::TitleBg, themeWindowBgColor);
    UI::PushStyleColor(UI::Col::TitleBgActive, themeWindowBgColor);
    UI::PushStyleColor(UI::Col::TitleBgCollapsed, themeWindowBgColor);

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

    // Pop the window background and title bar style colors
    UI::PopStyleColor(4);

    // Render map filters popup window (independent of main window)
    Lobby::RenderMapFiltersWindow();

    // Render color customization window (independent of main window)
    ColorCustomization::RenderWindow();
}
