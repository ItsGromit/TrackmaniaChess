// ============================================================================
// UI BOARD INTERACTION
// ============================================================================
// Handles user interaction with the chess board (clicking squares)
// ============================================================================

/**
 * Handles when a user clicks on a chess board square
 * @param row The row index (0-7)
 * @param col The column index (0-7)
 */
void HandleSquareClick(int row, int col) {
    // Only handle network game logic (practice mode removed)
    if (GameManager::currentState != GameState::Playing || gameId == "") {
        return;
    }

    if (!GameManager::isLocalPlayerTurn()) {
        return;
    }

    if (gSelR == -1) {
        Piece@ piece = board[row][col];
        if (piece is null || piece.type == PieceType::Empty) {
            return;
        }

        bool isPieceWhite = (piece.color == PieceColor::White);
        if (isPieceWhite != isWhite) {
            return;
        }

        gSelR = row; gSelC = col;
        selectedRow = row; selectedCol = col;
        return;
    } else {
        // Check if clicking on another piece of the same color - reselect it
        Piece@ clickedPiece = board[row][col];
        if (clickedPiece !is null && clickedPiece.type != PieceType::Empty) {
            bool isClickedPieceWhite = (clickedPiece.color == PieceColor::White);
            if (isClickedPieceWhite == isWhite) {
                // Reselect the new piece
                gSelR = row; gSelC = col;
                selectedRow = row; selectedCol = col;
                return;
            }
        }

        if (!IsValidMove(gSelR, gSelC, row, col)) {
            gSelR = gSelC = -1;
            selectedRow = selectedCol = -1;
            return;
        }

        Piece temp = board[row][col];
        board[row][col] = board[gSelR][gSelC];
        board[gSelR][gSelC] = Piece();

        bool wouldBeInCheck = IsInCheck(PieceColor(currentTurn));

        board[gSelR][gSelC] = board[row][col];
        board[row][col] = temp;

        if (wouldBeInCheck) {
            gSelR = gSelC = -1;
            selectedRow = selectedCol = -1;
            return;
        }
        string fromAlg = ToAlg(gSelR, gSelC);
        string toAlg   = ToAlg(row, col);
        SendMove(fromAlg, toAlg);
        gSelR = gSelC = -1;
        selectedRow = selectedCol = -1;
        return;
    }
}
