enum GameState {
    Menu,
    Connecting,
    InQueue,
    InLobby,
    Playing,
    GameOver
}

namespace GameManager {
    GameState currentState = GameState::Menu;
    
    bool isLocalPlayerTurn() {
        if (!Network::isConnected) return true;
        return (currentTurn == PieceColor::White) == Network::isWhite;
    }

    void OnGameStart(const Json::Value &in data) {
        currentState = GameState::Playing;
        chessBoard.InitializeBoard();
        // re-link globals
        @board = chessBoard.GetBoard();
        currentTurn = chessBoard.currentTurn;
        selectedRow = chessBoard.selectedRow;
        selectedCol = chessBoard.selectedCol;
        moveHistory = chessBoard.moveHistory;
        gameOver = chessBoard.gameOver;
        gameResult = chessBoard.gameResult;
        Network::isWhite = bool(data["isWhite"]);
        // Reset other game state as needed
    }

    void OnOpponentMove(Move@ m) {

    }

    void OnGameOver(const string &in winner) {
        currentState = GameState::GameOver;
        gameOver = true;
        gameResult = winner + " wins!";
    }
}