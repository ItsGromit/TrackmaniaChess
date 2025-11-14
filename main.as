ChessBoardSetup chessBoard;
PieceAssets pAssets;

bool showWindow = false;

// UI overrides for server host/port (kept from your snippet)
string ui_serverHost = "";
string ui_serverPort = "";

// Called by Openplanet on plugin start
void Main() {
    Network::Init();
    InitializeGlobals();

    chessBoard.InitializeBoard();

    // Link globals to chessBoard internals so server FEN updates flow into renderer
    @board       = chessBoard.GetBoard();
    currentTurn  = chessBoard.currentTurn;
    selectedRow  = chessBoard.selectedRow;
    selectedCol  = chessBoard.selectedCol;
    moveHistory  = chessBoard.moveHistory;
    gameOver     = chessBoard.gameOver;
    gameResult   = chessBoard.gameResult;
}

void OnDestroyed() {
    Network::Disconnect();
}

void Update(float dt) {
    Network::Update();
}

bool gPiecesLoaded = false;

void EnsurePieceAssetsLoaded() {
    if (!gPiecesLoaded) {
        LoadPieceAssets();
        gPiecesLoaded = true;
    }
}

void RenderMenu() {
    if (UI::MenuItem("Chess Race")) {
        showWindow = !showWindow;
    }
}

