// Contract Addresses Management
const getContractAddress = (contractName) => {
  console.log(`getContractAddress called with: ${contractName}`);
  
  const addresses = {
    CRYPTOLOTTO_1DAY: process.env.REACT_APP_CRYPTOLOTTO_1DAY,
    CRYPTOLOTTO_7DAYS: process.env.REACT_APP_CRYPTOLOTTO_7DAYS,
    CRYPTOLOTTO_AD: process.env.REACT_APP_CRYPTOLOTTO_AD,
    TREASURY_MANAGER: process.env.REACT_APP_TREASURY_MANAGER,
    CONTRACT_REGISTRY: process.env.REACT_APP_CONTRACT_REGISTRY,
    STATS_AGGREGATOR: process.env.REACT_APP_STATS_AGGREGATOR,
    FUNDS_DISTRIBUTOR: process.env.REACT_APP_FUNDS_DISTRIBUTOR,
    CRYPTOLOTTO_REFERRAL: process.env.REACT_APP_CRYPTOLOTTO_REFERRAL,
    AD_TOKEN: process.env.REACT_APP_AD_TOKEN,
    OWNABLE: process.env.REACT_APP_OWNABLE,
  };

  console.log(`Environment variables:`, addresses);
  
  const address = addresses[contractName];
  if (!address) {
    console.warn(`Contract address not found for: ${contractName}`);
    return null;
  }
  
  console.log(`Returning address for ${contractName}: ${address}`);
  return address;
};

// Network Configuration
const NETWORK_CONFIG = {
  id: process.env.REACT_APP_NETWORK_ID || 4613,
  name: process.env.REACT_APP_NETWORK_NAME || 'Verychain',
  explorer: process.env.REACT_APP_EXPLORER_URL || 'https://veryscan.io',
  rpcUrl: process.env.REACT_APP_RPC_URL || 'https://rpc.verylabs.io',
};

// Game Types
const GAME_TYPES = {
  CRYPTOLOTTO_1DAY: 'CRYPTOLOTTO_1DAY',
  CRYPTOLOTTO_7DAYS: 'CRYPTOLOTTO_7DAYS',
  CRYPTOLOTTO_AD: 'CRYPTOLOTTO_AD',
};

export { getContractAddress, NETWORK_CONFIG, GAME_TYPES }; 