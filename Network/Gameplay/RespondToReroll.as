void RespondToReroll(bool accept) {
    print("[Chess] RespondToReroll called - accept: " + accept + ", gameId: " + (gameId.Length > 0 ? gameId : "EMPTY"));
    if (gameId.Length == 0) {
        print("[Chess] Cannot respond to re-roll - gameId is empty");
        return;
    }
    Json::Value j = Json::Object();
    j["type"] = "reroll_response";
    j["gameId"] = gameId;
    j["accept"] = accept;
    SendJson(j);
    rerollRequestReceived = false;
    print("[Chess] Sent re-roll response: " + (accept ? "accepted" : "declined"));
}