string GetColumnName(int col) {
    array<string> columns = {"a", "b", "c", "d", "e", "f", "g", "h"};
    if (col >= 0 && col < 8) {
        return columns[col];
    }
    return "?";
}

void MainMenu() {
    int windowFlags = windowResizeable ? 0 : UI::WindowFlags::NoResize;

    // Make title bar have same opacity as window background
    vec4 bgColor = UI::GetStyleColor(UI::Col::WindowBg);
    UI::PushStyleColor(UI::Col::TitleBg, bgColor);
    UI::PushStyleColor(UI::Col::TitleBgActive, bgColor);
    UI::PushStyleColor(UI::Col::TitleBgCollapsed, bgColor);

    if (UI::Begin("Chess Race", showWindow, windowFlags)) {

        switch (GameManager::currentState) {
            case GameState::Menu: {
                // navigation bar
                float tabButtonWidth = 80.0f;
                float lockButtonWidth = 30.0f;

                // Home tab
                vec4 homeColor = currentMenuTab == MenuTab::Home ? themeActiveTabColor : themeInactiveTabColor;
                UI::PushStyleColor(UI::Col::Button, homeColor);
                UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
                if (UI::Button("Home", vec2(tabButtonWidth, 30.0f))) {
                    currentMenuTab = MenuTab::Home;
                }
                UI::PopStyleColor(2);

                UI::SameLine();

                // Play tab
                vec4 playColor = currentMenuTab == MenuTab::Play ? themeActiveTabColor : themeInactiveTabColor;
                UI::PushStyleColor(UI::Col::Button, playColor);
                UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
                if (UI::Button("Play", vec2(tabButtonWidth, 30.0f))) {
                    currentMenuTab = MenuTab::Play;
                }
                UI::PopStyleColor(2);

                UI::SameLine();

                // Settings tab
                vec4 settingsColor = currentMenuTab == MenuTab::Settings ? themeActiveTabColor : themeInactiveTabColor;
                UI::PushStyleColor(UI::Col::Button, settingsColor);
                UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
                if (UI::Button("Settings", vec2(tabButtonWidth, 30.0f))) {
                    currentMenuTab = MenuTab::Settings;
                }
                UI::PopStyleColor(2);

                UI::SameLine();

                // Lock/Unlock button aligned with navigation bar
                vec2 availRegion = UI::GetContentRegionAvail();
                vec2 currentCursorPos = UI::GetCursorPos();
                UI::SetCursorPos(vec2(currentCursorPos.x + availRegion.x - lockButtonWidth, currentCursorPos.y));
                string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;
                if (UI::Button(lockText, vec2(lockButtonWidth, 30.0f))) {
                    // Check if Shift is held - if so, reset window to default size and lock it
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
                        windowResizeable = false;
                    } else {
                        windowResizeable = !windowResizeable;
                    }
                }
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::Text("Reset Window to Default Size");
                    } else {
                        UI::Text("Lock/Unlock Window Size");
                    }
                    UI::EndTooltip();
                }

                UI::Separator();
                UI::NewLine();

                // Tab content
                if (currentMenuTab == MenuTab::Home) {
                    // Home tab - Rules and information
                vec2 contentRegion = UI::GetContentRegionAvail();
                string titleText = "Chess Race";
                float titleWidth = Draw::MeasureString(titleText).x;
                vec2 currentPos = UI::GetCursorPos();
                UI::SetCursorPos(vec2(currentPos.x + (contentRegion.x - titleWidth) * 0.5f, currentPos.y));
                UI::Text(titleText);
                UI::Separator();
                    UI::NewLine();

                    UI::TextWrapped("Welcome to Chess Race! This is a competitive chess game where you can play against other players online.");
                    UI::NewLine();
                    UI::Text("\\$f80Rules:");
                    UI::TextWrapped("- Play follows standard chess rules");
                    UI::TextWrapped("- Click a piece to select it, then click a valid square to move");
                    UI::TextWrapped("- The game ends when checkmate is achieved or a player forfeits");
                    UI::NewLine();
                    UI::Text("\\$0f0How to Play:");
                    UI::TextWrapped("1. Click the 'Play' tab to find or create a game");
                    UI::TextWrapped("2. Join a lobby or create your own");
                    UI::TextWrapped("3. Wait for an opponent and start playing!");

                } else if (currentMenuTab == MenuTab::Play) {
                    // Play tab - Show lobby browser directly
                    // Auto-connect if not connected
                    if (!Network::isConnected) {
                        // Ensure UI overrides are applied
                        if (ui_serverHost != "") Network::serverHost = ui_serverHost;
                        if (ui_serverPort != "") {
                            uint portParsed = Text::ParseUInt(ui_serverPort);
                            if (portParsed > 0) Network::serverPort = portParsed;
                        }

                        print("[Chess] Attempting to connect to server: " + Network::serverHost + ":" + Network::serverPort);
                        if (Network::Connect()) {
                            print("[Chess] Successfully connected to server");
                            Network::ListLobbies();
                        } else {
                            print("[Chess] Failed to connect to server");
                        }
                    }

                    // Show lobby browser UI with centered title
                    vec2 contentRegion = UI::GetContentRegionAvail();
                    string titleText = "Lobby Browser";
                    float titleWidth = Draw::MeasureString(titleText).x;
                    vec2 currentPos = UI::GetCursorPos();
                    UI::SetCursorPos(vec2(currentPos.x + (contentRegion.x - titleWidth) * 0.5f, currentPos.y));
                    UI::Text(titleText);
                    UI::NewLine();
                    UI::Separator();
                    UI::NewLine();

                    // Render create lobby UI
                    Lobby::RenderCreateLobby();

                    // Show lobby list
                    Lobby::RenderLobbyList();

                } else if (currentMenuTab == MenuTab::Settings) {
                    // Settings tab
                    vec2 contentRegion = UI::GetContentRegionAvail();
                    string titleText = "Settings";
                    float titleWidth = Draw::MeasureString(titleText).x;
                    vec2 currentPos = UI::GetCursorPos();
                    UI::SetCursorPos(vec2(currentPos.x + (contentRegion.x - titleWidth) * 0.5f, currentPos.y));
                    UI::Text(titleText);
                    UI::Separator();
                    UI::NewLine();

                    UI::Text("Window Settings:");
                    UI::NewLine();

                    // Window resize toggle (moved from top right for settings page)
                    string settingsLockText = windowResizeable ? "Window is Unlocked" : "Window is Locked";
                    string settingsButtonText = windowResizeable ? "Lock Window Size" : "Unlock Window Size";
                    UI::Text(settingsLockText);
                    if (UI::Button(settingsButtonText, vec2(150.0f, 0))) {
                        windowResizeable = !windowResizeable;
                    }
                }

                break;
            }
            // Connecting
            case GameState::Connecting: {
                // Top bar with lock button - same height as menu navigation
                float lockButtonWidth = 30.0f;
                float barHeight = 30.0f;
                vec2 contentAvail = UI::GetContentRegionAvail();
                vec2 lockCursor = UI::GetCursorPos();

                // Lock button at right
                UI::SetCursorPos(vec2(lockCursor.x + contentAvail.x - lockButtonWidth, lockCursor.y));
                string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;
                if (UI::Button(lockText + "##connecting", vec2(lockButtonWidth, barHeight))) {
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
                        windowResizeable = false;
                    } else {
                        windowResizeable = !windowResizeable;
                    }
                }
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::Text("Reset Window to Default Size");
                    } else {
                        UI::Text("Lock/Unlock Window Size");
                    }
                    UI::EndTooltip();
                }

                // Reset cursor and add dummy invisible item to maintain bar height
                UI::SetCursorPos(lockCursor);
                UI::Dummy(vec2(0, barHeight));

                UI::Separator();
                UI::NewLine();

                UI::Text("Connecting to server...");
                break;
            }
            // In Queue (Depricated)
            case GameState::InQueue: {
                // Top bar with lock button - same height as menu navigation
                float lockButtonWidth = 30.0f;
                float barHeight = 30.0f;
                vec2 contentAvail = UI::GetContentRegionAvail();
                vec2 lockCursor = UI::GetCursorPos();

                // Lock button at right
                UI::SetCursorPos(vec2(lockCursor.x + contentAvail.x - lockButtonWidth, lockCursor.y));
                string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;
                if (UI::Button(lockText + "##queue", vec2(lockButtonWidth, barHeight))) {
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
                        windowResizeable = false;
                    } else {
                        windowResizeable = !windowResizeable;
                    }
                }
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::Text("Reset Window to Default Size");
                    } else {
                        UI::Text("Lock/Unlock Window Size");
                    }
                    UI::EndTooltip();
                }

                // Reset cursor and add dummy invisible item to maintain bar height
                UI::SetCursorPos(lockCursor);
                UI::Dummy(vec2(0, barHeight));

                UI::Separator();
                UI::NewLine();

                // Render create lobby UI
                Lobby::RenderCreateLobby();

                // Show lobby list
                Lobby::RenderLobbyList();

                if (UI::Button("Back to Menu")) {
                    GameManager::currentState = GameState::Menu;
                }
                break;
            }
            // In Lobby
            case GameState::InLobby: {
                // Top bar with lock button - same height as menu navigation
                float lockButtonWidth = 30.0f;
                float barHeight = 30.0f;
                vec2 contentAvail = UI::GetContentRegionAvail();
                vec2 lockCursor = UI::GetCursorPos();

                // Lock button at right
                UI::SetCursorPos(vec2(lockCursor.x + contentAvail.x - lockButtonWidth, lockCursor.y));
                string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;
                if (UI::Button(lockText + "##lobby", vec2(lockButtonWidth, barHeight))) {
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
                        windowResizeable = false;
                    } else {
                        windowResizeable = !windowResizeable;
                    }
                }
                if (UI::IsItemHovered()) {
                    UI::BeginTooltip();
                    if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                        UI::Text("Reset Window to Default Size");
                    } else {
                        UI::Text("Lock/Unlock Window Size");
                    }
                    UI::EndTooltip();
                }

                // Reset cursor and add "Lobby" label as a button-style element
                UI::SetCursorPos(lockCursor);
                UI::PushStyleColor(UI::Col::Button, themeActiveTabColor);
                UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
                UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
                UI::Button("Lobby", vec2(80.0f, barHeight));
                UI::PopStyleColor(3);

                UI::Separator();
                UI::NewLine();

                // Render the current lobby details
                Lobby::RenderCurrentLobby();
                break;
            }
            case GameState::Playing: {
                break;
            }

            case GameState::GameOver: {
                break;
            }
        }

        if (GameManager::currentState == GameState::Playing || GameManager::currentState == GameState::GameOver) {
            // Top bar with lock button - same height as menu navigation
            float lockButtonWidth = 30.0f;
            float barHeight = 30.0f;
            vec2 contentAvail = UI::GetContentRegionAvail();
            vec2 lockCursor = UI::GetCursorPos();

            // Lock button at right
            UI::SetCursorPos(vec2(lockCursor.x + contentAvail.x - lockButtonWidth, lockCursor.y));
            string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;
            if (UI::Button(lockText + "##playing", vec2(lockButtonWidth, barHeight))) {
                if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                    UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
                    windowResizeable = false;
                } else {
                    windowResizeable = !windowResizeable;
                }
            }
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
                    UI::Text("Reset Window to Default Size");
                } else {
                    UI::Text("Lock/Unlock Window Size");
                }
                UI::EndTooltip();
            }

            // Reset cursor and add dummy invisible item to maintain bar height
            UI::SetCursorPos(lockCursor);
            UI::Dummy(vec2(0, barHeight));

            UI::Separator();

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
            if (gameOver) {
                UI::SameLine();
                UI::Text("\\$ff0Game over!" + gameResult);
            }

            UI::Separator();

            vec2 contentRegion = UI::GetContentRegionAvail();

            float moveHistoryWidth = 150.0f;
            float spacing = 10.0f;

            float labelSize = 20.0f;

            float belowBoardUIHeight = 30.0f;
            float availableHeight = contentRegion.y - belowBoardUIHeight;

            float availableWidth = contentRegion.x - moveHistoryWidth - spacing - labelSize - 20.0f;

            float maxBoardSize = Math::Min(availableWidth, availableHeight);
            maxBoardSize = Math::Max(maxBoardSize, 80.0f);

            if (maxBoardSize > availableHeight) {
                maxBoardSize = availableHeight;
            }

            float squareSize = maxBoardSize / 8.0f;

            bool flipBoard = (Network::gameId != "" && !Network::isWhite);

            UI::BeginGroup();
            UI::BeginChild("MoveHistory", vec2(moveHistoryWidth, availableHeight), true);
            UI::Text("Move History:");
            UI::Separator();
            for (uint i = 0; i < moveHistory.Length; i++) {
                Move@ m = moveHistory[i];
                string moveText = "" + (i + 1) + ". " +
                                GetColumnName(m.fromCol) + (8 - m.fromRow) + " -> " +
                                GetColumnName(m.toCol) + (8 - m.toRow);
                UI::Text(moveText);
            }
            UI::EndChild();

            // Forfeit button below move history, aligned with it
            if (GameManager::currentState == GameState::Playing && !gameOver) {
                vec2 buttonCursor = UI::GetCursorPos();
                UI::SetCursorPos(vec2(buttonCursor.x, buttonCursor.y - 10.0f));
                if (UI::Button("Forfeit", vec2(moveHistoryWidth, belowBoardUIHeight))) {
                    Network::Resign();
                }
            }
            UI::EndGroup();

            UI::SameLine();

            BoardRender();
        }
    }
    UI::End();

    // Pop the title bar style colors
    UI::PopStyleColor(3);
}

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
    bool flipBoard = (Network::gameId != "" && !Network::isWhite);

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

    array<string> rankLabels = {"8", "7", "6", "5", "4", "3", "2", "1"};
    for (int row = 0; row < 8; row++) {
        string label = flipBoard ? rankLabels[7 - row] : rankLabels[row];
        UI::SetCursorPos(vec2(boardPos.x - labelSize, boardPos.y + row * squareSize + squareSize / 2.0f - 7.0f));
        UI::Text(label);
    }

    array<string> fileLabels = {"a", "b", "c", "d", "e", "f", "g", "h"};
    for (int col = 0; col < 8; col++) {
        string label = flipBoard ? fileLabels[7 - col] : fileLabels[col];
        UI::SetCursorPos(vec2(boardPos.x + col * squareSize + squareSize / 2.0f - 4.0f, boardPos.y + 8 * squareSize + 5.0f));
        UI::Text(label);
    }
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            // Calculate display position (flip for black player)
            int displayRow = flipBoard ? (7 - row) : row;
            int displayCol = flipBoard ? (7 - col) : col;

            UI::SetCursorPos(boardPos + vec2(displayCol * squareSize, displayRow * squareSize));

            // Square color
            bool isLight = (row + col) % 2 == 0;
            vec4 squareColor = isLight ? vec4(0.9, 0.9, 0.8, 0.4) : vec4(0.5, 0.4, 0.3, 0.4);

            // Only show highlights when it's the player's turn
            if (GameManager::isLocalPlayerTurn()) {
                // Highlight selected square
                if (selectedRow == row && selectedCol == col) {
                    squareColor = vec4(0.3, 0.7, 0.3, 1);
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
                            squareColor = vec4(0.7, 0.9, 0.7, 0.4);
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

void HandleSquareClick(int row, int col) {
    if (GameManager::currentState == GameState::Playing && Network::gameId != "") {
        if (!GameManager::isLocalPlayerTurn()) {
            return;
        }

        if (gSelR == -1) {
            Piece@ piece = board[row][col];
            if (piece is null || piece.type == PieceType::Empty) {
                return;
            }


            bool isPieceWhite = (piece.color == PieceColor::White);
            if (isPieceWhite != Network::isWhite) {
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
            string fromAlg = Network::ToAlg(gSelR, gSelC);
            string toAlg   = Network::ToAlg(row, col);
            Network::SendMove(fromAlg, toAlg);
            gSelR = gSelC = -1;
            selectedRow = selectedCol = -1;
            return;
        }
    }
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
            Piece moved = board[fr][fc];
            board[row][col] = moved;
            board[fr][fc] = Piece();
            currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;
        }
        return;
    }
}