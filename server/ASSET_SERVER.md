# Asset Server Setup

This server provides both TCP game logic and HTTP asset hosting for the Trackmania Chess plugin.

## What's Included

The server now runs two services:
1. **TCP Server** (port from `PORT` env var, default 29802) - Game logic and multiplayer
2. **HTTP Server** (port from `HTTP_PORT` env var, default 3000) - Static asset hosting

## Asset Files

All chess piece textures are located in the `/assets` directory:
- `king_white.png`, `king_black.png`
- `queen_white.png`, `queen_black.png`
- `rook_white.png`, `rook_black.png`
- `bishop_white.png`, `bishop_black.png`
- `knight_white.png`, `knight_black.png`
- `pawn_white.png`, `pawn_black.png`
- `chess_icon.png`

## Setup Instructions

### 1. Install Dependencies

```bash
cd server
npm install
```

This will install:
- `chess.js` - Chess game logic
- `express` - HTTP server framework
- `cors` - Cross-origin resource sharing for web requests

### 2. Run Locally

```bash
npm start
```

The server will start:
- TCP server on port 29802 (or `PORT` env var)
- HTTP server on port 3000 (or `HTTP_PORT` env var)

Assets will be available at: `http://localhost:3000/assets/`

### 3. Deploy to Railway

Railway will automatically:
1. Build the Docker container (including the `/assets` folder)
2. Expose port 8080 (Railway's standard)
3. Set the `PORT` environment variable

**Important**: You need to configure Railway environment variables:

In your Railway project settings, add:
- `PORT` - The port for TCP server (Railway will auto-set this, usually to match the exposed port)
- `HTTP_PORT` - Set this to `8080` or whatever port Railway exposes

Since Railway routes external traffic to port 8080, you should configure your server to use port 8080 for the HTTP server by setting `HTTP_PORT=8080` in Railway.

### 4. Update Plugin Configuration

Make sure your plugin's asset URL points to your deployed Railway app:

In `Pieces/PieceAssets.as`:
```angelscript
const string BASE_URL = "https://trackmaniachess.up.railway.app/assets/";
```

## Testing Asset Availability

Once deployed, you can test asset availability:

1. **Health Check**: Visit `https://trackmaniachess.up.railway.app/health`
   - Should return: `{"status":"ok","timestamp":"..."}`

2. **Asset Test**: Visit `https://trackmaniachess.up.railway.app/assets/king_white.png`
   - Should display the white king chess piece image

3. **List All Assets**:
   ```bash
   curl https://trackmaniachess.up.railway.app/assets/
   ```

## How It Works

When a user first installs/starts the plugin:

1. The plugin calls `LoadTex()` for each piece (in `PieceAssets.as`)
2. `LoadTex()` checks local cache: `IO::FromStorageFolder("textures/" + filename)`
3. If not cached, it downloads from: `BASE_URL + filename`
4. The downloaded file is cached locally for future use
5. The texture is loaded and returned

This means assets are only downloaded once per user, then cached permanently.

## Troubleshooting

**Assets not loading?**
- Check that Railway app is running
- Verify `HTTP_PORT` environment variable is set correctly in Railway
- Test the health endpoint: `https://trackmaniachess.up.railway.app/health`
- Check Railway logs for HTTP server startup message

**CORS errors?**
- The server includes CORS middleware to allow requests from any origin
- This is required for Openplanet to download assets

**Missing assets?**
- Verify all PNG files exist in the `server/assets/` directory
- Check the Dockerfile copies the assets folder: `COPY /assets ./assets`
