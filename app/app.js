const axios = require('axios');
const yargs = require('yargs');

// Define command line options
const argv = yargs
  .option('server', {
    alias: 's',
    description: 'Server ID',
    type: 'string',
    demandOption: true // Server ID is required
  })
  .option('user', {
    alias: 'u',
    description: 'User ID to compare onAccount',
    type: 'string',
    demandOption: true // User ID is required
  })
  .argv;

// Get the server ID and user ID from the command line arguments
const serverId = argv.server;
const userId = argv.user;

// URL to query
const url = `https://api.spy.pet/servers/${serverId}`;

axios.get(url)
  .then(response => {
    const onAccountValue = response.data.onAccount;
    // Check if the onAccount attribute is not equal to the provided command line value
    if (onAccountValue !== userId) {
      console.log(`onAccount is not equal to ${userId}. Current value: ${onAccountValue}`);
    } else {
      console.log(`onAccount is equal to ${userId}`);
    }
  })
  .catch(error => {
    const status = parseInt(error.response.status);
    if (status >= 400 && status < 500) {
      console.error('Error fetching data:', error.response.data);
    } else {
      console.error('Error fetching data:', error);
    }
  });
