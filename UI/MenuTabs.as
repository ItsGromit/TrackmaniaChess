// ============================================================================
// UI MENU TABS
// ============================================================================
// Handles rendering of menu tabs (Home, Play, Settings)
// ============================================================================

/**
 * Renders the menu state UI with tabs
 */
void RenderMenuState() {
    float lockButtonWidth = 30.0f;
    float barHeight = 30.0f;
    vec2 contentAvail = UI::GetContentRegionAvail();
    vec2 barCursor = UI::GetCursorPos();

    // Lock button at right
    RenderLockButton("menu", barHeight);

    // Reset cursor and add tab buttons as left-aligned elements
    UI::SetCursorPos(barCursor);

    // Home tab
    UI::PushStyleColor(UI::Col::Button, currentMenuTab == MenuTab::Home ? themeActiveTabColor : themeInactiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
    if (UI::Button("Home", vec2(80.0f, barHeight))) {
        currentMenuTab = MenuTab::Home;
    }
    UI::PopStyleColor(3);

    UI::SameLine();

    // Play tab
    UI::PushStyleColor(UI::Col::Button, currentMenuTab == MenuTab::Play ? themeActiveTabColor : themeInactiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
    if (UI::Button("Play", vec2(80.0f, barHeight))) {
        currentMenuTab = MenuTab::Play;
    }
    UI::PopStyleColor(3);

    UI::SameLine();

    // Settings tab
    UI::PushStyleColor(UI::Col::Button, currentMenuTab == MenuTab::Settings ? themeActiveTabColor : themeInactiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
    if (UI::Button("Settings", vec2(80.0f, barHeight))) {
        currentMenuTab = MenuTab::Settings;
    }
    UI::PopStyleColor(3);

    UI::NewLine();

    // Tab content
    if (currentMenuTab == MenuTab::Home) {
        RenderHomeTab();
    } else if (currentMenuTab == MenuTab::Play) {
        RenderPlayTab();
    } else if (currentMenuTab == MenuTab::Settings) {
        RenderSettingsTab();
    }
}

/**
 * Renders the Home tab content
 */
void RenderHomeTab() {
    UI::TextWrapped("Welcome to Chess Race Classic! This is a competitive chess game where you can play against other players online.");
    UI::NewLine();

    // Practice Mode Section - Only show in developer mode
    if (developerMode) {
        UI::Text(themeSectionLabelColor + "Practice Mode (Developer):");
        UI::NewLine();
        UI::TextWrapped("Play against a simple AI opponent to test the full game including racing challenges. You will be randomly assigned white or black.");
        UI::NewLine();

        // Race mode selection for practice
        UI::Text("Game Mode:");
        UI::SetNextItemWidth(200);
        if (UI::BeginCombo("##practicemode", currentRaceMode == RaceMode::SquareRace ? "Chess Race" : "Capture Race (Classic)")) {
            if (UI::Selectable("Chess Race", currentRaceMode == RaceMode::SquareRace)) {
                currentRaceMode = RaceMode::SquareRace;
            }
            if (UI::Selectable("Capture Race (Classic)", currentRaceMode == RaceMode::CaptureRace)) {
                currentRaceMode = RaceMode::CaptureRace;
            }
            UI::EndCombo();
        }
        UI::NewLine();

        if (StyledButton("Start Practice Game", vec2(200.0f, 30.0f))) {
            InitializeGlobals();
            ApplyFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", "w");
            GameManager::currentState = GameState::Playing;

            // Initialize new race mode if selected
            if (currentRaceMode == RaceMode::SquareRace) {
                startnew(RaceMode::MapAssignment::InitializeBoardMaps);
            }

            // Randomly assign colors (like the server does)
            bool dummyPlaysWhite = (Math::Rand(0, 2) == 0);
            DummyClient::StartGame(dummyPlaysWhite);
        }

        UI::NewLine();
        UI::NewLine();
    }

    UI::Text("\\$f80Rules:");
    UI::TextWrapped("- Play follows standard chess rules");
    UI::TextWrapped("To do");
    UI::NewLine();
    UI::Text("\\$0f0How to Play:");
    UI::TextWrapped("To do");
}

/**
 * Renders the Play tab content
 */
void RenderPlayTab() {
    // Auto-connect if not connected
    if (!isConnected) {
        // Ensure UI overrides are applied
        if (ui_serverHost != "") serverHost = ui_serverHost;
        if (ui_serverPort != "") {
            uint portParsed = Text::ParseUInt(ui_serverPort);
            if (portParsed > 0) serverPort = portParsed;
        }

        print("[Chess] Attempting to connect to server: " + serverHost + ":" + serverPort);
        if (Connect()) {
            print("[Chess] Successfully connected to server");
            ListLobbies();
        } else {
            print("[Chess] Failed to connect to server");
        }
    }

    // Show create lobby page or lobby list
    if (Lobby::isCreatingLobby) {
        Lobby::RenderCreateLobbyPage();
    } else {
        // Render create lobby UI
        Lobby::RenderCreateLobby();

        // Show lobby list
        Lobby::RenderLobbyList();
    }
}

/**
 * Renders the Settings tab content
 */
void RenderSettingsTab() {
    UI::Text(themeSectionLabelColor + "Window Settings:");
    UI::NewLine();

    // Window resize toggle
    string settingsButtonText = windowResizeable ? "Lock Window Size" : "Unlock Window Size";
    UI::Text("Allow the window to be resized:");
    if (StyledButton(settingsButtonText, vec2(150.0f, 0))) {
        windowResizeable = !windowResizeable;
    }

    UI::NewLine();

    // Theme Settings Section
    UI::Text(themeSectionLabelColor + "Theme Settings:");

    if (StyledButton("Customize Colors", vec2(200.0f, 30.0f))) {
        showColorCustomizationWindow = true;
    }
    UI::TextWrapped("Open the color customization window to change button and board colors.");

    // Developer Mode Section
    UI::NewLine();
    UI::NewLine();

    UI::Text(themeSectionLabelColor + "Developer Settings:");
    UI::NewLine();

    developerMode = UI::Checkbox("Enable Developer Mode", developerMode);
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text("Enables testing features including practice mode with AI");
        UI::EndTooltip();
    }

    if (developerMode) {
        UI::NewLine();
        UI::Text(themeWarningTextColor + "Developer Mode Active");
        UI::TextWrapped("Practice mode is now available in the Home tab.");
    }
}
