void Main() {
    Init();
    InitializeGlobals();
    LoadPieceAssets();
    LoadLogo();
}

void Update(float dt) {
    Update();

    // Handle race state management
    RaceStateManager::Update();
}

void RenderMenu() {
    if (UI::MenuItem("Chess Race")) {
        showWindow = !showWindow;
    }
}

void Render() {
    // Always render race window if in race state
    if (GameManager::currentState == GameState::RaceChallenge) {
        RenderRaceWindow();

        // Close main window during race, remember it was open
        if (showWindow) {
            collapseChessWindow = true;
            showWindow = false;
        }
    } else {
        // Reopen window after race if it was open before
        if (collapseChessWindow) {
            showWindow = true;
            collapseChessWindow = false;
        }
    }

    if (showWindow) {
        MainMenu();
    }
}