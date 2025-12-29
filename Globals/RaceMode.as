// Race Mode Selection
enum RaceMode {
    SquareRace,      // New mode: Each square has assigned map, race when clicking
    CaptureRace      // Classic mode: Race only when capturing pieces
}

RaceMode currentRaceMode = RaceMode::SquareRace;

// Square Race Mode Mappack Configuration
[Setting category="Square Race Mode" name="Use Specific Mappack" description="Use a specific TMX mappack instead of random campaign maps"]
bool useSpecificMappack = true;

[Setting category="Square Race Mode" name="Mappack ID" description="TMX Mappack ID (e.g., 2823 for Training - Spring 2022)"]
int squareRaceMappackId = 2823;