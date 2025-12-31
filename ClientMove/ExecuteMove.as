/**
 * Executes a chess move including special moves (castling, en passant, promotion)
 * @param fromRow Source row
 * @param fromCol Source column
 * @param toRow Destination row
 * @param toCol Destination column
 * @param promotionPiece The piece type to promote to (for pawn promotion), default Queen
 */
void ExecuteChessMove(int fromRow, int fromCol, int toRow, int toCol, PieceType promotionPiece = PieceType::Queen) {
    Piece movingPiece = board[fromRow][fromCol];

    // Handle castling
    if (movingPiece.type == PieceType::King && Math::Abs(toCol - fromCol) == 2) {
        // Move the king
        board[toRow][toCol] = movingPiece;
        board[fromRow][fromCol] = Piece();

        // Move the rook
        if (toCol == 6) {
            // Kingside castling - move rook from h-file to f-file
            board[toRow][5] = board[toRow][7];
            board[toRow][7] = Piece();
        } else if (toCol == 2) {
            // Queenside castling - move rook from a-file to d-file
            board[toRow][3] = board[toRow][0];
            board[toRow][0] = Piece();
        }
    }
    // Handle en passant capture
    else if (movingPiece.type == PieceType::Pawn && toCol != fromCol && board[toRow][toCol].IsEmpty()) {
        // This is an en passant capture
        board[toRow][toCol] = movingPiece;
        board[fromRow][fromCol] = Piece();

        // Remove the captured pawn (it's on the same row as the moving pawn, not the destination row)
        board[fromRow][toCol] = Piece();
    }
    // Handle pawn promotion (including promotion captures)
    else if (movingPiece.type == PieceType::Pawn && (toRow == 0 || toRow == 7)) {
        // Promote the pawn
        board[toRow][toCol] = Piece(promotionPiece, movingPiece.color);
        board[fromRow][fromCol] = Piece();
    }
    // Normal move (including normal captures)
    else {
        board[toRow][toCol] = movingPiece;
        board[fromRow][fromCol] = Piece();
    }

    // Update en passant target square
    enPassantTarget = "";
    enPassantRow = -1;
    enPassantCol = -1;

    if (movingPiece.type == PieceType::Pawn && Math::Abs(toRow - fromRow) == 2) {
        // Pawn moved two squares, set en passant target
        int targetRow = (fromRow + toRow) / 2;  // Middle square
        enPassantRow = targetRow;
        enPassantCol = fromCol;
        enPassantTarget = ToAlg(targetRow, fromCol);
    }

    // Update castling rights based on piece moves
    if (movingPiece.type == PieceType::King) {
        if (movingPiece.color == PieceColor::White) {
            whiteCanCastleKingside = false;
            whiteCanCastleQueenside = false;
        } else {
            blackCanCastleKingside = false;
            blackCanCastleQueenside = false;
        }
    }

    if (movingPiece.type == PieceType::Rook) {
        // White rooks
        if (fromRow == 7 && fromCol == 7) whiteCanCastleKingside = false;
        if (fromRow == 7 && fromCol == 0) whiteCanCastleQueenside = false;
        // Black rooks
        if (fromRow == 0 && fromCol == 7) blackCanCastleKingside = false;
        if (fromRow == 0 && fromCol == 0) blackCanCastleQueenside = false;
    }

    // Also remove castling rights if a rook is captured
    if (toRow == 7 && toCol == 7) whiteCanCastleKingside = false;
    if (toRow == 7 && toCol == 0) whiteCanCastleQueenside = false;
    if (toRow == 0 && toCol == 7) blackCanCastleKingside = false;
    if (toRow == 0 && toCol == 0) blackCanCastleQueenside = false;
}
