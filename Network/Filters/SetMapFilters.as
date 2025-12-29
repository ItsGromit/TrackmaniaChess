void SetMapFilters(const string &in lobbyId, Json::Value &in filters) {
    if (lobbyId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "set_map_filters";
    j["lobbyId"] = lobbyId;
    j["filters"] = filters;
    print("[Chess] Setting map filters for lobby: " + lobbyId);
    SendJson(j);
}