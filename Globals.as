// Top-level globals used by legacy MoveCalculator and main UI
array<array<Piece>>@ board;
PieceColor currentTurn = PieceColor::White;
int selectedRow = -1;
int selectedCol = -1;
array<Move@> moveHistory;
bool gameOver = false;
string gameResult = "";

void InitializeGlobals() {
    @board = array<array<Piece>>(8);
    for (int r = 0; r < 8; r++) {
        board[r].Resize(8);
    }
    currentTurn = PieceColor::White;
    selectedRow = -1;
    selectedCol = -1;
    moveHistory.Resize(0);
    gameOver = false;
    gameResult = "";
}
