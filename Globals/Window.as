bool showWindow = false;
bool windowResizeable = false;
bool showColorCustomizationWindow = false;
bool collapseChessWindow = false;
enum MenuTab {
    Home,
    Play,
    Settings
}
MenuTab currentMenuTab = MenuTab::Home;
vec2 screenSize = vec2(Draw::GetWidth(), Draw::GetHeight());
float defaultHeight = screenSize.y * 0.6f;
float defaultWidth = defaultHeight * 1.05f;