namespace Lobby {
    // announce lobby variables
    string createLobbyPassword = "";
    string lobbyPassword = "";
    string createLobbyRoomCode = "";
    string joinLobbyPassword = "";
    string selectedLobbyId = "";

    void RenderCreateLobby() {
        UI::Text("Create Room");
        UI::Text("Input password(optional)");
        UI::SetNextItemWidth(200);
        createLobbyPassword = UI::InputText("Password (optional)", createLobbyPassword);

        if (UI::Button("Create Room")) {
            Network::CreateLobby("", createLobbyPassword);
            createLobbyPassword = "";
            GameManager::currentState = GameState::InLobby;
        }
        UI::SameLine();
        if (UI::Button("Refresh")) {
            Network::ListLobbies();
        }
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
            UI::Text("\\$ff0Room Code: " + l.id);
            UI::SameLine();
            if (UI::Button("Copy##roomcode")) {
                IO::SetClipboard(l.id);
            }

            if (l.hasPassword && Network::currentLobbyPassword.Length > 0) {
                UI::Text("Password: " + Network::currentLobbyPassword);
                UI::SameLine();
                if (UI::Button("Copy##password")) {
                    IO::SetClipboard(Network::currentLobbyPassword);
                }
            }

            UI::BeginChild("LobbyPlayers", vec2(0, 100));
            UI::Text("\\$0f0Players in Lobby:");
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

            if (Network::isHost) {
                if (UI::Button("Start Game")) {
                    Network::StartGame();
                }
                UI::SameLine();
            }
            if (UI::Button("Leave Lobby")) {
                Network::LeaveLobby();
                GameManager::currentState = GameState::Menu;
            }
            break;
        }

        // If lobby not found in list yet, show basic info
        if (!foundLobby) {
            UI::Text("\\$ff0Room Code: " + Network::currentLobbyId);
            UI::SameLine();
            if (UI::Button("Copy##roomcode")) {
                IO::SetClipboard(Network::currentLobbyId);
            }

            UI::Text("\\$0f0Waiting for lobby details...");

            if (UI::Button("Refresh")) {
                Network::ListLobbies();
            }
            UI::SameLine();
            if (UI::Button("Leave Lobby")) {
                Network::LeaveLobby();
                GameManager::currentState = GameState::InQueue;
            }
        }
    }
}