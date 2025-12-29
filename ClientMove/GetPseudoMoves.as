void GetPseudoMoves(int fr, int fc, array<Int2>@ moves) {
    moves.Resize(0);
    if (!InBounds(fr, fc)) return;
    Piece p = board[fr][fc];
    if (p.IsEmpty()) return;

    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            if (IsValidMove(fr, fc, r, c)) moves.InsertLast(Int2(r, c));
        }
    }
}