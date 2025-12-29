void RespondToRematch(bool accept) {
    print("[Chess] RespondToRematch called - accept: " + accept + ", gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
    if (gameId.Length == 0) {
        print("[Chess] Cannot respond to rematch - gameId is empty");
        return;
    }
    Json::Value j = Json::Object();
    j["type"] = "rematch_response";
    j["gameId"] = gameId;
    j["accept"] = accept;
    SendJson(j);
    rematchRequestReceived = false;
    print("[Chess] Sent rematch response: " + (accept ? "accepted" : "declined"));
}