const net = require('net');
const http = require('http');
const WebSocket = require('ws');

const games = new Map(); // gameId -> {white: socket, black: socket, state: boardState}
const queue = []; // (deprecated) kept for backward compat

// Lobby system
const lobbies = new Map(); // lobbyId -> {id, host, players: [socket], open}

// Track connected plain TCP clients and websocket clients
const clients = new Set();

// Helper to normalize send for different socket types
function makeWrapperForWS(ws) {
    ws.id = Math.random().toString(36).substr(2, 9);
    ws.sendJson = (obj) => {
        try { ws.send(JSON.stringify(obj)); } catch (e) { console.error('WS send error', e); }
    };
    ws.closeSocket = () => { try { ws.close(); } catch (e) {} };
    return ws;
}

function sendToClient(c, obj) {
    // TCP sockets use write(), ws uses send()
    if (!c) return;
    if (typeof c.write === 'function') {
        // TCP: append newline
        try { c.write(JSON.stringify(obj) + "\n"); } catch (e) { console.error('TCP write error', e); }
    } else if (typeof c.send === 'function') {
        try { c.send(JSON.stringify(obj)); } catch (e) { console.error('WS send error', e); }
    } else if (typeof c.sendJson === 'function') {
        c.sendJson(obj);
    }
}

// Shared message handler
function handleMessage(socket, data) {
    console.log('Received:', data);
    switch (data.type) {
        case 'join_queue':
            handleJoinQueue(socket);
            break;
        case 'leave_queue':
            handleLeaveQueue(socket);
            break;
        case 'create_lobby':
            handleCreateLobby(socket, data);
            break;
        case 'list_lobbies':
            handleListLobbies(socket);
            break;
        case 'join_lobby':
            handleJoinLobby(socket, data);
            break;
        case 'leave_lobby':
            handleLeaveLobby(socket, data);
            break;
        case 'start_game':
            handleStartGame(socket, data);
            break;
        case 'move':
            handleMove(socket, data);
            break;
        default:
            console.log('Unknown message type:', data.type);
    }
}

// --- HTTP + WebSocket server (for Railway) ---
const httpPort = process.env.PORT || 29801;
const httpServer = http.createServer((req, res) => {
    // simple health endpoint and optional debug
    if (req.url === '/health') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ status: 'ok' }));
        return;
    }
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Chess server running');
});

const wss = new WebSocket.Server({ noServer: true });

wss.on('connection', (ws, req) => {
    makeWrapperForWS(ws);
    clients.add(ws);
    console.log('New WebSocket client connected', ws.id);

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message.toString());
            handleMessage(ws, data);
        } catch (e) { console.error('WS message parse error', e); }
    });

    ws.on('close', () => {
        console.log('WS client disconnected', ws.id);
        clients.delete(ws);
        handleDisconnect(ws);
    });
    ws.on('error', (err) => console.error('WS error', err));
});

httpServer.on('upgrade', (request, socket, head) => {
    // handle websocket upgrade
    wss.handleUpgrade(request, socket, head, (ws) => {
        wss.emit('connection', ws, request);
    });
});

httpServer.listen(httpPort, () => console.log(`HTTP/WebSocket server listening on port ${httpPort}`));

// --- Raw TCP server (kept for Trackmania Net::Socket local testing if desired) ---
const tcpPort = process.env.TCP_PORT || 29802;
const tcpServer = net.createServer((socket) => {
    console.log('New TCP client connected');
    socket.id = Math.random().toString(36).substr(2, 9);
    clients.add(socket);
    socket.setEncoding('utf8');

    // buffer to accumulate data until newline
    let buffer = '';

    socket.on('data', (chunk) => {
        buffer += chunk;
        let idx;
        while ((idx = buffer.indexOf('\n')) !== -1) {
            const line = buffer.slice(0, idx).trim();
            buffer = buffer.slice(idx + 1);
            if (line.length === 0) continue;
            try {
                const data = JSON.parse(line);
                handleMessage(socket, data);
            } catch (error) {
                console.error('Error handling message:', error);
            }
        }
    });

    socket.on('close', () => {
        console.log('Client disconnected', socket.id);
        clients.delete(socket);
        handleDisconnect(socket);
    });

    socket.on('error', (err) => {
        console.log('Socket error', err);
    });
});