void Render() {
    if (!showWindow) return;



    EnsurePieceAssetsLoaded();

    // Set default window size to half of screen height
    vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
    float defaultHeight = screenSize.y * 0.5f;
    float defaultWidth = defaultHeight * 0.75f; // Maintain a reasonable aspect ratio
    UI::SetNextWindowSize(int(defaultWidth), int(defaultHeight), UI::Cond::FirstUseEver);
    if (UI::Begin("Chess Race", showWindow)) {
        switch (GameManager::currentState) {
            case GameState::Menu: {
                UI::Text("Chess Race");
                UI::Separator();

                if (UI::Button("Play")) {
                    // Ensure UI overrides are applied
                    if (ui_serverHost != "") Network::serverHost = ui_serverHost;
                    if (ui_serverPort != "") {
                        uint portParsed = Text::ParseUInt(ui_serverPort);
                        if (portParsed > 0) Network::serverPort = portParsed;
                    }

                    if (!Network::isConnected) {
                        if (Network::Connect()) {
                            GameManager::currentState = GameState::InQueue;
                            // request available lobbies
                            Network::ListLobbies();
                        } else {
                            UI::ShowNotification("Chess", "Failed to connect. Check host/port.", vec4(1,0.4,0.4,1), 4000);
                        }
                    } else {
                        GameManager::currentState = GameState::InQueue;
                        Network::ListLobbies();
                    }
                }
                break;
            }
            
            case GameState::Connecting: {
                UI::Text("Connecting to server...");
                break;
            }
            
            case GameState::InQueue: {
                UI::Text("Lobby Browser");
                UI::Separator();

                // Render create lobby UI (your existing UI module)
                Lobby::RenderCreateLobby();

                // Show lobby list
                Lobby::RenderLobbyList();

                if (UI::Button("Back to Menu")) {
                    GameManager::currentState = GameState::Menu;
                }
                break;
            }

            case GameState::InLobby: {
                UI::Text("\\$0f0Lobby");
                UI::Separator();

                // Render the current lobby details
                Lobby::RenderCurrentLobby();
                break;
            }
            
            case GameState::Playing:
            case GameState::GameOver: {
                // Game UI will be rendered below for both Playing and GameOver states
                break;
            }
        }

        if (GameManager::currentState == GameState::Playing || GameManager::currentState == GameState::GameOver) {
            // Game info
            string turnText = (currentTurn == PieceColor::White) ? "\\$fffWhite" : "\\$666Black";
            UI::Text("Turn: " + turnText);
            
            if (!GameManager::isLocalPlayerTurn()) {
                UI::Text("\\$ff0Waiting for opponent's move...");
            } else {
                UI::Text("");
            }
            
            if (IsInCheck(currentTurn)) {
                UI::Text("\\$f00CHECK!");
            }
            
            if (gameOver) {
                UI::Text("\\$ff0" + gameResult);
            }
            
            UI::Separator();

            // Draw chess board
            // Calculate available space for the board
            vec2 contentRegion = UI::GetContentRegionAvail();

            // Reserve space for UI elements below the board AND minimum move history space
            float moveHistoryMinHeight = 100.0f; // Minimum visible space for move history
            float belowBoardUIHeight = 80.0f; // Space for buttons, color text, separator, etc.
            float reservedHeight = belowBoardUIHeight + moveHistoryMinHeight;
            float availableHeight = contentRegion.y - reservedHeight;
            float availableWidth = contentRegion.x - 20.0f; // Add padding

            // Use the smaller dimension to ensure board fits and remains square
            float maxBoardSize = Math::Min(availableWidth, availableHeight);
            // Add a minimum size to prevent the board from becoming too small
            maxBoardSize = Math::Max(maxBoardSize, 240.0f);
            // Add a maximum size to prevent the board from becoming too large
            maxBoardSize = Math::Min(maxBoardSize, 800.0f);

            float squareSize = maxBoardSize / 8.0f;

            // Flip board if playing as black
            bool flipBoard = (Network::gameId != "" && !Network::isWhite);

            // Label dimensions
            float labelSize = 20.0f;

            // Center the board horizontally (accounting for left labels)
            float boardWidth = squareSize * 8.0f;
            float totalWidth = labelSize + boardWidth;
            float centerOffset = (contentRegion.x - totalWidth) / 2.0f;
            vec2 currentPos = UI::GetCursorPos();
            UI::SetCursorPos(vec2(currentPos.x + centerOffset, currentPos.y));

            // Reserve space for top labels
            vec2 startPos = UI::GetCursorPos();
            UI::SetCursorPos(vec2(startPos.x, startPos.y + labelSize));

            vec2 boardPos = UI::GetCursorPos();

            // Set button rounding to 0 for sharp corners
            UI::PushStyleVar(UI::StyleVar::FrameRounding, 0.0f);

            // Draw row labels (1-8) on the left side
            array<string> rankLabels = {"8", "7", "6", "5", "4", "3", "2", "1"};
            for (int row = 0; row < 8; row++) {
                // When flipped: visual row 0 should show "1", visual row 7 should show "8"
                // When not flipped: visual row 0 should show "8", visual row 7 should show "1"
                string label = flipBoard ? rankLabels[7 - row] : rankLabels[row];
                UI::SetCursorPos(vec2(boardPos.x - labelSize, boardPos.y + row * squareSize + squareSize / 2.0f - 7.0f));
                UI::Text(label);
            }

            // Draw column labels (a-h) on the bottom
            array<string> fileLabels = {"a", "b", "c", "d", "e", "f", "g", "h"};
            for (int col = 0; col < 8; col++) {
                // When flipped: visual col 0 should show "h", visual col 7 should show "a"
                // When not flipped: visual col 0 should show "a", visual col 7 should show "h"
                string label = flipBoard ? fileLabels[7 - col] : fileLabels[col];
                UI::SetCursorPos(vec2(boardPos.x + col * squareSize + squareSize / 2.0f - 4.0f, boardPos.y + 8 * squareSize + 2.0f));
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

                                bool wouldBeInCheck = IsInCheck(currentTurn);

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
                    UI::Texture@ tex = GetPieceTexture(chessBoard.board[row][col]);
                    chessBoard.DrawCenteredImageOverLastItem(tex, 6.0f);

                    UI::PopStyleColor(3);

                    if (col < 7) UI::SameLine();
                }
            }

            // Restore button rounding
            UI::PopStyleVar();

            UI::SetCursorPos(boardPos + vec2(0, 8 * squareSize + labelSize + 10));

            // Display player's color prominently at the bottom
            string colorDisplayText = Network::isWhite ? "\\$fffYou are playing as WHITE" : "\\$666You are playing as BLACK";
            UI::Text(colorDisplayText);

            UI::Separator();

            // Only show game buttons when not in GameOver state
            if (GameManager::currentState != GameState::GameOver) {
                // Online game buttons
                if (Network::gameId != "") {
                    if (UI::Button("Forfeit")) {
                        Network::Resign();
                    }
                    UI::SameLine();
                    if (UI::Button("New Game")) {
                        Network::RequestNewGame();
                    }
                } else {
                    // Local game buttons
                    if (UI::Button("New Game")) {
                        chessBoard.InitializeBoard();
                        // re-link globals
                        @board       = chessBoard.GetBoard();
                        currentTurn  = chessBoard.currentTurn;
                        selectedRow  = chessBoard.selectedRow;
                        selectedCol  = chessBoard.selectedCol;
                        moveHistory  = chessBoard.moveHistory;
                        gameOver     = chessBoard.gameOver;
                        gameResult   = chessBoard.gameResult;
                    }

                    UI::SameLine();

                    if (UI::Button("Undo Move") && moveHistory.Length > 0) {
                        UndoLastMove();
                    }
                }
            }
            
            // Move history - separate scrollable section
            UI::Separator();
            UI::Text("Move History:");

            // Use remaining window space for scrollable move history
            vec2 remainingSpace = UI::GetContentRegionAvail();
            UI::BeginChild("MoveHistory", vec2(0, remainingSpace.y), true);
            for (uint i = 0; i < moveHistory.Length; i++) {
                Move@ m = moveHistory[i];
                string moveText = "" + (i + 1) + ". " +
                                GetColumnName(m.fromCol) + (8 - m.fromRow) + " -> " +
                                GetColumnName(m.toCol) + (8 - m.toRow);
                UI::Text(moveText);
            }
            UI::EndChild();
        } // end Playing UI
    }
    UI::End();

    // Game over modal window - positioned relative to the main chess window
    if (GameManager::currentState == GameState::GameOver) {
        // Get the main window's position and size
        vec2 mainWindowPos = UI::GetWindowPos();
        vec2 mainWindowSize = UI::GetWindowSize();

        // Calculate center of the main window
        vec2 modalSize = vec2(350, 200);
        vec2 modalPos = mainWindowPos + (mainWindowSize - modalSize) * 0.5f;

        UI::SetNextWindowSize(int(modalSize.x), int(modalSize.y), UI::Cond::Always);
        UI::SetNextWindowPos(int(modalPos.x), int(modalPos.y), UI::Cond::Always);

        UI::Begin("Game Over", UI::WindowFlags::NoResize | UI::WindowFlags::NoCollapse);

        UI::Text("\\$f00GAME OVER");
        UI::Separator();
        UI::NewLine();

        UI::TextWrapped(gameResult);
        UI::NewLine();
        UI::Separator();
        UI::NewLine();

        // Center buttons
        float buttonWidth = 120.0f;
        float spacing = 20.0f;
        float totalWidth = buttonWidth * 2 + spacing;
        float startX = (350.0f - totalWidth) / 2.0f;

        UI::SetCursorPos(vec2(startX, UI::GetCursorPos().y));
        if (UI::Button("Rematch", vec2(buttonWidth, 35.0f))) {
            Network::RequestNewGame();
        }

        UI::SameLine();
        UI::Dummy(vec2(spacing, 0));
        UI::SameLine();

        if (UI::Button("Back to Menu", vec2(buttonWidth, 35.0f))) {
            GameManager::currentState = GameState::Menu;
            Network::gameId = "";
        }

        UI::End();
    }
}

