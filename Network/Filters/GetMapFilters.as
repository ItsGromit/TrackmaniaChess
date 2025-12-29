void GetMapFilters(const string &in lobbyId) {
    if (lobbyId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "get_map_filters";
    j["lobbyId"] = lobbyId;
    SendJson(j);
}