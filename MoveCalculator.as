// Get piece symbol
string GetPieceSymbol(Piece piece) {
    if (piece.IsEmpty()) return "";
    
    string symbol = "";
    switch (piece.type) {
        case PieceType::King: symbol = "K"; break;
        case PieceType::Queen: symbol = "Q"; break;
        case PieceType::Rook: symbol = "R"; break;
        case PieceType::Bishop: symbol = "B"; break;
        case PieceType::Knight: symbol = "N"; break;
        case PieceType::Pawn: symbol = "P"; break;
    }
    
    return symbol;
}

// Get piece Unicode symbol
string GetPieceUnicode(Piece piece) {
    if (piece.IsEmpty()) return "";
    
    if (piece.color == PieceColor::White) {
        switch (piece.type) {
            case PieceType::King: return "/assets/white_king.png";
            case PieceType::Queen: return "/assets/white_queen.png";
            case PieceType::Rook: return "/assets/white_rook.png";
            case PieceType::Bishop: return "/assets/white_bishop.png";
            case PieceType::Knight: return "/assets/white_knight.png";
            case PieceType::Pawn: return "/assets/white_pawn.png";
        }
    } else {
        switch (piece.type) {
            case PieceType::King: return "/assets/black_king.png";
            case PieceType::Queen: return "/assets/black_queen.png";
            case PieceType::Rook: return "/assets/black_rook.png";
            case PieceType::Bishop: return "/assets/black_bishop.png";
            case PieceType::Knight: return "/assets/black_knight.png";
            case PieceType::Pawn: return "/assets/black_pawn.png";
        }
    }
    return "";
}

// Check if a move is valid
bool IsValidMove(int fromRow, int fromCol, int toRow, int toCol) {
    // Basic bounds checking
    if (toRow < 0 || toRow >= 8 || toCol < 0 || toCol >= 8) return false;
    if (fromRow == toRow && fromCol == toCol) return false;
    
    Piece piece = board[fromRow][fromCol];
    if (piece.IsEmpty()) return false;
    
    // Can't capture own piece
    Piece target = board[toRow][toCol];
    if (!target.IsEmpty() && target.color == piece.color) return false;
    
    int rowDiff = toRow - fromRow;
    int colDiff = toCol - fromCol;
    
    switch (piece.type) {
        case PieceType::Pawn:
            return IsValidPawnMove(fromRow, fromCol, toRow, toCol, piece.color);
        case PieceType::Knight:
            return (Math::Abs(rowDiff) == 2 && Math::Abs(colDiff) == 1) ||
                   (Math::Abs(rowDiff) == 1 && Math::Abs(colDiff) == 2);
        case PieceType::Bishop:
            return IsValidBishopMove(fromRow, fromCol, toRow, toCol);
        case PieceType::Rook:
            return IsValidRookMove(fromRow, fromCol, toRow, toCol);
        case PieceType::Queen:
            return IsValidBishopMove(fromRow, fromCol, toRow, toCol) ||
                   IsValidRookMove(fromRow, fromCol, toRow, toCol);
        case PieceType::King:
            return Math::Abs(rowDiff) <= 1 && Math::Abs(colDiff) <= 1;
    }
    
    return false;
}

bool IsValidPawnMove(int fromRow, int fromCol, int toRow, int toCol, PieceColor color) {
    int direction = (color == PieceColor::White) ? -1 : 1;
    int startRow = (color == PieceColor::White) ? 6 : 1;
    
    int rowDiff = toRow - fromRow;
    int colDiff = toCol - fromCol;
    
    // Move forward one square
    if (colDiff == 0 && rowDiff == direction) {
        return board[toRow][toCol].IsEmpty();
    }
    
    // Move forward two squares from start
    if (colDiff == 0 && rowDiff == 2 * direction && fromRow == startRow) {
        return board[toRow][toCol].IsEmpty() && 
               board[fromRow + direction][fromCol].IsEmpty();
    }
    
    // Capture diagonally
    if (Math::Abs(colDiff) == 1 && rowDiff == direction) {
        return !board[toRow][toCol].IsEmpty() && 
               board[toRow][toCol].color != color;
    }
    
    return false;
}

bool IsValidRookMove(int fromRow, int fromCol, int toRow, int toCol) {
    if (fromRow != toRow && fromCol != toCol) return false;
    
    return IsPathClear(fromRow, fromCol, toRow, toCol);
}

bool IsValidBishopMove(int fromRow, int fromCol, int toRow, int toCol) {
    int rowDiff = Math::Abs(toRow - fromRow);
    int colDiff = Math::Abs(toCol - fromCol);
    
    if (rowDiff != colDiff) return false;
    
    return IsPathClear(fromRow, fromCol, toRow, toCol);
}

bool IsPathClear(int fromRow, int fromCol, int toRow, int toCol) {
    int rowStep = 0;
    int colStep = 0;
    
    if (toRow > fromRow) rowStep = 1;
    else if (toRow < fromRow) rowStep = -1;
    
    if (toCol > fromCol) colStep = 1;
    else if (toCol < fromCol) colStep = -1;
    
    int currentRow = fromRow + rowStep;
    int currentCol = fromCol + colStep;
    
    while (currentRow != toRow || currentCol != toCol) {
        if (!board[currentRow][currentCol].IsEmpty()) {
            return false;
        }
        currentRow += rowStep;
        currentCol += colStep;
    }
    
    return true;
}

