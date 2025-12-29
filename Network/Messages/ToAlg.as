string ToAlg(int row, int col) {
    string file = (col >= 0 && col < 8) ? FILES[col] : "?";
    int rank = 8 - row;
    return file + rank;
}