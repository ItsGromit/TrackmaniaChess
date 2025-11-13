namespace Network {
    Net::Socket@ sock;
    bool isConnected = false;

    [Setting category="Network" name="Server host"] string serverHost = "shortline.proxy.rlwy.net";
    [Setting category="Network" name="Server port"] uint   serverPort = 37920;

    string playerId;
    string currentLobbyId;
    string gameId;
    bool   isWhite = false;
    bool   isHost  = false;

    // file letters (avoid chr())
    const array<string> FILES = {"a","b","c","d","e","f","g","h"};

    // Helper function to get local player's display name
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
        // Some UI code references l.password; keep it so it compiles.
        // We don't know the actual password, so just show "*" when hasPassword=true.
        string password;
        array<string> playerNames;
    }
    array<Lobby> lobbies;

    string _buf;

    void Init() {
        @sock = Net::Socket();
        // Note: Net::Socket has no SetBlocking() on Openplanet. Non-blocking read is achieved
        // by calling ReadRaw(n) with a small n each frame. We'll mark connected after Connect().
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

        // Read small chunks each frame; returns "" if nothing available.
        string chunk = sock.ReadRaw(32768);
        if (chunk.Length == 0) return;

        _buf += chunk;
        int nl;
        while ((nl = _buf.IndexOf("\n")) >= 0) {
            string line = _buf.SubStr(0, nl).Trim();
            _buf = _buf.SubStr(nl + 1);
            if (line.Length == 0) continue;

            Json::Value msg;
            bool ok = true;
            try { msg = Json::Parse(line); } catch { ok = false; }
            if (ok) HandleMsg(msg);
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
        // Use provided name or get local player name
        string name = playerName.Length > 0 ? playerName : GetLocalPlayerName();
        j["playerName"] = name;
        SendJson(j);
    }

    void JoinLobby(const string &in lobbyId, const string &in password = "", const string &in playerName = "") {
        if (lobbyId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "join_lobby";
        j["lobbyId"] = lobbyId;
        if (password.Length > 0) j["password"] = password;
        // Use provided name or get local player name
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
        if (gameId.Length == 0) return;
        Json::Value j = Json::Object();
        j["type"] = "resign";
        j["gameId"] = gameId;
        SendJson(j);
    }

    // ---------- Messages ----------
    void HandleMsg(Json::Value &msg) {
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
            ApplyFEN(fen, turn);
            GameManager::currentState = GameState::Playing;
        }
        else if (t == "moved") {
            string fen  = string(msg["fen"]);
            string turn = string(msg["turn"]);
            ApplyFEN(fen, turn);
        }
        else if (t == "game_over") {
            string reason = string(msg["reason"]);
            string winner = msg.HasKey("winner") ? string(msg["winner"]) : "none";
            GameManager::currentState = GameState::GameOver;
            gameOver = true;
            gameResult = (winner.Length > 0 ? winner : "none") + " — " + reason;
            gameId = "";
        }
        else if (t == "error") {
            UI::ShowNotification("Chess", "Error: " + string(msg["code"]), vec4(1,0.4,0.4,1), 4000);
        }
    }

    // row/col -> "a1" (avoid chr())
    string ToAlg(int row, int col) {
        string file = (col >= 0 && col < 8) ? FILES[col] : "?";
        int rank = 8 - row;
        return file + rank;
    }
}
