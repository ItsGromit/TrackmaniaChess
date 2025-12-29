// ============================================================================
// UI BOARD RENDERER
// ============================================================================
// Handles rendering of the chess board
// ============================================================================

/**
 * Renders the chess board with pieces
 */
void BoardRender() {
    UI::BeginGroup();

    // Calculate sizes based on the context from MainMenu
    float labelSize = 20.0f;
    vec2 contentRegion = UI::GetContentRegionAvail();
    float moveHistoryWidth = 150.0f;
    float spacing = 10.0f;
    float belowBoardUIHeight = 30.0f;
    float availableHeight = contentRegion.y - belowBoardUIHeight;
    // contentRegion.x is already the space AFTER Move History panel due to UI::SameLine()
    float boardPadding = 10.0f; // Small padding on sides
    float availableWidth = contentRegion.x - labelSize - boardPadding * 2;
    float minBoardSize = 320.0f; // Minimum 40px per square
    float maxBoardSize = Math::Min(availableWidth, availableHeight);
    maxBoardSize = Math::Max(maxBoardSize, minBoardSize);
    if (maxBoardSize > availableHeight) {
        maxBoardSize = availableHeight;
        maxBoardSize = Math::Max(maxBoardSize, minBoardSize); // Enforce minimum even after height constraint
    }
    float squareSize = maxBoardSize / 8.0f;
    bool flipBoard = (gameId != "" && !isWhite);

    vec2 startPos = UI::GetCursorPos();

    // Total width includes rank labels, board, and small right padding
    float totalBoardWidth = labelSize + maxBoardSize + boardPadding;
    float totalBoardHeight = labelSize + maxBoardSize + labelSize; // Top padding + board + file labels

    // Calculate horizontal offset to center the board in available space
    float horizontalOffset = (contentRegion.x - totalBoardWidth) / 2.0f;
    horizontalOffset = Math::Max(horizontalOffset, 0.0f); // Ensure non-negative

    // Calculate vertical offset to center the board in available space
    float verticalOffset = (contentRegion.y - totalBoardHeight) / 2.0f;
    verticalOffset = Math::Max(verticalOffset, 0.0f); // Ensure non-negative

    // Apply centering offset
    UI::SetCursorPos(vec2(startPos.x + horizontalOffset + labelSize, startPos.y + verticalOffset + labelSize));

    vec2 boardPos = UI::GetCursorPos();

    UI::PushStyleVar(UI::StyleVar::FrameRounding, 0.0f);

    // Render rank labels (8-1)
    array<string> rankLabels = {"8", "7", "6", "5", "4", "3", "2", "1"};
    for (int row = 0; row < 8; row++) {
        string label = flipBoard ? rankLabels[7 - row] : rankLabels[row];
        UI::SetCursorPos(vec2(boardPos.x - labelSize, boardPos.y + row * squareSize + squareSize / 2.0f - 7.0f));
        UI::Text(label);
    }

    // Render file labels (a-h)
    array<string> fileLabels = {"a", "b", "c", "d", "e", "f", "g", "h"};
    for (int col = 0; col < 8; col++) {
        string label = flipBoard ? fileLabels[7 - col] : fileLabels[col];
        UI::SetCursorPos(vec2(boardPos.x + col * squareSize + squareSize / 2.0f - 4.0f, boardPos.y + 8 * squareSize + 5.0f));
        UI::Text(label);
    }

    // Render squares and pieces
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            // Calculate display position (flip for black player)
            int displayRow = flipBoard ? (7 - row) : row;
            int displayCol = flipBoard ? (7 - col) : col;

            UI::SetCursorPos(boardPos + vec2(displayCol * squareSize, displayRow * squareSize));

            // Square color
            bool isLight = (row + col) % 2 == 0;
            vec4 squareColor = isLight ? boardLightSquareColor : boardDarkSquareColor;

            // Only show highlights when it's the player's turn
            if (GameManager::isLocalPlayerTurn()) {
                // Highlight selected square
                if (selectedRow == row && selectedCol == col) {
                    squareColor = boardSelectedSquareColor;
                }

                // Highlight valid moves (your existing local preview remains)
                if (selectedRow != -1 && selectedCol != -1) {
                    if (IsValidMove(selectedRow, selectedCol, row, col)) {
                        Piece temp = board[row][col];
                        board[row][col] = board[selectedRow][selectedCol];
                        board[selectedRow][selectedCol] = Piece();

                        bool wouldBeInCheck = IsInCheck(PieceColor(currentTurn));

                        board[selectedRow][selectedCol] = board[row][col];
                        board[row][col] = temp;

                        if (!wouldBeInCheck) {
                            squareColor = boardValidMoveColor;
                        }
                    }
                }
            }

            UI::PushStyleColor(UI::Col::Button, squareColor);
            UI::PushStyleColor(UI::Col::ButtonHovered, squareColor * 1.1f);

            // Only show click/active effect when it's the player's turn
            if (GameManager::isLocalPlayerTurn()) {
                UI::PushStyleColor(UI::Col::ButtonActive, squareColor * 0.9f);
            } else {
                UI::PushStyleColor(UI::Col::ButtonActive, squareColor * 1.1f); // Same as hover
            }

            // 1) Button for the square (for clicks)
            bool clicked = UI::Button("##" + row + "_" + col, vec2(squareSize, squareSize));
            if (clicked && !gameOver && GameManager::currentState != GameState::GameOver) HandleSquareClick(row, col);

            // 2) Overlay the piece texture using the window draw list (on top of the button)
            UI::Texture@ tex = GetPieceTexture(board[row][col]);
            DrawCenteredImageOverLastItem(tex, 6.0f);

            UI::PopStyleColor(3);

            if (col < 7) UI::SameLine();
        }
    }

    UI::PopStyleVar();
    UI::EndGroup();
}
