# Game Modes

This folder contains the different game mode implementations for TM Chess.

## Structure

### Classic (Capture Race Mode)
Located in `GameModes/Classic/`

- **Classic.as** - Main entry point for Classic mode

In Classic mode:
- Players race only when capturing opponent pieces
- A random Trackmania map is loaded for each capture
- The winner of the race determines if the capture succeeds

### Square Race Mode
Located in `GameModes/Chess Race/`

- **SquareRace.as** - Main entry point and initialization
- **DataStructures.as** - Core data structures (SquareMapData, OpponentCheckpointData)
- **MapAssignment.as** - Map assignment system for all 64 squares
- **RaceExecution.as** - Race execution and completion logic
- **OpponentTracking.as** - Opponent checkpoint tracking and display
- **ThumbnailRendering.as** - Map thumbnail loading and rendering

In Square Race mode:
- Each of the 64 chess board squares is assigned a specific Trackmania map
- Map thumbnails are displayed on each square (future feature)
- **Players race ONLY when a capture is attempted** (attacker vs defender)
- The map used is the one assigned to the destination square being captured
- **Winner of the race gets the piece** (even if they were defending)
- Opponent checkpoint times are displayed in real-time during races

## How Both Modes Work

Both Classic and Square Race modes follow the same core mechanic:

1. **Normal chess moves** (non-captures) happen instantly without racing
2. **Capture attempts** trigger a race challenge:
   - The attacking player initiates the capture
   - Both players race the same Trackmania map
   - **Winner of the race gets the piece** regardless of who was attacking/defending
3. The only difference between modes is **which map is selected** for the race

### Classic Mode Map Selection
- Uses a **random** Trackmania map for each capture

### Square Race Mode Map Selection
- Uses the **pre-assigned map** for the destination square being captured
- All 64 board squares have assigned maps (from a mappack or random campaign maps)

## Migration Notes

The Square Race mode was previously located in `NewRaceMode.as` at the root level. It has been refactored into multiple organized files within `GameModes/Chess Race/`.

### Namespace Changes
- `NewRaceMode::` → `RaceMode::`
- Global variables are now organized within sub-namespaces:
  - `RaceMode::MapAssignment::` - Map assignment logic
  - `RaceMode::RaceExecution::` - Race execution logic
  - `RaceMode::OpponentTracking::` - Opponent tracking (future)
  - `RaceMode::ThumbnailRendering::` - Thumbnail rendering (future)

### Updated References
The following files were updated to use the new namespace structure:
- `UI/UI.as` - Practice mode initialization
- `Network/Messages/HandleMessage.as` - Game start initialization
- `DummyClient/DummyClient.as` - Race map fetching

## Future Enhancements

Both game modes can be expanded with additional features:
- Classic mode could support different map selection strategies
- Square Race mode could support custom map assignments per game
- Both modes could support additional race result outcomes
