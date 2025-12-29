namespace DummyClient {
    bool enabled = false;
    bool isMyTurn = false;
    int thinkingTimeMs = 1000; // Time to wait before making a move
    uint64 lastMoveTime = 0;
    int dummyColor = PieceColor::Black; // Which color the dummy plays

    // Simple AI: makes random valid moves
    void Update() {
        if (!enabled) return;
        if (!isMyTurn) return;
        if (gameOver) return;

        // Don't move during race challenges - wait until back to Playing state
        if (GameManager::currentState != GameState::Playing) return;

        // Wait a bit before making a move (simulates thinking)
        if (Time::Now < lastMoveTime + uint64(thinkingTimeMs)) return;

        // Find all valid moves for the current player
        array<array<int>> validMoves;

        for (int fromRow = 0; fromRow < 8; fromRow++) {
            for (int fromCol = 0; fromCol < 8; fromCol++) {
                Piece piece = board[fromRow][fromCol];

                // Skip empty squares or opponent pieces
                if (piece.type == PieceType::Empty) continue;
                if (piece.color != currentTurn) continue;

                // Find all valid destinations for this piece
                for (int toRow = 0; toRow < 8; toRow++) {
                    for (int toCol = 0; toCol < 8; toCol++) {
                        if (fromRow == toRow && fromCol == toCol) continue;

                        // Check if this is a valid move
                        if (IsValidMove(fromRow, fromCol, toRow, toCol)) {
                            // Test if this move would leave us in check
                            Piece temp = board[toRow][toCol];
                            board[toRow][toCol] = board[fromRow][fromCol];
                            board[fromRow][fromCol] = Piece();

                            bool wouldBeInCheck = IsInCheck(PieceColor(currentTurn));

                            board[fromRow][fromCol] = board[toRow][toCol];
                            board[toRow][toCol] = temp;

                            if (!wouldBeInCheck) {
                                array<int> move = {fromRow, fromCol, toRow, toCol};
                                validMoves.InsertLast(move);
                            }
                        }
                    }
                }
            }
        }

        // If we have valid moves, pick one randomly
        if (validMoves.Length > 0) {
            int randomIndex = Math::Rand(0, int(validMoves.Length));
            array<int> selectedMove = validMoves[randomIndex];

            int fromRow = selectedMove[0];
            int fromCol = selectedMove[1];
            int toRow = selectedMove[2];
            int toCol = selectedMove[3];

            // Execute the move locally
            ExecuteDummyMove(fromRow, fromCol, toRow, toCol);

            isMyTurn = false;
            lastMoveTime = Time::Now;
        }
    }

    void ExecutePlayerMove(int fromRow, int fromCol, int toRow, int toCol) {
        // Check if this is a capture move
        Piece targetPiece = board[toRow][toCol];
        bool isCapture = (targetPiece.type != PieceType::Empty);

        // If it's a capture, trigger a race challenge instead of executing immediately
        if (isCapture) {
            // Store the move details for after the race
            captureFrom = ToAlg(fromRow, fromCol);
            captureTo = ToAlg(toRow, toCol);

            // Player is the attacker, so they are NOT the defender
            isDefender = false;

            // Use square race mode map or fallback to random map
            if (currentRaceMode == RaceMode::SquareRace) {
                RaceMode::RaceExecution::pendingCaptureRow = toRow;
                RaceMode::RaceExecution::pendingCaptureCol = toCol;
                startnew(RaceMode::RaceExecution::FetchSquareRaceMapWrapper);
            } else {
                startnew(FetchPracticeModeRaceMap);
            }

            // The move will be completed after the race in ApplyRaceResult
            return;
        }

        // Non-capture move - execute immediately
        ExecuteMoveDirectly(fromRow, fromCol, toRow, toCol);

        // After player moves, it's dummy's turn
        isMyTurn = true;
        lastMoveTime = Time::Now;
    }

    void ExecuteDummyMove(int fromRow, int fromCol, int toRow, int toCol) {
        // Check if this is a capture move
        Piece targetPiece = board[toRow][toCol];
        bool isCapture = (targetPiece.type != PieceType::Empty);

        // If it's a capture, trigger a race challenge instead of executing immediately
        if (isCapture) {
            // Store the move details for after the race
            captureFrom = ToAlg(fromRow, fromCol);
            captureTo = ToAlg(toRow, toCol);

            // Dummy is the attacker, so the player IS the defender
            isDefender = true;

            // Use square race mode map or fallback to random map
            if (currentRaceMode == RaceMode::SquareRace) {
                RaceMode::RaceExecution::pendingCaptureRow = toRow;
                RaceMode::RaceExecution::pendingCaptureCol = toCol;
                startnew(RaceMode::RaceExecution::FetchSquareRaceMapWrapper);
            } else {
                startnew(FetchPracticeModeRaceMap);
            }

            // The move will be completed after the race in ApplyRaceResult
            return;
        }

        // Non-capture move - execute immediately
        ExecuteMoveDirectly(fromRow, fromCol, toRow, toCol);
    }

    void ExecuteMoveDirectly(int fromRow, int fromCol, int toRow, int toCol) {
        // Store the move in history
        Move@ m = Move(fromRow, fromCol, toRow, toCol);
        m.capturePiece = board[toRow][toCol];
        moveHistory.InsertLast(m);

        // Handle pawn promotion
        Piece piece = board[fromRow][fromCol];
        if (piece.type == PieceType::Pawn) {
            // White pawn reaches row 0, or black pawn reaches row 7
            if ((piece.color == PieceColor::White && toRow == 0) ||
                (piece.color == PieceColor::Black && toRow == 7)) {
                piece.type = PieceType::Queen; // Auto-promote to queen
            }
        }

        // Move the piece
        board[toRow][toCol] = piece;
        board[fromRow][fromCol] = Piece();

        // Handle castling
        if (piece.type == PieceType::King) {
            int colDiff = toCol - fromCol;
            if (Math::Abs(colDiff) == 2) {
                // Kingside castling
                if (colDiff == 2) {
                    board[fromRow][5] = board[fromRow][7];
                    board[fromRow][7] = Piece();
                }
                // Queenside castling
                else if (colDiff == -2) {
                    board[fromRow][3] = board[fromRow][0];
                    board[fromRow][0] = Piece();
                }
            }
        }

        // Handle en passant
        if (piece.type == PieceType::Pawn && fromCol != toCol && m.capturePiece.type == PieceType::Empty) {
            // This was an en passant capture
            if (piece.color == PieceColor::White) {
                board[toRow + 1][toCol] = Piece(); // Remove captured pawn
            } else {
                board[toRow - 1][toCol] = Piece(); // Remove captured pawn
            }
        }

        // Switch turns
        currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;

        // Check for game over conditions
        CheckGameOver();
    }

    void ApplyRaceResult(bool captureSucceeded) {
        // Parse the stored move
        int fromRow, fromCol, toRow, toCol;
        if (!AlgToRowCol(captureFrom, fromRow, fromCol)) {
            print("[DummyClient] ERROR: Failed to parse captureFrom: " + captureFrom);
            return;
        }
        if (!AlgToRowCol(captureTo, toRow, toCol)) {
            print("[DummyClient] ERROR: Failed to parse captureTo: " + captureTo);
            return;
        }

        print("[DummyClient] ApplyRaceResult - captureSucceeded: " + captureSucceeded + ", from: " + captureFrom + " to: " + captureTo);
        print("[DummyClient] Piece at fromRow=" + fromRow + " fromCol=" + fromCol + ": type=" + board[fromRow][fromCol].type);
        print("[DummyClient] Piece at toRow=" + toRow + " toCol=" + toCol + ": type=" + board[toRow][toCol].type);

        if (captureSucceeded) {
            // Attacker won - execute the capture
            // ExecuteMoveDirectly will switch turns automatically
            print("[DummyClient] Executing capture move");
            ExecuteMoveDirectly(fromRow, fromCol, toRow, toCol);
            print("[DummyClient] After ExecuteMoveDirectly - Piece at toRow=" + toRow + " toCol=" + toCol + ": type=" + board[toRow][toCol].type);
        } else {
            // Defender won - move is blocked, attacker's turn ends
            // Just switch turns (attacker's turn is over)
            print("[DummyClient] Defender won, switching turns without executing move");
            currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;
        }

        // Update isMyTurn based on current turn and dummy's color
        if (!gameOver) {
            isMyTurn = (currentTurn == dummyColor);
            if (isMyTurn) {
                lastMoveTime = Time::Now;
            }
        }
    }

    void CheckGameOver() {
        // Check if current player has any valid moves
        bool hasValidMove = false;

        for (int fromRow = 0; fromRow < 8 && !hasValidMove; fromRow++) {
            for (int fromCol = 0; fromCol < 8 && !hasValidMove; fromCol++) {
                Piece piece = board[fromRow][fromCol];
                if (piece.type == PieceType::Empty) continue;
                if (piece.color != currentTurn) continue;

                for (int toRow = 0; toRow < 8 && !hasValidMove; toRow++) {
                    for (int toCol = 0; toCol < 8 && !hasValidMove; toCol++) {
                        if (fromRow == toRow && fromCol == toCol) continue;

                        if (IsValidMove(fromRow, fromCol, toRow, toCol)) {
                            Piece temp = board[toRow][toCol];
                            board[toRow][toCol] = board[fromRow][fromCol];
                            board[fromRow][fromCol] = Piece();

                            bool wouldBeInCheck = IsInCheck(PieceColor(currentTurn));

                            board[fromRow][fromCol] = board[toRow][toCol];
                            board[toRow][toCol] = temp;

                            if (!wouldBeInCheck) {
                                hasValidMove = true;
                            }
                        }
                    }
                }
            }
        }

        if (!hasValidMove) {
            gameOver = true;
            if (IsInCheck(PieceColor(currentTurn))) {
                // Checkmate
                string winner = (currentTurn == PieceColor::White) ? "Black" : "White";
                gameResult = winner + " wins by checkmate!";
            } else {
                // Stalemate
                gameResult = "Draw by stalemate!";
            }
        }
    }

    void StartGame(bool dummyPlaysWhite) {
        enabled = true;
        dummyColor = dummyPlaysWhite ? PieceColor::White : PieceColor::Black;
        isMyTurn = dummyPlaysWhite;
        lastMoveTime = Time::Now;
        gameOver = false;
        gameResult = "";
    }

    void StopGame() {
        enabled = false;
        isMyTurn = false;
    }

    void Reset() {
        enabled = false;
        isMyTurn = false;
        gameOver = false;
        gameResult = "";
    }
}
