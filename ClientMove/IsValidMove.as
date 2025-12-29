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