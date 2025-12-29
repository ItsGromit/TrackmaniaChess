bool IsInCheck(PieceColor side) {
    int kr = -1, kc = -1;
    // locate king
    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            auto p = board[r][c];
            if (!p.IsEmpty() && p.type == PieceType::King && p.color == side) {
                kr = r; kc = c; break;
            }
        }
        if (kr != -1) break;
    }
    if (kr == -1) return false;

    // any opponent pseudo-attack to king square?
    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            auto p = board[r][c];
            if (p.IsEmpty() || p.color == side) continue;

            if (p.type == PieceType::Pawn) {
                int dir = (p.color == PieceColor::White) ? -1 : 1;
                if (r + dir == kr && (c + 1 == kc || c - 1 == kc)) return true;
                continue;
            }
            if (IsValidMove(r, c, kr, kc)) return true;
        }
    }
    return false;
}