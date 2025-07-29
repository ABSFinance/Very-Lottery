const { ethers } = require('ethers');

// Contract addresses from .env
const CONTRACT_ADDRESS = "0x76a2d934580872C3Ca53a7c913CeD5f3aB9dc591";
const OWNABLE_ADDRESS = "0x08cA6CDD48b36108b370AEc40c8cfCf72F332427";
const DISTRIBUTOR_ADDRESS = "0x1B1e516EdF75E9985B1ABdfEf68BaAb560056756";
const STATS_ADDRESS = "0x8aa9Af4Ae93414b34e187537af1643Fb0357396a";
const REFERRAL_ADDRESS = "0x8fAdC40c07fA9e1417770cF6572948A655a10Edc";

// Contract ABI for constructor
const CONTRACT_ABI = [
  "function Cryptolotto1Day(address ownableContract, address distributor, address statsA, address referralSystem) public"
];

async function initializeContract() {
  try {
    // Connect to provider
    const provider = new ethers.providers.JsonRpcProvider('https://rpc.verylabs.io');
    
    // You need to provide your private key here
    const privateKey = process.env.PRIVATE_KEY; // Set your private key
    if (!privateKey) {
      console.error('Please set PRIVATE_KEY environment variable');
      return;
    }
    
    const wallet = new ethers.Wallet(privateKey, provider);
    
    // Create contract instance
    const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, wallet);
    
    console.log('Initializing contract with addresses:');
    console.log('Ownable:', OWNABLE_ADDRESS);
    console.log('Distributor:', DISTRIBUTOR_ADDRESS);
    console.log('Stats:', STATS_ADDRESS);
    console.log('Referral:', REFERRAL_ADDRESS);
    
    // Call constructor
    const tx = await contract.Cryptolotto1Day(
      OWNABLE_ADDRESS,
      DISTRIBUTOR_ADDRESS,
      STATS_ADDRESS,
      REFERRAL_ADDRESS
    );
    
    console.log('Transaction hash:', tx.hash);
    await tx.wait();
    console.log('Contract initialized successfully!');
    
  } catch (error) {
    console.error('Error initializing contract:', error);
  }
}

initializeContract(); 