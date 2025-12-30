// ============================================================================
// SQUARE RACE MODE - THUMBNAIL RENDERING
// ============================================================================

namespace RaceMode {

namespace ThumbnailRendering {

// Dictionary to track downloads by URL (since we can't pass objects directly)
dictionary@ downloadingSquares = dictionary();

/**
 * Downloads and caches a map thumbnail image
 *
 * @param squareData Reference to the square's map data
 */
void DownloadThumbnail(SquareMapData@ squareData) {
    if (squareData is null) return;

    // Don't download if already loaded or loading
    if (squareData.thumbnailTexture !is null || squareData.thumbnailLoading) {
        return;
    }

    // Don't download if no URL
    if (squareData.thumbnailUrl.Length == 0) {
        return;
    }

    print("[ThumbnailRendering] Downloading thumbnail for " + squareData.mapName + " from " + squareData.thumbnailUrl);
    squareData.thumbnailLoading = true;

    // Store reference in dictionary and start async download
    downloadingSquares.Set(squareData.thumbnailUrl, @squareData);
    startnew(CoroutineFuncUserdataString(DownloadThumbnailCoroutine), squareData.thumbnailUrl);
}

/**
 * Async coroutine to download thumbnail image
 */
void DownloadThumbnailCoroutine(const string &in url) {
    // Retrieve the square data from the dictionary
    SquareMapData@ squareData;
    if (!downloadingSquares.Get(url, @squareData) || squareData is null) {
        return;
    }

    try {
        // Download the image
        auto req = Net::HttpGet(url);

        // Wait for completion
        while (!req.Finished()) {
            yield();
        }

        // Check for errors
        if (req.ResponseCode() != 200) {
            print("[ThumbnailRendering] Failed to download thumbnail: HTTP " + req.ResponseCode());
            squareData.thumbnailLoading = false;
            return;
        }

        // Get image data as buffer
        MemoryBuffer@ imageData = req.Buffer();

        // Load texture from memory buffer
        @squareData.thumbnailTexture = UI::LoadTexture(imageData);

        if (squareData.thumbnailTexture !is null) {
            print("[ThumbnailRendering] Successfully loaded thumbnail for " + squareData.mapName);
        } else {
            print("[ThumbnailRendering] Failed to create texture for " + squareData.mapName);
        }

    } catch {
        print("[ThumbnailRendering] Exception downloading thumbnail: " + getExceptionInfo());
    }

    squareData.thumbnailLoading = false;

    // Clean up dictionary entry
    downloadingSquares.Delete(url);
}

/**
 * Renders a map thumbnail on a chess board square
 * This should be called after the square button is drawn, as it uses GetItemRect()
 *
 * @param row The row index (0-7)
 * @param col The column index (0-7)
 */
void RenderMapThumbnail(int row, int col) {
    // Get the square's map data
    if (row < 0 || row >= 8 || col < 0 || col >= 8) return;

    SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
    if (squareData is null) return;

    // If thumbnail not loaded, try to download it
    if (squareData.thumbnailTexture is null && !squareData.thumbnailLoading) {
        DownloadThumbnail(squareData);
        return; // Don't render until loaded
    }

    // If still loading or no texture, don't render
    if (squareData.thumbnailTexture is null) return;

    // Get the screen position and size of the last drawn item (the button)
    vec4 rect = UI::GetItemRect();
    vec2 pos = vec2(rect.x, rect.y);
    vec2 size = vec2(rect.z, rect.w);

    auto drawList = UI::GetWindowDrawList();

    // Add padding so thumbnail renders slightly inside the square boundaries
    float padding = 8.0f;
    vec2 imagePos = pos + vec2(padding, padding);
    vec2 imageSize = size - vec2(padding * 2, padding * 2);

    // Draw thumbnail with full opacity
    // Color format is RGBA as uint: 0xRRGGBBAA where RR is red, GG is green, BB is blue, AA is alpha
    // For white (RGB 255,255,255) with full opacity (alpha 255 = 0xFF): 0xFFFFFFFF
    drawList.AddImage(squareData.thumbnailTexture, imagePos, imageSize, 0xFFFFFF80);
}

/**
 * Preloads thumbnails for all assigned maps
 */
void PreloadAllThumbnails() {
    print("[ThumbnailRendering] Preloading all thumbnails...");

    int downloadCount = 0;

    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
            if (squareData !is null && squareData.tmxId > 0) {
                DownloadThumbnail(squareData);
                downloadCount++;
            }
        }
    }

    print("[ThumbnailRendering] Started downloading " + downloadCount + " thumbnails");
}

/**
 * Clears all cached thumbnails to free memory
 */
void ClearThumbnailCache() {
    print("[ThumbnailRendering] Clearing thumbnail cache...");

    int clearedCount = 0;

    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
            if (squareData !is null) {
                @squareData.thumbnailTexture = null;
                squareData.thumbnailLoading = false;
                clearedCount++;
            }
        }
    }

    print("[ThumbnailRendering] Cleared " + clearedCount + " thumbnails from cache");
}

} // namespace ThumbnailRendering

} // namespace RaceMode
