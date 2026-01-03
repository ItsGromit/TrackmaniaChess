class Move {
    int fromRow;
    int fromCol;
    int toRow;
    int toCol;
    Piece capturePiece;
    string san = "";  // Standard Algebraic Notation (e.g., "Nf3", "exd5", "O-O")

    Move(int fr, int fc, int tr, int tc) {
        fromRow = fr;
        fromCol = fc;
        toRow = tr;
        toCol = tc;
    }
}