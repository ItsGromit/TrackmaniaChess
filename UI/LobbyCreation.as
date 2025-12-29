// ============================================================================
// LOBBY UI
// ============================================================================
// Handles rendering of lobby creation, browsing, and management
// ============================================================================

namespace Lobby {

/**
 * Helper function to join array of strings with a separator
 */
string JoinStrings(const array<string> &in arr, const string &in separator) {
    if (arr.Length == 0) return "";
    if (arr.Length == 1) return arr[0];

    string result = arr[0];
    for (uint i = 1; i < arr.Length; i++) {
        result += separator + arr[i];
    }
    return result;
}

// Lobby creation state
bool isCreatingLobby = false;
string newLobbyTitle = "";
string newLobbyPassword = "";
string newLobbyRaceMode = "capture"; // "capture" or "square"

// Map filters window state
bool showMapFiltersWindow = false;

/**
 * Renders the lobby list browser
 */
void RenderLobbyList() {
    UI::Text("\\$f80Available Lobbies:");
    UI::Separator();

    if (lobbies.Length == 0) {
        UI::TextDisabled("No lobbies available. Create one to get started!");
        return;
    }

    // Display lobbies
    for (uint i = 0; i < lobbies.Length; i++) {
        Lobby@ lobby = lobbies[i];

        UI::PushID("lobby_" + i);

        // Lobby title and info
        string lobbyTitle = lobby.title != "" ? lobby.title : "Untitled Lobby";
        string playerCount = lobby.players + "/2";
        string lockIcon = lobby.hasPassword ? Icons::Lock + " " : "";
        string modeIcon = lobby.raceMode == "square" ? "🏁 " : "♟️ ";

        UI::Text(modeIcon + lockIcon + lobbyTitle + " (" + playerCount + ")");

        // Player names
        if (lobby.playerNames.Length > 0) {
            UI::SameLine();
            UI::TextDisabled("- " + JoinStrings(lobby.playerNames, ", "));
        }

        UI::SameLine();

        // Join button
        if (lobby.open && lobby.players < 2) {
            if (StyledButton("Join", vec2(60.0f, 0))) {
                if (lobby.hasPassword) {
                    // TODO: Show password prompt
                    JoinLobby(lobby.id, "");
                } else {
                    JoinLobby(lobby.id, "");
                }
            }
        } else {
            UI::BeginDisabled();
            UI::Button("Full", vec2(60.0f, 0));
            UI::EndDisabled();
        }

        UI::PopID();
    }
}

/**
 * Renders the create lobby button
 */
void RenderCreateLobby() {
    if (StyledButton("+ Create Lobby", vec2(150.0f, 30.0f))) {
        isCreatingLobby = true;
        newLobbyTitle = "";
        newLobbyPassword = "";
        newLobbyRaceMode = "capture";
    }
}

/**
 * Renders the create lobby page with form
 */
void RenderCreateLobbyPage() {
    UI::Text("\\$f80Create New Lobby");
    UI::Separator();

    UI::Text("Lobby Title:");
    UI::SetNextItemWidth(300);
    newLobbyTitle = UI::InputText("##lobbytitle", newLobbyTitle);

    UI::NewLine();

    UI::Text("Game Mode:");
    if (UI::RadioButton("Capture Race (Classic)", newLobbyRaceMode == "capture")) {
        newLobbyRaceMode = "capture";
    }
    UI::SameLine();
    if (UI::RadioButton("Square Race", newLobbyRaceMode == "square")) {
        newLobbyRaceMode = "square";
    }

    UI::NewLine();

    // Square Race Mode Settings - only show for Square Race
    if (newLobbyRaceMode == "square") {
        UI::Text(themeSectionLabelColor + "Square Race Settings:");
        UI::NewLine();

        useSpecificMappack = UI::Checkbox("Use Specific Mappack", useSpecificMappack);
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::PushTextWrapPos(250.0f);
            UI::Text("Use a specific TMX mappack instead of random campaign maps.");
            UI::PopTextWrapPos();
            UI::EndTooltip();
        }

        if (useSpecificMappack) {
            UI::Text("Mappack ID:");
            UI::SameLine();
            UI::SetNextItemWidth(150);
            squareRaceMappackId = UI::InputInt("##mappackid", squareRaceMappackId);
            if (squareRaceMappackId < 1) squareRaceMappackId = 1;

            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                UI::PushTextWrapPos(250.0f);
                UI::Text("TMX Mappack ID (e.g., 2823 for Training - Spring 2022). Find mappack IDs at trackmania.exchange");
                UI::PopTextWrapPos();
                UI::EndTooltip();
            }
        }

