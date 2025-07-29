const { ethers } = require('ethers');

// Contract ABIs (simplified for deployment)
const OWNABLE_ABI = [
  "constructor()"
];

const FUNDS_DISTRIBUTOR_ABI = [
  "constructor()"
];

const STATS_AGGREGATOR_ABI = [
  "constructor()"
];

const REFERRAL_ABI = [
  "constructor(address owner)"
];

const CRYPTOLOTTO_ABI = [
  "constructor(address ownableContract, address distributor, address statsA, address referralSystem)"
];

async function deployContracts() {
  try {
    // Connect to provider
    const provider = new ethers.providers.JsonRpcProvider('https://rpc.verylabs.io');
    
    // Get private key from environment
    const privateKey = process.env.PRIVATE_KEY;
    if (!privateKey) {
      console.error('Please set PRIVATE_KEY environment variable');
      return;
    }
    
    const wallet = new ethers.Wallet(privateKey, provider);
    console.log('Deploying from address:', wallet.address);
    
    // Deploy Ownable
    console.log('Deploying Ownable...');
    const Ownable = new ethers.ContractFactory(OWNABLE_ABI, [], wallet);
    const ownable = await Ownable.deploy();
    await ownable.deployed();
    console.log('Ownable deployed at:', ownable.address);
    
    // Deploy FundsDistributor
    console.log('Deploying FundsDistributor...');
    const FundsDistributor = new ethers.ContractFactory(FUNDS_DISTRIBUTOR_ABI, [], wallet);
    const fundsDistributor = await FundsDistributor.deploy();
    await fundsDistributor.deployed();
    console.log('FundsDistributor deployed at:', fundsDistributor.address);
    
    // Deploy StatsAggregator
    console.log('Deploying StatsAggregator...');
    const StatsAggregator = new ethers.ContractFactory(STATS_AGGREGATOR_ABI, [], wallet);
    const statsAggregator = await StatsAggregator.deploy();
    await statsAggregator.deployed();
    console.log('StatsAggregator deployed at:', statsAggregator.address);
    
    // Deploy CryptolottoReferral
    console.log('Deploying CryptolottoReferral...');
    const CryptolottoReferral = new ethers.ContractFactory(REFERRAL_ABI, [], wallet);
    const referral = await CryptolottoReferral.deploy(ownable.address);
    await referral.deployed();
    console.log('CryptolottoReferral deployed at:', referral.address);
    
    // Deploy Cryptolotto1Day
    console.log('Deploying Cryptolotto1Day...');
    const Cryptolotto1Day = new ethers.ContractFactory(CRYPTOLOTTO_ABI, [], wallet);
    const cryptolotto1Day = await Cryptolotto1Day.deploy(
      ownable.address,
      fundsDistributor.address,
      statsAggregator.address,
      referral.address
    );
    await cryptolotto1Day.deployed();
    console.log('Cryptolotto1Day deployed at:', cryptolotto1Day.address);
    
    // Deploy Cryptolotto7Days
    console.log('Deploying Cryptolotto7Days...');
    const Cryptolotto7Days = new ethers.ContractFactory(CRYPTOLOTTO_ABI, [], wallet);
    const cryptolotto7Days = await Cryptolotto7Days.deploy(
      ownable.address,
      fundsDistributor.address,
      statsAggregator.address,
      referral.address
    );
    await cryptolotto7Days.deployed();
    console.log('Cryptolotto7Days deployed at:', cryptolotto7Days.address);
    
    console.log('\n=== DEPLOYMENT SUMMARY ===');
    console.log('Ownable:', ownable.address);
    console.log('FundsDistributor:', fundsDistributor.address);
    console.log('StatsAggregator:', statsAggregator.address);
    console.log('CryptolottoReferral:', referral.address);
    console.log('Cryptolotto1Day:', cryptolotto1Day.address);
    console.log('Cryptolotto7Days:', cryptolotto7Days.address);
    
  } catch (error) {
    console.error('Deployment failed:', error);
  }
}

deployContracts(); 