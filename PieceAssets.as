// PieceAssets.as
// Everything related to chess pieces (types, struct, textures, mapping) lives here.

// ------------------- Types -------------------
enum PieceType {
    Empty = 0, 
    King = 1, 
    Queen = 2, 
    Rook = 3, 
    Bishop = 4, 
    Knight = 5, 
    Pawn = 6
    }
enum PieceColor {
    White = 0,
    Black = 1
    }

class Piece {
    PieceType type;
    PieceColor color;
    Piece() { type = PieceType::Empty; color = PieceColor::White; }
    Piece(PieceType t, PieceColor c) { type = t; color = c; }
    bool IsEmpty() const { return type == PieceType::Empty; }
}

// Small helper so other files can create pieces without knowing internals.
Piece MakePiece(PieceType t, PieceColor c) { return Piece(t, c); }

// ------------------- Assets -------------------
class PieceAssets {
    // White
    UI::Texture@ wK; UI::Texture@ wQ; UI::Texture@ wR; UI::Texture@ wB; UI::Texture@ wN; UI::Texture@ wP;
    // Black
    UI::Texture@ bK; UI::Texture@ bQ; UI::Texture@ bR; UI::Texture@ bB; UI::Texture@ bN; UI::Texture@ bP;

    void Load() {
        // Paths are RELATIVE to plugin root (where info.toml lives). No leading slash.
        @wK = LoadTex("assets/king_white.png");
        @wQ = LoadTex("assets/queen_white.png");
        @wR = LoadTex("assets/rook_white.png");
        @wB = LoadTex("assets/bishop_white.png");
        @wN = LoadTex("assets/knight_white.png");
        @wP = LoadTex("assets/pawn_white.png");

        @bK = LoadTex("assets/king_black.png");
        @bQ = LoadTex("assets/queen_black.png");
        @bR = LoadTex("assets/rook_black.png");
        @bB = LoadTex("assets/bishop_black.png");
        @bN = LoadTex("assets/knight_black.png");
        @bP = LoadTex("assets/pawn_black.png");

        trace("[PieceAssets] Load() done");
    }

    UI::Texture@ GetTexture(const Piece &in p) const {
        if (p.type == PieceType::Empty) return null;

        if (p.color == PieceColor::White) {
            switch (p.type) {
                case PieceType::King:   return wK;
                case PieceType::Queen:  return wQ;
                case PieceType::Rook:   return wR;
                case PieceType::Bishop: return wB;
                case PieceType::Knight: return wN;
                case PieceType::Pawn:   return wP;
            }
        } else { // Black
            switch (p.type) {
                case PieceType::King:   return bK;
                case PieceType::Queen:  return bQ;
                case PieceType::Rook:   return bR;
                case PieceType::Bishop: return bB;
                case PieceType::Knight: return bN;
                case PieceType::Pawn:   return bP;
            }
        }
        return null;
    }

    // ---------- internals ----------
    private UI::Texture@ LoadTex(const string &in relPath) {
        IO::FileSource fs(relPath);
        if (fs.Size() <= 0) {
            warn("[PieceAssets] Missing or empty: " + relPath);
            return null;
        }
        auto buf = fs.Read(fs.Size());
        auto tex = UI::LoadTexture(buf);
        if (tex is null) warn("[PieceAssets] Failed to decode: " + relPath);
        return tex;
    }
}

// A single global instance so other files can just call into it.
PieceAssets gPieces;

// Convenience forwarders so other files don’t need to touch gPieces directly.
void LoadPieceAssets() { gPieces.Load(); }
UI::Texture@ GetPieceTexture(const Piece &in p) { return gPieces.GetTexture(p); }