// ------------------------------------------------------------
// Click handling:
// ------------------------------------------------------------
int gSelR = -1, gSelC = -1;

void HandleSquareClick(int row, int col) {
    // ONLINE: authoritative server
    if (GameManager::currentState == GameState::Playing && Network::gameId != "") {
        // Check if it's the player's turn
        if (!GameManager::isLocalPlayerTurn()) {
            return; // Not your turn, ignore clicks
        }

        if (gSelR == -1) {
            // First click: selecting a piece
            Piece@ piece = board[row][col];
            if (piece is null || piece.type == PieceType::Empty) {
                return; // No piece here, ignore
            }

            // Check if the piece belongs to the player
            bool isPieceWhite = (piece.color == PieceColor::White);
            if (isPieceWhite != Network::isWhite) {
                return; // Not your piece, ignore
            }

            gSelR = row; gSelC = col;
            selectedRow = row; selectedCol = col;
            return;
        } else {
            // Second click: attempting to move
            string fromAlg = Network::ToAlg(gSelR, gSelC);
            string toAlg   = Network::ToAlg(row, col);
            Network::SendMove(fromAlg, toAlg);
            gSelR = gSelC = -1;
            selectedRow = selectedCol = -1;
            return;
        }
    }

    // LOCAL: minimal pseudo-legal move (visual only)
    if (gSelR == -1) {
        // First click: selecting a piece
        Piece@ piece = board[row][col];
        if (piece is null || piece.type == PieceType::Empty) {
            return; // No piece here, ignore
        }

        // Check if the piece belongs to the current player
        if (piece.color != currentTurn) {
            return; // Not the current player's piece, ignore
        }

        gSelR = row; gSelC = col;
        selectedRow = row; selectedCol = col;
        return;
    } else {
        int fr = gSelR, fc = gSelC;
        gSelR = gSelC = -1;
        selectedRow = selectedCol = -1;

        if (IsValidMove(fr, fc, row, col)) {
            // apply move locally (no server)
            Piece moved = board[fr][fc];
            board[row][col] = moved;
            board[fr][fc] = Piece();

            // (Optional) very light "promotion" UI could go here if you want later.

            // toggle turn
            currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;

            // (Optional) append to moveHistory if you have a public ctor; omitted to avoid signature mismatches
            // Move@ m = Move(fr, fc, row, col); moveHistory.InsertLast(m);
        }
        return;
    }
}

void UndoLastMove() {
    // Optional: call chessBoard.UndoLastMove() if you have one.
}

// Avoid chr(): map 0..7 -> a..h
const array<string> FILES_MAIN = {"a","b","c","d","e","f","g","h"};
string GetColumnName(int col) {
    if (col < 0 || col >= 8) return "?";
    return FILES_MAIN[col];
}