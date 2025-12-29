// Texture assets
class PieceAssets {
    // White pieces
    UI::Texture@ wK; UI::Texture@ wQ; UI::Texture@ wR; UI::Texture@ wB; UI::Texture@ wN; UI::Texture@ wP;
    // Black pieces
    UI::Texture@ bK; UI::Texture@ bQ; UI::Texture@ bR; UI::Texture@ bB; UI::Texture@ bN; UI::Texture@ bP;

    // Base URL for texture downloads
    string BASE_URL = "https://trackmaniachess.up.railway.app/assets/";

    void Load() {
        // Loading textures from remote server
        // White
        @wK = LoadTex("king_white.png");
        @wQ = LoadTex("queen_white.png");
        @wR = LoadTex("rook_white.png");
        @wB = LoadTex("bishop_white.png");
        @wN = LoadTex("knight_white.png");
        @wP = LoadTex("pawn_white.png");
        // Black
        @bK = LoadTex("king_black.png");
        @bQ = LoadTex("queen_black.png");
        @bR = LoadTex("rook_black.png");
        @bB = LoadTex("bishop_black.png");
        @bN = LoadTex("knight_black.png");
        @bP = LoadTex("pawn_black.png");

        trace("[PieceAssets] loaded");
    }
    // Assign textures to pieces
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
    // internal texture buffer - downloads from server and caches locally
    private UI::Texture@ LoadTex(const string &in filename) {
        // Check if texture is already cached locally
        string cachePath = IO::FromStorageFolder("textures/" + filename);

        // Try to load from cache first
        if (IO::FileExists(cachePath)) {
            trace("[PieceAssets] Loading from cache: " + filename);
            IO::FileSource fs(cachePath);
            if (fs.Size() > 0) {
                auto buf = fs.Read(fs.Size());
                auto tex = UI::LoadTexture(buf);
                if (tex !is null) return tex;
            }
        }

        // Download from server
        trace("[PieceAssets] Downloading: " + filename);
        string url = BASE_URL + filename;

        Net::HttpRequest@ req = Net::HttpGet(url);
        while (!req.Finished()) yield();

        if (req.ResponseCode() != 200) {
            warn("[PieceAssets] Failed to download " + filename + " (HTTP " + req.ResponseCode() + ")");
            return null;
        }

        auto buf = req.Buffer();
        if (buf.GetSize() == 0) {
            warn("[PieceAssets] Empty response for: " + filename);
            return null;
        }

        // Cache the downloaded file
        IO::CreateFolder(IO::FromStorageFolder("textures"), true);
        IO::File file(cachePath, IO::FileMode::Write);
        file.Write(buf);
        file.Close();
        trace("[PieceAssets] Cached: " + filename);

        // Load texture from buffer
        auto tex = UI::LoadTexture(buf);
        if (tex is null) {
            warn("[PieceAssets] Failed to decode: " + filename);
        }
        return tex;
    }
}

PieceAssets gPieces;