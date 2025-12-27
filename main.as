void Main() {
    Network::Init();
    InitializeGlobals();
}

void Update(float dt) {
    Network::Update();
    DummyClient::Update();
    NewRaceMode::UpdateRaceState();

    // Check if player finished race or gave up in practice mode
    if (DummyClient::enabled && GameManager::currentState == GameState::RaceChallenge && !playerFinishedRace && !playerDNF) {
        auto app = cast<CTrackMania>(GetApp());
        if (app !is null) {
            auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
            if (playground !is null && playground.Arena !is null) {
                auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
                if (player !is null) {
                    auto scriptPlayer = cast<CSmScriptPlayer>(player.ScriptAPI);
                    if (scriptPlayer !is null) {
                        // Check if player finished (RaceTime > 0 means finished)
                        if (scriptPlayer.Score.BestRaceTimes.Length > 0 && scriptPlayer.Score.BestRaceTimes[0] > 0) {
                            playerFinishedRace = true;
                            playerRaceTime = scriptPlayer.Score.BestRaceTimes[0];
                            print("[Chess] Player finished race in " + playerRaceTime + "ms");
                        }
                    }
                }
            }

            // Check if player is back at menu (retired/gave up)
            if (app.CurrentPlayground is null || cast<CSmArenaClient>(app.CurrentPlayground) is null) {
                playerDNF = true;
                playerFinishedRace = true;  // Mark as "finished" so UI updates
                print("[Chess] Player gave up / DNF");
            }
        }
    }
}

void OnDestroyed() {
    print("[Chess] Plugin unloading - disconnecting from server");
    Network::Disconnect();
    print("[Chess] Disconnected from server");
}

void Render() {
    // Render color customization window independently
    ColorCustomization::RenderWindow();

    // Render new race mode opponent checkpoints if racing
    NewRaceMode::RenderOpponentCheckpoints();

    if (!showWindow) return;
    EnsurePieceAssetsLoaded();

    // Hide main window during race challenge
    if (GameManager::currentState == GameState::RaceChallenge) {
        RenderRaceWindow();
        return;
    }

    UI::SetNextWindowSize(int(defaultWidth), int(defaultHeight), UI::Cond::Appearing);

    int windowFlags = windowResizeable ? 0 : UI::WindowFlags::NoResize;

    vec2 mainWindowPos;
    vec2 mainWindowSize;

    MainMenu();
}

void RenderRaceWindow() {
    UI::SetNextWindowSize(400, 350, UI::Cond::Appearing);
    UI::Begin("Race Challenge", UI::WindowFlags::NoCollapse);

    UI::Text(themeSectionLabelColor + "Race Challenge!");
    UI::NewLine();
    UI::Text("Map: " + Network::raceMapName);
    UI::Text("You are the: " + (Network::isDefender ? themeWarningTextColor + "Defender" : themeSuccessTextColor + "Attacker"));
    UI::NewLine();

    // Show race status in practice mode
    if (DummyClient::enabled) {
        if (playerFinishedRace) {
            if (playerDNF) {
                UI::Text(themeErrorTextColor + "You gave up / DNF!");
                UI::Text("Waiting for opponent to finish...");
            } else {
                UI::Text(themeSuccessTextColor + "You finished in " + playerRaceTime + "ms!");
                UI::Text("Waiting for opponent to finish...");
            }
            UI::NewLine();

            // In developer mode, show button to simulate opponent finishing
            if (developerMode) {
                UI::Text("Simulate opponent finish:");
                if (UI::Button("Opponent Finished (Slower)", vec2(200.0f, 0))) {
                    // Player is faster (or both DNF -> attacker wins)
                    bool captureSucceeded = !Network::isDefender;
                    DummyClient::ApplyRaceResult(captureSucceeded);
                    GameManager::currentState = GameState::Playing;
                    playerFinishedRace = false;
                    playerRaceTime = -1;
                    playerDNF = false;
                }
                if (UI::Button("Opponent Finished (Faster)", vec2(200.0f, 0))) {
                    // Opponent is faster, player loses
                    bool captureSucceeded = Network::isDefender;
                    DummyClient::ApplyRaceResult(captureSucceeded);
                    GameManager::currentState = GameState::Playing;
                    playerFinishedRace = false;
                    playerRaceTime = -1;
                    playerDNF = false;
                }
                if (UI::Button("Opponent DNF (Both DNF)", vec2(200.0f, 0))) {
                    // Both DNF -> Attacker wins by default
                    bool captureSucceeded = !Network::isDefender;
                    DummyClient::ApplyRaceResult(captureSucceeded);
                    GameManager::currentState = GameState::Playing;
                    playerFinishedRace = false;
                    playerRaceTime = -1;
                    playerDNF = false;
                }
            }
        } else {
            UI::Text("Complete the race to continue!");
            UI::Text(themeWarningTextColor + "You only get one attempt!");
            UI::Text(themeWarningTextColor + "If you give up, you forfeit!");
        }

        // Developer mode utility buttons
        if (developerMode) {
            UI::NewLine();
            if (UI::Button("Re-roll Map", vec2(200.0f, 0))) {
                // Reset race state for the new map
                playerFinishedRace = false;
                playerRaceTime = -1;
                playerDNF = false;
                // Fetch new random map using practice mode logic
                startnew(Network::FetchPracticeModeRaceMap);
            }
            if (UI::Button("Return to Menu", vec2(200.0f, 0))) {
                auto app = cast<CTrackMania>(GetApp());
                if (app !is null) {
                    app.BackToMainMenu();
                    GameManager::currentState = GameState::Menu;
                    playerFinishedRace = false;
                    playerRaceTime = -1;
                    playerDNF = false;
                }
            }
        }
    } else {
        // Normal multiplayer mode with request/response
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
    }

    UI::End();
}

void RenderMenu() {
    if (UI::MenuItem("Chess Race", "", showWindow)) {
        showWindow = !showWindow;
    }
}

void EnsurePieceAssetsLoaded() {
    if (!gPiecesLoaded) {
        LoadPieceAssets();
        gPiecesLoaded = true;
    }
}