tcpServer.listen(tcpPort, () => console.log(`TCP server listening on port ${tcpPort}`));

function handleJoinQueue(socket) {
    console.log(`Player ${socket.id} joined queue`);
    queue.push(socket);
    if (queue.length >= 2) {
        const player1 = queue.shift();
        const player2 = queue.shift();
        createGame(player1, player2);
    }
}

function handleLeaveQueue(socket) {
    const index = queue.indexOf(socket);
    if (index > -1) {
        queue.splice(index, 1);
        console.log(`Player ${socket.id} left queue`);
    }
}

function createGame(player1, player2) {
    const gameId = Math.random().toString(36).substr(2, 9);
    console.log(`Creating game ${gameId} between ${player1.id} and ${player2.id}`);
    
    games.set(gameId, {
        white: player1,
        black: player2,
        state: 'playing'
    });
    
    // Notify players
    sendToClient(player1, {
        type: 'game_start',
        gameId: gameId,
        isWhite: true,
        opponentId: player2.id
    });

    sendToClient(player2, {
        type: 'game_start',
        gameId: gameId,
        isWhite: false,
        opponentId: player1.id
    });
}

// LOBBY HANDLERS
function handleCreateLobby(socket, data) {
    const lobbyId = data.roomCode || Math.random().toString(36).substr(2, 6).toUpperCase();
    console.log(`handleCreateLobby: received create_lobby from ${socket.id} data=${JSON.stringify(data)}`);
    console.log(`Creating lobby ${lobbyId} for ${socket.id}`);
    const lobby = {
        id: lobbyId,
        host: socket,
        players: [socket],
        playerNames: [data.playerName || socket.id],
        password: data.password || "",
        open: true
    };
    lobbies.set(lobbyId, lobby);

    // notify creator
    sendToClient(socket, { type: 'lobby_created', lobbyId: lobbyId });

    // broadcast updated lobby list to all connected clients
    console.log(`Lobby ${lobbyId} created. Total lobbies: ${lobbies.size}`);
    broadcastLobbyList();
}

function handleListLobbies(socket) {
    const list = [];
    for (const [id, l] of lobbies.entries()) {
        list.push({ 
            id: id, 
            hostId: l.host.id, 
            players: l.players.length, 
            open: l.open,
            hasPassword: !!l.password,
            playerNames: l.playerNames
        });
    }
    sendToClient(socket, { type: 'lobby_list', lobbies: list });
}

function handleJoinLobby(socket, data) {
    const id = data.lobbyId;
    const lobby = lobbies.get(id);
    if (!lobby) {
        console.log(`handleJoinLobby: lobby ${id} not found for ${socket.id}`);
        sendToClient(socket, { type: 'lobby_error', message: 'Lobby not found' });
        return;
    }
    if (!lobby.open) {
        sendToClient(socket, { type: 'lobby_error', message: 'Lobby closed' });
        return;
    }
    if (lobby.password && lobby.password !== data.password) {
        sendToClient(socket, { type: 'lobby_error', message: 'Incorrect password' });
        return;
    }
    if (lobby.players.find(p => p === socket)) {
        // already in lobby
        console.log(`handleJoinLobby: ${socket.id} already in lobby ${id}`);
    } else {
        lobby.players.push(socket);
        lobby.playerNames.push(data.playerName || socket.id);
        console.log(`handleJoinLobby: ${socket.id} joined lobby ${id}. players=${lobby.players.map(p=>p.id)}`);
    }

    // if lobby full (2 players) close it to new joiners
    if (lobby.players.length >= 2) lobby.open = false;

    // notify all players in lobby
    for (const p of lobby.players) {
        sendToClient(p, {
            type: 'lobby_update',
            lobbyId: id,
            players: lobby.players.map(x => x.id),
            playerNames: lobby.playerNames,
            hostId: lobby.host.id,
            password: lobby.password
        });
    }

    // broadcast lobby list to everyone
    broadcastLobbyList();
}

