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
    float lockButtonWidth = 30.0f;
    vec2 contentAvail = UI::GetContentRegionAvail();
    vec2 barCursor = UI::GetCursorPos();

    // Lock button at right
    UI::SetCursorPos(vec2(barCursor.x + contentAvail.x - lockButtonWidth, barCursor.y));
    string lockText = windowResizeable ? Icons::Unlock : Icons::Lock;
    if (UI::Button(lockText + "##" + uniqueId, vec2(lockButtonWidth, barHeight))) {
        if (UI::IsKeyDown(UI::Key::LeftShift) || UI::IsKeyDown(UI::Key::RightShift)) {
            UI::SetWindowSize(vec2(defaultWidth, defaultHeight));
            windowResizeable = false;
        } else {
            windowResizeable = !windowResizeable;
        }
    }
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
