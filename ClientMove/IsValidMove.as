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

            // en passant capture
            if (Math::Abs(dc) == 1 && dr == dir && IsEmpty(tr, tc)) {
                // Check if target square matches en passant target
                if (enPassantRow == tr && enPassantCol == tc) {
                    return true;
                }
            }

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
            // Normal 1-square king move
            if (Math::Abs(dr) <= 1 && Math::Abs(dc) <= 1) return true;

            // Castling logic
            if (dr == 0 && Math::Abs(dc) == 2) {
                // White castling from e1 (row 7, col 4)
                if (p.color == PieceColor::White && fr == 7 && fc == 4) {
                    // Kingside castling (to g1)
                    if (tc == 6 && whiteCanCastleKingside) {
                        // Check if squares f1 and g1 are empty
                        if (IsEmpty(7, 5) && IsEmpty(7, 6)) {
                            // Check if king is not in check and doesn't move through check
                            if (!IsSquareAttacked(7, 4, PieceColor::Black) &&
                                !IsSquareAttacked(7, 5, PieceColor::Black) &&
                                !IsSquareAttacked(7, 6, PieceColor::Black)) {
                                return true;
                            }
                        }
                    }
                    // Queenside castling (to c1)
                    if (tc == 2 && whiteCanCastleQueenside) {
                        // Check if squares b1, c1, d1 are empty
                        if (IsEmpty(7, 1) && IsEmpty(7, 2) && IsEmpty(7, 3)) {
                            // Check if king is not in check and doesn't move through check
                            if (!IsSquareAttacked(7, 4, PieceColor::Black) &&
                                !IsSquareAttacked(7, 3, PieceColor::Black) &&
                                !IsSquareAttacked(7, 2, PieceColor::Black)) {
                                return true;
                            }
                        }
                    }
                }
                // Black castling from e8 (row 0, col 4)
                if (p.color == PieceColor::Black && fr == 0 && fc == 4) {
                    // Kingside castling (to g8)
                    if (tc == 6 && blackCanCastleKingside) {
                        // Check if squares f8 and g8 are empty
                        if (IsEmpty(0, 5) && IsEmpty(0, 6)) {
                            // Check if king is not in check and doesn't move through check
                            if (!IsSquareAttacked(0, 4, PieceColor::White) &&
                                !IsSquareAttacked(0, 5, PieceColor::White) &&
                                !IsSquareAttacked(0, 6, PieceColor::White)) {
                                return true;
                            }
                        }
                    }
                    // Queenside castling (to c8)
                    if (tc == 2 && blackCanCastleQueenside) {
                        // Check if squares b8, c8, d8 are empty
                        if (IsEmpty(0, 1) && IsEmpty(0, 2) && IsEmpty(0, 3)) {
                            // Check if king is not in check and doesn't move through check
                            if (!IsSquareAttacked(0, 4, PieceColor::White) &&
                                !IsSquareAttacked(0, 3, PieceColor::White) &&
                                !IsSquareAttacked(0, 2, PieceColor::White)) {
                                return true;
                            }
                        }
                    }
                }
            }

            return false;
        }
    }
    return false;
}