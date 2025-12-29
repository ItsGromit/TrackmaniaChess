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