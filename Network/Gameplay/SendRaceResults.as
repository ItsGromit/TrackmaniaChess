void SendRaceResult(int timeMs) {
    if (gameId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "race_result";
    j["gameId"] = gameId;
    j["time"] = timeMs;

    // Format time nicely for display
    int minutes = timeMs / 60000;
    int seconds = (timeMs % 60000) / 1000;
    int millis = timeMs % 1000;
    string timeStr = "";
    if (minutes > 0) {
        timeStr = minutes + ":" + Text::Format("%02d", seconds) + "." + Text::Format("%03d", millis);
    } else {
        timeStr = seconds + "." + Text::Format("%03d", millis) + "s";
    }

    print("[Chess] Race completed - Time: " + timeStr + " (" + timeMs + "ms)");
    SendJson(j);
}