// ====================
// Connection Functions
// ====================
void Init() {
    @sock = Net::Socket();
}
// Connect function
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