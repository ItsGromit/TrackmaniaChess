    void HandleMsg(Json::Value &msg) {
        if (msg.GetType() != Json::Type::Object) {
            print("Network::HandleMsg - Invalid message type: " + msg.GetType());
            return;
        }

        string t = msg["type"];

        if (t == "hello") {
            playerId = string(msg["id"]);
        }
        else if (t == "lobby_list") {
            lobbies.Resize(0);
            auto arr = msg["lobbies"];
            for (uint i = 0; i < arr.Length; i++) {
                Lobby l;
                auto e = arr[i];
                l.id          = string(e["id"]);
                l.title       = e.HasKey("title") ? string(e["title"]) : "";
                l.hostId      = string(e["hostId"]);
                l.players     = int(e["players"]);
                l.open        = bool(e["open"]);
                l.hasPassword = bool(e["hasPassword"]);
                l.password    = l.hasPassword ? "*" : "";
                l.raceMode    = e.HasKey("raceMode") ? string(e["raceMode"]) : "capture";
                l.playerNames.Resize(0);
                if (e["playerNames"].GetType() != Json::Type::Null) {
                    for (uint j = 0; j < e["playerNames"].Length; j++) {
                        l.playerNames.InsertLast(string(e["playerNames"][j]));
                    }
                }
                lobbies.InsertLast(l);
            }
        }
        else if (t == "lobby_created") {
            currentLobbyId = string(msg["lobbyId"]);
            isHost = true;
            // Store the lobby's race mode
            if (msg.HasKey("raceMode")) {
                currentLobbyRaceMode = string(msg["raceMode"]);
            }
            // Initialize player names array (creator is the only player initially)
            currentLobbyPlayerNames.Resize(0);
            currentLobbyPlayerNames.InsertLast(GetLocalPlayerName());
            print("[Chess Race Classic] Lobby successfully created - LobbyId: " + currentLobbyId);
            GameManager::currentState = GameState::InLobby;
        }
        else if (t == "lobby_update") {
            string id = string(msg["lobbyId"]);
            if (id == currentLobbyId || currentLobbyId.Length == 0) {
                currentLobbyId = id;
                string host = string(msg["hostId"]);
                isHost = (host == playerId);
                // Store the lobby's race mode
                if (msg.HasKey("raceMode")) {
                    currentLobbyRaceMode = string(msg["raceMode"]);
                }
                // Store player names
                currentLobbyPlayerNames.Resize(0);
                if (msg.HasKey("playerNames") && msg["playerNames"].GetType() != Json::Type::Null) {
                    for (uint j = 0; j < msg["playerNames"].Length; j++) {
                        currentLobbyPlayerNames.InsertLast(string(msg["playerNames"][j]));
                    }
                }
                // Transition to InLobby state when joining
                if (currentLobbyId.Length > 0 && GameManager::currentState == GameState::InQueue) {
                    GameManager::currentState = GameState::InLobby;
                    // Request current map filters when joining lobby (only for Capture Race mode)
                    if (currentLobbyRaceMode == "capture") {
                        GetMapFilters(currentLobbyId);
                    }
                }
            }
        }
        else if (t == "game_start") {
            gameId  = string(msg["gameId"]);
            isWhite = bool(msg["isWhite"]);
            string fen  = string(msg["fen"]);
            string turn = string(msg["turn"]); // "w"/"b"

            // Receive race mode from server
            if (msg.HasKey("raceMode")) {
                string raceModeStr = string(msg["raceMode"]);
                currentRaceMode = (raceModeStr == "square") ? RaceMode::SquareRace : RaceMode::CaptureRace;
                print("[Chess] Game starting - gameId: " + gameId + ", isWhite: " + isWhite + ", turn: " + turn + ", mode: " + raceModeStr);
            } else {
                print("[Chess] Game starting - gameId: " + gameId + ", isWhite: " + isWhite + ", turn: " + turn);
            }

            // Reset game state variables
            gameOver = false;
            gameResult = "";
            moveHistory.Resize(0); // Clear move history for new game
            rematchRequestReceived = false;
            rematchRequestSent = false;

            ApplyFEN(fen, turn);
            GameManager::currentState = GameState::Playing;

            // Initialize new race mode if selected
            if (currentRaceMode == RaceMode::SquareRace) {
                startnew(RaceMode::InitializeAndAssignMaps);
            }

            print("[Chess] Game state updated to Playing");
        } else if (t == "moved") {
            string fen  = string(msg["fen"]);
            string turn = string(msg["turn"]);

            // Parse move information and add to history
            if (msg.HasKey("from") && msg.HasKey("to")) {
                string fromAlg = string(msg["from"]);
                string toAlg = string(msg["to"]);

                // Convert algebraic notation to row/col
                int fromRow, fromCol, toRow, toCol;
                if (AlgToRowCol(fromAlg, fromRow, fromCol) && AlgToRowCol(toAlg, toRow, toCol)) {
                    Move@ m = Move(fromRow, fromCol, toRow, toCol);
                    moveHistory.InsertLast(m);
                }
            }

            ApplyFEN(fen, turn);
        } else if (t == "game_over") {
            string reason = string(msg["reason"]);
            string winner = msg.HasKey("winner") ? string(msg["winner"]) : "none";
            print("[Chess] Game over - reason: " + reason + ", winner: " + winner + ", gameId: " + gameId);
            GameManager::currentState = GameState::GameOver;
            gameOver = true;
            gameResult = (winner.Length > 0 ? winner : "none") + " — " + reason;
            print("[Chess] gameId preserved for rematch: " + gameId);
        } else if (t == "race_challenge") {
            raceMapTmxId = int(msg["tmxId"]);
            raceMapName = msg.HasKey("mapName") ? string(msg["mapName"]) : "Unknown Map";
            isDefender = bool(msg["isDefender"]);
            captureFrom = string(msg["from"]);
            captureTo = string(msg["to"]);
            defenderTime = -1;

            print("[Chess] Race challenge started - Map: " + raceMapName + " (TMX ID: " + raceMapTmxId + "), You are: " + (isDefender ? "Defender" : "Attacker"));
            GameManager::currentState = GameState::RaceChallenge;

            // Reset race state in main.as via external variable
            raceStartedAt = Time::Now;

            // Download and load the race map from TMX
            DownloadAndLoadMapFromTMX(raceMapTmxId, raceMapName);
        } else if (t == "race_defender_finished") {
            // Defender finished their race
            defenderTime = int(msg["time"]);
            print("[Chess] Defender finished race in " + defenderTime + "ms");
        } else if (t == "race_result") {
            // Race completed, apply the result
            bool captureSucceeded = bool(msg["captureSucceeded"]);
            string fen = string(msg["fen"]);
            string turn = string(msg["turn"]);

            print("[Chess] Race result - Capture " + (captureSucceeded ? "succeeded" : "failed"));

            // Apply the board state
            ApplyFEN(fen, turn);
            GameManager::currentState = GameState::Playing;

            // Reset race state
            raceMapTmxId = -1;
            raceMapName = "";
            isDefender = false;
            defenderTime = -1;
            captureFrom = "";
            captureTo = "";
        } else if (t == "rematch_request") {
            print("[Chess] Received rematch request from opponent");
            rematchRequestReceived = true;
            rematchRequestSent = false;
            UI::ShowNotification("Chess", "Your opponent wants a rematch!", vec4(0.2,0.8,0.2,1), 5000);
        } else if (t == "rematch_sent") {
            print("[Chess] Rematch request sent to opponent");
            rematchRequestSent = true;
            rematchRequestReceived = false;
            UI::ShowNotification("Chess", "Rematch request sent. Waiting for opponent...", vec4(0.8,0.8,0.2,1), 4000);
        } else if (t == "rematch_declined") {
            print("[Chess] Rematch declined");
            rematchRequestReceived = false;
            rematchRequestSent = false;
            UI::ShowNotification("Chess", "Rematch declined", vec4(1,0.4,0.4,1), 4000);
        } else if (t == "reroll_request") {
            print("[Chess] Received re-roll request from opponent");
            rerollRequestReceived = true;
            rerollRequestSent = false;
            UI::ShowNotification("Chess", "Your opponent wants to re-roll the map!", vec4(0.2,0.8,0.2,1), 5000);
        } else if (t == "reroll_sent") {
            print("[Chess] Re-roll request sent to opponent");
            rerollRequestSent = true;
            rerollRequestReceived = false;
            UI::ShowNotification("Chess", "Re-roll request sent. Waiting for opponent...", vec4(0.8,0.8,0.2,1), 4000);
        } else if (t == "reroll_declined") {
            print("[Chess] Re-roll declined");
            rerollRequestReceived = false;
            rerollRequestSent = false;
            UI::ShowNotification("Chess", "Re-roll declined", vec4(1,0.4,0.4,1), 4000);
        } else if (t == "reroll_approved") {
            print("[Chess] Re-roll approved - loading new map");
            rerollRequestReceived = false;
            rerollRequestSent = false;

            // Update map info and load new map
            raceMapTmxId = int(msg["tmxId"]);
            raceMapName = msg.HasKey("mapName") ? string(msg["mapName"]) : "Unknown Map";

            print("[Chess] New map: " + raceMapName + " (TMX ID: " + raceMapTmxId + ")");
            UI::ShowNotification("Chess", "Loading new map: " + raceMapName, vec4(0.2,0.8,0.2,1), 5000);

            DownloadAndLoadMapFromTMX(raceMapTmxId, raceMapName);
        } else if (t == "map_filters_updated") {
            print("[Chess] Map filters updated for lobby");
            // Update local filter values from server
            if (msg.HasKey("filters")) {
                auto filters = msg["filters"];
                if (filters.HasKey("authortimemax")) {
                    mapFilterAuthorTimeMax = int(filters["authortimemax"]);
                }
                if (filters.HasKey("authortimemin")) {
                    mapFilterAuthorTimeMin = int(filters["authortimemin"]);
                }
                if (filters.HasKey("tags")) {
                    mapFilterSelectedTags.Resize(0);
                    auto tagsArray = filters["tags"];
                    for (uint i = 0; i < tagsArray.Length; i++) {
                        mapFilterSelectedTags.InsertLast(string(tagsArray[i]));
                    }
                }
                if (filters.HasKey("excludeTags")) {
                    mapFilterBlacklistedTags.Resize(0);
                    auto excludeTagsArray = filters["excludeTags"];
                    for (uint i = 0; i < excludeTagsArray.Length; i++) {
                        mapFilterBlacklistedTags.InsertLast(string(excludeTagsArray[i]));
                    }
                }
            }
        } else if (t == "map_filters") {
            print("[Chess] Received current map filters");
            // Update local filter values from server
            if (msg.HasKey("filters")) {
                auto filters = msg["filters"];
                if (filters.HasKey("authortimemax")) {
                    mapFilterAuthorTimeMax = int(filters["authortimemax"]);
                }
                if (filters.HasKey("authortimemin")) {
                    mapFilterAuthorTimeMin = int(filters["authortimemin"]);
                }
                if (filters.HasKey("tags")) {
                    mapFilterSelectedTags.Resize(0);
                    auto tagsArray = filters["tags"];
                    for (uint i = 0; i < tagsArray.Length; i++) {
                        mapFilterSelectedTags.InsertLast(string(tagsArray[i]));
                    }
                }
                if (filters.HasKey("excludeTags")) {
                    mapFilterBlacklistedTags.Resize(0);
                    auto excludeTagsArray = filters["excludeTags"];
                    for (uint i = 0; i < excludeTagsArray.Length; i++) {
                        mapFilterBlacklistedTags.InsertLast(string(excludeTagsArray[i]));
                    }
                }
            }
        } else if (t == "error") {
            string errorCode = string(msg["code"]);
            if (errorCode == "REMATCH_ALREADY_SENT") {
                UI::ShowNotification("Chess", "You have already sent a rematch request", vec4(1,0.4,0.4,1), 4000);
            } else if (errorCode == "INVALID_PLAYER_COUNT") {
                UI::ShowNotification("Chess", "Need exactly 2 players to start the game", vec4(1,0.4,0.4,1), 4000);
            } else {
                UI::ShowNotification("Chess", "Error: " + errorCode, vec4(1,0.4,0.4,1), 4000);
            }
        }
    }