void StartGame(const string &in lobbyId="") {
    string id = lobbyId.Length > 0 ? lobbyId : currentLobbyId;
    if (id.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "start_game";
    j["lobbyId"] = id;
    SendJson(j);
}