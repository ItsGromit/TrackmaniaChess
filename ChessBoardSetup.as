class ChessBoardSetup {

        // Global game state
        array<array<Piece>> board;
        PieceColor currentTurn = PieceColor::White;
        bool showWindow = true;
        int selectedRow = -1;
        int selectedCol = -1;
        array<Move@> moveHistory;
        bool gameOver = false;
        string gameResult = "";
        
        void ChessBoard() {
            board.Resize(8);
            for (int row = 0; row < 8; row++) {
                board[row].Resize(8);
            }
        }
        
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
            
            board[7][0] = Piece(PieceType::Rook, PieceColor::White);
            board[7][1] = Piece(PieceType::Knight, PieceColor::White);
            board[7][2] = Piece(PieceType::Bishop, PieceColor::White);
            board[7][3] = Piece(PieceType::Queen, PieceColor::White);
            board[7][4] = Piece(PieceType::King, PieceColor::White);
            board[7][5] = Piece(PieceType::Bishop, PieceColor::White);
            board[7][6] = Piece(PieceType::Knight, PieceColor::White);
            board[7][7] = Piece(PieceType::Rook, PieceColor::White);
            // Set up white pieces (bottom, rows 6-7)
            for (int col = 0; col < 8; col++) {
                board[6][col] = Piece(PieceType::Pawn, PieceColor::White);
            }
            
            board[0][0] = Piece(PieceType::Rook, PieceColor::Black);
            board[0][1] = Piece(PieceType::Knight, PieceColor::Black);
            board[0][2] = Piece(PieceType::Bishop, PieceColor::Black);
            board[0][3] = Piece(PieceType::Queen, PieceColor::Black);
            board[0][4] = Piece(PieceType::King, PieceColor::Black);
            board[0][5] = Piece(PieceType::Bishop, PieceColor::Black);
            board[0][6] = Piece(PieceType::Knight, PieceColor::Black);
            board[0][7] = Piece(PieceType::Rook, PieceColor::Black);
            // Set up black pieces (top, rows 0-1)
            for (int col = 0; col < 8; col++) {
                board[1][col] = Piece(PieceType::Pawn, PieceColor::Black);
            }
        }
        
        Piece@ GetPiece(int row, int col) {
            return board[row][col];
        }
        
        void MovePiece(Position@ from, Position@ to) {
            board[to.row][to.col] = board[from.row][from.col];
            board[from.row][from.col] = Piece();
        }

        array<array<Piece>>@ GetBoard() {
            return board;
        }
    }