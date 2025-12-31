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

// castling rights (format: "KQkq" - White kingside, White queenside, Black kingside, Black queenside)
bool whiteCanCastleKingside = true;
bool whiteCanCastleQueenside = true;
bool blackCanCastleKingside = true;
bool blackCanCastleQueenside = true;

// en passant target square (algebraic notation like "e3", or "" if none)
string enPassantTarget = "";
int enPassantRow = -1;
int enPassantCol = -1;

// pawn promotion tracking
bool isPendingPromotion = false;
int promotionRow = -1;
int promotionCol = -1;

// map info tooltip tracking (right-click to show)
int mapInfoTooltipRow = -1;
int mapInfoTooltipCol = -1;

// rematch variables
bool rematchRequestReceived = false;
bool rematchRequestSent = false;

// re-roll variables
bool rerollRequestReceived = false;
bool rerollRequestSent = false;