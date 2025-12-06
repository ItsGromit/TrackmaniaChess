namespace Lobby {
    // announce lobby variables
    string createLobbyPassword = "";
    string lobbyPassword = "";
    string createLobbyRoomCode = "";
    string joinLobbyPassword = "";
    string selectedLobbyId = "";
    bool showCreateRoomSection = false;

    void RenderCreateLobby() {
        // Create Room toggle button
        string toggleIcon = showCreateRoomSection ? Icons::ChevronDown : Icons::ChevronRight;
        if (UI::Button(toggleIcon + " Create Room", vec2(200.0f, 30.0f))) {
            showCreateRoomSection = !showCreateRoomSection;
        }

        UI::Separator();

        // Show expanded section if toggled
        if (showCreateRoomSection) {
            UI::NewLine();

            UI::Text("Password (optional):");
            UI::SetNextItemWidth(200);
            createLobbyPassword = UI::InputText("##password", createLobbyPassword);
            UI::NewLine();

            if (UI::Button("Create Room", vec2(150.0f, 30.0f))) {
                Network::CreateLobby("", createLobbyPassword);
                createLobbyPassword = "";
                showCreateRoomSection = false;
                GameManager::currentState = GameState::InLobby;
            }

            UI::SameLine();

            if (UI::Button("Cancel", vec2(150.0f, 30.0f))) {
                showCreateRoomSection = false;
                createLobbyPassword = "";
            }

            UI::NewLine();
            UI::Separator();
        }

        // Refresh button always visible
        UI::NewLine();
        if (UI::Button("Refresh Lobby List", vec2(200.0f, 30.0f))) {
            Network::ListLobbies();
        }
        UI::NewLine();
        UI::Separator();
    }

    void RenderLobbyList() {
        UI::Text("Available Games:");

        for (uint i = 0; i < Network::lobbies.Length; i++) {
            Network::Lobby@ l = Network::lobbies[i];
            if (l.id == Network::currentLobbyId) continue;
            string hostName = l.playerNames.Length > 0 ? l.playerNames[0] : l.hostId;
            string lobbyText = "Room: " + l.id + " (" + l.players + " players)";
            UI::Text("[" + l.id + "]" + hostName + " (" + l.players + ")");
            UI::SameLine();

            if(l.open)
                if (l.hasPassword) {
                    lobbyText += " [Password Protected]";
                    if (selectedLobbyId == l.id) {
                        UI::SetNextItemWidth(100);
                        joinLobbyPassword = UI::InputText('Password##' + l.id, joinLobbyPassword);
                        UI::SameLine();
                        if (UI::Button("Join##" + l.id)) {
                            Network::JoinLobby(l.id, joinLobbyPassword);
                            joinLobbyPassword = "";
                            selectedLobbyId = "";
                        }
                        UI::SameLine();
                        if (UI::Button("Cancel##" + l.id)) {
                            selectedLobbyId = "";
                            joinLobbyPassword = "";
                        }
                    } else {
                        if (UI::Button("Join (Password)##" + l.id)) {
                            selectedLobbyId = l.id;
                        }
                    }
                } else {
                    if (UI::Button(lobbyText + "Join##" + l.id)) {
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
            UI::Text(themeSectionLabelColor + "Room Code:");
            UI::Text(l.id);
            UI::SameLine();
            if (UI::Button("Copy##roomcode")) {
                IO::SetClipboard(l.id);
            }
            UI::NewLine();

            // Password section (if applicable)
            if (l.hasPassword && Network::currentLobbyPassword.Length > 0) {
                UI::Text(themeSectionLabelColor + "Password:");
                UI::Text(Network::currentLobbyPassword);
                UI::SameLine();
                if (UI::Button("Copy##password")) {
                    IO::SetClipboard(Network::currentLobbyPassword);
                }
                UI::NewLine();
            }

            // Players section
            UI::Text(themeSuccessTextColor + "Players in Lobby:");
            UI::Separator();
            UI::BeginChild("LobbyPlayers", vec2(0, 120), true);
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
                if (UI::Button("Start Game", vec2(150.0f, 30.0f))) {
                    Network::StartGame();
                }
                UI::SameLine();
            }
            if (UI::Button("Leave Lobby", vec2(150.0f, 30.0f))) {
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
            if (UI::Button("Copy##roomcode")) {
                IO::SetClipboard(Network::currentLobbyId);
            }
            UI::NewLine();

            UI::Text(themeSuccessTextColor + "Waiting for lobby details...");
            UI::NewLine();

            if (UI::Button("Refresh", vec2(150.0f, 30.0f))) {
                Network::ListLobbies();
            }
            UI::SameLine();
            if (UI::Button("Leave Lobby", vec2(150.0f, 30.0f))) {
                Network::LeaveLobby();
                GameManager::currentState = GameState::Menu;
            }
        }
    }
}