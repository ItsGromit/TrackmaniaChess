# Game Mechanics - Race Modes

## Core Race Mechanic (Both Modes)

All chess races in TM Chess follow this flow:

### When Captures Happen
1. Player attempts to capture an opponent's piece
2. **Race challenge is triggered** - both players load into a Trackmania map
3. Both players race the same map simultaneously
4. **Winner of the race gets the piece**, regardless of who initiated the capture
   - If attacker wins: capture succeeds (normal chess)
   - If defender wins: **defender takes the attacker's piece instead!**
5. Game returns to chess board with the result applied

### When Non-Captures Happen
- Normal chess moves (no capture) execute **instantly** without any race
- Turn switches immediately to the opponent

## The Two Game Modes

### Classic Mode (Capture Race)
**Map Selection:** Random Trackmania map for each capture

- Simple and straightforward
- Every capture is a surprise with a new map
- Uses random campaign maps or filtered maps based on lobby settings

### Square Race Mode
**Map Selection:** Pre-assigned map for each of the 64 board squares

- Each square on the chess board has a specific Trackmania map assigned to it
- When a capture is attempted, the map used is the one assigned to the **destination square** (where the capture would occur)
- Maps can be assigned from:
  - A specific TMX mappack (e.g., Training - Spring 2022)
  - Random campaign maps fetched at game start
- Players can see map thumbnails on squares (future feature)
- Strategic element: players might target certain squares based on the map assigned

## Example Scenarios

### Classic Mode Example
1. White pawn at e4 tries to capture Black knight at d5
2. Random map loads (e.g., "Alpine Valley #42")
3. Both players race
4. If White wins → White captures the knight (normal)
5. If Black wins → Black's knight captures White's pawn instead!

### Square Race Mode Example
1. White pawn at e4 tries to capture Black knight at d5
2. Map assigned to square d5 loads (e.g., "Ice Mountain Challenge" - always the same map for d5)
3. Both players race
4. If White wins → White captures the knight (normal)
5. If Black wins → Black's knight captures White's pawn instead!

## Strategic Implications

### Classic Mode
- Pure racing skill determines outcomes
- No predictability - can't prepare for specific maps
- Every capture is equally risky

### Square Race Mode
- Racing skill + map knowledge
- Players can learn which maps are on which squares
- Strategic targeting: avoid squares with maps you're bad at
- Psychological element: players might memorize opponent's weak maps
- Adds a metagame layer to chess strategy
