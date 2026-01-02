class Move {
    int fromRow;
    int fromCol;
    int toRow;
    int toCol;
    Piece capturePiece;

    Move(int fr, int fc, int tr, int tc) {
        fromRow = fr;
        fromCol = fc;
        toRow = tr;
        toCol = tc;
    }
}