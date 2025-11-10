
ChessBoardSetup chessBoard = ChessBoardSetup();

bool showWindow = true;
// UI overrides for network host/port
string ui_serverHost = "";
string ui_serverPort = "";
// shared state lives in Globals.as

void Main() {
    Network::Init();
    InitializeGlobals();
    chessBoard.InitializeBoard();
    // Link globals to chessBoard internals
    @board = chessBoard.GetBoard();
    currentTurn = chessBoard.currentTurn;
    selectedRow = chessBoard.selectedRow;
    selectedCol = chessBoard.selectedCol;
    moveHistory = chessBoard.moveHistory;
    gameOver = chessBoard.gameOver;
    gameResult = chessBoard.gameResult;
}

void OnDestroyed() {
    Network::Disconnect();
}

void Update(float dt) {
    Network::Update();
}

void Render() {
    if (!showWindow) return;
    
    UI::SetNextWindowSize(600, 680, UI::Cond::FirstUseEver);
    if (UI::Begin("Chess Online", showWindow)) {
        switch(GameManager::currentState) {
            case GameState::Menu: {
                UI::Text("Chess Online");
                UI::Separator();
                // Server override fields
                UI::Text("Server Host:");
                UI::SameLine();
                UI::SetNextItemWidth(250);
                ui_serverHost = UI::InputText("Host", ui_serverHost);
                if (ui_serverHost == "") ui_serverHost = Network::serverHost;
                UI::Text("Server Port:");
                UI::SameLine();
                UI::SetNextItemWidth(120);
                ui_serverPort = UI::InputText("Port", ui_serverPort);
                if (ui_serverPort == "") ui_serverPort = "" + Network::serverPort;

                if (UI::Button("Apply Settings")) {
                    if (ui_serverHost != "") Network::SetServerHost(ui_serverHost);
                    if (ui_serverPort != "") Network::SetServerPortString(ui_serverPort);
                }

                UI::Separator();

                if (UI::Button("Play Online")) {
                    if (!Network::isConnected) {
                        // ensure UI overrides are applied as a convenience
                        if (ui_serverHost != "") Network::SetServerHost(ui_serverHost);
                        if (ui_serverPort != "") Network::SetServerPortString(ui_serverPort);
                        if (Network::Connect()) {
                            GameManager::currentState = GameState::InQueue;
                            // request available lobbies
                            Network::ListLobbies();
                        }
                    }
                }
                
                if (UI::Button("Play Locally")) {
                    GameManager::currentState = GameState::Playing;
                    chessBoard.InitializeBoard();
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
                
                // Render create lobby UI
                Lobby::RenderCreateLobby();

                // Show either current lobby or lobby list
                if (Network::currentLobbyId != "") {
                    Lobby::RenderCurrentLobby();
                } else {
                    Lobby::RenderLobbyList();
                }

                if (UI::Button("Back to Menu")) {
                    GameManager::currentState = GameState::Menu;
                }
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
    string playerColorText = Network::isWhite ? "\\$fffWhite" : "\\$666Black";
    UI::Text("Playing as: " + playerColorText);
    
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
        
        // Draw chess board
        float squareSize = 60.0f;
        vec2 boardPos = UI::GetCursorPos();
        
        for (int row = 0; row < 8; row++) {
            for (int col = 0; col < 8; col++) {
                UI::SetCursorPos(boardPos + vec2(col * squareSize, row * squareSize));
                
                // Square color
                bool isLight = (row + col) % 2 == 0;
                vec4 squareColor = isLight ? vec4(0.9, 0.9, 0.8, 1) : vec4(0.5, 0.4, 0.3, 1);
                
                // Highlight selected square
                if (selectedRow == row && selectedCol == col) {
                    squareColor = vec4(0.3, 0.7, 0.3, 1);
                }
                
                // Highlight valid moves
                if (selectedRow != -1 && selectedCol != -1) {
                    if (IsValidMove(selectedRow, selectedCol, row, col)) {
                        Piece temp = board[row][col];
                        board[row][col] = board[selectedRow][selectedCol];
                        board[selectedRow][selectedCol] = Piece();
                        
                        bool wouldBeInCheck = IsInCheck(currentTurn);
                        
                        board[selectedRow][selectedCol] = board[row][col];
                        board[row][col] = temp;
                        
                        if (!wouldBeInCheck) {
                            squareColor = vec4(0.7, 0.9, 0.7, 1);
                        }
                    }
                }
                
                UI::PushStyleColor(UI::Col::Button, squareColor);
                UI::PushStyleColor(UI::Col::ButtonHovered, squareColor * 1.1f);
                UI::PushStyleColor(UI::Col::ButtonActive, squareColor * 0.9f);
                
                string pieceText = GetPieceUnicode(board[row][col]);
                
                if (UI::Button(pieceText + "##" + row + "_" + col, vec2(squareSize, squareSize))) {
                    if (!gameOver) {
                        HandleSquareClick(row, col);
                    }
                }
                
                UI::PopStyleColor(3);
                
                if (col < 7) UI::SameLine();
            }
        }
        
        UI::SetCursorPos(boardPos + vec2(0, 8 * squareSize + 10));
        
        UI::Separator();
        
        if (UI::Button("New Game")) {
            chessBoard.InitializeBoard();
            // re-link globals
            @board = chessBoard.GetBoard();
            currentTurn = chessBoard.currentTurn;
            selectedRow = chessBoard.selectedRow;
            selectedCol = chessBoard.selectedCol;
            moveHistory = chessBoard.moveHistory;
            gameOver = chessBoard.gameOver;
            gameResult = chessBoard.gameResult;
        }
        
        UI::SameLine();
        
        if (UI::Button("Undo Move") && moveHistory.Length > 0) {
            UndoLastMove();
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