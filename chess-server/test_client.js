const net = require('net');

const client = new net.Socket();
client.connect(29801, '127.0.0.1', () => {
  console.log('Connected to server');
  const msg = {
    type: 'create_lobby',
    playerId: 'test_client',
    playerName: 'Tester',
    roomCode: '',
    password: 'secret'
  };
  console.log('Sending:', msg);
  client.write(JSON.stringify(msg) + '\n');
});

client.on('data', (data) => {
  process.stdout.write('Received: ' + data.toString());
});

client.on('close', () => console.log('Disconnected'));
client.on('error', (err) => console.error('Error', err));
