namespace Network {
    Net::Socket@ sock;
    bool isConnected = false;

    [Setting category="Network" name="Server host"] string serverHost = "yamanote.proxy.rlwy.net";
    [Setting category="Network" name="Server port"] uint   serverPort = 36621;

    string playerId;
    string currentLobbyId;
    string gameId;
    bool   isWhite = false;
    bool   isHost  = false;

    // Race challenge state
    string raceMapUid = "";
    string raceMapName = "";
    bool   isDefender = false;  // true if you're defending (race first)
    int    defenderTime = -1;   // Defender's race time in ms
    string captureFrom = "";    // Algebraic notation of attacking piece
    string captureTo = "";      // Algebraic notation of target square

    const array<string> FILES = {"a","b","c","d","e","f","g","h"};

    string GetLocalPlayerName() {
        auto app = GetApp();
        if (app is null) return "Player";
        auto playerInfo = app.LocalPlayerInfo;
        if (playerInfo is null) return "Player";
        return playerInfo.Name;
    }

    class Lobby {
        string id;
        string hostId;
        int    players;
        bool   open;
        bool   hasPassword;
        string password;
        array<string> playerNames;
    }
    array<Lobby> lobbies;

    string _buf;

    void Init() {
        @sock = Net::Socket();
    }

    bool Connect() {
        if (sock is null) Init();
        bool ok = sock.Connect(serverHost, uint16(serverPort));
        isConnected = ok;
        return ok;
    }

    void Disconnect() {
        if (sock !is null) sock.Close();
        isConnected = false;
        _buf = "";
        gameId = "";
        currentLobbyId = "";
        lobbies.Resize(0);
    }

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

    void SendJson(Json::Value &in j) {
        if (!isConnected || sock is null) return;
        sock.WriteRaw(Json::Write(j) + "\n");
    }

    // ---------- Lobby ----------
    void ListLobbies() {
        Json::Value j = Json::Object(); j["type"] = "list_lobbies"; SendJson(j);
    }

    void CreateLobby(const string &in roomCode = "", const string &in password = "", const string &in playerName = "") {
        Json::Value j = Json::Object();
        j["type"] = "create_lobby";
        if (roomCode.Length > 0) j["roomCode"] = roomCode;
        if (password.Length > 0) j["password"] = password;
        // Get local player name
        string name = playerName.Length > 0 ? playerName : GetLocalPlayerName();
        j["playerName"] = name;
        print("[Chess] Creating lobby - RoomCode: " + (roomCode.Length > 0 ? roomCode : "none") + ", HasPassword: " + (password.Length > 0 ? "yes" : "no") + ", Player: " + name);
        SendJson(j);
    }

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

    void LeaveLobby() {
        if (currentLobbyId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "leave_lobby";
        j["lobbyId"] = currentLobbyId;
        SendJson(j);
        currentLobbyId = "";
        isHost = false;
    }

    void StartGame(const string &in lobbyId="") {
        string id = lobbyId.Length > 0 ? lobbyId : currentLobbyId;
        if (id.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "start_game";
        j["lobbyId"] = id;
        SendJson(j);
    }

    // ---------- Gameplay ----------
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

    void SendRaceResult(int timeMs) {
        if (gameId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "race_result";
        j["gameId"] = gameId;
        j["time"] = timeMs;
        print("[Chess] Sending race result: " + timeMs + "ms");
        SendJson(j);
    }

    void RetireFromRace() {
        if (gameId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "race_retire";
        j["gameId"] = gameId;
        print("[Chess] Retiring from race - forfeiting piece");
        SendJson(j);
    }

    // ---------- Messages ----------
    void HandleMsg(Json::Value &msg) {
        // Safety check: ensure msg is valid
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
            print("[Chess] Lobby created successfully - LobbyId: " + currentLobbyId);
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

            ApplyFEN(fen, turn);
            GameManager::currentState = GameState::Playing;
            print("[Chess] Game state updated to Playing");
        }
        else if (t == "moved") {
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
        }
        else if (t == "game_over") {
            string reason = string(msg["reason"]);
            string winner = msg.HasKey("winner") ? string(msg["winner"]) : "none";
            print("[Chess] Game over - reason: " + reason + ", winner: " + winner + ", gameId: " + gameId);
            GameManager::currentState = GameState::GameOver;
            gameOver = true;
            gameResult = (winner.Length > 0 ? winner : "none") + " — " + reason;
            print("[Chess] gameId preserved for rematch: " + gameId);
            // Don't clear gameId here so rematch can use it
        }
        else if (t == "race_challenge") {
            // A capture attempt triggers a race
            raceMapUid = string(msg["mapUid"]);
            raceMapName = msg.HasKey("mapName") ? string(msg["mapName"]) : "Unknown Map";
            isDefender = bool(msg["isDefender"]);
            captureFrom = string(msg["from"]);
            captureTo = string(msg["to"]);
            defenderTime = -1;

            print("[Chess] Race challenge started - Map: " + raceMapName + ", You are: " + (isDefender ? "Defender" : "Attacker"));
            GameManager::currentState = GameState::RaceChallenge;

            // Reset race state in main.as via external variable
            raceStartedAt = Time::Now;
        }
        else if (t == "race_defender_finished") {
            // Defender finished their race
            defenderTime = int(msg["time"]);
            print("[Chess] Defender finished race in " + defenderTime + "ms");
        }
        else if (t == "race_result") {
            // Race completed, apply the result
            bool captureSucceeded = bool(msg["captureSucceeded"]);
            string fen = string(msg["fen"]);
            string turn = string(msg["turn"]);

            print("[Chess] Race result - Capture " + (captureSucceeded ? "succeeded" : "failed"));

            // Apply the board state
            ApplyFEN(fen, turn);
            GameManager::currentState = GameState::Playing;

            // Reset race state
            raceMapUid = "";
            raceMapName = "";
            isDefender = false;
            defenderTime = -1;
            captureFrom = "";
            captureTo = "";
        }
        else if (t == "error") {
            UI::ShowNotification("Chess", "Error: " + string(msg["code"]), vec4(1,0.4,0.4,1), 4000);
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

        // Convert file (a-h) to column (0-7)
        col = -1;
        for (uint i = 0; i < FILES.Length; i++) {
            if (FILES[i] == file) {
                col = int(i);
                break;
            }
        }
        if (col < 0 || col > 7) return false;

        // Convert rank (1-8) to row (7-0)
        int rank = Text::ParseInt(rankStr);
        if (rank < 1 || rank > 8) return false;
        row = 8 - rank;

        return true;
    }
}
