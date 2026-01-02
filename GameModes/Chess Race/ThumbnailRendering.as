// ============================================================================
// SQUARE RACE MODE - THUMBNAIL RENDERING
// ============================================================================

namespace RaceMode {

namespace ThumbnailRendering {

// Dictionary to track downloads by URL (since we can't pass objects directly)
dictionary@ downloadingSquares = dictionary();

// Loading state tracking
bool isLoadingThumbnails = false;
int totalThumbnailsToLoad = 0;
int thumbnailsLoaded = 0;

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

    // Check if thumbnail is already cached locally
    string filename = "thumb_" + squareData.tmxId + ".jpg";
    string cachePath = IO::FromStorageFolder("textures/thumbnails/" + filename);

    // Try to load from cache first
    if (IO::FileExists(cachePath)) {
        if (developerMode) print("[ThumbnailRendering] Loading thumbnail from cache: " + squareData.mapName);
        try {
            IO::File file(cachePath, IO::FileMode::Read);
            if (file.Size() > 0) {
                auto buf = file.Read(file.Size());
                file.Close();
                @squareData.thumbnailTexture = UI::LoadTexture(buf);
                if (squareData.thumbnailTexture !is null) {
                    if (developerMode) print("[ThumbnailRendering] Successfully loaded thumbnail from cache for " + squareData.mapName);

                    // Increment loaded counter if we're in loading mode
                    if (isLoadingThumbnails) {
                        thumbnailsLoaded++;

                        // Check if all thumbnails are loaded
                        if (thumbnailsLoaded >= totalThumbnailsToLoad) {
                            isLoadingThumbnails = false;
                            if (developerMode) print("[ThumbnailRendering] All thumbnails loaded from cache (" + thumbnailsLoaded + "/" + totalThumbnailsToLoad + ")");
                        }
                    }

                    return;
                }
            }
            file.Close();
        } catch {
            warn("[ThumbnailRendering] Failed to load cached thumbnail, deleting: " + filename);
            IO::Delete(cachePath);
        }
    }

    // Download from server
    if (developerMode) print("[ThumbnailRendering] Downloading thumbnail for " + squareData.mapName + " from " + squareData.thumbnailUrl);
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
            warn("[ThumbnailRendering] Failed to download thumbnail: HTTP " + req.ResponseCode());
            squareData.thumbnailLoading = false;
            squareData.thumbnailFailed = true;
            squareData.thumbnailRetryCount++;
            return;
        }

        // Get image data as buffer
        MemoryBuffer@ imageData = req.Buffer();

        if (imageData.GetSize() == 0) {
            warn("[ThumbnailRendering] Empty response for thumbnail: " + squareData.mapName);
            squareData.thumbnailLoading = false;
            squareData.thumbnailFailed = true;
            squareData.thumbnailRetryCount++;
            return;
        }

        // Cache the downloaded file
        string filename = "thumb_" + squareData.tmxId + ".jpg";
        string cachePath = IO::FromStorageFolder("textures/thumbnails/" + filename);
        IO::CreateFolder(IO::FromStorageFolder("textures/thumbnails"), true);

        try {
            IO::File file(cachePath, IO::FileMode::Write);
            file.Write(imageData);
            file.Close();
            if (developerMode) print("[ThumbnailRendering] Cached thumbnail: " + filename);
        } catch {
            warn("[ThumbnailRendering] Failed to cache thumbnail: " + filename);
        }

        // Load texture from memory buffer
        @squareData.thumbnailTexture = UI::LoadTexture(imageData);

