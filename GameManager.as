// Gamestate possibilities
enum GameState {
    Menu,
    Connecting,
    InQueue,
    InLobby,
    Playing,
    Racing,
    RaceChallenge,
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
        InitializeBoard();
        // re-link globals
        InitializeGlobals();
        Network::isWhite = bool(data["isWhite"]);
    }
    void OnOpponentMove(Move@ m) {
        
    }

    void OnGameOver(const string &in winner) {
        currentState = GameState::GameOver;
        gameOver = true;
        gameResult = winner + "wins!";
    }
}