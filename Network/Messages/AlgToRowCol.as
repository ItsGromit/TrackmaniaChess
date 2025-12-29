bool AlgToRowCol(const string &in alg, int &out row, int &out col) {
    if (alg.Length < 2) return false;
    string file = alg.SubStr(0, 1).ToLower();
    string rankStr = alg.SubStr(1, 1);
    col = -1;
    for (uint i = 0; i < FILES.Length; i++) {
        if (FILES[i] == file) {
            col = int(i);
            break;
        }
    }
    if (col < 0 || col > 7) return false;
    int rank = Text::ParseInt(rankStr);
    if (rank < 1 || rank > 8) return false;
    row = 8 - rank;
    return true;
}