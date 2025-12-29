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