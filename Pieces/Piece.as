class Piece {
    PieceType type;
    PieceColor color;
    Piece() {
        type = PieceType::Empty;
        color = PieceColor::White;
    }
    Piece(PieceType t, PieceColor c) {
        type = t;
        color = c;
    }
    bool IsEmpty() const {
        return type == PieceType::Empty;
    }
}
Piece MakePiece(PieceType t, PieceColor c) {
    return Piece(t, c);
}