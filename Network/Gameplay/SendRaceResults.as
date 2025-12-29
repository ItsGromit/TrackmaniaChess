void SendRaceResult(int timeMs) {
    if (gameId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "race_result";
    j["gameId"] = gameId;
    j["time"] = timeMs;
    print("[Chess] Sending race result: " + timeMs + "ms");
    SendJson(j);
}