# Chess Server (TrackmaniaChess)

This server uses a plain TCP interface (newline-delimited JSON) for compatibility with Trackmania's `Net::Socket`.

On Railway or other hosts, the server will listen on `process.env.PORT` (Railway sets `PORT` automatically). If you prefer a separate TCP port locally, you can set `TCP_PORT` — otherwise the server falls back to port `29802`.

Message format (JSON objects). For TCP clients, send JSON followed by a `\n` newline.

Common messages:
- create_lobby: { type: 'create_lobby', playerName: 'Alice', password: 'opt' }
- list_lobbies: { type: 'list_lobbies' }
- join_lobby: { type: 'join_lobby', lobbyId: 'ABC123', playerName: 'Bob', password: '' }
- leave_lobby: { type: 'leave_lobby', lobbyId: 'ABC123' }
- start_game: { type: 'start_game', lobbyId: 'ABC123' }
- move: { type: 'move', gameId: 'xyz', fromRow:0, fromCol:0, toRow:1, toCol:0 }

Server responses are JSON objects with types like `lobby_list`, `lobby_update`, `game_start`, `move`, `game_over`.

Deployment notes (Railway):
1. Push this `chess-server` folder to a GitHub repo.
2. On Railway, create a new project and choose "Deploy from GitHub repo".
3. Railway will detect the repository and Dockerfile. It will set `PORT` automatically; the server will listen on that TCP port. Note: Railway's ability to expose arbitrary TCP ports depends on your plan and service configuration.

If you deploy to Railway and your project exposes a TCP port, you can connect your Trackmania plugin directly to that host:port. If Railway does not expose TCP for your plan, run the server on a host that does (VPS, cloud VM) or use a bridge/proxy.


Local testing:
- Run: `npm install` then `node server.js` (the server will listen on `PORT` or `29802` by default).

Example TCP client (Node):

```js
const net = require('net');
const c = net.createConnection({ port: 29802 }, () => {
  c.write(JSON.stringify({ type: 'list_lobbies' }) + '\n');
});
c.on('data', d => console.log('data', d.toString()));
```

If you want, I can also add a small Railway `railway.toml` file or tweak the `Dockerfile` to better match Railway's defaults. Let me know which you'd prefer.