// Find king position
array<int> FindKing(PieceColor color) {
    array<int> pos = {-1, -1};
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            Piece p = board[row][col];
            if (p.type == PieceType::King && p.color == color) {
                pos[0] = row;
                pos[1] = col;
                return pos;
            }
        }
    }
    return pos;
}

// Check if king is in check
bool IsInCheck(PieceColor color) {
    array<int> kingPos = FindKing(color);
    if (kingPos[0] == -1) return false;
    
    // Check if any opponent piece can attack the king
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            Piece p = board[row][col];
            if (!p.IsEmpty() && p.color != color) {
                if (IsValidMove(row, col, kingPos[0], kingPos[1])) {
                    return true;
                }
            }
        }
    }
    return false;
}

// Check if there are any valid moves
bool HasValidMoves(PieceColor color) {
    for (int fromRow = 0; fromRow < 8; fromRow++) {
        for (int fromCol = 0; fromCol < 8; fromCol++) {
            Piece p = board[fromRow][fromCol];
            if (!p.IsEmpty() && p.color == color) {
                for (int toRow = 0; toRow < 8; toRow++) {
                    for (int toCol = 0; toCol < 8; toCol++) {
                        if (IsValidMove(fromRow, fromCol, toRow, toCol)) {
                            // Try the move
                            Piece temp = board[toRow][toCol];
                            board[toRow][toCol] = board[fromRow][fromCol];
                            board[fromRow][fromCol] = Piece();
                            
                            bool inCheck = IsInCheck(color);
                            
                            // Undo the move
                            board[fromRow][fromCol] = board[toRow][toCol];
                            board[toRow][toCol] = temp;
                            
                            if (!inCheck) return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

// Make a move
void MakeMove(int fromRow, int fromCol, int toRow, int toCol) {
    Move move(fromRow, fromCol, toRow, toCol);
    move.capturedPiece = board[toRow][toCol];
    
    board[toRow][toCol] = board[fromRow][fromCol];
    board[fromRow][fromCol] = Piece();
    
    // Check for pawn promotion
    if (board[toRow][toCol].type == PieceType::Pawn) {
        if ((board[toRow][toCol].color == PieceColor::White && toRow == 0) ||
            (board[toRow][toCol].color == PieceColor::Black && toRow == 7)) {
            board[toRow][toCol].type = PieceType::Queen; // Auto-promote to queen
        }
    }
    
    moveHistory.InsertLast(move);
    
    // Switch turns
    currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;
    
    // Check for checkmate or stalemate
    if (!HasValidMoves(currentTurn)) {
        gameOver = true;
        if (IsInCheck(currentTurn)) {
            string winner = (currentTurn == PieceColor::White) ? "Black" : "White";
            gameResult = "Checkmate! " + winner + " wins!";
        } else {
            gameResult = "Stalemate! Draw.";
        }
    }
}

void HandleSquareClick(int row, int col) {
    Piece clickedPiece = board[row][col];
    
    // If no piece is selected
    if (selectedRow == -1) {
        // Select piece if it belongs to current player
        if (!clickedPiece.IsEmpty() && clickedPiece.color == currentTurn) {
            selectedRow = row;
            selectedCol = col;
        }
    } else {
        // Try to move the selected piece
        if (IsValidMove(selectedRow, selectedCol, row, col)) {
            // Check if move would leave king in check
            Piece temp = board[row][col];
            board[row][col] = board[selectedRow][selectedCol];
            board[selectedRow][selectedCol] = Piece();
            
            bool wouldBeInCheck = IsInCheck(currentTurn);
            
            board[selectedRow][selectedCol] = board[row][col];
            board[row][col] = temp;
            
            if (!wouldBeInCheck) {
                MakeMove(selectedRow, selectedCol, row, col);
                selectedRow = -1;
                selectedCol = -1;
            }
        } else {
            // Deselect or select new piece
            if (!clickedPiece.IsEmpty() && clickedPiece.color == currentTurn) {
                selectedRow = row;
                selectedCol = col;
            } else {
                selectedRow = -1;
                selectedCol = -1;
            }
        }
    }
}

void UndoLastMove() {
    if (moveHistory.Length == 0) return;
    
    Move@ lastMove = moveHistory[moveHistory.Length - 1];
    
    board[lastMove.fromRow][lastMove.fromCol] = board[lastMove.toRow][lastMove.toCol];
    board[lastMove.toRow][lastMove.toCol] = lastMove.capturedPiece;
    
    moveHistory.RemoveLast();
    currentTurn = (currentTurn == PieceColor::White) ? PieceColor::Black : PieceColor::White;
    gameOver = false;
    gameResult = "";
    selectedRow = -1;
    selectedCol = -1;
}

string GetColumnName(int col) {
    string[] columns = {"a", "b", "c", "d", "e", "f", "g", "h"};
    return columns[col];
}
