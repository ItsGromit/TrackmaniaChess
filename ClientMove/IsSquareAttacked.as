/**
 * Checks if a square is attacked by any piece of the specified color
 * @param row The row to check
 * @param col The column to check
 * @param attackerColor The color of the attacking pieces
 * @return true if the square is under attack
 */
bool IsSquareAttacked(int row, int col, int attackerColor) {
    // Check all squares on the board for pieces of attackerColor
    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            Piece p = board[r][c];
            if (p.IsEmpty() || p.color != attackerColor) continue;

            // Check if this piece can attack the target square
            // We need to use simplified attack logic (not full move validation)
            int dr = row - r;
            int dc = col - c;

            switch (p.type) {
                case PieceType::Pawn: {
                    int dir = (p.color == PieceColor::White) ? -1 : 1;
                    // Pawns attack diagonally
                    if (dr == dir && Math::Abs(dc) == 1) {
                        return true;
                    }
                    break;
                }

                case PieceType::Knight: {
                    int adr = Math::Abs(dr), adc = Math::Abs(dc);
                    if ((adr == 2 && adc == 1) || (adr == 1 && adc == 2)) {
                        return true;
                    }
                    break;
                }

                case PieceType::Bishop: {
                    if (Math::Abs(dr) == Math::Abs(dc) && IsPathClear(r, c, row, col)) {
                        return true;
                    }
                    break;
                }

                case PieceType::Rook: {
                    if ((dr == 0 || dc == 0) && IsPathClear(r, c, row, col)) {
                        return true;
                    }
                    break;
                }

                case PieceType::Queen: {
                    if ((dr == 0 || dc == 0 || Math::Abs(dr) == Math::Abs(dc)) && IsPathClear(r, c, row, col)) {
                        return true;
                    }
                    break;
                }

                case PieceType::King: {
                    if (Math::Abs(dr) <= 1 && Math::Abs(dc) <= 1) {
                        return true;
                    }
                    break;
                }
            }
        }
    }
    return false;
}
