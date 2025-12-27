namespace Lobby {
    // announce lobby variables
    string createLobbyPassword = "";
    string createLobbyRoomTitle = "";
    string lobbyPassword = "";
    string createLobbyRoomCode = "";
    string joinLobbyPassword = "";
    string selectedLobbyId = "";
    bool showCreateRoomSection = false;
    bool showMapFiltersSection = false;
    bool isCreatingLobby = false;  // New state for create lobby page

    // Tag dropdown state - Complete list from TrackmaniaExchange
    array<string> availableTags = {
        "Altered Nadeo", "Arena", "Backwards", "Bobsleigh", "Bugslide", "Bumper",
        "Competitive", "CruiseControl", "DesertCar", "Dirt", "Educational", "Endurance",
        "EngineOff", "FlagRush", "Fragile", "Freeblocking", "Freestyle", "FullSpeed",
        "Grass", "Ice", "Kacky", "LOL", "Magnet", "Mini", "Minigame", "Mixed",
        "MixedCar", "Moving Items", "Mudslide", "MultiLap", "Nascar", "NoBrake",
        "NoGrip", "NoSteer", "Obstacle", "Offroad", "Pathfinding", "Pipes", "Plastic",
        "Platform", "Press Forward", "Puzzle", "Race", "RallyCar", "Reactor",
        "Remake", "Royal", "RPG", "RPG-Immersive", "Sausage", "Scenery",
        "Signature", "Slow Motion", "SnowCar", "SpeedDrift", "SpeedFun",
        "SpeedMapping", "SpeedTech", "Stunt", "Tech", "Transitional", "Trial",
        "Turtle", "Underwater", "Water", "Wood", "ZrT"
    };
    int selectedTagIndex = 0;

    // Map filters popup window state
    bool showMapFiltersWindow = false;

    void RenderCreateLobby() {
        // Create Room button
        if (StyledButton("Create Lobby", vec2(200.0f, 30.0f))) {
            isCreatingLobby = true;
        }

        UI::NewLine();

        // Refresh button always visible
        if (StyledButton("Refresh Lobby List", vec2(200.0f, 30.0f))) {
            Network::ListLobbies();
        }
        UI::NewLine();
    }

    void RenderCreateLobbyPage() {
        // Set default title if empty
        if (createLobbyRoomTitle.Length == 0) {
            createLobbyRoomTitle = Network::GetLocalPlayerName() + "'s Chess Room";
        }

        UI::Text(themeSectionLabelColor + "Create New Lobby");
        UI::NewLine();

        // Room Title input
        UI::Text("Room Title:");
        UI::SetNextItemWidth(300);
        createLobbyRoomTitle = UI::InputText("##roomtitle", createLobbyRoomTitle);
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::PushTextWrapPos(250.0f);
            UI::Text("The display name for your lobby.");
            UI::PopTextWrapPos();
            UI::EndTooltip();
        }
        UI::NewLine();

        // Password input
        UI::Text("Password (Optional):");
        UI::SetNextItemWidth(300);
        createLobbyPassword = UI::InputText("##createpassword", createLobbyPassword, UI::InputTextFlags::Password);
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::PushTextWrapPos(250.0f);
            UI::Text("Leave blank for a public lobby. Players will need this password to join.");
            UI::PopTextWrapPos();
            UI::EndTooltip();
        }
        UI::NewLine();
        UI::NewLine();

        // Action buttons
        if (StyledButton("Create Lobby", vec2(150.0f, 30.0f))) {
            // Pass title to CreateLobby (server will generate room code)
            Network::CreateLobby(createLobbyRoomTitle, createLobbyPassword);

            // Clear inputs and return to lobby list
            createLobbyPassword = "";
            createLobbyRoomTitle = "";
            isCreatingLobby = false;
            GameManager::currentState = GameState::InLobby;
        }

        UI::SameLine();

        if (StyledButton("Cancel", vec2(150.0f, 30.0f))) {
            isCreatingLobby = false;
            createLobbyPassword = "";
            createLobbyRoomTitle = "";
        }
    }

    void RenderLobbyList() {
        UI::Text("Available Games:");

        for (uint i = 0; i < Network::lobbies.Length; i++) {
            Network::Lobby@ l = Network::lobbies[i];
            if (l.id == Network::currentLobbyId) continue;
            string hostName = l.playerNames.Length > 0 ? l.playerNames[0] : l.hostId;
            string modeLabel = l.raceMode == "square" ? "\\$0f0[SQ]" : "\\$ff0[CAP]";
            string displayTitle = l.title.Length > 0 ? l.title : l.id;
            string lobbyText = displayTitle + " (" + l.players + " players)";
            UI::Text(modeLabel + " [" + l.id + "] " + displayTitle + " (" + l.players + ")");
            UI::SameLine();

            if(l.open)
                if (l.hasPassword) {
                    lobbyText += " [Password Protected]";
                    if (selectedLobbyId == l.id) {
                        UI::SetNextItemWidth(100);
                        joinLobbyPassword = UI::InputText('Password##' + l.id, joinLobbyPassword);
                        UI::SameLine();
                        if (StyledButton("Join##" + l.id)) {
                            Network::JoinLobby(l.id, joinLobbyPassword);
                            joinLobbyPassword = "";
                            selectedLobbyId = "";
                        }
                        UI::SameLine();
                        if (StyledButton("Cancel##" + l.id)) {
                            selectedLobbyId = "";
                            joinLobbyPassword = "";
                        }
                    } else {
                        if (StyledButton("Join (Password)##" + l.id)) {
                            selectedLobbyId = l.id;
                        }
                    }
                } else {
                    if (StyledButton(lobbyText + "Join##" + l.id)) {
                        Network::JoinLobby(l.id);
                    }
                
            }
        }

        if (Network::lobbies.Length == 0) {
            UI::Text("No lobbies available. Create one!");
        }
    }

    void RenderCurrentLobby() {
        if (Network::currentLobbyId == "") return;

        bool foundLobby = false;
        for (uint i = 0; i < Network::lobbies.Length; i++) {
            Network::Lobby@ l = Network::lobbies[i];
            if (l.id != Network::currentLobbyId) continue;

            foundLobby = true;

            // Room Code section
            UI::Text(themeSectionLabelColor + "Room Code: " + themeSuccessTextColor + l.id);
            UI::SameLine();
            if (StyledButton("Copy##roomcode", vec2(60.0f, 0))) {
                IO::SetClipboard(l.id);
            }

            // Password section (if applicable)
            if (l.hasPassword && Network::currentLobbyPassword.Length > 0) {
                UI::SameLine();
                UI::Text(themeSectionLabelColor + "Password: " + themeSuccessTextColor + Network::currentLobbyPassword);
                UI::SameLine();
                if (StyledButton("Copy##password", vec2(60.0f, 0))) {
                    IO::SetClipboard(Network::currentLobbyPassword);
                }
            }

            UI::NewLine();

            // Navigation bar with buttons (matching main menu style)
            float barHeight = 30.0f;

            // Players button (no longer used, just show content directly)
            UI::NewLine();

            // Race Mode Selection (Host Only)
                if (Network::isHost) {
                    UI::Text(themeSectionLabelColor + "Race Mode:");
                    UI::SameLine();

                    // Square Race Mode (New Default)
                    if (UI::RadioButton("Square Race##lobby", currentRaceMode == RaceMode::SquareRace)) {
                        currentRaceMode = RaceMode::SquareRace;
                    }
                    if (UI::IsItemHovered()) {
                        UI::BeginTooltip();
                        UI::PushTextWrapPos(250.0f);
                        UI::Text("Each square has a unique map. Race when capturing pieces.");
                        UI::PopTextWrapPos();
                        UI::EndTooltip();
                    }

                    UI::SameLine();

                    // Capture Race Mode (Classic)
                    if (UI::RadioButton("Capture Race (Classic)##lobby", currentRaceMode == RaceMode::CaptureRace)) {
                        currentRaceMode = RaceMode::CaptureRace;
                    }
                    if (UI::IsItemHovered()) {
                        UI::BeginTooltip();
                        UI::PushTextWrapPos(250.0f);
                        UI::Text("Race only when capturing opponent pieces (original mode).");
                        UI::PopTextWrapPos();
                        UI::EndTooltip();
                    }

                    UI::NewLine();

                    // Show Map Filters button only for Classic mode
                    if (currentRaceMode == RaceMode::CaptureRace) {
                        if (StyledButton("Configure Map Filters", vec2(200.0f, 30.0f))) {
                            showMapFiltersWindow = true;
                        }
                        UI::NewLine();
                    }
                } else {
                    // Show current mode for non-host players
                    string modeText = currentRaceMode == RaceMode::SquareRace ? "Square Race" : "Capture Race (Classic)";
                    UI::Text(themeSectionLabelColor + "Race Mode: " + themeSuccessTextColor + modeText);
                    UI::NewLine();
                }

                // Players content
                UI::Text(themeSectionLabelColor + "Players:");
                UI::BeginChild("LobbyPlayers", vec2(0, 100), true);
                for (uint j = 0; j < l.playerNames.Length; j++) {
                    string playerName = l.playerNames[j];
                    // The first player in the list is the host
                    if (j == 0) {
                        UI::Text("\\$ff0[Host] " + playerName);
                    } else {
                        UI::Text(playerName);
                    }
                }
                UI::EndChild();

            UI::NewLine();

            // Action buttons
            if (Network::isHost) {
                // Check if there are exactly 2 players
                bool canStart = l.playerNames.Length == 2;
                bool tooManyPlayers = l.playerNames.Length > 2;

                if (!canStart) {
                    UI::BeginDisabled();
                }

                if (StyledButton("Start Game", vec2(150.0f, 30.0f))) {
                    if (canStart) {
                        Network::StartGame();
                    }
                }

                if (!canStart) {
                    UI::EndDisabled();
                    if (UI::IsItemHovered(UI::HoveredFlags::AllowWhenDisabled)) {
                        UI::BeginTooltip();
                        if (tooManyPlayers) {
                            UI::Text("Too many players! Game requires exactly 2 players");
                        } else {
                            UI::Text("Need exactly 2 players to start");
                        }
                        UI::EndTooltip();
                    }
                }

                UI::SameLine();
            }
            if (StyledButton("Leave Lobby", vec2(150.0f, 30.0f))) {
                Network::LeaveLobby();
                GameManager::currentState = GameState::Menu;
            }
            break;
        }

        // If lobby not found in list yet, show basic info
        if (!foundLobby) {
            UI::Text(themeSectionLabelColor + "Room Code:");
            UI::Text(Network::currentLobbyId);
            UI::SameLine();
            if (StyledButton("Copy##roomcode")) {
                IO::SetClipboard(Network::currentLobbyId);
            }
            UI::NewLine();

            UI::Text(themeSuccessTextColor + "Waiting for lobby details...");
            UI::NewLine();

            if (StyledButton("Refresh", vec2(150.0f, 30.0f))) {
                Network::ListLobbies();
            }
            UI::SameLine();
            if (StyledButton("Leave Lobby", vec2(150.0f, 30.0f))) {
                Network::LeaveLobby();
                GameManager::currentState = GameState::Menu;
            }
        }
    }

    // Render Map Filters Popup Window
    void RenderMapFiltersWindow() {
        if (!showMapFiltersWindow) return;

        UI::SetNextWindowSize(500, 550, UI::Cond::Appearing);
        UI::SetNextWindowPos(400, 150, UI::Cond::Appearing);

        if (UI::Begin("Map Filters (Classic Mode)", showMapFiltersWindow, UI::WindowFlags::NoCollapse)) {
            UI::TextWrapped("Configure map filters for Capture Race (Classic) mode. These filters determine which maps can be selected for race challenges.");
            UI::Separator();
            UI::NewLine();

            UI::Text("Max Author Time (seconds):");
            UI::SetNextItemWidth(150);
            Network::mapFilterAuthorTimeMax = UI::InputInt("##maxtime", Network::mapFilterAuthorTimeMax);
            if (Network::mapFilterAuthorTimeMax < 1) Network::mapFilterAuthorTimeMax = 1;
            if (Network::mapFilterAuthorTimeMax > 300) Network::mapFilterAuthorTimeMax = 300;

            UI::Text("Min Author Time (seconds):");
            UI::SetNextItemWidth(150);
            Network::mapFilterAuthorTimeMin = UI::InputInt("##mintime", Network::mapFilterAuthorTimeMin);
            if (Network::mapFilterAuthorTimeMin < 0) Network::mapFilterAuthorTimeMin = 0;
            if (Network::mapFilterAuthorTimeMin >= Network::mapFilterAuthorTimeMax) {
                Network::mapFilterAuthorTimeMin = Network::mapFilterAuthorTimeMax - 1;
            }

            UI::NewLine();
            UI::Separator();
            UI::NewLine();

            // Tag filter mode toggle
            UI::Text("Tag Filter Mode:");
            if (UI::BeginCombo("##tagmode", Network::useTagWhitelist ? "Whitelist (Include)" : "Blacklist (Exclude)")) {
                if (UI::Selectable("Whitelist (Include)", Network::useTagWhitelist)) {
                    Network::useTagWhitelist = true;
                }
                if (UI::Selectable("Blacklist (Exclude)", !Network::useTagWhitelist)) {
                    Network::useTagWhitelist = false;
                }
                UI::EndCombo();
            }

            UI::NewLine();

            // Tag selection dropdown
            UI::Text("Select tag to add:");
            UI::SetNextItemWidth(200);
            if (UI::BeginCombo("##tagselect", availableTags[selectedTagIndex])) {
                for (uint k = 0; k < availableTags.Length; k++) {
                    bool isSelected = (selectedTagIndex == int(k));
                    if (UI::Selectable(availableTags[k], isSelected)) {
                        selectedTagIndex = k;
                    }
                    if (isSelected) {
                        UI::SetItemDefaultFocus();
                    }
                }
                UI::EndCombo();
            }

            UI::SameLine();
            if (StyledButton("Add Tag##addtag", vec2(100.0f, 0))) {
                string tagToAdd = availableTags[selectedTagIndex];
                // Add to the appropriate list based on mode
                if (Network::useTagWhitelist) {
                    if (Network::mapFilterSelectedTags.Find(tagToAdd) < 0) {
                        Network::mapFilterSelectedTags.InsertLast(tagToAdd);
                    }
                } else {
                    if (Network::mapFilterBlacklistedTags.Find(tagToAdd) < 0) {
                        Network::mapFilterBlacklistedTags.InsertLast(tagToAdd);
                    }
                }
            }

            UI::NewLine();
            UI::Separator();
            UI::NewLine();

            // Display selected tags based on mode
            UI::BeginChild("TagsList", vec2(0, 180), true);
            if (Network::useTagWhitelist) {
                if (Network::mapFilterSelectedTags.Length > 0) {
                    UI::Text(themeSuccessTextColor + "Whitelisted Tags (Include):");
                    for (uint m = 0; m < Network::mapFilterSelectedTags.Length; m++) {
                        UI::Text("  " + Network::mapFilterSelectedTags[m]);
                        UI::SameLine();
                        if (StyledButton("Remove##wl" + m)) {
                            Network::mapFilterSelectedTags.RemoveAt(m);
                            break;
                        }
                    }
                } else {
                    UI::TextDisabled("No tags whitelisted (any map type allowed)");
                }
            } else {
                if (Network::mapFilterBlacklistedTags.Length > 0) {
                    UI::Text(themeWarningTextColor + "Blacklisted Tags (Exclude):");
                    for (uint m = 0; m < Network::mapFilterBlacklistedTags.Length; m++) {
                        UI::Text("  " + Network::mapFilterBlacklistedTags[m]);
                        UI::SameLine();
                        if (StyledButton("Remove##bl" + m)) {
                            Network::mapFilterBlacklistedTags.RemoveAt(m);
                            break;
                        }
                    }
                } else {
                    UI::TextDisabled("No tags blacklisted (all map types allowed)");
                }
            }
            UI::EndChild();

            UI::NewLine();
            UI::Separator();

            // Bottom buttons
            if (StyledButton("Apply Filters", vec2(150.0f, 30.0f))) {
                // Build filters JSON and send to server
                Json::Value filters = Json::Object();
                filters["authortimemax"] = Network::mapFilterAuthorTimeMax;
                if (Network::mapFilterAuthorTimeMin > 0) {
                    filters["authortimemin"] = Network::mapFilterAuthorTimeMin;
                }

                // Add whitelist tags
                if (Network::mapFilterSelectedTags.Length > 0) {
                    Json::Value tagsArray = Json::Array();
                    for (uint n = 0; n < Network::mapFilterSelectedTags.Length; n++) {
                        tagsArray.Add(Network::mapFilterSelectedTags[n]);
                    }
                    filters["tags"] = tagsArray;
                }

                // Add blacklist tags
                if (Network::mapFilterBlacklistedTags.Length > 0) {
                    Json::Value excludeTagsArray = Json::Array();
                    for (uint p = 0; p < Network::mapFilterBlacklistedTags.Length; p++) {
                        excludeTagsArray.Add(Network::mapFilterBlacklistedTags[p]);
                    }
                    filters["excludeTags"] = excludeTagsArray;
                }

                Network::SetMapFilters(Network::currentLobbyId, filters);
                UI::ShowNotification("Chess", "Map filters updated!", vec4(0.2,0.8,0.2,1), 3000);
            }

            UI::SameLine();

            if (StyledButton("Close", vec2(150.0f, 30.0f))) {
                showMapFiltersWindow = false;
            }
        }
        UI::End();
    }
}