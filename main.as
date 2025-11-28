ChessBoardSetup chessBoard;
PieceAssets pAssets;

bool showWindow = false;
bool windowResizable = false; // Window is locked by default

// Menu tab state
enum MenuTab {
    Home,
    Play,
    Settings
}
MenuTab currentMenuTab = MenuTab::Home;

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
    print("[Chess] Plugin unloading - disconnecting from server");
    Network::Disconnect();
    print("[Chess] Disconnected from server");
}

void Update(float dt) {
    Network::Update();
    CheckRaceCompletion();
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
    float defaultHeight = screenSize.y * 0.5f; // Increased from 0.5f to 0.55f for more space
    float defaultWidth = defaultHeight * 1.0f; // Increased width to accommodate move history panel + board
    UI::SetNextWindowSize(int(defaultWidth), int(defaultHeight), UI::Cond::FirstUseEver);

    // Set window flags based on resize lock
    int windowFlags = windowResizable ? 0 : UI::WindowFlags::NoResize;

    // Variables to store main window position/size for modal centering
    vec2 mainWindowPos;
    vec2 mainWindowSize;

    if (UI::Begin("Chess Race", showWindow, windowFlags)) {
        // Add resize lock toggle button in top right corner (always visible)
        string lockText = windowResizable ? "Lock" : "Unlock";
        float lockButtonWidth = 60.0f;
        vec2 windowSize = UI::GetWindowSize();
        vec2 cursorStart = UI::GetCursorPos();
        UI::SetCursorPos(vec2(windowSize.x - lockButtonWidth - 10.0f, cursorStart.y));
        if (UI::Button(lockText, vec2(lockButtonWidth, 0))) {
            windowResizable = !windowResizable;
        }
        UI::SetCursorPos(cursorStart);

        switch (GameManager::currentState) {
            case GameState::Menu: {
                // Tab navigation bar
                float tabButtonWidth = 80.0f;

                // Home tab
                vec4 homeColor = currentMenuTab == MenuTab::Home ? vec4(0.2f, 0.5f, 0.8f, 1.0f) : vec4(0.26f, 0.26f, 0.26f, 1.0f);
                UI::PushStyleColor(UI::Col::Button, homeColor);
                if (UI::Button("Home", vec2(tabButtonWidth, 30.0f))) {
                    currentMenuTab = MenuTab::Home;
                }
                UI::PopStyleColor();

                UI::SameLine();

                // Play tab
                vec4 playColor = currentMenuTab == MenuTab::Play ? vec4(0.2f, 0.5f, 0.8f, 1.0f) : vec4(0.26f, 0.26f, 0.26f, 1.0f);
                UI::PushStyleColor(UI::Col::Button, playColor);
                if (UI::Button("Play", vec2(tabButtonWidth, 30.0f))) {
                    currentMenuTab = MenuTab::Play;
                }
                UI::PopStyleColor();

                UI::SameLine();

                // Settings tab
                vec4 settingsColor = currentMenuTab == MenuTab::Settings ? vec4(0.2f, 0.5f, 0.8f, 1.0f) : vec4(0.26f, 0.26f, 0.26f, 1.0f);
                UI::PushStyleColor(UI::Col::Button, settingsColor);
                if (UI::Button("Settings", vec2(tabButtonWidth, 30.0f))) {
                    currentMenuTab = MenuTab::Settings;
                }
                UI::PopStyleColor();

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
                    string settingsLockText = windowResizable ? "Window is Unlocked" : "Window is Locked";
                    string settingsButtonText = windowResizable ? "Lock Window Size" : "Unlock Window Size";
                    UI::Text(settingsLockText);
                    if (UI::Button(settingsButtonText, vec2(150.0f, 0))) {
                        windowResizable = !windowResizable;
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

            case GameState::RaceChallenge: {
                vec2 contentRegion = UI::GetContentRegionAvail();

                // Title
                string titleText = "\\$f80RACE CHALLENGE!";
                float titleWidth = Draw::MeasureString(titleText).x;
                vec2 currentPos = UI::GetCursorPos();
                UI::SetCursorPos(vec2(currentPos.x + (contentRegion.x - titleWidth) * 0.5f, currentPos.y));
                UI::Text(titleText);
                UI::NewLine();
                UI::Separator();
                UI::NewLine();

                // Explain the capture attempt
                UI::TextWrapped("A piece capture has been challenged!");
                UI::TextWrapped("Move: " + Network::captureFrom + " → " + Network::captureTo);
                UI::NewLine();

                // Show role
                if (Network::isDefender) {
                    UI::TextWrapped("\\$0f0You are DEFENDING your piece!");
                    UI::TextWrapped("Set a time for your opponent to beat.");
                } else {
                    UI::TextWrapped("\\$f00You are ATTACKING!");
                    if (Network::defenderTime > 0) {
                        UI::TextWrapped("Beat the defender's time of " + (Network::defenderTime / 1000.0) + " seconds to capture the piece!");
                    } else {
                        UI::TextWrapped("Wait for the defender to finish their run...");
                    }
                }
                UI::NewLine();

                // Map info
                UI::Text("Map: \\$fff" + Network::raceMapName);
                UI::NewLine();

                // Show timeout countdown
                if (raceStartedAt > 0) {
                    int elapsed = Time::Now - raceStartedAt;
                    int remaining = raceTimeoutMs - elapsed;
                    if (remaining > 0) {
                        UI::Text("\\$f80Time remaining: " + (remaining / 1000) + " seconds");
                    } else {
                        UI::Text("\\$f00TIME'S UP!");
                    }
                } else {
                    UI::Text("\\$888Time limit: 2 minutes");
                }
                UI::NewLine();

                // Instructions
                UI::Separator();
                UI::TextWrapped("The map will load in solo mode. Complete your run and your time will be submitted automatically.");
                UI::NewLine();

                if (UI::Button("Load Map Now", vec2(150, 30))) {
                    LoadRaceMap();
                    if (raceStartedAt == 0) {
                        raceStartedAt = Time::Now;
                    }
                }

                UI::SameLine();

                if (UI::Button("Retire (Forfeit)", vec2(150, 30))) {
                    Network::RetireFromRace();
                    raceInProgress = false;
                    raceStartedAt = 0;
                }

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

            // Calculate available space
            vec2 contentRegion = UI::GetContentRegionAvail();

            // Move history width (left side)
            float moveHistoryWidth = 150.0f;
            float spacing = 10.0f;

            // Label dimensions
            float labelSize = 20.0f;

            // Calculate board size
            float belowBoardUIHeight = 110.0f; // Space for buttons, color text, separator
            float availableHeight = contentRegion.y - belowBoardUIHeight;
            // Account for move history, spacing, and board labels in width calculation
            float availableWidth = contentRegion.x - moveHistoryWidth - spacing - labelSize - 20.0f;

            // Use the smaller dimension to ensure board fits and remains square
            float maxBoardSize = Math::Min(availableWidth, availableHeight);
            maxBoardSize = Math::Max(maxBoardSize, 80.0f); // Reduced minimum size to allow smaller scaling
            // Ensure we don't make the board so large that buttons get cut off
            if (maxBoardSize > availableHeight) {
                maxBoardSize = availableHeight;
            }

            float squareSize = maxBoardSize / 8.0f;

            // Flip board if playing as black
            bool flipBoard = (Network::gameId != "" && !Network::isWhite);

            // Start with move history on the left
            UI::BeginChild("MoveHistory", vec2(moveHistoryWidth, availableHeight + belowBoardUIHeight), true);
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

            UI::SameLine();

            // Right side: board and controls
            UI::BeginGroup();

            // Reserve space for top labels
            vec2 startPos = UI::GetCursorPos();
            UI::SetCursorPos(vec2(startPos.x + labelSize, startPos.y + labelSize));

            vec2 boardPos = UI::GetCursorPos();

            // Set button rounding to 0 for sharp corners
            UI::PushStyleVar(UI::StyleVar::FrameRounding, 0.0f);

            // Draw row labels (1-8) on the left side
            array<string> rankLabels = {"8", "7", "6", "5", "4", "3", "2", "1"};
            for (int row = 0; row < 8; row++) {
                string label = flipBoard ? rankLabels[7 - row] : rankLabels[row];
                UI::SetCursorPos(vec2(boardPos.x - labelSize, boardPos.y + row * squareSize + squareSize / 2.0f - 7.0f));
                UI::Text(label);
            }

            // Draw column labels (a-h) on the bottom
            array<string> fileLabels = {"a", "b", "c", "d", "e", "f", "g", "h"};
            for (int col = 0; col < 8; col++) {
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

            UI::EndGroup();
        } // end Playing UI

        // Game over modal overlay - rendered inside the main window
    if (GameManager::currentState == GameState::GameOver) {
            // Get current window size for centering
            vec2 modalWindowSize = UI::GetWindowSize();
            vec2 modalWindowPos = UI::GetWindowPos();

            // Draw semi-transparent overlay
            UI::DrawList@ drawList = UI::GetWindowDrawList();
            vec4 overlayRect = vec4(modalWindowPos.x, modalWindowPos.y, modalWindowPos.x + modalWindowSize.x, modalWindowPos.y + modalWindowSize.y);
            drawList.AddRectFilled(overlayRect, vec4(0, 0, 0, 0.7f));

            // Modal content
        vec2 modalSize = vec2(350, 200);
            vec2 modalPos = (modalWindowSize - modalSize) * 0.5f;

            UI::SetCursorPos(modalPos);
            UI::BeginChild("GameOverModal", modalSize, true);

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
            float startX = (modalSize.x - totalWidth) / 2.0f;

        UI::SetCursorPos(vec2(startX, UI::GetCursorPos().y));
        if (UI::Button("Rematch", vec2(buttonWidth, 35.0f))) {
            // Simply start a new game in the current lobby
            if (Network::currentLobbyId.Length > 0) {
                print("[Chess] Rematch requested - Starting new game in lobby: " + Network::currentLobbyId);
                Network::StartGame(Network::currentLobbyId);
                // Clear the game over state to return to lobby waiting
                GameManager::currentState = GameState::InLobby;
            } else {
                print("[Chess] Cannot rematch - no lobby ID available");
            }
        }

        UI::SameLine();
        UI::Dummy(vec2(spacing, 0));
        UI::SameLine();

        if (UI::Button("Back to Menu", vec2(buttonWidth, 35.0f))) {
            GameManager::currentState = GameState::Menu;
            Network::gameId = "";
        }

            UI::EndChild();
        }

        // Store window position and size before ending the window (for potential future use)
        mainWindowPos = UI::GetWindowPos();
        mainWindowSize = UI::GetWindowSize();
    }
        UI::End();
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
            // Validate the move before sending to server
            if (!IsValidMove(gSelR, gSelC, row, col)) {
                gSelR = gSelC = -1;
                selectedRow = selectedCol = -1;
                return; // Invalid move, don't send to server
            }

            // Check if this move would leave the player in check
            Piece temp = board[row][col];
            board[row][col] = board[gSelR][gSelC];
            board[gSelR][gSelC] = Piece();

            bool wouldBeInCheck = IsInCheck(currentTurn);

            // Restore the board
            board[gSelR][gSelC] = board[row][col];
            board[row][col] = temp;

            if (wouldBeInCheck) {
                gSelR = gSelC = -1;
                selectedRow = selectedCol = -1;
                return; // Can't move into check
            }

            // Move is valid, send to server
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

// ---------- Race Challenge ----------
bool raceInProgress = false;
int raceStartTime = 0;
int raceTimeoutMs = 120000; // 2 minutes in milliseconds
int raceStartedAt = 0; // When the race challenge started (for timeout)

void LoadRaceMap() {
    if (Network::raceMapUid.Length == 0) {
        print("[Chess] No map UID available");
        return;
    }

    print("[Chess] Loading map with ID: " + Network::raceMapUid);

    // Get the Trackmania app
    auto app = cast<CTrackMania>(GetApp());
    if (app is null) {
        print("[Chess] Could not get CTrackMania app");
        return;
    }

    // Access the menu system to load the map
    auto menuBase = cast<CGameModuleMenuBase>(app.MenuManager.MenuCustom_CurrentManiaApp);
    if (menuBase is null) {
        print("[Chess] Could not access menu base");
        return;
    }

    // Load map from Trackmania Exchange using the map ID
    string tmxUrl = "https://trackmania.exchange/maps/download/" + Network::raceMapUid;
    print("[Chess] Loading map from TMX: " + tmxUrl);

    // Use Openplanet's PlayMap function to load the map in solo mode
    menuBase.PlayMap(tmxUrl);

    raceInProgress = true;
    raceStartTime = Time::Now;
}

// Called every frame to check if player finished the race
void CheckRaceCompletion() {
    if (!raceInProgress) {
        // Check for timeout even when not actively racing
        if (GameManager::currentState == GameState::RaceChallenge && raceStartedAt > 0) {
            int elapsed = Time::Now - raceStartedAt;
            if (elapsed > raceTimeoutMs) {
                print("[Chess] Race timed out - auto-retiring");
                Network::RetireFromRace();
                raceStartedAt = 0;
            }
        }
        return;
    }

    auto app = cast<CTrackMania>(GetApp());
    if (app is null) return;

    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (network is null) return;

    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    if (playground is null) return;

    // Get the player
    auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
    if (player is null) return;

    auto scriptPlayer = cast<CSmScriptPlayer>(player.ScriptAPI);
    if (scriptPlayer is null) return;

    // Check if player finished
    if (scriptPlayer.CurrentRaceTime > 0 && scriptPlayer.Score.BestRaceTimes.Length > 0) {
        int finishTime = scriptPlayer.Score.BestRaceTimes[0];
        print("[Chess] Race finished in " + finishTime + "ms");

        // Send result to server
        Network::SendRaceResult(finishTime);

        raceInProgress = false;
        raceStartTime = 0;
        raceStartedAt = 0;
    }
}