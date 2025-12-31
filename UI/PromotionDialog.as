// ============================================================================
// PAWN PROMOTION DIALOG
// ============================================================================
// Handles UI for selecting pawn promotion piece
// ============================================================================

/**
 * Renders the pawn promotion selection dialog
 * @return The selected piece type, or PieceType::Empty if no selection yet
 */
PieceType RenderPromotionDialog() {
    if (!isPendingPromotion) return PieceType::Empty;

    // Determine the color of the promoting pawn
    bool isWhite = (currentTurn == PieceColor::White);

    // Create a modal-style overlay
    vec2 windowSize = UI::GetWindowSize();
    vec2 dialogSize = vec2(300.0f, 200.0f);
    vec2 dialogPos = vec2(
        (windowSize.x - dialogSize.x) * 0.5f,
        (windowSize.y - dialogSize.y) * 0.5f
    );

    UI::SetNextWindowSize(int(dialogSize.x), int(dialogSize.y), UI::Cond::Always);
    UI::SetNextWindowPos(int(dialogPos.x), int(dialogPos.y), UI::Cond::Always);

    PieceType selectedPiece = PieceType::Empty;

    if (UI::Begin("Pawn Promotion", UI::WindowFlags::NoResize | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoMove)) {
        UI::Text("\\$f80Choose promotion piece:");
        UI::NewLine();

        // Calculate button size and spacing
        float buttonSize = 50.0f;
        float totalWidth = buttonSize * 4 + 30.0f;  // 4 buttons + 3 spacings
        float offsetX = (dialogSize.x - totalWidth) * 0.5f;

        UI::SetCursorPos(UI::GetCursorPos() + vec2(offsetX, 0.0f));

        // Queen button
        UI::BeginGroup();
        UI::PushStyleColor(UI::Col::Button, vec4(0.2f, 0.6f, 0.2f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.3f, 0.7f, 0.3f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.1f, 0.5f, 0.1f, 1.0f));
        if (UI::Button("Q##queen", vec2(buttonSize, buttonSize))) {
            selectedPiece = PieceType::Queen;
        }
        UI::PopStyleColor(3);
        UI::Text("Queen");
        UI::EndGroup();

        UI::SameLine();

        // Rook button
        UI::BeginGroup();
        UI::PushStyleColor(UI::Col::Button, vec4(0.2f, 0.4f, 0.6f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.3f, 0.5f, 0.7f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.1f, 0.3f, 0.5f, 1.0f));
        if (UI::Button("R##rook", vec2(buttonSize, buttonSize))) {
            selectedPiece = PieceType::Rook;
        }
        UI::PopStyleColor(3);
        UI::Text("Rook");
        UI::EndGroup();

        UI::SameLine();

        // Bishop button
        UI::BeginGroup();
        UI::PushStyleColor(UI::Col::Button, vec4(0.6f, 0.4f, 0.2f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.7f, 0.5f, 0.3f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.5f, 0.3f, 0.1f, 1.0f));
        if (UI::Button("B##bishop", vec2(buttonSize, buttonSize))) {
            selectedPiece = PieceType::Bishop;
        }
        UI::PopStyleColor(3);
        UI::Text("Bishop");
        UI::EndGroup();

        UI::SameLine();

        // Knight button
        UI::BeginGroup();
        UI::PushStyleColor(UI::Col::Button, vec4(0.6f, 0.2f, 0.6f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.7f, 0.3f, 0.7f, 1.0f));
        UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.5f, 0.1f, 0.5f, 1.0f));
        if (UI::Button("N##knight", vec2(buttonSize, buttonSize))) {
            selectedPiece = PieceType::Knight;
        }
        UI::PopStyleColor(3);
        UI::Text("Knight");
        UI::EndGroup();
    }
    UI::End();

    return selectedPiece;
}
