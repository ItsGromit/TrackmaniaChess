namespace Network {
    Net::Socket@ sock;
    // Default host/port for plain TCP (Trackmania's Net::Socket uses plain TCP).
    // For local testing run the server locally and keep the defaults (127.0.0.1:29802).
    // NOTE: Railway may or may not expose raw TCP ports depending on plan/configuration.
    // If Railway exposes TCP for your project, you can point the plugin at that host:port.
    // Otherwise run the server on a host that exposes raw TCP (VPS, cloud VM) and change
    // these values accordingly.
    // Default to the Railway deployment host and port used in your deployment logs.
    // Change these values if you host elsewhere or for local testing (127.0.0.1).
    string serverHost = "trackmaniachess.up.railway.app"; // Railway host (change if different)
    int serverPort = 8080; // Railway injected PORT (logs showed 8080)
    bool isConnected = false;
    string playerId;
    string opponentId;
    string gameId;
    bool isWhite;

    bool debug = true;  // Set to true for connection debugging
    
    // Lobby client state
    class Lobby {
        string id;
        string hostId;
        int players;
        bool open;
        bool hasPassword;
        array<string> playerNames;
        string password;  // only set for current lobby

        Lobby() {
            playerNames.Resize(0);
            hasPassword = false;
            password = "";
        }
    }

    array<Lobby@> lobbies;
    string currentLobbyId = "";
    bool isHost = false;

    void Init() {
        @sock = Net::Socket();
        if (debug) print("Network: Initialized socket");
    }

    // Allow runtime override of host/port from the UI
    void SetServerHost(const string &in host) {
        if (host.Length > 0) serverHost = host;
    }

    void SetServerPortString(const string &in portStr) {
        if (portStr.Length == 0) return;
        int p = 0;
        for (uint i = 0; i < portStr.Length; i++) {
            uint c = uint(portStr[i]);
            if (c >= 48 && c <= 57) {
                p = p * 10 + int(c - 48);
            } else {
                // stop at first non-digit
                break;
            }
        }
        if (p > 0) serverPort = p;
    }

    bool Connect() {
        if (sock is null) Init();
        
    if (debug) print("Network: Attempting to connect to " + serverHost + ":" + ("" + serverPort));

        bool ok = sock.Connect(serverHost, serverPort);
        if (!ok) {
            warn("Failed to connect to chess server at " + serverHost + ":" + ("" + serverPort));
            return false;
        }

    if (debug) print("Network: Connected successfully to " + serverHost + ":" + ("" + serverPort));
        isConnected = true;
        // create a simple random player id
        playerId = "p_" + ("" + Math::Rand(0, 1000000));
        return true;
    }

    void Disconnect() {
        if (sock !is null) {
            sock.Close();
            @sock = null;
        }
        isConnected = false;
        if (debug) print("Network: Disconnected");
    }

    void SendMove(Move@ move) {
        if (!isConnected) return;

        Json::Value moveData = Json::Object();
        moveData["type"] = "move";
        moveData["gameId"] = gameId;
        moveData["playerId"] = playerId;
        moveData["fromRow"] = move.fromRow;
        moveData["fromCol"] = move.fromCol;
        moveData["toRow"] = move.toRow;
        moveData["toCol"] = move.toCol;

        string jsonStr = Json::Write(moveData);
        if (debug) print("Network: Sending move: " + jsonStr);
        sock.WriteRaw(jsonStr + "\n");
    }

    void Update() {
        if (!isConnected || sock is null) return;
        string line;
        // Net::Socket::ReadLine expects a string&out and returns bool
        while (sock.ReadLine(line)) {
            if (line.Length == 0) continue;
            if (debug) print("Network: Received: " + line);
            try {
                Json::Value data = Json::Parse(line);
                string msgType = data["type"];

                if (msgType == "game_start") {
                    gameId = data["gameId"];
                    isWhite = data["isWhite"];
                    opponentId = data["opponentId"];
                    if (debug) print("Network: Game started, playing as: " + (isWhite ? "White" : "Black"));
                    GameManager::OnGameStart(data);
                }
                else if (msgType == "lobby_list") {
                    // replace lobby list
                    lobbies.Resize(0);
                    for (uint i = 0; i < data["lobbies"].Length; i++) {
                        Json::Value entry = data["lobbies"][i];
                        Lobby l = Lobby();
                        l.id = entry["id"];
                        l.hostId = entry["hostId"];
                        l.players = int(entry["players"]);
                        l.open = bool(entry["open"]);
                        l.hasPassword = bool(entry["hasPassword"]);
                        
                        if (entry["playerNames"].GetType() != Json::Type::Null) {
                            for (uint j = 0; j < entry["playerNames"].Length; j++) {
                                l.playerNames.InsertLast(string(entry["playerNames"][j]));
                            }
                        }
                        lobbies.InsertLast(l);
                    }
                }
                else if (msgType == "lobby_update") {
                    string id = data["lobbyId"];
                    // update local current lobby info
                    if (currentLobbyId == id) {
                        string host = data["hostId"];
                        isHost = (host == playerId);
                        // Update lobby in our list with new player names and password
                        for (uint i = 0; i < lobbies.Length; i++) {
                            if (lobbies[i].id == id) {
                                lobbies[i].playerNames.Resize(0);
                                Json::Value names = data["playerNames"];
                                for (uint j = 0; j < names.Length; j++) {
                                    lobbies[i].playerNames.InsertLast(string(names[j]));
                                }
                                lobbies[i].hasPassword = data["hasPassword"];
                                if (data["password"].GetType() != Json::Type::Null) {
                                    lobbies[i].password = string(data["password"]);
                                }
                                break;
                            }
                        }
                    }
                }
                else if (msgType == "lobby_created") {
                    currentLobbyId = data["lobbyId"];
                    isHost = true;
                    if (debug) print("Network: Created and joined lobby: " + currentLobbyId);
                    
                    // Request fresh lobby list to see our new lobby
                    ListLobbies();
                }
                else if (msgType == "lobby_error") {
                    if (debug) print("Network: Lobby error: " + Json::Write(data["message"]));
                }
                else if (msgType == "move") {
                    Move move(
                        int(data["fromRow"]),
                        int(data["fromCol"]),
                        int(data["toRow"]),
                        int(data["toCol"])
                    );
                    if (debug) print("Network: Received move from opponent");
                    GameManager::OnOpponentMove(move);
                }
                else if (msgType == "game_over") {
                    string reason = Json::Write(data["reason"]);
                    if (debug) print("Network: Game over - " + reason);
                    GameManager::OnGameOver(data["winner"]);
                }
            } catch {
                warn("Failed to parse message: " + line);
            }
        }
    }

    void JoinQueue() {
        if (!isConnected) return;

        Json::Value data = Json::Object();
        data["type"] = "join_queue";
        data["playerId"] = playerId;

        string jsonStr = Json::Write(data);
        if (debug) print("Network: Joining queue");
        sock.WriteRaw(jsonStr + "\n");
    }

    void LeaveQueue() {
        if (!isConnected) return;

        Json::Value data = Json::Object();
        data["type"] = "leave_queue";
        data["playerId"] = playerId;

        string jsonStr = Json::Write(data);
        if (debug) print("Network: Leaving queue");
        sock.WriteRaw(jsonStr + "\n");
    }

    // Lobby client API
    void CreateLobby(const string &in roomCode = "", const string &in password = "") {
        if (!isConnected) return;
        Json::Value data = Json::Object();
        data["type"] = "create_lobby";
        data["playerId"] = playerId;
        data["playerName"] = playerId;  // can be customized later
        
        // If no room code provided, generate a 5 digit number
        string code = roomCode;
        if (code == "") {
            code = "" + (Math::Rand(10000, 99999));
        }
        data["roomCode"] = code;
        
        if (password != "") {
            data["password"] = password;
        }
        
        if (debug) print("Network: Creating lobby with code: " + code);
        sock.WriteRaw(Json::Write(data) + "\n");
    }

    void ListLobbies() {
        if (!isConnected) return;
        Json::Value data = Json::Object();
        data["type"] = "list_lobbies";
        sock.WriteRaw(Json::Write(data) + "\n");
    }

    void JoinLobby(const string &in lobbyId, const string &in password = "") {
        if (!isConnected) return;
        Json::Value data = Json::Object();
        data["type"] = "join_lobby";
        data["playerId"] = playerId;
        data["playerName"] = playerId;  // can be customized later
        data["lobbyId"] = lobbyId;
        if (password != "") data["password"] = password;
        sock.WriteRaw(Json::Write(data) + "\n");
        currentLobbyId = lobbyId;
    }

    void LeaveLobby() {
        if (!isConnected || currentLobbyId == "") return;
        Json::Value data = Json::Object();
        data["type"] = "leave_lobby";
        data["playerId"] = playerId;
        data["lobbyId"] = currentLobbyId;
        sock.WriteRaw(Json::Write(data) + "\n");
        currentLobbyId = "";
        isHost = false;
    }

    void StartGame() {
        if (!isConnected || currentLobbyId == "") return;
        Json::Value data = Json::Object();
        data["type"] = "start_game";
        data["lobbyId"] = currentLobbyId;
        sock.WriteRaw(Json::Write(data) + "\n");
    }
}