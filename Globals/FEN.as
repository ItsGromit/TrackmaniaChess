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

    // Parse castling rights (part 2 of FEN)
    whiteCanCastleKingside = false;
    whiteCanCastleQueenside = false;
    blackCanCastleKingside = false;
    blackCanCastleQueenside = false;

    if (parts.Length > 2) {
        string castling = parts[2];
        if (castling.Contains("K")) whiteCanCastleKingside = true;
        if (castling.Contains("Q")) whiteCanCastleQueenside = true;
        if (castling.Contains("k")) blackCanCastleKingside = true;
        if (castling.Contains("q")) blackCanCastleQueenside = true;
    } else {
        // Default: both sides can castle
        whiteCanCastleKingside = true;
        whiteCanCastleQueenside = true;
        blackCanCastleKingside = true;
        blackCanCastleQueenside = true;
    }

    // Parse en passant target square (part 3 of FEN)
    enPassantTarget = "";
    enPassantRow = -1;
    enPassantCol = -1;

    if (parts.Length > 3 && parts[3] != "-") {
        enPassantTarget = parts[3];
        // Convert algebraic notation to row/col
        if (enPassantTarget.Length >= 2) {
            int file = int(enPassantTarget.SubStr(0, 1)[0]) - int("a"[0]);
            int rank = Text::ParseInt(enPassantTarget.SubStr(1, 1));
            if (file >= 0 && file < 8 && rank >= 1 && rank <= 8) {
                enPassantCol = file;
                enPassantRow = 8 - rank;  // Convert to 0-based row index
            }
        }
    }
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