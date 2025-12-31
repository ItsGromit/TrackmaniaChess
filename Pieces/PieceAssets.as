// Texture assets
class PieceAssets {
    // White pieces
    UI::Texture@ wK; UI::Texture@ wQ; UI::Texture@ wR; UI::Texture@ wB; UI::Texture@ wN; UI::Texture@ wP;
    // Black pieces
    UI::Texture@ bK; UI::Texture@ bQ; UI::Texture@ bR; UI::Texture@ bB; UI::Texture@ bN; UI::Texture@ bP;

    // Base URL for texture downloads
    string BASE_URL = "https://tmchessassets-production.up.railway.app/assets/";

    // Loading tracking
    bool isLoading = false;
    int piecesLoaded = 0;
    int totalPieces = 12;

    void Load() {
        isLoading = true;
        piecesLoaded = 0;

        // Loading textures from remote server
        // White
        @wK = LoadTex("king_white.png"); piecesLoaded++;
        @wQ = LoadTex("queen_white.png"); piecesLoaded++;
        @wR = LoadTex("rook_white.png"); piecesLoaded++;
        @wB = LoadTex("bishop_white.png"); piecesLoaded++;
        @wN = LoadTex("knight_white.png"); piecesLoaded++;
        @wP = LoadTex("pawn_white.png"); piecesLoaded++;
        // Black
        @bK = LoadTex("king_black.png"); piecesLoaded++;
        @bQ = LoadTex("queen_black.png"); piecesLoaded++;
        @bR = LoadTex("rook_black.png"); piecesLoaded++;
        @bB = LoadTex("bishop_black.png"); piecesLoaded++;
        @bN = LoadTex("knight_black.png"); piecesLoaded++;
        @bP = LoadTex("pawn_black.png"); piecesLoaded++;

        isLoading = false;
        print("[PieceAssets] All piece assets loaded successfully");
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
    // Clears all piece textures from memory and cache
    void ClearCache() {
        print("[PieceAssets] Clearing piece texture cache...");

        // Clear memory references
        @wK = null; @wQ = null; @wR = null; @wB = null; @wN = null; @wP = null;
        @bK = null; @bQ = null; @bR = null; @bB = null; @bN = null; @bP = null;

        // Delete cached files
        string texturesFolder = IO::FromStorageFolder("textures");
        if (IO::FolderExists(texturesFolder)) {
            array<string> files = {
                "king_white.png", "queen_white.png", "rook_white.png",
                "bishop_white.png", "knight_white.png", "pawn_white.png",
                "king_black.png", "queen_black.png", "rook_black.png",
                "bishop_black.png", "knight_black.png", "pawn_black.png"
            };

            int deletedCount = 0;
            for (uint i = 0; i < files.Length; i++) {
                string filePath = texturesFolder + "/" + files[i];
                if (IO::FileExists(filePath)) {
                    IO::Delete(filePath);
                    deletedCount++;
                }
            }
            print("[PieceAssets] Deleted " + deletedCount + " cached piece textures");
        }

        print("[PieceAssets] Cache cleared");
    }

    // internal texture buffer - downloads from server and caches locally
    private UI::Texture@ LoadTex(const string &in filename) {
        // Check if texture is already cached locally
        string cachePath = IO::FromStorageFolder("textures/" + filename);

        // Try to load from cache first
        if (IO::FileExists(cachePath)) {
            trace("[PieceAssets] Loading from cache: " + filename);
            try {
                IO::File file(cachePath, IO::FileMode::Read);
                if (file.Size() > 0) {
                    auto buf = file.Read(file.Size());
                    file.Close();
                    auto tex = UI::LoadTexture(buf);
                    if (tex !is null) return tex;
                }
                file.Close();
            } catch {
                warn("[PieceAssets] Failed to load cached file, deleting: " + filename);
                // Delete corrupted cache file
                IO::Delete(cachePath);
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