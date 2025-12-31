// ============================================================================
// LOGO ASSET LOADER
// ============================================================================
// Handles loading and caching the TMChess logo

// Logo texture
UI::Texture@ logoTexture = null;

// Base URL for asset downloads
const string LOGO_BASE_URL = "https://tmchessassets-production.up.railway.app/assets/";

// Loading tracking
bool isLoadingLogo = false;

/**
 * Loads the TMChess logo from cache or downloads it
 */
void LoadLogo() {
    isLoadingLogo = true;
    @logoTexture = LoadLogoTexture("TMChess.png");
    if (logoTexture !is null) {
        print("[Logo] TMChess logo loaded successfully");
    }
    isLoadingLogo = false;
}

/**
 * Returns the logo texture (null if not loaded)
 */
UI::Texture@ GetLogoTexture() {
    return logoTexture;
}

/**
 * Internal function to load texture from cache or download
 */
UI::Texture@ LoadLogoTexture(const string &in filename) {
    // Check if texture is already cached locally
    string cachePath = IO::FromStorageFolder("textures/" + filename);

    // Try to load from cache first
    if (IO::FileExists(cachePath)) {
        trace("[Logo] Loading from cache: " + filename);
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
            warn("[Logo] Failed to load cached file, deleting: " + filename);
            // Delete corrupted cache file
            IO::Delete(cachePath);
        }
    }

    // Download from server
    trace("[Logo] Downloading: " + filename);
    string url = LOGO_BASE_URL + filename;

    Net::HttpRequest@ req = Net::HttpGet(url);
    while (!req.Finished()) yield();

    if (req.ResponseCode() != 200) {
        warn("[Logo] Failed to download " + filename + " (HTTP " + req.ResponseCode() + ")");
        return null;
    }

    auto buf = req.Buffer();
    if (buf.GetSize() == 0) {
        warn("[Logo] Empty response for: " + filename);
        return null;
    }

    // Cache the downloaded file
    IO::CreateFolder(IO::FromStorageFolder("textures"), true);
    IO::File file(cachePath, IO::FileMode::Write);
    file.Write(buf);
    file.Close();
    trace("[Logo] Cached: " + filename);

    // Load texture from buffer
    auto tex = UI::LoadTexture(buf);
    if (tex is null) {
        warn("[Logo] Failed to decode: " + filename);
    }
    return tex;
}

/**
 * Clears the logo from memory and cache
 */
void ClearLogoCache() {
    if (developerMode) print("[Logo] Clearing logo cache...");

    @logoTexture = null;

    string cachePath = IO::FromStorageFolder("textures/TMChess.png");
    if (IO::FileExists(cachePath)) {
        IO::Delete(cachePath);
        if (developerMode) print("[Logo] Deleted cached logo");
    }
}

/**
 * Renders the logo centered with specified width
 * Height is calculated to maintain aspect ratio
 */
void RenderLogoCentered(float maxWidth) {
    if (logoTexture is null) return;

    vec2 availRegion = UI::GetContentRegionAvail();

    // Calculate dimensions maintaining aspect ratio
    vec2 texSize = logoTexture.GetSize();
    float aspectRatio = texSize.y / texSize.x;

    float logoWidth = Math::Min(maxWidth, availRegion.x);
    float logoHeight = logoWidth * aspectRatio;

    // Center horizontally
    float offsetX = (availRegion.x - logoWidth) * 0.5f;
    offsetX = Math::Max(offsetX, 0.0f);

    vec2 currentPos = UI::GetCursorPos();
    UI::SetCursorPos(vec2(currentPos.x + offsetX, currentPos.y));

    // Render the logo
    UI::Image(logoTexture, vec2(logoWidth, logoHeight));
}
