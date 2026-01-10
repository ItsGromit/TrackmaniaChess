// connectionHandlers.js - Connection and handshake handlers

const { REQUIRED_CLIENT_VERSION } = require('./config');
const { validatedClients } = require('./state');
const { send } = require('./utils');

// Handle client handshake with version check
function handleHandshake(socket, msg) {
  const clientVersion = msg.version || '0.0.0';

  console.log(`[Connection] Client ${socket.id} connected with version ${clientVersion}`);

  // Check if client version matches required version
  if (clientVersion !== REQUIRED_CLIENT_VERSION) {
    console.log(`[Connection] Version mismatch - Client ${socket.id} has ${clientVersion}, server requires ${REQUIRED_CLIENT_VERSION}`);
    send(socket, {
      type: 'version_mismatch',
      requiredVersion: REQUIRED_CLIENT_VERSION,
      clientVersion: clientVersion,
      message: `Server requires version ${REQUIRED_CLIENT_VERSION}, you have ${clientVersion}. Please update your plugin.`
    });
    // Close the socket after sending the error
    setTimeout(() => {
      socket.destroy();
    }, 1000);
    return;
  }

  console.log(`[Connection] Client ${socket.id} version OK - adding to validated clients`);
  // Mark client as validated
  validatedClients.add(socket);
}

module.exports = {
  handleHandshake
};
