# Railway Deployment Setup

## Quick Start

### 1. Install Dependencies Locally
Before deploying, install the new dependencies:
```bash
cd server
npm install
```

This installs `express` and `cors` for the HTTP asset server.

### 2. Railway Environment Variables

In your Railway project dashboard, add this environment variable:

- **Variable Name**: `GAME_PORT`
- **Value**: `29802`

**Note**: Do NOT set `PORT` manually - Railway sets this automatically for HTTP traffic routing.

### 3. Deploy

Push your changes to trigger a Railway rebuild:
```bash
git add .
git commit -m "Add HTTP asset server"
git push
```

Railway will automatically:
1. Detect changes
2. Build the Docker container (with `/assets` folder included)
3. Set `PORT` to the HTTP routing port (usually 8080)
4. Start both servers:
   - HTTP server on `PORT` (for assets)
   - TCP server on `GAME_PORT` (29802 for game logic)

### 4. Verify Deployment

Once deployed, test these URLs:

**Health Check**:
```
https://trackmaniachess.up.railway.app/health
```
Should return: `{"status":"ok","timestamp":"2025-..."}`

**Asset Test**:
```
https://trackmaniachess.up.railway.app/assets/king_white.png
```
Should display the white king chess piece image.

**All Assets Should Be Available At**:
```
https://trackmaniachess.up.railway.app/assets/king_white.png
https://trackmaniachess.up.railway.app/assets/king_black.png
https://trackmaniachess.up.railway.app/assets/queen_white.png
https://trackmaniachess.up.railway.app/assets/queen_black.png
https://trackmaniachess.up.railway.app/assets/rook_white.png
https://trackmaniachess.up.railway.app/assets/rook_black.png
https://trackmaniachess.up.railway.app/assets/bishop_white.png
https://trackmaniachess.up.railway.app/assets/bishop_black.png
https://trackmaniachess.up.railway.app/assets/knight_white.png
https://trackmaniachess.up.railway.app/assets/knight_black.png
https://trackmaniachess.up.railway.app/assets/pawn_white.png
https://trackmaniachess.up.railway.app/assets/pawn_black.png
```

### 5. Check Logs

In Railway dashboard, check your deployment logs. You should see:
```
HTTP asset server listening on port 8080
Assets available at: https://trackmaniachess.up.railway.app/assets/
Authoritative TCP chess server listening on 29802
```

## How It Works

### Port Configuration
- **`PORT`** (Railway auto-set): Used for HTTP server serving assets
- **`GAME_PORT`** (you set to 29802): Used for TCP game server

### Why Two Servers?
1. **HTTP Server**: Serves static PNG files via Express.js on Railway's public HTTP port
2. **TCP Server**: Handles game logic and multiplayer via raw TCP sockets on a separate port

Railway routes all public HTTP traffic through the `PORT` variable, which is why we use it for assets. The TCP server uses a custom `GAME_PORT` variable.

## Troubleshooting

### Assets not accessible
1. Check Railway logs for "HTTP asset server listening" message
2. Verify `PORT` variable exists in Railway (should be auto-set)
3. Make sure deployment succeeded without errors
4. Test health endpoint first: `/health`

### TCP Game Server Not Working
1. Check Railway logs for "Authoritative TCP chess server listening on 29802"
2. Verify `GAME_PORT=29802` is set in Railway environment variables
3. Railway may require TCP proxy configuration for raw TCP connections
4. Check Railway's TCP proxy documentation if needed

### CORS Issues
- The server already includes `cors()` middleware
- All origins are allowed by default
- If issues persist, check browser console for specific CORS errors

## Summary

**What Changed**:
- Added Express.js HTTP server to serve assets
- HTTP server uses Railway's `PORT` (auto-set)
- TCP server now uses `GAME_PORT` (manual set to 29802)
- Docker container now includes `/assets` folder
- Assets are served at: `https://trackmaniachess.up.railway.app/assets/`

**What You Need To Do**:
1. Run `npm install` locally
2. Add `GAME_PORT=29802` to Railway environment variables
3. Push changes to trigger redeploy
4. Test `/health` and `/assets/king_white.png` endpoints
