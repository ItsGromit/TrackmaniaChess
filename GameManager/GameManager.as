namespace GameManager {
    GameState currentState = GameState::Menu;

    bool isLocalPlayerTurn() {
        if (!isConnected) return true;
        return (currentTurn == PieceColor::White) == isWhite;
    }

    void OnGameStart(const Json::Value &in data) {
        currentState = GameState::Playing;
        InitializeBoard();
        // re-link globals
        InitializeGlobals();
        isWhite = bool(data["isWhite"]);
    }
    void OnOpponentMove(Move@ m) {
        
    }

    void OnGameOver(const string &in winner) {
        currentState = GameState::GameOver;
        gameOver = true;
        gameResult = winner + "wins!";
    }
}