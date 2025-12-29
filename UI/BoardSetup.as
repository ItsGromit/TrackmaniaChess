void GetLastItemCorners(vec2 pMin, vec2 pMax) {
    auto r = UI::GetItemRect();

    pMin = vec2(r.x, r.y);
    pMax = vec2(r.x + r.z, r.y + r.w);
}

void DrawCenteredImageOverLastItem(UI::Texture@ tex, float padPx = 6.0f) {

    vec4 r = UI::GetItemRect();

    auto dl = UI::GetWindowDrawList();

    if (tex is null) return;

    vec2 pos = vec2(r.x, r.y);
    vec2 size = vec2(r.z, r.w);

    vec2 innerPos = pos + vec2(padPx, padPx);
    vec2 innerSize = size - vec2(2.0f * padPx, 2.0f * padPx);

    float side = Math::Min(innerSize.x, innerSize.y);
    vec2 imgPos = innerPos + (innerSize - vec2(side, side)) * 0.5f;
    vec2 imgSize = vec2(side, side);

    dl.AddImage(tex, imgPos, imgSize, 0xFFFFFFFF);
}

// Initialize board
void InitializeBoard() {
    board.Resize(8);
    for (int i = 0; i < 8; i++) {
        board[i].Resize(8);
    }
    // Clear board
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            board[row][col] = Piece();
        }
    }
    // Set up white pieces
    board[7][0] = Piece(PieceType::Rook, PieceColor::White);
    board[7][1] = Piece(PieceType::Knight, PieceColor::White);
    board[7][2] = Piece(PieceType::Bishop, PieceColor::White);
    board[7][3] = Piece(PieceType::Queen, PieceColor::White);
    board[7][4] = Piece(PieceType::King, PieceColor::White);
    board[7][5] = Piece(PieceType::Bishop, PieceColor::White);
    board[7][6] = Piece(PieceType::Knight, PieceColor::White);
    board[7][7] = Piece(PieceType::Rook, PieceColor::White);
    for (int col = 0; col < 8; col++) {
        board[6][col] = Piece(PieceType::Pawn, PieceColor::White);
    }
    // Set up black pieces
    board[0][0] = Piece(PieceType::Rook, PieceColor::Black);
    board[0][1] = Piece(PieceType::Knight, PieceColor::Black);
    board[0][2] = Piece(PieceType::Bishop, PieceColor::Black);
    board[0][3] = Piece(PieceType::Queen, PieceColor::Black);
    board[0][4] = Piece(PieceType::King, PieceColor::Black);
    board[0][5] = Piece(PieceType::Bishop, PieceColor::Black);
    board[0][6] = Piece(PieceType::Knight, PieceColor::Black);
    board[0][7] = Piece(PieceType::Rook, PieceColor::Black);
    for (int col = 0; col < 8; col++) {
        board[1][col] = Piece(PieceType::Pawn, PieceColor::Black);
    }
}

Piece GetPiece(int row, int col) {
    return board[row][col];
}

void MovePiece(Position@ from, Position@ to) {
    board[to.row][to.col] = board[from.row][from.col];
    board[from.row][from.col] = Piece();
}

array<array<Piece>>@ GetBoard() {
    return board;
}