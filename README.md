# Chess Race Classic

A multiplayer chess plugin for Trackmania that changes chess strategy to match Trackmania skill!

## Features

### Two Game Modes

#### 🏁 Chess Race (Recommended)
- Each square on the chess board is assigned a unique Trackmania map
- When you want to capture a piece, both players race on that square's map
- Fastest time wins the capture!
- Uses pre-built map packs from TMX (Trackmania.Exchange)

#### ⚔️ Capture Race (Classic)
- Race on random maps whenever a capture attempt is made
- Defender sets the time to beat, attacker must beat it
- More traditional racing format

### Multiplayer Features

- **Lobby System** - Create or join lobbies to play with friends
- **Password Protection** - Secure your lobbies with passwords
- **Rematch System** - Instantly start a new game after finishing
- **Real-time Racing** - See your opponent's live race time as they compete
- **Move History** - Full game history with proper chess notation (e.g., "Nf3", "Qxe5")

### Audio Integration

- **Built-in Sounds** - Uses Trackmania's checkpoint and finish sounds by default
  - Normal moves → Checkpoint sound
  - Captures → Better time checkpoint sound (green)
  - Check → Worse time checkpoint sound (red/warning)
  - Checkmate → Race finish sound
- **Custom Sounds** - Option to use your own sound effects (see [Audio/README.md](Audio/README.md))

### Visual Features

- **Board Flipping** - Automatically flips the board for black player
- **Map Thumbnails** - See preview images of maps on each square (Chess Race mode)
- **Race Results Window** - View race times after returning to the board
- **Color Customization** - Customize board colors and piece styles

## How to Play

### Starting a Game

1. Click "Chess Race" in the Openplanet menu
2. Connect to the server (automatic)
3. **Create a Lobby:**
   - Click "Create New Lobby"
   - Choose a game mode (Chess Race or Capture Race)
   - Set a password (optional)
   - For Chess Race: Select a map pack ID (default: 7237)
   - Click "Create Lobby"
4. **Or Join a Lobby:**
   - Browse available lobbies
   - Click "Join" on any open lobby
5. Wait for both players, then click "Start Game" (host only)

### Playing Chess

- Click on a piece to select it
- Valid moves are highlighted
- Click on a highlighted square to move
- **Making Captures:**
  - Click on an opponent's piece to attempt capture
  - Both players race on the assigned map
  - Fastest time wins the capture!

### Race Mechanics

1. **Race Challenge** - Window opens showing map info
2. **Load the Map** - Map automatically loads and opens
3. **Race!** - Timer starts when the in game timer starts
4. **Finish** - One chance to set fastest time
5. **Return to Board** - Race results shown, board updates automatically

### Winning

- **Checkmate** - Trap opponent's king (detected automatically)
- **Stalemate** - No legal moves but not in check (automatic draw)
- **Resignation** - Click "Forfeit" to resign

## Game Modes Explained

### Chess Race Mode
- 64 maps (if the mappack does not have enough maps, it will reuse maps)
- Maps are synchronized between both players
- Strategic depth: some squares have easier/harder maps
- Uses TMX map packs for curated map selection

### Capture Race Mode
- Random maps for each capture attempt
- More variety in racing
- Can filter maps by tags, author time, etc.

## Settings

Access settings via Openplanet settings menu:

### Audio
- Enable/disable sound effects
- Toggle between game sounds and custom sounds
- Adjust volume for each sound type

### Visual
- Customize board colors
- Adjust window size
- Toggle developer mode for debug info

## Contributing

This project is open-source, but I'm trying to keep it running at all times. DM me on discord, or ping me in one of the various trackmania discord.
My discord is: itsgromit

## Credits

- Thanks to Fort_TM for putting up with my questions during development
- Special thanks to Ultimate_Life for the help with testing and creating the ideas for the plugin

## License

The plugin AND the server are both licensed under the GNU General Public License v3.0.

## Support

For bugs or feature requests, please open an issue on GitHub.

---

**Enjoy playing Chess Race! 🏁♟️**
