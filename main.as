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
    
    UI::SetNextWindowSize(600, 680, UI::Cond::FirstUseEver);
    if (UI::Begin("Chess Online", showWindow)) {
        switch (GameManager::currentState) {
            case GameState::Menu: {
                UI::Text("Chess Online");
                UI::Separator();
                // Server override fields
                // UI::Text("Server Host:");
                // UI::SameLine();
                // UI::SetNextItemWidth(250);
                // ui_serverHost = UI::InputText("Host", ui_serverHost);
                // if (ui_serverHost == "") ui_serverHost = Network::serverHost;

                // UI::Text("Server Port:");
                // UI::SameLine();
                // UI::SetNextItemWidth(120);
                // ui_serverPort = UI::InputText("Port", ui_serverPort);
                // if (ui_serverPort == "") ui_serverPort = "" + Network::serverPort;

                // if (UI::Button("Apply Settings")) {
                //     if (ui_serverHost != "") Network::serverHost = ui_serverHost;
                //     if (ui_serverPort != "") {
                //         uint portParsed = Text::ParseUInt(ui_serverPort);
                //         if (portParsed > 0) Network::serverPort = portParsed;
                //     }
                // }

                UI::Separator();

                if (UI::Button("Play Online")) {
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
                UI::Text("Online Lobby Browser");
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
                UI::Text("\\$0f0Lobby Screen");
                UI::Separator();

                // Render the current lobby details
                Lobby::RenderCurrentLobby();
                break;
            }
            
            case GameState::Playing: {
                // Game UI will be rendered below when in Playing state
                break;
            }
            
            case GameState::GameOver: {
                UI::Text("Game Over: " + gameResult);
                if (UI::Button("Back to Menu")) {
                    GameManager::currentState = GameState::Menu;
                }
                break;
            }
        }
        
        if (GameManager::currentState == GameState::Playing) {
            // Game info
            string turnText = (currentTurn == PieceColor::White) ? "\\$fffWhite" : "\\$666Black";
            UI::Text("Turn: " + turnText);
            
            if (!GameManager::isLocalPlayerTurn()) {
                UI::Text("\\$ff0Waiting for opponent's move...");
            }
            
            if (IsInCheck(currentTurn)) {
                UI::Text("\\$f00CHECK!");
            }
            
            if (gameOver) {
                UI::Text("\\$ff0" + gameResult);
            }
            
            UI::Separator();
            
            // Draw chess board (unchanged)
            float squareSize = 60.0f;
            vec2 boardPos = UI::GetCursorPos();
            
            for (int row = 0; row < 8; row++) {
                for (int col = 0; col < 8; col++) {
                    UI::SetCursorPos(boardPos + vec2(col * squareSize, row * squareSize));
                    
                    // Square color
                    bool isLight = (row + col) % 2 == 0;
                    vec4 squareColor = isLight ? vec4(0.9, 0.9, 0.8, 0.4) : vec4(0.5, 0.4, 0.3, 0.4);
                    
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
                    
                    UI::PushStyleColor(UI::Col::Button, squareColor);
                    UI::PushStyleColor(UI::Col::ButtonHovered, squareColor * 1.1f);
                    UI::PushStyleColor(UI::Col::ButtonActive, squareColor * 0.9f);
                    
                    // 1) Button for the square (for clicks)
                    bool clicked = UI::Button("##" + row + "_" + col, vec2(squareSize, squareSize));
                    if (clicked && !gameOver) HandleSquareClick(row, col);

                    // 2) Overlay the piece texture using the window draw list (on top of the button)
                    UI::Texture@ tex = GetPieceTexture(chessBoard.board[row][col]);
                    chessBoard.DrawCenteredImageOverLastItem(tex, 6.0f);
                    
                    UI::PopStyleColor(3);
                    
                    if (col < 7) UI::SameLine();
                }
            }
            
            UI::SetCursorPos(boardPos + vec2(0, 8 * squareSize + 10));

            // Display player's color prominently at the bottom
            string colorDisplayText = Network::isWhite ? "\\$fffYou are playing as WHITE" : "\\$666You are playing as BLACK";
            UI::Text(colorDisplayText);

            UI::Separator();

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
            
            // Move history
            UI::Separator();
            UI::Text("Move History:");
            UI::BeginChild("MoveHistory", vec2(0, 100));
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
}

// ------------------------------------------------------------
// Click handling:
// ------------------------------------------------------------
int gSelR = -1, gSelC = -1;

void HandleSquareClick(int row, int col) {
    // ONLINE: authoritative server
    if (GameManager::currentState == GameState::Playing && Network::gameId != "") {
        if (gSelR == -1) {
            gSelR = row; gSelC = col;
            selectedRow = row; selectedCol = col;
            return;
        } else {
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