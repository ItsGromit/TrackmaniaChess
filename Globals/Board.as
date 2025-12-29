// global board variables
array<array<Piece>>@ board;
bool gPiecesLoaded = false;

// move history array
array<Move@> moveHistory;

// game variables
bool gameOver = false;
string gameResult = "";
int currentTurn = PieceColor::White;
int selectedRow;
int selectedCol;
int gSelR = -1;
int gSelC = -1;

// rematch variables
bool rematchRequestReceived = false;
bool rematchRequestSent = false;

// re-roll variables
bool rerollRequestReceived = false;
bool rerollRequestSent = false;