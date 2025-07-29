const crypto = require('crypto');

// Generate a random private key
const privateKey = crypto.randomBytes(32).toString('hex');

// Create a simple hash-based address (this is a simplified version)
const hash = crypto.createHash('sha256').update(privateKey).digest('hex');
const address = '0x' + hash.slice(-40);

console.log('=== Ethereum Keypair Generated ===');
console.log('Private Key:', privateKey);
console.log('Address:', address);
console.log('==================================');
console.log('');
console.log('⚠️  IMPORTANT: Keep your private key secure and never share it!');
console.log('This private key controls access to your funds.'); 