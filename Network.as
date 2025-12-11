namespace Network {
    Net::Socket@ sock;
    bool isConnected = false;

    [Setting category="Network" name="Server host"] string serverHost = "yamanote.proxy.rlwy.net";
    [Setting category="Network" name="Server port"] uint serverPort = 36621;

    // =================
    // Network variables
    // =================
    
    string playerId;
    string currentLobbyId;
    string currentLobbyPassword;
    string gameId;
    bool isWhite = false;
    bool isHost = false;

    // ==============
    // Race variables
    // ==============
    int raceMapTmxId = -1;
    string raceMapName = "";
    bool isDefender = false;
    int defenderTime = -1;
    string captureFrom = "";
    string captureTo = "";

    const array<string> FILES = {"a", "b", "c", "d", "e", "f", "g", "h"};

    string GetLocalPlayerName() {
        auto app = GetApp();
        if (app is null) return "Player";
        auto playerInfo = app.LocalPlayerInfo;
        if (playerInfo is null) return "Player";
        return playerInfo.Name;
    }

    class Lobby {
        string  id;
        string  hostId;
        int     players;
        bool    open;
        bool    hasPassword;
        string  password;
        array<string> playerNames;
    }
    array<Lobby> lobbies;

    string _buf;

    // ====================
    // Connection functions
    // ====================
    void Init() {
        @sock = Net::Socket();
    }
    // Connect bool
    bool Connect() {
        if (sock is null) Init();
        bool ok = sock.Connect(serverHost, uint16(serverPort));
        isConnected = ok;
        return ok;
    }
    // Disconnect function
    void Disconnect() {
        if (sock !is null) sock.Close();
        isConnected = false;
        _buf = "";
        gameId = "";
        currentLobbyId = "";
        currentLobbyPassword = "";
        lobbies.Resize(0);
    }
    // Update function
    void Update() {
        if (!isConnected || sock is null) return;

        string chunk = sock.ReadRaw(32768);
        if (chunk.Length == 0) return;

        _buf += chunk;
        int nl;
        while ((nl = _buf.IndexOf("\n")) >= 0) {
            string line = _buf.SubStr(0, nl).Trim();
            _buf = _buf.SubStr(nl + 1);
            if (line.Length == 0) continue;

            Json::Value msg;
            try {
                msg = Json::Parse(line);
                if (msg.GetType() == Json::Type::Object) {
                    HandleMsg(msg);
                } else {
                    print("Network::Update - Parsed JSON is not an object: " + line);
                }
            } catch {
                print("Network::Update - JSON parse error: " + line);
            }
        }
    }
    // Send JSON function
    void SendJson(Json::Value &in j) {
        if (!isConnected || sock is null) return;
        sock.WriteRaw(Json::Write(j) + "\n");
    }

    // ===============
    // Lobby functions
    // ===============
    void ListLobbies() {
        Json::Value j = Json::Object();
        j["type"] = "list_lobbies";
        SendJson(j);
    }
    // Create lobby
    void CreateLobby(const string &in roomCode = "", const string &in password = "", const string &in playerName = "") {
        Json::Value j = Json::Object();
        j["type"] = "create_lobby";

        // Generate random 5-letter room code if not provided
        string code = roomCode;
        if (code.Length == 0) {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            for (uint i = 0; i < 5; i++) {
                uint index = Math::Rand(0, chars.Length);
                code += chars.SubStr(index, 1);
            }
        }

        j["lobbyId"] = code;
        if (password.Length > 0) j["password"] = password;
        // Get local player name
        string name = playerName.Length > 0 ? playerName : GetLocalPlayerName();
        j["playerName"] = name;
        print("[Chess] Creating lobby - RoomCode: " + code + ", HasPassword: " + (password.Length > 0 ? "yes" : "no") + ", Player: " + name);
        SendJson(j);
    }
    // Join lobby
    void JoinLobby(const string &in lobbyId, const string &in password = "", const string &in playerName = "") {
        if (lobbyId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "join_lobby";
        j["lobbyId"] = lobbyId;
        if (password.Length > 0) j["password"] = password;
        // Use local player name
        string name = playerName.Length > 0 ? playerName : GetLocalPlayerName();
        j["playerName"] = name;
        SendJson(j);
    }
    // Leave lobby (will close lobby if you are the host)
    void LeaveLobby() {
        if (currentLobbyId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "leave_lobby";
        j["lobbyId"] = currentLobbyId;
        SendJson(j);
        currentLobbyId = "";
        currentLobbyPassword = "";
        isHost = false;
    }
    // Start game in current lobby
    void StartGame(const string &in lobbyId="") {
        string id = lobbyId.Length > 0 ? lobbyId : currentLobbyId;
        if (id.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "start_game";
        j["lobbyId"] = id;
        SendJson(j);
    }

    // ==================
    // Gameplay functions
    // ==================
    void SendMove(const string &in fromAlg, const string &in toAlg, const string &in promo="q") {
        if (gameId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"]  = "move";
        j["gameId"]= gameId;
        j["from"]  = fromAlg;
        j["to"]    = toAlg;
        if (promo.Length > 0) j["promo"] = promo;
        SendJson(j);
    }
    // Forfeit
    void Resign() {
        print("[Chess] Resign called - gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
        if (gameId.Length == 0) {
            print("[Chess] Cannot resign - gameId is empty");
            return;
        }
        print("[Chess] Sending resign request to server with gameId: " + gameId);
        Json::Value j = Json::Object();
        j["type"] = "resign";
        j["gameId"] = gameId;
        SendJson(j);
    }
    // New game request (with previous gameId)
    void RequestNewGame() {
        print("[Chess] RequestNewGame called - gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
        if (gameId.Length == 0) {
            print("[Chess] Cannot request new game - gameId is empty");
            return;
        }
        print("[Chess] Sending new_game request to server with gameId: " + gameId);
        Json::Value j = Json::Object();
        j["type"] = "new_game";
        j["gameId"] = gameId;
        SendJson(j);
    }
    // Respond to rematch request
    void RespondToRematch(bool accept) {
        print("[Chess] RespondToRematch called - accept: " + accept + ", gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
        if (gameId.Length == 0) {
            print("[Chess] Cannot respond to rematch - gameId is empty");
            return;
        }
        Json::Value j = Json::Object();
        j["type"] = "rematch_response";
        j["gameId"] = gameId;
        j["accept"] = accept;
        SendJson(j);
        rematchRequestReceived = false;
        print("[Chess] Sent rematch response: " + (accept ? "accepted" : "declined"));
    }
    // Request re-roll
    void RequestReroll() {
        print("[Chess] RequestReroll called - gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
        if (gameId.Length == 0) {
            print("[Chess] Cannot request re-roll - gameId is empty");
            return;
        }
        print("[Chess] Sending reroll_request to server with gameId: " + gameId);
        Json::Value j = Json::Object();
        j["type"] = "reroll_request";
        j["gameId"] = gameId;
        SendJson(j);
    }
    // Respond to re-roll request
    void RespondToReroll(bool accept) {
        print("[Chess] RespondToReroll called - accept: " + accept + ", gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
        if (gameId.Length == 0) {
            print("[Chess] Cannot respond to re-roll - gameId is empty");
            return;
        }
        Json::Value j = Json::Object();
        j["type"] = "reroll_response";
        j["gameId"] = gameId;
        j["accept"] = accept;
        SendJson(j);
        rerollRequestReceived = false;
        print("[Chess] Sent re-roll response: " + (accept ? "accepted" : "declined"));
    }
    // Send race result
    void SendRaceResult(int timeMs) {
        if (gameId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "race_result";
        j["gameId"] = gameId;
        j["time"] = timeMs;
        print("[Chess] Sending race result: " + timeMs + "ms");
        SendJson(j);
    }
    // Retire from race (player doesn't finish the track)
    void RetireFromRace() {
        if (gameId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "race_retire";
        j["gameId"] = gameId;
        print("[Chess] Retiring from race - forfeiting piece");
        SendJson(j);
    }

    // ========
    // Messages
    // ========
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
                l.hostId      = string(e["hostId"]);
                l.players     = int(e["players"]);
                l.open        = bool(e["open"]);
                l.hasPassword = bool(e["hasPassword"]);
                l.password    = l.hasPassword ? "*" : "";
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
            print("[Chess Race] Lobby successfully created - LobbyId: " + currentLobbyId);
            GameManager::currentState = GameState::InLobby;
        }
        else if (t == "lobby_update") {
            string id = string(msg["lobbyId"]);
            if (id == currentLobbyId || currentLobbyId.Length == 0) {
                currentLobbyId = id;
                string host = string(msg["hostId"]);
                isHost = (host == playerId);
                // Transition to InLobby state when joining
                if (currentLobbyId.Length > 0 && GameManager::currentState == GameState::InQueue) {
                    GameManager::currentState = GameState::InLobby;
                }
            }
        }
        else if (t == "game_start") {
            gameId  = string(msg["gameId"]);
            isWhite = bool(msg["isWhite"]);
            string fen  = string(msg["fen"]);
            string turn = string(msg["turn"]); // "w"/"b"

            print("[Chess] Game starting - gameId: " + gameId + ", isWhite: " + isWhite + ", turn: " + turn);

            // Reset game state variables
            gameOver = false;
            gameResult = "";
            moveHistory.Resize(0); // Clear move history for new game
            rematchRequestReceived = false;
            rematchRequestSent = false;

            ApplyFEN(fen, turn);
            GameManager::currentState = GameState::Playing;
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
        } else if (t == "error") {
            string errorCode = string(msg["code"]);
            if (errorCode == "REMATCH_ALREADY_SENT") {
                UI::ShowNotification("Chess", "You have already sent a rematch request", vec4(1,0.4,0.4,1), 4000);
            } else {
                UI::ShowNotification("Chess", "Error: " + errorCode, vec4(1,0.4,0.4,1), 4000);
            }
        }
    }

    // row/col -> "a1"
    string ToAlg(int row, int col) {
        string file = (col >= 0 && col < 8) ? FILES[col] : "?";
        int rank = 8 - row;
        return file + rank;
    }

    // "a1" -> row/col
    bool AlgToRowCol(const string &in alg, int &out row, int &out col) {
        if (alg.Length < 2) return false;

        string file = alg.SubStr(0, 1).ToLower();
        string rankStr = alg.SubStr(1, 1);

        col = -1;
        for (uint i = 0; i < FILES.Length; i++) {
            if (FILES[i] == file) {
                col = int(i);
                break;
            }
        }
        if (col < 0 || col > 7) return false;

        int rank = Text::ParseInt(rankStr);
        if (rank < 1 || rank > 8) return false;
        row = 8 - rank;

        return true;
    }

    // Developer/Testing function to simulate a race challenge
    void TestRaceChallenge() {
        print("[Chess] Developer: Simulating race challenge");

        // Fetch a random map from the current campaign
        startnew(FetchTestRaceMap);
    }

    // Coroutine to fetch a random campaign map for test race challenge
    void FetchTestRaceMap() {
        print("[Chess] Fetching random campaign map for test race...");

        // Fetch from current campaign by searching for Nadeo maps with campaign tag
        string tmxUrl = "https://trackmania.exchange/mapsearch2/search?api=on&authorlogin=nadeo&tags=23&limit=25&order=TrackID&orderdir=DESC";

        auto req = Net::HttpRequest();
        req.Url = tmxUrl;
        req.Method = Net::HttpMethod::Get;
        req.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
        req.Start();

        // Wait for request to complete
        while (!req.Finished()) {
            yield();
        }

        int tmxId = -1;
        string testMapName;

        if (req.ResponseCode() == 200) {
            // Parse response
            auto response = Json::Parse(req.String());
            if (response.GetType() == Json::Type::Object && response.HasKey("results")) {
                auto results = response["results"];
                if (results.Length > 0) {
                    // Pick a random map from the campaign
                    int randomIndex = Math::Rand(0, results.Length);
                    auto mapData = results[randomIndex];

                    tmxId = int(mapData["TrackID"]);
                    testMapName = mapData.HasKey("GbxMapName") ? string(mapData["GbxMapName"]) : string(mapData["Name"]);

                    print("[Chess] Selected campaign map: " + testMapName + " (TMX ID: " + tmxId + ")");
                } else {
                    print("[Chess] No campaign maps found, cannot start test race");
                    UI::ShowNotification("Chess", "No campaign maps found", vec4(1,0.4,0.4,1), 4000);
                    return;
                }
            } else {
                print("[Chess] Invalid TMX response, cannot start test race");
                UI::ShowNotification("Chess", "Invalid TMX response", vec4(1,0.4,0.4,1), 4000);
                return;
            }
        } else {
            print("[Chess] Failed to fetch from TMX (HTTP " + req.ResponseCode() + "), cannot start test race");
            UI::ShowNotification("Chess", "Failed to fetch from TMX", vec4(1,0.4,0.4,1), 4000);
            return;
        }

        // Simulate receiving a race_challenge message
        raceMapName = testMapName;
        isDefender = (Math::Rand(0, 2) == 0); // Random attacker/defender
        captureFrom = "e2";
        captureTo = "e4";
        defenderTime = -1;

        print("[Chess] Test Race - Map: " + raceMapName + ", You are: " + (isDefender ? "Defender" : "Attacker"));
        GameManager::currentState = GameState::RaceChallenge;

        raceStartedAt = Time::Now;

        // Download and load the map from TMX
        DownloadAndLoadMapFromTMX(tmxId, testMapName);
    }

    // Developer/Testing function to re-roll to a new map (no opponent approval needed)
    void TestRerollMap() {
        print("[Chess] Developer: Re-rolling to new map");

        // Fetch a random map from the current campaign
        // Start a coroutine to fetch from TMX
        startnew(FetchDevRandomMap);
    }

    // Coroutine to fetch a random map from TMX for developer mode
    void FetchDevRandomMap() {
        print("[Chess] Fetching random map from current campaign...");

        // Fetch from current campaign by searching for Nadeo maps with campaign tag
        string tmxUrl = "https://trackmania.exchange/mapsearch2/search?api=on&authorlogin=nadeo&tags=23&limit=25&order=TrackID&orderdir=DESC";

        auto req = Net::HttpRequest();
        req.Url = tmxUrl;
        req.Method = Net::HttpMethod::Get;
        req.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
        req.Start();

        // Wait for request to complete
        while (!req.Finished()) {
            yield();
        }

        if (req.ResponseCode() != 200) {
            print("[Chess] ERROR: Failed to fetch campaign maps from TMX. HTTP code: " + req.ResponseCode());
            UI::ShowNotification("Chess", "Failed to fetch map from TMX", vec4(1,0.4,0.4,1), 4000);
            return;
        }

        // Parse response
        auto response = Json::Parse(req.String());
        if (response.GetType() != Json::Type::Object || !response.HasKey("results")) {
            print("[Chess] ERROR: Invalid TMX response");
            UI::ShowNotification("Chess", "Invalid TMX response", vec4(1,0.4,0.4,1), 4000);
            return;
        }

        auto results = response["results"];
        if (results.Length == 0) {
            print("[Chess] ERROR: No maps found in current campaign");
            UI::ShowNotification("Chess", "No maps found", vec4(1,0.4,0.4,1), 4000);
            return;
        }

        // Pick a random map from the results
        int randomIndex = Math::Rand(0, results.Length);
        auto mapData = results[randomIndex];

        int tmxId = int(mapData["TrackID"]);
        raceMapName = mapData.HasKey("GbxMapName") ? string(mapData["GbxMapName"]) : string(mapData["Name"]);

        print("[Chess] Re-rolled to new map: " + raceMapName + " (TMX ID: " + tmxId + ")");
        UI::ShowNotification("Chess", "Loading new map: " + raceMapName, vec4(0.2,0.8,0.2,1), 5000);

        // Download and load the new map from TMX
        DownloadAndLoadMapFromTMX(tmxId, raceMapName);
    }

    // Download and load a map from TMX by its TMX ID
    void DownloadAndLoadMapFromTMX(int tmxId, const string &in mapName) {
        print("[Chess] Downloading map from TMX ID: " + tmxId);

        string downloadUrl = "https://trackmania.exchange/maps/download/" + tmxId;

        auto downloadReq = Net::HttpRequest();
        downloadReq.Url = downloadUrl;
        downloadReq.Method = Net::HttpMethod::Get;
        downloadReq.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
        downloadReq.Start();

        // Wait for download to complete
        while (!downloadReq.Finished()) {
            yield();
        }

        if (downloadReq.ResponseCode() != 200) {
            print("[Chess] ERROR: Failed to download map from TMX. HTTP code: " + downloadReq.ResponseCode());
            UI::ShowNotification("Chess", "Failed to download map", vec4(1,0.4,0.4,1), 4000);
            return;
        }

        string mapFileData = downloadReq.String();
        print("[Chess] Map downloaded successfully (" + mapFileData.Length + " bytes)");

        // Save the map to the Downloaded folder
        string tempMapPath = IO::FromUserGameFolder("Maps/Downloaded/ChessRace_" + tmxId + ".Map.Gbx");

        // Create directory if it doesn't exist
        string dir = IO::FromUserGameFolder("Maps/Downloaded/");
        if (!IO::FolderExists(dir)) {
            IO::CreateFolder(dir);
            print("[Chess] Created download directory: " + dir);
        }

        // Write the map file
        IO::File file;
        file.Open(tempMapPath, IO::FileMode::Write);
        file.Write(mapFileData);
        file.Close();

        print("[Chess] Map saved to: " + tempMapPath);

        // Now load the downloaded map
        auto app = cast<CTrackMania>(GetApp());
        if (app is null) {
            print("[Chess] Error: Could not get app instance for loading");
            return;
        }

        // Check if we're already in a map
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (playground !is null) {
            print("[Chess] Currently in a map, returning to menu first");
            app.BackToMainMenu();

            // Wait for menu transition
            for (int i = 0; i < 100; i++) {
                yield();
                auto check = cast<CSmArenaClient>(app.CurrentPlayground);
                if (check is null) {
                    print("[Chess] Successfully returned to menu");
                    break;
                }
            }
            sleep(1000);
        }

        auto maniaTitleAPI = app.ManiaTitleControlScriptAPI;
        if (maniaTitleAPI !is null) {
            print("[Chess] Loading downloaded map: " + mapName);
            maniaTitleAPI.PlayMap(tempMapPath, "TrackMania/TM_PlayMap_Local", "");

            sleep(3000);
            auto result = cast<CSmArenaClient>(app.CurrentPlayground);
            if (result !is null) {
                print("[Chess] SUCCESS: Map loaded!");
            } else {
                print("[Chess] Map loading - please wait...");
            }
        }
    }

    // Load a race map by UID
    void LoadRaceMap(const string &in mapUid) {
        if (mapUid.Length == 0) {
            print("[Chess] Cannot load map - empty UID");
            return;
        }

        print("[Chess] Loading race map with UID: " + mapUid);

        // Try to load the map directly by UID
        // The PlayMap API might accept the UID directly, or we need to construct a proper URL
        // For now, we'll try the UID directly as many Openplanet plugins do

        print("[Chess] Attempting to load map by UID: " + mapUid);

        // Store the UID in a temporary variable for the coroutine
        tempMapUrl = mapUid;

        // Load the map using TrackMania's PlayMap function
        // The game mode for time attack is "TrackMania/TM_PlayMap_Local"
        startnew(LoadMapNow);
    }

    // Temporary variable to pass data to coroutine
    string tempMapUrl = "";

    // Coroutine to load the map
    void LoadMapNow() {
        string mapUid = tempMapUrl;
        tempMapUrl = "";

        print("[Chess] Starting map load coroutine with UID: " + mapUid);

        auto app = cast<CTrackMania>(GetApp());
        if (app is null) {
            print("[Chess] Error: Could not get app instance for loading");
            return;
        }

        // Check if we're already in a map
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (playground !is null) {
            print("[Chess] Currently in a map, returning to menu first");
            app.BackToMainMenu();

            // Wait for menu transition
            for (int i = 0; i < 100; i++) {
                yield();
                auto check = cast<CSmArenaClient>(app.CurrentPlayground);
                if (check is null) {
                    print("[Chess] Successfully returned to menu");
                    break;
                }
            }
            sleep(1000);
        }

        // Try to find the map in the local file system or campaign
        print("[Chess] Searching for map with UID: " + mapUid);
        auto menuManager = app.MenuManager;
        if (menuManager is null) {
            print("[Chess] ERROR: MenuManager is null");
            return;
        }

        CGameCtnChallengeInfo@ mapInfo = null;
        auto campaignInfos = menuManager.ChallengeInfosCampaign;

        // Search for the map in campaigns
        if (campaignInfos.Length > 0) {
            print("[Chess] Searching through " + campaignInfos.Length + " campaign maps");
            for (uint i = 0; i < campaignInfos.Length; i++) {
                auto info = campaignInfos[i];
                if (info.MapUid == mapUid) {
                    @mapInfo = info;
                    print("[Chess] Found map: " + info.Name);
                    break;
                }
            }
        }

        // If map not found locally, download it from TrackmaniaExchange
        if (mapInfo is null) {
            print("[Chess] Map not found locally, searching TrackmaniaExchange...");

            // First, search TMX for the map by UID
            string searchUrl = "https://trackmania.exchange/mapsearch2/search?api=on&trackuid=" + mapUid;
            print("[Chess] Searching TMX: " + searchUrl);

            auto searchReq = Net::HttpRequest();
            searchReq.Url = searchUrl;
            searchReq.Method = Net::HttpMethod::Get;
            searchReq.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
            searchReq.Start();

            // Wait for search to complete
            while (!searchReq.Finished()) {
                yield();
            }

            if (searchReq.ResponseCode() != 200) {
                print("[Chess] ERROR: TMX search failed. HTTP code: " + searchReq.ResponseCode());
                print("[Chess] Cannot download map without TMX ID");
                return;
            }

            // Parse the search results
            auto searchResult = Json::Parse(searchReq.String());
            if (searchResult.GetType() != Json::Type::Object || !searchResult.HasKey("results")) {
                print("[Chess] ERROR: Invalid TMX search response");
                return;
            }

            auto results = searchResult["results"];
            if (results.Length == 0) {
                print("[Chess] ERROR: Map not found on TrackmaniaExchange");
                print("[Chess] The map might be a campaign/official map or not uploaded to TMX");
                return;
            }

            // Get the first result (should be exact match by UID)
            auto mapData = results[0];
            int tmxId = int(mapData["TrackID"]);
            string mapName = string(mapData["GbxMapName"]);
            print("[Chess] Found map on TMX: " + mapName + " (ID: " + tmxId + ")");

            // Download the map from TMX
            string downloadUrl = "https://trackmania.exchange/maps/download/" + tmxId;
            print("[Chess] Downloading from: " + downloadUrl);

            auto downloadReq = Net::HttpRequest();
            downloadReq.Url = downloadUrl;
            downloadReq.Method = Net::HttpMethod::Get;
            downloadReq.Headers['User-Agent'] = "TrackmaniaChess/1.0 (Openplanet)";
            downloadReq.Start();

            // Wait for download to complete
            while (!downloadReq.Finished()) {
                yield();
            }

            if (downloadReq.ResponseCode() == 200) {
                string mapFileData = downloadReq.String();
                print("[Chess] Map downloaded successfully (" + mapFileData.Length + " bytes)");

                // Save the map to a temporary location
                string tempMapPath = IO::FromUserGameFolder("Maps/Downloaded/" + mapUid + ".Map.Gbx");

                // Create directory if it doesn't exist
                string dir = IO::FromUserGameFolder("Maps/Downloaded/");
                if (!IO::FolderExists(dir)) {
                    IO::CreateFolder(dir);
                    print("[Chess] Created download directory: " + dir);
                }

                // Write the map file
                IO::File file;
                file.Open(tempMapPath, IO::FileMode::Write);
                file.Write(mapFileData);
                file.Close();

                print("[Chess] Map saved to: " + tempMapPath);

                // Now try to load the downloaded map
                auto maniaTitleAPI = app.ManiaTitleControlScriptAPI;
                if (maniaTitleAPI !is null) {
                    print("[Chess] Loading downloaded map...");
                    maniaTitleAPI.PlayMap(tempMapPath, "TrackMania/TM_PlayMap_Local", "");

                    sleep(3000);
                    auto result = cast<CSmArenaClient>(app.CurrentPlayground);
                    if (result !is null) {
                        print("[Chess] SUCCESS: Downloaded map loaded!");
                    } else {
                        print("[Chess] Map loading - please wait...");
                    }
                }
            } else {
                print("[Chess] ERROR: Failed to download map from TMX. HTTP code: " + downloadReq.ResponseCode());
                print("[Chess] The download might have been blocked or the map is unavailable");
            }
            return;
        }

        // If we found the map locally, load it directly
        print("[Chess] Loading map from local files: " + mapInfo.FileName);
        app.BackToMainMenu();
        yield();

        auto maniaTitleAPI = app.ManiaTitleControlScriptAPI;
        if (maniaTitleAPI !is null) {
            maniaTitleAPI.PlayMap(mapInfo.FileName, "TrackMania/TM_PlayMap_Local", "");

            // Wait and verify
            sleep(3000);
            auto result = cast<CSmArenaClient>(app.CurrentPlayground);
            if (result !is null) {
                print("[Chess] SUCCESS: Map loaded!");
            } else {
                print("[Chess] Map loading - please wait...");
            }
        }
    }
}