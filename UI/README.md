# UI Components

The UI has been refactored into modular components for better organization and maintainability.

## File Structure

```
UI/
├── UI.as                    # Main entry point - coordinates all UI components
├── Helpers.as               # Helper functions (GetColumnName, RenderLockButton)
├── MenuTabs.as              # Menu state with tabs (Home, Play, Settings)
├── GameStates.as            # Game state UIs (Connecting, InQueue, InLobby)
├── PlayingState.as          # Playing and GameOver state UI
├── BoardRenderer.as         # Chess board rendering
├── BoardInteraction.as      # Board click handling and move logic
├── BoardSetup.as            # Board setup utilities (existing)
├── ColorCustomization.as    # Color customization window (existing)
├── Home.as                  # (existing - may be deprecated)
└── LobbyCreation.as         # Lobby creation UI (existing)
```

## Component Responsibilities

### UI.as (Main Entry Point)
- Creates the main window
- Delegates to appropriate state renderers based on `GameManager::currentState`
- Handles window-level styling

### Helpers.as
- **GetColumnName(col)** - Converts column index to algebraic notation (a-h)
- **RenderLockButton(uniqueId, barHeight)** - Renders the window lock/resize button

### MenuTabs.as
Handles the menu state (when not in a game):
- **RenderMenuState()** - Main menu with tabbed navigation
- **RenderHomeTab()** - Welcome screen, practice mode (developer only)
- **RenderPlayTab()** - Lobby browser, auto-connect to server
- **RenderSettingsTab()** - Window, theme, race mode, and developer settings

### GameStates.as
Handles intermediate game states:
- **RenderConnectingState()** - "Connecting to server..." message
- **RenderInQueueState()** - Deprecated queue state (shows lobby browser)
- **RenderInLobbyState()** - Lobby waiting room

### PlayingState.as
Handles active gameplay:
- **RenderPlayingState()** - Main game UI for both Playing and GameOver states
- **RenderMoveHistory(...)** - Move history panel with action buttons (Forfeit/Rematch/etc)

### BoardRenderer.as
- **BoardRender()** - Renders the chess board with:
  - Board centering and sizing calculations
  - Rank and file labels (a-h, 1-8)
  - Square rendering with highlighting (selected, valid moves)
  - Piece texture overlays
  - Board flipping for black player

### BoardInteraction.as
- **HandleSquareClick(row, col)** - Handles user clicks on board squares
  - Network game move validation and submission
  - Local/practice game move execution
  - Check validation
  - Piece selection and deselection

## Data Flow

1. **Main.as** calls `MainMenu()` every frame
2. **UI.as** checks `GameManager::currentState` and delegates to the appropriate renderer
3. Each state renderer handles its own UI logic and user interactions
4. Board components work together:
   - **BoardRenderer.as** draws the board and calls **HandleSquareClick** on clicks
   - **BoardInteraction.as** validates and executes moves
   - **PlayingState.as** displays move history and game status

## Benefits of Refactoring

1. **Modularity** - Each component has a single, clear responsibility
2. **Maintainability** - Easy to find and modify specific UI elements
3. **Readability** - Functions are focused and well-documented
4. **Reusability** - Helper functions can be used across components
5. **Testability** - Individual components can be tested in isolation
6. **Scalability** - Easy to add new features or states without affecting others

## Migration Notes

The original monolithic `UI.as` file (758 lines) has been split into focused components:
- UI.as: 54 lines (main coordinator)
- Helpers.as: 56 lines
- MenuTabs.as: 222 lines
- GameStates.as: 73 lines
- PlayingState.as: 145 lines
- BoardRenderer.as: 127 lines
- BoardInteraction.as: 106 lines

Total: ~783 lines (similar to original, but much better organized)

The old file has been preserved as `UI.as.old` for reference.
