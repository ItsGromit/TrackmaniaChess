void ListLobbies() {
    Json::Value j = Json::Object();
    j["type"] = "list_lobbies";
    SendJson(j);
}