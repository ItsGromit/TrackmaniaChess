void SendMove(const string &in fromAlg, const string &in toAlg, const string &in promo="q") {
    if (gameId.Length == 0) return;
    Json::Value j = Json::Object();
    j["type"]  = "move";
    j["gameId"]= gameId;
    j["from"]  = fromAlg;
    j["to"]    = toAlg;
    if (promo.Length > 0) j["promo"] = promo;
    SendJson(j);
}