// ============================================================================
// UI BOARD RENDERER
// ============================================================================
// Handles rendering of the chess board
// ============================================================================

/**
 * Renders the chess board with pieces
 */
void BoardRender() {
    // Check if thumbnails are loading (only when thumbnails are enabled)
    if (showThumbnails && RaceMode::ThumbnailRendering::IsLoadingThumbnails()) {
        RenderThumbnailLoadingScreen();
        return;
    }

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

            // 2) Render map thumbnail (when enabled)
            // Must be called after button so GetItemRect() works correctly
            if (showThumbnails) {
                RaceMode::ThumbnailRendering::RenderMapThumbnail(row, col);
            }

            // 3) Overlay the piece texture using the window draw list (on top of the button and thumbnail)
            UI::Texture@ tex = GetPieceTexture(board[row][col]);
            DrawCenteredImageOverLastItem(tex, 6.0f);

            // 4) Right-click tooltip for map info (Chess Race mode only)
            if (currentRaceMode == RaceMode::SquareRace) {
                // Handle right-click to show tooltip
                if (UI::IsItemHovered() && UI::IsMouseClicked(UI::MouseButton::Right)) {
                    RaceMode::SquareMapData@ mapData = RaceMode::MapAssignment::GetSquareMap(row, col);
                    if (mapData !is null && mapData.tmxId > 0) {
                        // Set this square to show tooltip
                        mapInfoTooltipRow = row;
                        mapInfoTooltipCol = col;
                    }
                }

                // Hide tooltip if mouse moves away from the tracked square
                if (mapInfoTooltipRow == row && mapInfoTooltipCol == col) {
                    if (!UI::IsItemHovered()) {
                        // Mouse left this square, hide tooltip
                        mapInfoTooltipRow = -1;
                        mapInfoTooltipCol = -1;
                    }
                }

                // Show tooltip if this is the tracked square and mouse is hovering
                if (mapInfoTooltipRow == row && mapInfoTooltipCol == col && UI::IsItemHovered()) {
                    RaceMode::SquareMapData@ mapData = RaceMode::MapAssignment::GetSquareMap(row, col);
                    if (mapData !is null && mapData.tmxId > 0) {
                        UI::BeginTooltip();
                        UI::Text("\\$z" + mapData.mapName);
                        UI::Separator();

                        UI::Text("TMX ID: " + mapData.tmxId);

                        if (mapData.tags.Length > 0) {
                            UI::Text("Tags:");
                            UI::Dummy(vec2(0, 3)); // Small spacing

                            // Render tags as colored circular badges in a line
                            for (uint i = 0; i < mapData.tags.Length; i++) {
                                RaceMode::MapTag@ tag = mapData.tags[i];

                                // Parse hex color from TMX (format: "RRGGBB")
                                vec4 tagColor = vec4(0.5f, 0.5f, 0.5f, 1.0f); // Default gray
                                if (tag.color.Length == 6) {
                                    // Parse RGB from hex string
                                    int r = Text::ParseInt(tag.color.SubStr(0, 2), 16);
                                    int g = Text::ParseInt(tag.color.SubStr(2, 2), 16);
                                    int b = Text::ParseInt(tag.color.SubStr(4, 2), 16);
                                    tagColor = vec4(r / 255.0f, g / 255.0f, b / 255.0f, 1.0f);
                                }

                                // Push rounded button style
                                UI::PushStyleVar(UI::StyleVar::FrameRounding, 12.0f);
                                UI::PushStyleColor(UI::Col::Button, tagColor);
                                UI::PushStyleColor(UI::Col::ButtonHovered, tagColor * 1.1f);
                                UI::PushStyleColor(UI::Col::ButtonActive, tagColor * 0.9f);

                                // Render tag as button
                                UI::Button(tag.name + "##tag_" + i, vec2(0, 24));

                                UI::PopStyleColor(3);
                                UI::PopStyleVar();

                                // Keep tags on same line
                                if (i < mapData.tags.Length - 1) {
                                    UI::SameLine();
                                }
                            }
                        } else {
                            UI::Text("Tags: None");
                        }
                        UI::EndTooltip();
                    }
                }
            }

            UI::PopStyleColor(3);

            if (col < 7) UI::SameLine();
        }
    }

    UI::PopStyleVar();
    UI::EndGroup();
}

/**
 * Renders a loading screen while thumbnails are being downloaded
 */
void RenderThumbnailLoadingScreen() {
    vec2 contentRegion = UI::GetContentRegionAvail();

    // Calculate loading box size based on available space
    float maxLoadingBoxWidth = Math::Min(400.0f, contentRegion.x - 40.0f);
    float maxLoadingBoxHeight = Math::Min(200.0f, contentRegion.y - 40.0f);

    // Center the loading content
    vec2 loadingBoxPos = vec2(
        (contentRegion.x - maxLoadingBoxWidth) * 0.5f,
        (contentRegion.y - maxLoadingBoxHeight) * 0.5f
    );

    UI::SetCursorPos(UI::GetCursorPos() + loadingBoxPos);

    // Render loading content without child window to avoid scrollbars
    UI::BeginGroup();

    UI::Dummy(vec2(0, maxLoadingBoxHeight * 0.1f)); // Top spacing

    // Title - centered
    string titleText = Icons::Hourglass + " Loading Thumbnails";
    vec2 titleSize = Draw::MeasureString(titleText);
    vec2 currentPos = UI::GetCursorPos();
    UI::SetCursorPos(vec2(currentPos.x + (maxLoadingBoxWidth - titleSize.x) * 0.5f, currentPos.y));
    UI::Text("\\$z" + titleText);

    UI::Dummy(vec2(0, maxLoadingBoxHeight * 0.1f)); // Spacing

    // Progress bar - centered
    float progressBarWidth = Math::Min(maxLoadingBoxWidth - 40.0f, 360.0f);
    currentPos = UI::GetCursorPos();
    UI::SetCursorPos(vec2(currentPos.x + (maxLoadingBoxWidth - progressBarWidth) * 0.5f, currentPos.y));
    float progress = RaceMode::ThumbnailRendering::GetLoadingProgress();
    UI::ProgressBar(progress, vec2(progressBarWidth, 30.0f));

    UI::Dummy(vec2(0, 10.0f)); // Spacing

    // Status text - centered
    string statusText = RaceMode::ThumbnailRendering::GetLoadingText();
    vec2 statusSize = Draw::MeasureString(statusText);
    currentPos = UI::GetCursorPos();
    UI::SetCursorPos(vec2(currentPos.x + (maxLoadingBoxWidth - statusSize.x) * 0.5f, currentPos.y));
    UI::Text(statusText);

    UI::Dummy(vec2(0, maxLoadingBoxHeight * 0.15f)); // Spacing

    // Skip button - centered
    float buttonWidth = 150.0f;
    currentPos = UI::GetCursorPos();
    UI::SetCursorPos(vec2(currentPos.x + (maxLoadingBoxWidth - buttonWidth) * 0.5f, currentPos.y));
    if (StyledButton("Skip and Show Board", vec2(buttonWidth, 30.0f))) {
        RaceMode::ThumbnailRendering::isLoadingThumbnails = false;
    }

    UI::EndGroup();
}
