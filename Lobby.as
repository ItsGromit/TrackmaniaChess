namespace Lobby {
    string createLobbyPassword = "";
    string createLobbyRoomCode = "";
    string joinLobbyPassword = "";
    string selectedLobbyId = "";
    string password = "";

    void RenderCreateLobby() {
        UI::Text("Create Room");
        
        UI::Text("Input a password unless you want random people to join and play you.");
        UI::SetNextItemWidth(200);
        createLobbyPassword = UI::InputText("Password (optional)", createLobbyPassword);

        if (UI::Button("Create Room")) {
            Network::CreateLobby("", createLobbyPassword);
            createLobbyPassword = "";
        }
        UI::SameLine();
        if (UI::Button("Refresh")) {
            Network::ListLobbies();
        }
        UI::Separator();
    }

    void RenderLobbyList() {
        UI::Text("Available Lobbies:");

        for (uint i = 0; i < Network::lobbies.Length; i++) {
            Network::Lobby@ l = Network::lobbies[i];
            if (l.id == Network::currentLobbyId) continue;

            // Get the host name from playerNames array (host is first player)
            string hostName = l.playerNames.Length > 0 ? l.playerNames[0] : l.hostId;
            UI::Text("[" + l.id + "] " + hostName + " (" + l.players + ")");
            UI::SameLine();
            
            if (l.open) {
                if (l.hasPassword) {
                    if (selectedLobbyId == l.id) {
                        UI::SetNextItemWidth(100);
                        joinLobbyPassword = UI::InputText("Password##" + l.id, joinLobbyPassword);
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
                    if (UI::Button("Join##" + l.id)) {
                        Network::JoinLobby(l.id);
                    }
                }
            } else {
                UI::Text("(In Game)");
            }
        }
    }

    void RenderCurrentLobby() {
        if (Network::currentLobbyId == "") return;
        
        for (uint i = 0; i < Network::lobbies.Length; i++) {
            Network::Lobby@ l = Network::lobbies[i];
            if (l.id != Network::currentLobbyId) continue;
            
            UI::Text("\\$ff0Room Code: " + l.id);
            UI::SameLine();
            if (UI::Button("Copy##roomcode")) {
                IO::SetClipboard(l.id);
            }
            
            if (l.hasPassword) {
                UI::Text("Password: " + l.password);
                UI::SameLine();
                if (UI::Button("Copy##password")) {
                    IO::SetClipboard(l.password);
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
                GameManager::currentState = GameState::InQueue;
            }
            break;
        }
    }
}