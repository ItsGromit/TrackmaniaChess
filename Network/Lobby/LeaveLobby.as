void LeaveLobby() {
    if (currentLobbyId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"] = "leave_lobby";
    j["lobbyId"] = currentLobbyId;
    SendJson(j);
    currentLobbyId = "";
    currentLobbyPassword = "";
    isHost = false;
}