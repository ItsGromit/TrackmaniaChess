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
}

/**
 * Renders the move history panel and action buttons
 */
void RenderMoveHistory(float moveHistoryWidth, float availableHeight, float belowBoardUIHeight) {
    UI::BeginChild("MoveHistory", vec2(moveHistoryWidth, availableHeight - 40.0f), true);
    UI::Text("Move History:");
    for (uint i = 0; i < moveHistory.Length; i++) {
        Move@ m = moveHistory[i];
        string moveText = "" + (i + 1) + ". " +
                        GetColumnName(m.fromCol) + (8 - m.fromRow) + " -> " +
                        GetColumnName(m.toCol) + (8 - m.toRow);
        UI::Text(moveText);
    }
    UI::EndChild();

    // Forfeit/Back to Menu button below move history, aligned with it
    if (GameManager::currentState == GameState::Playing && !gameOver) {
        vec2 buttonCursor = UI::GetCursorPos();
        UI::SetCursorPos(vec2(buttonCursor.x, buttonCursor.y + 30.0f));

        if (DummyClient::enabled) {
            // Dummy client mode - show back to menu button
            if (StyledButton("Back to Menu", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                DummyClient::StopGame();
                GameManager::currentState = GameState::Menu;
            }
        } else {
            // Network game - show forfeit button
            if (StyledButton("Forfeit", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                Resign();
            }
        }
    }
    if (GameManager::currentState == GameState::GameOver) {
        vec2 buttonCursor = UI::GetCursorPos();
        UI::SetCursorPos(vec2(buttonCursor.x, buttonCursor.y - 5.0f));

        // Check if playing against dummy client
        if (DummyClient::enabled) {
            // Dummy client mode - show simple play again button
            if (StyledButton("Play Again", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                bool dummyPlaysWhite = DummyClient::isMyTurn; // If it's dummy's turn now, dummy was white
                InitializeGlobals();
                ApplyFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", "w");
                GameManager::currentState = GameState::Playing;
                DummyClient::StartGame(dummyPlaysWhite);
            }

            if (StyledButton("Back to Menu", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                DummyClient::StopGame();
                GameManager::currentState = GameState::Menu;
            }
        } else {
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
}
