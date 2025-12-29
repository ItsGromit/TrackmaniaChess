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