enum PieceType {
    Empty = 0,
    Pawn = 1,
    Rook = 2,
    Knight = 3,
    Bishop = 4,
    Queen = 5,
    King = 6
}

enum PieceColor {
    White = 0,
    Black = 1
}

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

    bool IsEmpty() {
        return type == PieceType::Empty;
    }
}

class Position {
        int row;
        int col;
        
        Position(int r, int c) {
            row = r;
            col = c;
        }
    }