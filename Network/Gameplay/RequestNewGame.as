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