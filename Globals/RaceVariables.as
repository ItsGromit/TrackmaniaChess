// race variables
uint64 raceStartedAt = 0;
bool playerFinishedRace = false;
int playerRaceTime = -1;
bool playerDNF = false;

void InitializeGlobals() {
    @board = array<array<Piece>>(8);
    for (int r = 0; r < 8; r++) {
        board[r].Resize(8);
        for (int c = 0; c < 8; c++) board[r][c] = Piece();
    }
    currentTurn = PieceColor::White;
    selectedRow = selectedCol = -1;
    moveHistory.Resize(0);
    gameOver = false;
    gameResult = "";
}