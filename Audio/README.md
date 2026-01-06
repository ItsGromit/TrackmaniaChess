# Chess Audio System

The chess plugin supports sound effects for various game events using **Trackmania's built-in checkpoint and finish sounds**!

## Game Sounds (Default)

By default, the plugin uses Trackmania's in-game audio system for an immersive experience:

- **Normal Move** - Regular checkpoint sound (same as passing a checkpoint)
- **Capture** - Better time checkpoint sound (green checkpoint - that satisfying better time sound!)
- **Check** - Worse time checkpoint sound (red checkpoint - warning sound!)
- **Checkmate** - Race finish sound (victory!)
- **Castle** - Regular checkpoint sound

This creates a familiar and satisfying audio feedback using sounds you already know from racing!

## Custom Sound Files (Optional)

If you prefer custom sounds, you can disable "Use Game Sounds" in settings and add your own:

1. Navigate to your Openplanet plugin storage folder:
   - Windows: `Documents/Openplanet4/PluginStorage/TrackmaniaChess/`

2. Place your sound files in this folder with these exact names:
   - **move.wav** - Normal moves
   - **capture.wav** - Captures
   - **check.wav** - Check
   - **checkmate.wav** - Checkmate
   - **castle.wav** - Castling

3. Supported formats: `.wav`, `.mp3`, `.flac`, `.ogg`

4. In settings, disable "Use Game Sounds" to use your custom sounds

5. Restart the plugin or reload it to load the new sounds

## Audio Settings

You can adjust sound settings in the Openplanet settings menu:

- **Enable Sound Effects** - Master toggle for all chess sounds
- **Use Game Sounds** - Toggle between Trackmania sounds and custom sounds (default: ON)
- **Move Sound Volume** - Volume for normal moves (0.0 - 1.0)
- **Capture Sound Volume** - Volume for captures (0.0 - 1.0)
- **Check Sound Volume** - Volume for checks (0.0 - 1.0)
- **Checkmate Sound Volume** - Volume for checkmate (0.0 - 1.0)
- **Castle Sound Volume** - Volume for castling (0.0 - 1.0)

## Technical Details

Sound playback is triggered based on the Standard Algebraic Notation (SAN) of each move:

- Moves containing `O-O` → Castle sound
- Moves containing `+` (but not `#`) → Check sound
- Moves containing `x` → Capture sound
- Moves containing `#` → Checkmate sound (via game_over message)
- All other moves → Normal move sound

Files larger than 512KB will automatically use streaming mode to reduce memory usage.
