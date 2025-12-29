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