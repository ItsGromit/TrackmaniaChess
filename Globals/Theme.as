// Theme preset options
enum ThemePreset {
    Default,
    Light,
    Dark
}

[Setting category="Theme" name="Selected Theme"]
ThemePreset currentTheme = ThemePreset::Default;

// Window background color - can be customized by user
[Setting category="Theme" name="Window Background Color"]
vec4 themeWindowBgColor = vec4(0.0f, 0.0f, 0.0f, 0.4f);

// Theme colors - can be customized by user
[Setting category="Theme" name="Active Tab Color"]
vec4 themeActiveTabColor = vec4(0.2f, 0.5f, 0.8f, 1.0f);

[Setting category="Theme" name="Inactive Tab Color"]
vec4 themeInactiveTabColor = vec4(0.26f, 0.26f, 0.26f, 1.0f);

// Chess board colors - can be customized by user
[Setting category="Theme" name="Light Square Color"]
vec4 boardLightSquareColor = vec4(0.9f, 0.9f, 0.8f, 0.4f);

[Setting category="Theme" name="Dark Square Color"]
vec4 boardDarkSquareColor = vec4(0.5f, 0.4f, 0.3f, 0.4f);

[Setting category="Theme" name="Selected Square Color"]
vec4 boardSelectedSquareColor = vec4(0.3f, 0.7f, 0.3f, 1.0f);

[Setting category="Theme" name="Valid Move Highlight Color"]
vec4 boardValidMoveColor = vec4(0.7f, 0.9f, 0.7f, 0.4f);

[Setting category="Theme" name="Section Label Color (Hex)"]
string themeSectionLabelColor = "\\$f80";

[Setting category="Theme" name="Success Text Color (Hex)"]
string themeSuccessTextColor = "\\$0f0";

[Setting category="Theme" name="Warning Text Color (Hex)"]
string themeWarningTextColor = "\\$ff0";

[Setting category="Theme" name="Error Text Color (Hex)"]
string themeErrorTextColor = "\\$f00";

// Styled button helper - applies theme colors to buttons
bool StyledButton(const string &in label, const vec2 &in size = vec2(0, 0), bool isActive = false) {
    UI::PushStyleColor(UI::Col::Button, isActive ? themeActiveTabColor : themeInactiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonHovered, themeActiveTabColor);
    UI::PushStyleColor(UI::Col::ButtonActive, themeActiveTabColor);
    bool clicked = UI::Button(label, size);
    UI::PopStyleColor(3);
    return clicked;
}

// Apply theme preset - sets all colors to match the selected theme
void ApplyTheme(ThemePreset theme) {
    currentTheme = theme;

    switch (theme) {
        case ThemePreset::Default:
            ApplyDefaultTheme();
            break;
        case ThemePreset::Light:
            ApplyLightTheme();
            break;
        case ThemePreset::Dark:
            ApplyDarkTheme();
            break;
    }
}

// Default theme (current colors with 40% window opacity)
void ApplyDefaultTheme() {
    themeWindowBgColor = vec4(0.0f, 0.0f, 0.0f, 0.4f);
    themeActiveTabColor = vec4(0.2f, 0.5f, 0.8f, 1.0f);
    themeInactiveTabColor = vec4(0.26f, 0.26f, 0.26f, 1.0f);
    boardLightSquareColor = vec4(0.9f, 0.9f, 0.8f, 0.4f);
    boardDarkSquareColor = vec4(0.5f, 0.4f, 0.3f, 0.4f);
    boardSelectedSquareColor = vec4(0.3f, 0.7f, 0.3f, 1.0f);
    boardValidMoveColor = vec4(0.7f, 0.9f, 0.7f, 0.4f);
    themeSectionLabelColor = "\\$f80";
    themeSuccessTextColor = "\\$0f0";
    themeWarningTextColor = "\\$ff0";
    themeErrorTextColor = "\\$f00";
}

// Light theme - bright, clean colors with light grey background
void ApplyLightTheme() {
    themeWindowBgColor = vec4(0.85f, 0.85f, 0.85f, 0.9f);
    themeActiveTabColor = vec4(0.3f, 0.6f, 0.9f, 1.0f);
    themeInactiveTabColor = vec4(0.7f, 0.7f, 0.7f, 1.0f);
    boardLightSquareColor = vec4(0.95f, 0.95f, 0.9f, 0.6f);
    boardDarkSquareColor = vec4(0.7f, 0.65f, 0.55f, 0.6f);
    boardSelectedSquareColor = vec4(0.4f, 0.75f, 0.4f, 1.0f);
    boardValidMoveColor = vec4(0.75f, 0.92f, 0.75f, 0.6f);
    themeSectionLabelColor = "\\$f70";
    themeSuccessTextColor = "\\$0c0";
    themeWarningTextColor = "\\$fb0";
    themeErrorTextColor = "\\$e00";
}

// Dark theme - dark, muted colors with current opacity
void ApplyDarkTheme() {
    themeWindowBgColor = vec4(0.1f, 0.1f, 0.1f, 0.9f);
    themeActiveTabColor = vec4(0.15f, 0.35f, 0.55f, 1.0f);
    themeInactiveTabColor = vec4(0.15f, 0.15f, 0.15f, 1.0f);
    boardLightSquareColor = vec4(0.4f, 0.4f, 0.38f, 0.5f);
    boardDarkSquareColor = vec4(0.2f, 0.18f, 0.15f, 0.5f);
    boardSelectedSquareColor = vec4(0.25f, 0.5f, 0.25f, 1.0f);
    boardValidMoveColor = vec4(0.35f, 0.55f, 0.35f, 0.5f);
    themeSectionLabelColor = "\\$d60";
    themeSuccessTextColor = "\\$0d0";
    themeWarningTextColor = "\\$dd0";
    themeErrorTextColor = "\\$d00";
}