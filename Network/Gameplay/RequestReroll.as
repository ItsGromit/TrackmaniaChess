void RequestReroll() {
    print("[Chess] RequestReroll called - gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
    if (gameId.Length == 0) {
        print("[Chess] Cannot request re-roll - gameId is empty");
        return;
    }
    print("[Chess] Sending reroll_request to server with gameId: " + gameId);
    Json::Value j = Json::Object();
    j["type"] = "reroll_request";
    j["gameId"] = gameId;
    SendJson(j);
}