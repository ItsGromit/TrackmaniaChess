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
    // Network game logic
    if (GameManager::currentState == GameState::Playing && gameId != "") {
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

    // Local/practice game logic
    if (gSelR == -1) {
        Piece@ piece = board[row][col];
        if (piece is null || piece.type == PieceType::Empty) {
            return;
        }
        if (piece.color != currentTurn) {
            return;
        }

        gSelR = row; gSelC = col;
        selectedRow = row; selectedCol = col;
        return;
    } else {
        int fr = gSelR, fc = gSelC;
        gSelR = gSelC = -1;
        selectedRow = selectedCol = -1;

        if (IsValidMove(fr, fc, row, col)) {
            // Check if move would result in check
            Piece temp = board[row][col];
            board[row][col] = board[fr][fc];
            board[fr][fc] = Piece();

            bool wouldBeInCheck = IsInCheck(PieceColor(currentTurn));

            board[fr][fc] = board[row][col];
            board[row][col] = temp;

            if (wouldBeInCheck) {
                return; // Invalid move - would put own king in check
            }

            // Execute the player's move
            DummyClient::ExecutePlayerMove(fr, fc, row, col);
        }
        return;
    }
}
