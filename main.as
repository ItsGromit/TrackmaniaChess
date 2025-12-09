void Main() {
    Network::Init();
    InitializeGlobals();
}

void Update(float dt) {
    Network::Update();
}

void OnDestroyed() {
    print("[Chess] Plugin unloading - disconnecting from server");
    Network::Disconnect();
    print("[Chess] Disconnected from server");
}

void Render() {
    if (!showWindow) return;
    EnsurePieceAssetsLoaded();

    UI::SetNextWindowSize(int(defaultWidth), int(defaultHeight), UI::Cond::Appearing);

    int windowFlags = windowResizeable ? 0 : UI::WindowFlags::NoResize;

    vec2 mainWindowPos;
    vec2 mainWindowSize;

    MainMenu();

    // Render separate race challenge window when in race
    if (GameManager::currentState == GameState::RaceChallenge) {
        RenderRaceWindow();
    }
}

void RenderRaceWindow() {
    UI::SetNextWindowSize(400, 200, UI::Cond::Appearing);
    UI::Begin("Race Challenge", UI::WindowFlags::NoCollapse);

    UI::Text(themeSectionLabelColor + "Race Challenge!");
    UI::NewLine();
    UI::Text("Map: " + Network::raceMapName);
    UI::Text("You are the: " + (Network::isDefender ? themeWarningTextColor + "Defender" : themeSuccessTextColor + "Attacker"));
    UI::NewLine();

    // Show re-roll UI based on state
    if (rerollRequestReceived) {
        UI::Text(themeSuccessTextColor + "Opponent wants to re-roll the map!");
        if (UI::Button("Accept Re-roll", vec2(180.0f, 0))) {
            Network::RespondToReroll(true);
        }
        UI::SameLine();
        if (UI::Button("Decline", vec2(180.0f, 0))) {
            Network::RespondToReroll(false);
        }
    } else if (rerollRequestSent) {
        UI::Text(themeWarningTextColor + "Waiting for opponent to accept re-roll...");
    } else {
        if (UI::Button("Request Re-roll", vec2(200.0f, 0))) {
            Network::RequestReroll();
        }
    }

    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem("Chess Race")) {
        showWindow = !showWindow;
    }
}

void EnsurePieceAssetsLoaded() {
    if (!gPiecesLoaded) {
        LoadPieceAssets();
        gPiecesLoaded = true;
    }
}