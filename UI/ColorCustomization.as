namespace ColorCustomization {
    void RenderWindow() {
        if (!showColorCustomizationWindow) return;

        UI::SetNextWindowSize(600, 500, UI::Cond::FirstUseEver);

        int windowFlags = UI::WindowFlags::NoCollapse;

        if (UI::Begin("Color Customization", showColorCustomizationWindow, windowFlags)) {
            UI::BeginTabBar("ColorTabs");

            // Theme Preset Tab
            if (UI::BeginTabItem("Theme Presets")) {
                UI::NewLine();
                UI::Text(themeSectionLabelColor + "Select a Theme:");
                UI::NewLine();

                UI::Text("Choose a preset theme or customize individual colors in other tabs.");
                UI::NewLine();

                // Default Theme
                UI::BeginGroup();
                UI::PushStyleColor(UI::Col::Button, vec4(0.2f, 0.5f, 0.8f, 1.0f));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.25f, 0.55f, 0.85f, 1.0f));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.15f, 0.45f, 0.75f, 1.0f));
                if (UI::Button("Default Theme", vec2(200.0f, 40.0f))) {
                    ApplyTheme(ThemePreset::Default);
                }
                UI::PopStyleColor(3);
                if (currentTheme == ThemePreset::Default) {
                    UI::SameLine();
                    UI::Text(themeSuccessTextColor + "(Active)");
                }
                UI::TextWrapped("The original blue and brown theme with moderate opacity.");
                UI::EndGroup();

                UI::NewLine();

                // Light Theme
                UI::BeginGroup();
                UI::PushStyleColor(UI::Col::Button, vec4(0.3f, 0.6f, 0.9f, 1.0f));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.35f, 0.65f, 0.95f, 1.0f));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.25f, 0.55f, 0.85f, 1.0f));
                if (UI::Button("Light Theme", vec2(200.0f, 40.0f))) {
                    ApplyTheme(ThemePreset::Light);
                }
                UI::PopStyleColor(3);
                if (currentTheme == ThemePreset::Light) {
                    UI::SameLine();
                    UI::Text(themeSuccessTextColor + "(Active)");
                }
                UI::TextWrapped("Bright, clean colors with higher opacity for better visibility.");
                UI::EndGroup();

                UI::NewLine();

                // Dark Theme
                UI::BeginGroup();
                UI::PushStyleColor(UI::Col::Button, vec4(0.15f, 0.35f, 0.55f, 1.0f));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.2f, 0.4f, 0.6f, 1.0f));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.1f, 0.3f, 0.5f, 1.0f));
                if (UI::Button("Dark Theme", vec2(200.0f, 40.0f))) {
                    ApplyTheme(ThemePreset::Dark);
                }
                UI::PopStyleColor(3);
                if (currentTheme == ThemePreset::Dark) {
                    UI::SameLine();
                    UI::Text(themeSuccessTextColor + "(Active)");
                }
                UI::TextWrapped("Dark, muted colors for a subtle appearance.");
                UI::EndGroup();

                UI::NewLine();
                UI::Separator();
                UI::NewLine();
                UI::TextWrapped("Note: You can select a theme and then customize individual colors in the other tabs. The theme setting will update to reflect your custom choices.");

                UI::EndTabItem();
            }

            // Button Colors Tab
            if (UI::BeginTabItem("Button Colors")) {
                UI::NewLine();
                UI::Text(themeSectionLabelColor + "Button Color Settings:");
                UI::NewLine();

                UI::Text("Active Button Color:");
                UI::SetNextItemWidth(200);
                themeActiveTabColor.x = UI::SliderFloat("Red##active", themeActiveTabColor.x, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                themeActiveTabColor.y = UI::SliderFloat("Green##active", themeActiveTabColor.y, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                themeActiveTabColor.z = UI::SliderFloat("Blue##active", themeActiveTabColor.z, 0.0f, 1.0f);

                UI::NewLine();

                UI::Text("Inactive Button Color:");
                UI::SetNextItemWidth(200);
                themeInactiveTabColor.x = UI::SliderFloat("Red##inactive", themeInactiveTabColor.x, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                themeInactiveTabColor.y = UI::SliderFloat("Green##inactive", themeInactiveTabColor.y, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                themeInactiveTabColor.z = UI::SliderFloat("Blue##inactive", themeInactiveTabColor.z, 0.0f, 1.0f);

                UI::NewLine();

                // Reset to default colors button
                if (StyledButton("Reset to Default", vec2(150.0f, 30.0f))) {
                    themeActiveTabColor = vec4(0.2f, 0.5f, 0.8f, 1.0f);
                    themeInactiveTabColor = vec4(0.26f, 0.26f, 0.26f, 1.0f);
                }

                UI::EndTabItem();
            }

            // Chess Board Colors Tab
            if (UI::BeginTabItem("Board Colors")) {
                UI::NewLine();
                UI::Text(themeSectionLabelColor + "Chess Board Color Settings:");
                UI::NewLine();

                // Start two-column layout: sliders on left, preview on right
                UI::BeginGroup();

                UI::Text("Light Square Color:");
                UI::SetNextItemWidth(200);
                boardLightSquareColor.x = UI::SliderFloat("Red##lightSquare", boardLightSquareColor.x, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardLightSquareColor.y = UI::SliderFloat("Green##lightSquare", boardLightSquareColor.y, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardLightSquareColor.z = UI::SliderFloat("Blue##lightSquare", boardLightSquareColor.z, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardLightSquareColor.w = UI::SliderFloat("Opacity##lightSquare", boardLightSquareColor.w, 0.0f, 1.0f);

                UI::NewLine();

                UI::Text("Dark Square Color:");
                UI::SetNextItemWidth(200);
                boardDarkSquareColor.x = UI::SliderFloat("Red##darkSquare", boardDarkSquareColor.x, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardDarkSquareColor.y = UI::SliderFloat("Green##darkSquare", boardDarkSquareColor.y, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardDarkSquareColor.z = UI::SliderFloat("Blue##darkSquare", boardDarkSquareColor.z, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardDarkSquareColor.w = UI::SliderFloat("Opacity##darkSquare", boardDarkSquareColor.w, 0.0f, 1.0f);

                UI::NewLine();

                UI::Text("Selected Square Color:");
                UI::SetNextItemWidth(200);
                boardSelectedSquareColor.x = UI::SliderFloat("Red##selectedSquare", boardSelectedSquareColor.x, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardSelectedSquareColor.y = UI::SliderFloat("Green##selectedSquare", boardSelectedSquareColor.y, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardSelectedSquareColor.z = UI::SliderFloat("Blue##selectedSquare", boardSelectedSquareColor.z, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardSelectedSquareColor.w = UI::SliderFloat("Opacity##selectedSquare", boardSelectedSquareColor.w, 0.0f, 1.0f);

                UI::NewLine();

                UI::Text("Valid Move Highlight Color:");
                UI::SetNextItemWidth(200);
                boardValidMoveColor.x = UI::SliderFloat("Red##validMove", boardValidMoveColor.x, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardValidMoveColor.y = UI::SliderFloat("Green##validMove", boardValidMoveColor.y, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardValidMoveColor.z = UI::SliderFloat("Blue##validMove", boardValidMoveColor.z, 0.0f, 1.0f);
                UI::SetNextItemWidth(200);
                boardValidMoveColor.w = UI::SliderFloat("Opacity##validMove", boardValidMoveColor.w, 0.0f, 1.0f);

                UI::EndGroup();

                // Preview board on the right side
                UI::SameLine();
                UI::BeginGroup();
                UI::Text("Preview:");

                // Draw a small 4x4 preview board
                float previewSquareSize = 25.0f;
                vec2 previewStartPos = UI::GetCursorPos();

                for (int pr = 0; pr < 4; pr++) {
                    for (int pc = 0; pc < 4; pc++) {
                        UI::SetCursorPos(previewStartPos + vec2(pc * previewSquareSize, pr * previewSquareSize));

                        // Determine square color
                        bool isLightSquare = (pr + pc) % 2 == 0;
                        vec4 previewColor;

                        // Show different colors in the preview
                        if (pr == 1 && pc == 1) {
                            previewColor = boardSelectedSquareColor; // Selected square example
                        } else if (pr == 2 && pc == 1) {
                            previewColor = boardValidMoveColor; // Valid move example
                        } else {
                            previewColor = isLightSquare ? boardLightSquareColor : boardDarkSquareColor;
                        }

                        UI::PushStyleColor(UI::Col::Button, previewColor);
                        UI::PushStyleColor(UI::Col::ButtonHovered, previewColor);
                        UI::PushStyleColor(UI::Col::ButtonActive, previewColor);
                        UI::Button("##preview" + pr + "_" + pc, vec2(previewSquareSize, previewSquareSize));
                        UI::PopStyleColor(3);
                    }
                }

                // Reset cursor position after the preview board
                UI::SetCursorPos(previewStartPos + vec2(0, 4 * previewSquareSize + 5));
                UI::TextWrapped("Preview shows: normal squares, selected (center-left), and valid move (below selected)");

                UI::EndGroup();

                UI::NewLine();

                // Reset board colors button
                if (StyledButton("Reset to Default", vec2(150.0f, 30.0f))) {
                    boardLightSquareColor = vec4(0.9f, 0.9f, 0.8f, 0.4f);
                    boardDarkSquareColor = vec4(0.5f, 0.4f, 0.3f, 0.4f);
                    boardSelectedSquareColor = vec4(0.3f, 0.7f, 0.3f, 1.0f);
                    boardValidMoveColor = vec4(0.7f, 0.9f, 0.7f, 0.4f);
                }

                UI::EndTabItem();
            }

            UI::EndTabBar();
        }
        UI::End();
    }
}