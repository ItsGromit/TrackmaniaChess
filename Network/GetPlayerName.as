string GetLocalPlayerName() {
    auto app = GetApp();
    if (app is null) return "Player";
    auto playerInfo = app.LocalPlayerInfo;
    if (playerInfo is null) return "Player";
    return playerInfo.Name;
}