function handleLeaveLobby(socket, data) {
    const id = data.lobbyId;
    const lobby = lobbies.get(id);
    if (!lobby) return;
    // remove player
    lobby.players = lobby.players.filter(p => p !== socket);
    if (lobby.players.length === 0) {
        lobbies.delete(id);
    } else {
        // if host left, promote another
        if (lobby.host === socket) {
            lobby.host = lobby.players[0];
        }
        lobby.open = lobby.players.length < 2;
        for (const p of lobby.players) {
            sendToClient(p, {
                type: 'lobby_update',
                lobbyId: id,
                players: lobby.players.map(x => x.id),
                playerNames: lobby.playerNames,
                hostId: lobby.host.id,
                password: lobby.password
            });
        }
    }
    broadcastLobbyList();
}

function handleStartGame(socket, data) {
    const id = data.lobbyId;
    const lobby = lobbies.get(id);
    if (!lobby) return;
    if (lobby.host !== socket) return; // only host can start
    if (lobby.players.length < 2) return; // need 2 players

    console.log(`handleStartGame: host ${socket.id} starting game for lobby ${id} with players ${lobby.players.map(p=>p.id)}`);
    // create a game between first two players
    const p1 = lobby.players[0];
    const p2 = lobby.players[1];
    const gameId = Math.random().toString(36).substr(2, 9);
    games.set(gameId, { white: p1, black: p2, state: 'playing' });

    // notify players
    sendToClient(p1, { type: 'game_start', gameId: gameId, isWhite: true, opponentId: p2.id });
    sendToClient(p2, { type: 'game_start', gameId: gameId, isWhite: false, opponentId: p1.id });

    // remove lobby
    lobbies.delete(id);
    console.log(`Game ${gameId} created for lobby ${id}. lobbies remaining: ${lobbies.size}`);
    broadcastLobbyList();
}

function broadcastLobbyList() {
    const list = [];
    for (const [id, l] of lobbies.entries()) {
        list.push({ 
            id: id, 
            hostId: l.host.id, 
            players: l.players.length, 
            open: l.open,
            hasPassword: !!l.password,
            playerNames: l.playerNames
        });
    }
    const msgObj = { type: 'lobby_list', lobbies: list };
    clients.forEach(c => {
        try { sendToClient(c, msgObj); } catch (e) { console.log('Failed to write to client', e); }
    });
}

function handleMove(socket, data) {
    const game = games.get(data.gameId);
    if (!game) {
        console.log(`Game ${data.gameId} not found`);
        return;
    }
    
    console.log(`Move in game ${data.gameId} by ${socket.id}`);
    const opponent = game.white === socket ? game.black : game.white;
    sendToClient(opponent, {
        type: 'move',
        fromRow: data.fromRow,
        fromCol: data.fromCol,
        toRow: data.toRow,
        toCol: data.toCol
    });
}

function handleDisconnect(socket) {
    handleLeaveQueue(socket);
    
    // Find and end any active games
    for (const [gameId, game] of games.entries()) {
        if (game.white === socket || game.black === socket) {
            const opponent = game.white === socket ? game.black : game.white;
            console.log(`Game ${gameId} ended due to disconnect of ${socket.id}`);
            sendToClient(opponent, {
                type: 'game_over',
                reason: 'disconnect',
                winner: game.white === socket ? 'black' : 'white'
            });
            games.delete(gameId);
        }
    }
}

console.log(`Chess server initialized (httpPort=${httpPort}, tcpPort=${tcpPort})`);