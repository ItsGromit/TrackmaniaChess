void RetireFromRace() {
    if (gameId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "race_retire";
    j["gameId"] = gameId;
    print("[Chess] Retiring from race - forfeiting piece");
    SendJson(j);
}