        if (squareData.thumbnailTexture !is null) {
            if (developerMode) print("[ThumbnailRendering] Successfully loaded thumbnail for " + squareData.mapName);
            // Reset failed state on success
            squareData.thumbnailFailed = false;
            squareData.thumbnailRetryCount = 0;
        } else {
            warn("[ThumbnailRendering] Failed to create texture for " + squareData.mapName);
            squareData.thumbnailFailed = true;
            squareData.thumbnailRetryCount++;
        }

    } catch {
        warn("[ThumbnailRendering] Exception downloading thumbnail: " + getExceptionInfo());
        squareData.thumbnailFailed = true;
        squareData.thumbnailRetryCount++;
    }

    squareData.thumbnailLoading = false;

    // Increment loaded counter
    thumbnailsLoaded++;

    // Check if all thumbnails are loaded
    if (isLoadingThumbnails && thumbnailsLoaded >= totalThumbnailsToLoad) {
        isLoadingThumbnails = false;
        print("[ThumbnailRendering] All thumbnails loaded (" + thumbnailsLoaded + "/" + totalThumbnailsToLoad + ")");
    }

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

    // Check if boardMaps is initialized
    if (MapAssignment::boardMaps.Length <= uint(row)) return;
    if (MapAssignment::boardMaps[row].Length <= uint(col)) return;

    SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
    if (squareData is null) return;

    // Only render thumbnail if this map was assigned by the server
    // (tmxId > 0 means server sent map data, -1 means no map assigned)
    if (squareData.tmxId <= 0) return;

    // If thumbnail not loaded, try to download it
    if (squareData.thumbnailTexture is null && !squareData.thumbnailLoading) {
        // Check if this thumbnail has failed and should retry
        const int MAX_RETRY_COUNT = 3;
        if (squareData.thumbnailFailed && squareData.thumbnailRetryCount < MAX_RETRY_COUNT) {
            if (developerMode) print("[ThumbnailRendering] Retrying failed thumbnail for " + squareData.mapName + " (attempt " + (squareData.thumbnailRetryCount + 1) + "/" + MAX_RETRY_COUNT + ")");
            squareData.thumbnailFailed = false; // Reset flag for retry
            DownloadThumbnail(squareData);
        } else if (!squareData.thumbnailFailed) {
            // First download attempt
            DownloadThumbnail(squareData);
        } else {
            // Exceeded max retries, log and skip
            if (squareData.thumbnailRetryCount >= MAX_RETRY_COUNT) {
                // Only log once when we first hit the limit
                if (squareData.thumbnailRetryCount == MAX_RETRY_COUNT) {
                    warn("[ThumbnailRendering] Max retries reached for " + squareData.mapName + ", giving up");
                    squareData.thumbnailRetryCount++; // Increment to prevent repeated logging
                }
            }
        }
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
    if (developerMode) print("[ThumbnailRendering] Preloading all thumbnails...");

    // Set loading state immediately to show loading screen
    isLoadingThumbnails = true;

    // Reset counters
    thumbnailsLoaded = 0;
    totalThumbnailsToLoad = 0;

    // Count thumbnails that need to be downloaded
    for (int row = 0; row < 8; row++) {
        // Check if row exists
        if (uint(row) >= MapAssignment::boardMaps.Length) break;
        if (MapAssignment::boardMaps[row].Length == 0) continue;

        for (int col = 0; col < 8; col++) {
            // Check if column exists
            if (uint(col) >= MapAssignment::boardMaps[row].Length) break;

            SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
            if (squareData !is null && squareData.tmxId > 0) {
                // Only count if not already loaded
                if (squareData.thumbnailTexture is null && !squareData.thumbnailLoading) {
                    totalThumbnailsToLoad++;
                }
            }
        }
    }

    // If no thumbnails to load, immediately disable loading state
    if (totalThumbnailsToLoad == 0) {
        if (developerMode) print("[ThumbnailRendering] All thumbnails already cached");
        isLoadingThumbnails = false;
        return;
    }

    if (developerMode) print("[ThumbnailRendering] Need to download " + totalThumbnailsToLoad + " thumbnails");

    // Start downloading
    for (int row = 0; row < 8; row++) {
        // Check if row exists
        if (uint(row) >= MapAssignment::boardMaps.Length) break;
        if (MapAssignment::boardMaps[row].Length == 0) continue;

        for (int col = 0; col < 8; col++) {
            // Check if column exists
            if (uint(col) >= MapAssignment::boardMaps[row].Length) break;

            SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
            if (squareData !is null && squareData.tmxId > 0) {
                DownloadThumbnail(squareData);
            }
        }
    }

    if (developerMode) print("[ThumbnailRendering] Started downloading " + totalThumbnailsToLoad + " thumbnails");
}

/**
 * Returns whether any assets are currently being loaded (thumbnails, pieces, or logo)
 */
bool IsLoadingThumbnails() {
    return isLoadingThumbnails || gPieces.isLoading || isLoadingLogo;
}

/**
 * Returns the loading progress (0.0 to 1.0)
 */
float GetLoadingProgress() {
    // Calculate total items to load
    int totalItems = totalThumbnailsToLoad + gPieces.totalPieces + 1; // thumbnails + pieces + logo
    if (totalItems == 0) return 1.0f;

    // Calculate loaded items
    int loadedItems = thumbnailsLoaded;
    if (!gPieces.isLoading) loadedItems += gPieces.totalPieces;
    else loadedItems += gPieces.piecesLoaded;
    if (!isLoadingLogo) loadedItems += 1;

    return float(loadedItems) / float(totalItems);
}

/**
 * Returns formatted loading text
 */
string GetLoadingText() {
    // Check what's currently loading
    if (isLoadingLogo) {
        return "Loading logo...";
    } else if (gPieces.isLoading) {
        return "Loading piece assets... " + gPieces.piecesLoaded + "/" + gPieces.totalPieces;
    } else if (isLoadingThumbnails) {
        return "Loading thumbnails... " + thumbnailsLoaded + "/" + totalThumbnailsToLoad;
    }
    return "Ready";
}

/**
 * Clears all cached thumbnails to free memory and delete cached files
 */
void ClearThumbnailCache() {
    if (developerMode) print("[ThumbnailRendering] Clearing thumbnail cache...");

    int clearedMemoryCount = 0;
    int deletedFileCount = 0;

    // Clear memory references
    if (MapAssignment::boardMaps.Length > 0) {
        for (int row = 0; row < 8; row++) {
            // Check if row is initialized
            if (row >= int(MapAssignment::boardMaps.Length)) break;
            if (MapAssignment::boardMaps[row].Length == 0) continue;

            for (int col = 0; col < 8; col++) {
                // Check if column is initialized
                if (col >= int(MapAssignment::boardMaps[row].Length)) break;

                SquareMapData@ squareData = MapAssignment::boardMaps[row][col];
                if (squareData !is null) {
                    @squareData.thumbnailTexture = null;
                    squareData.thumbnailLoading = false;
                    squareData.thumbnailFailed = false;
                    squareData.thumbnailRetryCount = 0;
                    clearedMemoryCount++;
                }
            }
        }
    }

    // Delete cached files from disk
    string thumbnailsFolder = IO::FromStorageFolder("textures/thumbnails");
    if (IO::FolderExists(thumbnailsFolder)) {
        array<string> files = IO::IndexFolder(thumbnailsFolder, false);
        for (uint i = 0; i < files.Length; i++) {
            // Only delete .jpg files
            if (files[i].EndsWith(".jpg")) {
                string filePath = thumbnailsFolder + "/" + files[i];
                if (IO::FileExists(filePath)) {
                    IO::Delete(filePath);
                    deletedFileCount++;
                }
            }
        }
    }

    if (developerMode) print("[ThumbnailRendering] Cleared " + clearedMemoryCount + " thumbnails from memory, deleted " + deletedFileCount + " cached files");
}

} // namespace ThumbnailRendering

} // namespace RaceMode
