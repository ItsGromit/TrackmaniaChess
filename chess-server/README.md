# Chess Server (TrackmaniaChess)

This server supports both WebSocket (HTTP upgrade) and a raw TCP interface for compatibility/testing.

- HTTP/WebSocket: listen on `process.env.PORT` (Railway sets `PORT` automatically). Use `ws://<railway-host>` or `wss://<railway-host>` from clients that support WebSocket.
- Raw TCP: listen on `process.env.TCP_PORT || 29802`. This is kept for local testing with Trackmania's `Net::Socket` (plain TCP). On Railway, exposing a raw TCP port may require a different service type or provider.

Message format (JSON objects). For WebSocket clients, send JSON messages as strings. For TCP clients, send JSON followed by a `\n` newline.

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
3. Railway will detect the repository and Dockerfile. It will set `PORT` automatically; the server listens on `process.env.PORT` for HTTP/WebSocket.
4. After deployment you'll get a host like `your-project.up.railway.app`. Use `ws://your-project.up.railway.app` (or `wss://` if Railway provides TLS) from WebSocket-capable clients.

If your Trackmania plugin cannot do WebSocket handshakes (older `Net::Socket`), you have three options:

1. Run the server on a VM/VPS or cloud VM that exposes raw TCP and point the plugin there.
2. Check if Railway supports exposing TCP ports for your project type (may require a different service or paid tier).
3. Add a small bridge/proxy that translates WebSocket to TCP on a host that can accept both (advanced).

Local testing:
- Run: `npm install` then `node server.js` (the server will listen on `PORT` and `TCP_PORT` reported in logs).

Example WebSocket client (Node):

```js
const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:29801');
ws.on('open', () => { ws.send(JSON.stringify({ type: 'list_lobbies' })); });
ws.on('message', m => console.log('msg', m.toString()));
```

Example TCP client (Node):

```js
const net = require('net');
const c = net.createConnection({ port: 29802 }, () => {
  c.write(JSON.stringify({ type: 'list_lobbies' }) + '\n');
});
c.on('data', d => console.log('data', d.toString()));
```

If you want, I can also add a small Railway `railway.toml` file or tweak the `Dockerfile` to better match Railway's defaults. Let me know which you'd prefer.
