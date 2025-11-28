// global plugin variables
bool showWindow = false;
bool windowResizeable = false;
enum MenuTab {
    Home,
    Play,
    Settings
}
MenuTab currentMenuTab = MenuTab::Home;
vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
float defaultHeight = screenSize.y * 0.6f;
float defaultWidth = defaultHeight * 1.1f;

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

// server variables
string ui_serverHost = "";
string ui_serverPort = "";

// race variables
uint64 raceStartedAt = 0;

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

// Position class
class Position {
    int row;
    int col;
    Position() {}
    Position(int r, int c) {
        row = r;
        col = c;
    }
    bool opEquals(const Position &in o) const {
        return row == o.row && col == o.col;
    }
}

// FEN
void ApplyFEN(const string &in fen, const string &in turnLetter="w") {
    if (board is null || board.Length != 8) InitializeGlobals();

    auto parts = fen.Split(" ");
    if (parts.Length == 0) return;
    auto ranks = parts[0].Split("/");
    if (ranks.Length != 8) return;

    // clear
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++)
            board[r][c] = Piece();
    

    // ranks come 8..1
    for (int r = 0; r < 8; r++) {
        string seg = ranks[r];
        int c = 0;
        for (int i = 0; i < int(seg.Length) && c < 8; i++) {
            string ch = seg.SubStr(i, 1);
            if (ch >= "1" && ch <= "8") {
                int empty = Text::ParseInt(ch);
                for (int k = 0; k < empty && c < 8; k++) board[r][c++] = Piece();
                continue;
            }
            // piece
            board[r][c++] = PieceFromFENChar(ch);
        }
    }
    // active color
    currentTurn = (turnLetter.ToLower() == "b") ? PieceColor::Black : PieceColor::White;
    
}

// Accept single-character string; easier in AngelScript than uint codepoints
Piece PieceFromFENChar(const string &in ch) {
    if (ch.Length == 0) return Piece();
    bool white = (ch == ch.ToUpper());
    string lower = ch.ToLower();

    PieceType t = PieceType::Pawn;
    if (lower == "k") t = PieceType::King;
    else if (lower == "q") t = PieceType::Queen;
    else if (lower == "r") t = PieceType::Rook;
    else if (lower == "b") t = PieceType::Bishop;
    else if (lower == "n") t = PieceType::Knight;
    else if (lower == "p") t = PieceType::Pawn;

    return Piece(t, white ? PieceColor::White : PieceColor::Black);
}
