bool InBounds(int r, int c) {
    return r >= 0 && r < 8 && c >= 0 && c < 8;
}
bool SameColor(const Piece &in a, const Piece &in b) {
    if (a.IsEmpty() || b.IsEmpty()) return false;
    return a.color == b.color;
}
bool IsEmpty(int r, int c) {
    if (!InBounds(r, c)) return false;
    return board[r][c].IsEmpty();
}
bool IsEnemy(int r, int c, PieceColor me) {
    if (!InBounds(r, c)) return false;
    if (board[r][c].IsEmpty()) return false;
    return board[r][c].color != me;
}
bool IsPathClear(int r0, int c0, int r1, int c1) {
    int dr = (r1 == r0) ? 0 : (r1 > r0 ? 1 : -1);
    int dc = (c1 == c0) ? 0 : (c1 > c0 ? 1 : -1);
    int r = r0 + dr;
    int c = c0 + dc;
    while (r != r1 || c != c1) {
        if (!IsEmpty(r, c)) return false;
        r += dr;
        c += dc;
    }
    return true;
}