        UI::NewLine();
    }

    UI::Text("Password (optional):");
    UI::SetNextItemWidth(200);
    newLobbyPassword = UI::InputText("##lobbypassword", newLobbyPassword, UI::InputTextFlags::Password);
    if (UI::IsItemHovered()) {
        UI::BeginTooltip();
        UI::Text("Leave blank for no password");
        UI::EndTooltip();
    }

    UI::NewLine();

    if (StyledButton("Create", vec2(100.0f, 30.0f))) {
        // Password is only set if the field is not blank
        string password = (newLobbyPassword.Length > 0) ? newLobbyPassword : "";
        CreateLobby(newLobbyTitle, password, newLobbyRaceMode);
        isCreatingLobby = false;
    }

    UI::SameLine();

    if (StyledButton("Cancel", vec2(100.0f, 30.0f))) {
        isCreatingLobby = false;
    }
}

/**
 * Renders the current lobby (when in lobby waiting room)
 */
void RenderCurrentLobby() {
    UI::Text("\\$f80Lobby: " + (currentLobbyId != "" ? currentLobbyId : "Unknown"));
    UI::Separator();

    // Show players in lobby
    UI::Text("Players:");
    // TODO: Display actual player list from lobby state
    UI::TextDisabled("Waiting for game to start...");

    UI::NewLine();

    // Host controls
    if (isHost) {
        UI::Text("\\$0f0You are the host");

        if (StyledButton("Start Game", vec2(150.0f, 30.0f))) {
            StartGame();
        }

        UI::SameLine();

        if (StyledButton("Map Filters", vec2(150.0f, 30.0f))) {
            showMapFiltersWindow = true;
        }
    } else {
        UI::TextDisabled("Waiting for host to start...");
    }

    UI::NewLine();

    if (StyledButton("Leave Lobby", vec2(150.0f, 30.0f))) {
        LeaveLobby();
        GameManager::currentState = GameState::Menu;
    }
}

/**
 * Renders the map filters configuration window
 */
void RenderMapFiltersWindow() {
    if (!showMapFiltersWindow) return;

    UI::SetNextWindowSize(400, 500, UI::Cond::Appearing);
    UI::SetNextWindowPos(100, 100, UI::Cond::Appearing);

    if (UI::Begin("Map Filters", showMapFiltersWindow, UI::WindowFlags::NoCollapse)) {
        UI::TextWrapped("Configure which maps can be selected for races in this lobby.");
        UI::Separator();

        // Author time filters
        UI::Text("Author Time Range:");
        UI::SetNextItemWidth(150);
        mapFilterAuthorTimeMin = UI::InputInt("Min (seconds)##authortimemin", mapFilterAuthorTimeMin);
        UI::SetNextItemWidth(150);
        mapFilterAuthorTimeMax = UI::InputInt("Max (seconds)##authortimemax", mapFilterAuthorTimeMax);

        UI::NewLine();

        // Tag filters
        UI::Text("Required Tags:");
        UI::TextDisabled("Tags that maps MUST have");
        // TODO: Tag selection UI

        UI::NewLine();

        UI::Text("Excluded Tags:");
        UI::TextDisabled("Tags that maps MUST NOT have");
        // TODO: Exclusion tag selection UI

        UI::NewLine();
        UI::Separator();

        if (isHost && StyledButton("Apply Filters", vec2(150.0f, 30.0f))) {
            // Build filters JSON object
            Json::Value filters = Json::Object();
            filters["authortimemin"] = mapFilterAuthorTimeMin;
            filters["authortimemax"] = mapFilterAuthorTimeMax;
            filters["tags"] = Json::Array();
            filters["excludeTags"] = Json::Array();

            SetMapFilters(currentLobbyId, filters);
        }

        UI::SameLine();

        if (StyledButton("Close", vec2(100.0f, 30.0f))) {
            showMapFiltersWindow = false;
        }
    }
    UI::End();
}

} // namespace Lobby
