// Race Mode Selection
enum RaceMode {
    SquareRace,      // New mode: Each square has assigned map, race when clicking
    CaptureRace      // Classic mode: Race only when capturing pieces
}

RaceMode currentRaceMode = RaceMode::SquareRace;

// Chess Race Mode Mappack Configuration
[Setting category="Chess Race Mode" name="Use Specific Mappack" description="Use a specific TMX mappack instead of random campaign maps"]
bool useSpecificMappack = true;

[Setting category="Chess Race Mode" name="Mappack ID" description="TMX Mappack ID (e.g., 7237 for Chess Race)"]
int squareRaceMappackId = 7237;