// ============================================================================
// UI HELPERS
// ============================================================================
// Helper functions used across UI components
// ============================================================================

/**
 * Converts a column index to its algebraic notation (a-h)
 */
string GetColumnName(int col) {
    array<string> columns = {"a", "b", "c", "d", "e", "f", "g", "h"};
    if (col >= 0 && col < 8) {
        return columns[col];
    }
    return "?";
}

/**
 * Renders a lock button for window resizing
 * @param uniqueId Unique identifier for the button (e.g., "menu", "playing")
 * @param barHeight Height of the button bar
 */
void RenderLockButton(const string &in uniqueId, float barHeight) {
    float buttonWidth = 30.0f;
    float spacing = 2.0f;
    vec2 contentAvail = UI::GetContentRegionAvail();
    vec2 barCursor = UI::GetCursorPos();

    // Thumbnail toggle button
    UI::SetCursorPos(vec2(barCursor.x + contentAvail.x - buttonWidth * 2 - spacing, barCursor.y));
    string thumbnailIcon = showThumbnails ? Icons::Eye : Icons::EyeSlash;

    // Apply theme colors to thumbnail button
    UI::PushStyleColor(UI::Col::Button, themeInactiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);

    if (UI::Button(thumbnailIcon + "##thumbnail_" + uniqueId, vec2(buttonWidth, barHeight))) {
        showThumbnails = !showThumbnails;
    }

    UI::PopStyleColor(3);
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text(showThumbnails ? "Hide Thumbnails" : "Show Thumbnails");
        UI::EndTooltip();
    }

    // Lock button at right
    UI::SetCursorPos(vec2(barCursor.x + contentAvail.x - buttonWidth, barCursor.y));
    string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;

    // Apply theme colors to lock button
    UI::PushStyleColor(UI::Col::Button, themeInactiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);

    if (UI::Button(lockText + "##lock_" + uniqueId, vec2(buttonWidth, barHeight))) {
        if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
            UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
            windowResizeable = false;
        } else {
            windowResizeable = !windowResizeable;
        }
    }

    UI::PopStyleColor(3);
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
            UI::Text("Reset Window to Default Size");
        } else {
            UI::Text("Lock/Unlock Window Size");
        }
        UI::EndTooltip();
    }

    // Reset cursor and add dummy invisible item to maintain bar height
    UI::SetCursorPos(barCursor);
}
