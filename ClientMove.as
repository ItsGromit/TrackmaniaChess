// Client side visual move preview
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

// Pseudo move test (only shows movement rules, not every move shown is legal)
bool IsValidMove(int fr, int fc, int tr, int tc) {
    if (!InBounds(fr, fc) || !InBounds(tr, tc)) return false;
    if (fr == tr && fc == tc) return false;

    Piece p = board[fr][fc];
    if (p.IsEmpty()) return false;

    Piece target = board[tr][tc];
    if (!target.IsEmpty() && target.color == p.color) return false;

    int dr = tr - fr;
    int dc = tc - fc;

    switch (p.type) {
        case PieceType::Pawn: {
            int dir = (p.color == PieceColor::White) ? -1 : 1;          // assuming row 0 is top (rank 8)
            int startRow = (p.color == PieceColor::White) ? 6 : 1;      // white starts on 6, black on 1

            // forward 1
            if (dc == 0 && dr == dir && IsEmpty(tr, tc)) return true;

            // forward 2 from start (both empty)
            if (dc == 0 && dr == 2*dir && fr == startRow && IsEmpty(fr + dir, fc) && IsEmpty(tr, tc)) return true;

            // diagonal capture
            if (Math::Abs(dc) == 1 && dr == dir && !target.IsEmpty() && target.color != p.color) return true;

            return false;
        }

        case PieceType::Knight: {
            int adr = Math::Abs(dr), adc = Math::Abs(dc);
            return (adr == 2 && adc == 1) || (adr == 1 && adc == 2);
        }

        case PieceType::Bishop: {
            if (Math::Abs(dr) != Math::Abs(dc)) return false;
            return IsPathClear(fr, fc, tr, tc);
        }

        case PieceType::Rook: {
            if (dr != 0 && dc != 0) return false;
            return IsPathClear(fr, fc, tr, tc);
        }

        case PieceType::Queen: {
            if (dr == 0 || dc == 0 || Math::Abs(dr) == Math::Abs(dc)) {
                return IsPathClear(fr, fc, tr, tc);
            }
            return false;
        }

        case PieceType::King: {
            // 1-square king move; no castling locally
            return Math::Abs(dr) <= 1 && Math::Abs(dc) <= 1;
        }
    }
    return false;
}

// Simple check detector (client UI only)
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

// Move highlight helpers
class Int2 {
    int x, y;
    Int2() {}
    Int2(int _x, int _y) { x = _x; y = _y; }
}

void GetPseudoMoves(int fr, int fc, array<Int2>@ moves) {
    moves.Resize(0);
    if (!InBounds(fr, fc)) return;
    Piece p = board[fr][fc];
    if (p.IsEmpty()) return;

    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            if (IsValidMove(fr, fc, r, c)) moves.InsertLast(Int2(r, c));
        }
    }
}