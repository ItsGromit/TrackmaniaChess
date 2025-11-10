namespace ChessUI {
    UI::Font@ MenuFont = UI::LoadFont("DroidSans-Bold.ttf", 24);
    
    void RenderMenu() {
        UI::PushFont(MenuFont);
        UI::Text("\\$f80Racing Chess");
        UI::PopFont();
        UI::Separator();
        UI::TextWrapped("Chess meets Trackmania! When you try to capture an opponent's piece, both players race on a track. The faster time wins!");
        UI::Separator();
    }
}
