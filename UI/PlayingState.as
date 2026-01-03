// ============================================================================
// UI PLAYING STATE
// ============================================================================
// Handles rendering of Playing and GameOver states
// ============================================================================

/**
 * Renders the Playing or GameOver state UI
 */
void RenderPlayingState() {
    float lockButtonWidth = 30.0f;
    float barHeight = 30.0f;
    vec2 contentAvail = UI::GetContentRegionAvail();
    vec2 lockCursor = UI::GetCursorPos();

    // Lock button at right
    RenderLockButton("playing", barHeight);

    // Reset cursor and add dummy invisible item to maintain bar height
    UI::SetCursorPos(lockCursor);
    UI::Dummy(vec2(0, barHeight));

    UI::NewLine();

    if (!gameOver) {
        // Game info
        string turnText = (currentTurn == PieceColor::White) ? "\\$fffWhite" : "\\$666Black";
        UI::Text("Turn: " + turnText);
        UI::SameLine();

        if (!GameManager::isLocalPlayerTurn()) {
            UI::SameLine();
            UI::Text("\\$ff0Waiting for opponent's move...");
        } else {
            UI::SameLine();
            UI::Text("");
        }
        if (IsInCheck(PieceColor(currentTurn))) {
            UI::SameLine();
            UI::Text("\\$f00CHECK!");
        }
    } else {
        UI::Text("\\$ff0Game over!" + gameResult);
    }

    vec2 contentRegion = UI::GetContentRegionAvail();

    float moveHistoryWidth = 150.0f;
    float belowBoardUIHeight = 30.0f;
    float availableHeight = contentRegion.y - belowBoardUIHeight;

    UI::BeginGroup();
    RenderMoveHistory(moveHistoryWidth, availableHeight, belowBoardUIHeight);
    UI::EndGroup();

    UI::SameLine();

    BoardRender();

    // Render promotion dialog if pending
    if (isPendingPromotion) {
        PieceType selectedPiece = RenderPromotionDialog();
        if (selectedPiece != PieceType::Empty) {
            // Store move in history
            Move@ m = Move(gSelR, gSelC, promotionRow, promotionCol);
            m.capturePiece = board[promotionRow][promotionCol];
            moveHistory.InsertLast(m);

            // Execute the promotion move
            ExecuteChessMove(gSelR, gSelC, promotionRow, promotionCol, selectedPiece);
            currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;

            // Clear promotion state
            isPendingPromotion = false;
            promotionRow = -1;
            promotionCol = -1;
            gSelR = -1;
            gSelC = -1;
            selectedRow = -1;
            selectedCol = -1;
        }
    }
}

/**
 * Renders the move history panel and action buttons
 */
void RenderMoveHistory(float moveHistoryWidth, float availableHeight, float belowBoardUIHeight) {
    UI::BeginChild("MoveHistory", vec2(moveHistoryWidth, availableHeight - 40.0f), true);
    UI::Text("Move History:");

    // Display moves in proper chess notation: "1. e4 e5  2. Nf3 Nc6"
    for (uint i = 0; i < moveHistory.Length; i += 2) {
        Move@ whiteMove = moveHistory[i];
        string moveText = "" + ((i / 2) + 1) + ". ";

        // Add white's move
        if (whiteMove.san != "") {
            moveText += whiteMove.san;
        } else {
            // Fallback to algebraic notation if SAN not available
            moveText += GetColumnName(whiteMove.fromCol) + (8 - whiteMove.fromRow) +
                       GetColumnName(whiteMove.toCol) + (8 - whiteMove.toRow);
        }

        // Add black's move if it exists
        if (i + 1 < moveHistory.Length) {
            Move@ blackMove = moveHistory[i + 1];
            moveText += " ";

            if (blackMove.san != "") {
                moveText += blackMove.san;
            } else {
                // Fallback to algebraic notation if SAN not available
                moveText += GetColumnName(blackMove.fromCol) + (8 - blackMove.fromRow) +
                           GetColumnName(blackMove.toCol) + (8 - blackMove.toRow);
            }
        }

        UI::Text(moveText);
    }
    UI::EndChild();

    // Forfeit button below move history, aligned with it
    if (GameManager::currentState == GameState::Playing && !gameOver) {
        vec2 buttonCursor = UI::GetCursorPos();
        UI::SetCursorPos(vec2(buttonCursor.x, buttonCursor.y + 30.0f));

        // Network game - show forfeit button
        if (StyledButton("Forfeit", vec2(moveHistoryWidth, belowBoardUIHeight))) {
            Resign();
        }
    }
    if (GameManager::currentState == GameState::GameOver) {
        vec2 buttonCursor = UI::GetCursorPos();
        UI::SetCursorPos(vec2(buttonCursor.x, buttonCursor.y - 5.0f));

        // Network game - show rematch UI based on rematch state
        if (rematchRequestReceived) {
            // Opponent requested rematch - show accept/decline buttons
            UI::Text(themeSuccessTextColor + "Opponent wants a rematch!");
            if (StyledButton("Accept Rematch", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                RespondToRematch(true);
            }
            if (StyledButton("Decline", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                RespondToRematch(false);
            }
        } else if (rematchRequestSent) {
            // Waiting for opponent to respond
            UI::Text(themeWarningTextColor + "Waiting for opponent...");
            if (StyledButton("Cancel Request", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                rematchRequestSent = false;
                UI::ShowNotification("Chess", "Rematch request cancelled", vec4(0.8,0.8,0.2,1), 3000);
            }
        } else {
            // Normal state - show rematch button
            if (StyledButton("Request Rematch", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                RequestNewGame();
            }
        }

        if (StyledButton("Back to menu", vec2(moveHistoryWidth, belowBoardUIHeight))) {
            LeaveLobby();
            GameManager::currentState = GameState::Menu;
            rematchRequestReceived = false;
            rematchRequestSent = false;
        }
    }
}
