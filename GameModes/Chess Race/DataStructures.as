// ============================================================================
// SQUARE RACE MODE - DATA STRUCTURES
// ============================================================================

namespace RaceMode {

// Represents a map assigned to a chess board square
class SquareMapData {
    int tmxId = -1;                    // Trackmania Exchange map ID
    string mapName = "";               // Display name of the map
    string mapUid = "";                // Unique map identifier
    string thumbnailUrl = "";          // URL to map thumbnail image
    UI::Texture@ thumbnailTexture;     // Loaded thumbnail texture (null if not loaded)
    bool thumbnailLoading = false;     // Whether thumbnail is currently being fetched
    int authorTime = -1;               // Author time in milliseconds
    int difficulty = 0;                // Difficulty rating (1-5)

    SquareMapData() {}
}

// Stores opponent's checkpoint data during a race
class OpponentCheckpointData {
    array<int> checkpointTimes;        // Opponent's time at each checkpoint (milliseconds)
    int finalTime = -1;                // Final race time if finished
    bool hasFinished = false;          // Whether opponent finished the race
    int currentCheckpoint = 0;         // Current checkpoint index

    void Reset() {
        checkpointTimes.RemoveRange(0, checkpointTimes.Length);
        finalTime = -1;
        hasFinished = false;
        currentCheckpoint = 0;
    }
}

} // namespace ChessRace
