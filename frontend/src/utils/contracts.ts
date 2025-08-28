import Cryptolotto1DayABI from '../contracts/Cryptolotto1Day.json';
import Cryptolotto7DaysABI from '../contracts/Cryptolotto7Days.json';
import CryptolottoReferralABI from '../contracts/CryptolottoReferral.json';
import FundsDistributorABI from '../contracts/FundsDistributor.json';
import { ethers } from 'ethers';
import { getVeryNetworkProvider } from './wepin';

// Debug: Log current environment variables
console.log("🔍 Contract Environment Variables:", {
  VITE_CONTRACT_CRYPTOLOTTO_1DAY: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_1DAY,
  VITE_CONTRACT_CRYPTOLOTTO_7DAYS: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_7DAYS,
  VITE_CONTRACT_CRYPTOLOTTO_AD: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_AD,
  VITE_CONTRACT_CRYPTOLOTTO_REFERRAL: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_REFERRAL,
  VITE_CONTRACT_FUNDS_DISTRIBUTOR: import.meta.env.VITE_CONTRACT_FUNDS_DISTRIBUTOR,
  VITE_CONTRACT_TREASURY_MANAGER: import.meta.env.VITE_CONTRACT_TREASURY_MANAGER,
  VITE_CONTRACT_REGISTRY: import.meta.env.VITE_CONTRACT_REGISTRY,
  VITE_CONTRACT_STATS_AGGREGATOR: import.meta.env.VITE_CONTRACT_STATS_AGGREGATOR,
  VITE_CONTRACT_AD_TOKEN: import.meta.env.VITE_CONTRACT_AD_TOKEN,
  VITE_CONTRACT_OWNABLE: import.meta.env.VITE_CONTRACT_OWNABLE,
});

// Game type definitions
export type GameType = "daily-lucky" | "weekly-jackpot" | "ads-lucky";

export interface GameConfig {
  title: string;
  description: string;
  contractAddress: string;
  ticketPrice: string;
  maxTicketsPerPlayer: number;
  gameDuration: number; // in seconds
  feePercentage: number;
  image: string;
  color: string;
}

// Game configurations - using contract addresses from environment variables
export const GAME_CONFIGS: Record<GameType, GameConfig> = {
  "daily-lucky": {
    title: "Daily LUCKY",
    description: "매일 새로운 기회! 하루 한 번의 행운을 잡아라!",
    contractAddress: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_1DAY || '0x6bd878ED448a3Fd9de868484DE4bF5a8008310f4',
    ticketPrice: "1 VERY",
    maxTicketsPerPlayer: 100,
    gameDuration: 86400, // 24 hours in seconds
    feePercentage: 10,
    image: "/fruit-color-1-3.png",
    color: "#ff6c74",
  },
  "weekly-jackpot": {
    title: "Weekly JACKPOT",
    description: "주간 대박! 7일간 쌓인 잭팟을 터뜨려라!",
    contractAddress: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_7DAYS || '0x6f450FAD7D63B080245AAFe107C3616D7F78af0f',
    ticketPrice: "5 VERY",
    maxTicketsPerPlayer: 50,
    gameDuration: 604800, // 7 days in seconds
    feePercentage: 15,
    image: "/fruit-color-1-3.png",
    color: "#ff6c74",
  },
  "ads-lucky": {
    title: "ADS LUCKY",
    description: "광고 시청하고 행운을 얻어라! 무료 티켓의 기회!",
    contractAddress: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_AD || '0x1CE13D1788bDd03ad4d9471FA36622988B2Ca87',
    ticketPrice: "0 VERY",
    maxTicketsPerPlayer: 10,
    gameDuration: 86400, // 24 hours in seconds
    feePercentage: 5,
    image: "/fruit-color-1-2.png",
    color: "#ff6d75",
  },
};

// Contract ABIs
export const CONTRACT_ABIS = {
  Cryptolotto1Day: Cryptolotto1DayABI.abi,
  Cryptolotto7Days: Cryptolotto7DaysABI.abi,
  CryptolottoReferral: CryptolottoReferralABI.abi,
  FundsDistributor: FundsDistributorABI.abi,
};

// Game type to contract mapping
export const GAME_CONTRACT_MAPPING = {
  'daily-lucky': 'Cryptolotto1Day',
  'weekly-jackpot': 'Cryptolotto7Days',
  'ads-lucky': 'Cryptolotto1Day', // Using 1Day for ads as well, can be updated later
} as const;

// Contract addresses from environment variables
export const CONTRACT_ADDRESSES = {
  Cryptolotto1Day: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_1DAY || '0x6bd878ED448a3Fd9de868484DE4bF5a8008310f4',
  Cryptolotto7Days: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_7DAYS || '0x6f450FAD7D63B080245AAFe107C3616D7F78af0f',
  CryptolottoReferral: import.meta.env.VITE_CONTRACT_CRYPTOLOTTO_REFERRAL || '0x90c5D5C21D34eFBDC2E61968620CE7AdE44e5471',
  FundsDistributor: import.meta.env.VITE_CONTRACT_FUNDS_DISTRIBUTOR || '0xaeBe0165b4F76fE6f410a02667E95842FB3ab634',
  TreasuryManager: import.meta.env.VITE_CONTRACT_TREASURY_MANAGER || '0xfF6b9dFb3d6f266e811377e6bD9C82Af31b68E67',
  ContractRegistry: import.meta.env.VITE_CONTRACT_REGISTRY || '0xd4960ea3628B4fd2CfE70E9caDC367632dCc31Ff',
  StatsAggregator: import.meta.env.VITE_CONTRACT_STATS_AGGREGATOR || '0x746a48BA8CDe3C449E60f784C006E19514644Cb0',
  AdToken: import.meta.env.VITE_CONTRACT_AD_TOKEN || '0x01b287c96F9b9BF7C97704880af93a25a5599D83',
  Ownable: import.meta.env.VITE_CONTRACT_OWNABLE || '0x337Df0A7ca20B0CEB77Fe248F45BAD05F8be41b4',
};

// Network configuration from environment variables
export const NETWORK_CONFIG = {
  chainId: import.meta.env.VITE_CHAIN_ID || '4613',
  networkName: import.meta.env.VITE_NETWORK_NAME || 'Verychain',
  rpcUrl: import.meta.env.VITE_RPC_URL || 'https://rpc.verylabs.io',
  explorerUrl: import.meta.env.VITE_EXPLORER_URL || 'https://veryscan.io',
};

// Wepin configuration from environment variables
export const WEPIN_CONFIG = {
  appId: import.meta.env.VITE_WEPIN_APP_ID || '',
  appKey: import.meta.env.VITE_WEPIN_APP_KEY || '',
};

// Helper function to get ABI for a game type
export const getGameABI = (gameType: keyof typeof GAME_CONTRACT_MAPPING) => {
  const contractName = GAME_CONTRACT_MAPPING[gameType];
  return CONTRACT_ABIS[contractName as keyof typeof CONTRACT_ABIS];
};

// Helper function to get contract address for a game type
export const getGameContractAddress = (gameType: keyof typeof GAME_CONTRACT_MAPPING) => {
  const contractName = GAME_CONTRACT_MAPPING[gameType];
  const contractAddress = CONTRACT_ADDRESSES[contractName as keyof typeof CONTRACT_ADDRESSES];
  
  console.log("🔍 getGameContractAddress called:", {
    gameType,
    contractName,
    contractAddress,
    isZeroAddress: contractAddress === '0x0000000000000000000000000000000000000000'
  });
  
  return contractAddress;
};

// Helper function to get contract info for a game type
export const getGameContractInfo = (gameType: keyof typeof GAME_CONTRACT_MAPPING) => {
  const contractName = GAME_CONTRACT_MAPPING[gameType];
  const contractAddress = getGameContractAddress(gameType);
  const contractABI = getGameABI(gameType);
  
  console.log("🔍 getGameContractInfo called:", {
    gameType,
    contractName,
    contractAddress,
    hasABI: !!contractABI,
    abiLength: contractABI?.length || 0
  });
  
  return {
    abi: contractABI,
    address: contractAddress,
  };
};

// Function to format seconds to HH:MM:SS
export const formatTime = (seconds: number): string => {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = seconds % 60;

  return `${hours.toString().padStart(2, "0")}:${minutes
    .toString()
    .padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
};

// Function to fetch remaining game time
export const fetchRemainingTime = async (gameType: GameType, provider: any): Promise<string> => {
  try {
    const contractInfo = getGameContractInfo(gameType);

    if (
      contractInfo.address !== "0x0000000000000000000000000000000000000000"
    ) {
      const ethersProvider = new ethers.BrowserProvider(provider);
      const contract = new ethers.Contract(
        contractInfo.address,
        contractInfo.abi,
        ethersProvider
      );

      // Get remaining game time in seconds
      const remainingSeconds = await contract.getRemainingGameTime();
      const timeString = formatTime(Number(remainingSeconds));
      return timeString;
    }
    return "00:00:00";
  } catch (error) {
    console.warn("Failed to fetch remaining time:", error);
    return "00:00:00";
  }
};

// Function to fetch user's ticket count
export const fetchUserTicketCount = async (
  gameType: GameType,
  account: string,
  provider: any
): Promise<number> => {
  console.log("🔍 fetchUserTicketCount called with:", {
    gameType,
    account,
    providerType: provider?.constructor?.name || "Unknown",
    hasProvider: !!provider
  });

  if (!account) {
    console.log("❌ No account provided, returning 0");
    return 0;
  }

  try {
    console.log("📋 Getting contract info for game type:", gameType);
    const contractInfo = getGameContractInfo(gameType);
    console.log("📋 Contract info:", {
      address: contractInfo.address,
      hasABI: !!contractInfo.abi,
      abiLength: contractInfo.abi?.length || 0
    });

    if (
      contractInfo.address !== "0x0000000000000000000000000000000000000000"
    ) {
      console.log("🔧 Creating ethers provider and contract...");
      const ethersProvider = new ethers.BrowserProvider(provider);
      const contract = new ethers.Contract(
        contractInfo.address,
        contractInfo.abi,
        ethersProvider
      );
      
      console.log("📞 Calling getPlayerInfo on contract:", contractInfo.address);
      console.log("📞 Account being queried:", account);
      
      // Use getPlayerInfo to get user's ticket count
      const playerInfo = await contract.getPlayerInfo(account);
      console.log('🎯 Player info received:', {
        ticketCount: playerInfo[0].toString(),
        lastPurchaseTime: playerInfo[1].toString(),
        totalSpent: playerInfo[2].toString()
      });
      
      const ticketCount = Number(playerInfo[0]); // ticketCount is the first element
      console.log("✅ Returning ticket count:", ticketCount);
      return ticketCount;
    } else {
      console.log("❌ Invalid contract address, returning 0");
      return 0;
    }
  } catch (error) {
    console.error("❌ fetchUserTicketCount failed:", error);
    console.error("Error details:", {
      message: error instanceof Error ? error.message : String(error),
      code: (error as any)?.code,
      data: (error as any)?.data,
      stack: error instanceof Error ? error.stack : undefined
    });
    return 0;
  }
};

// Function to fetch jackpot amount
export const fetchJackpot = async (gameType: GameType, provider: any): Promise<string> => {
  try {
    const contractInfo = getGameContractInfo(gameType);

    console.log('Fetching jackpot for game type:', gameType);
    console.log('Contract address:', contractInfo.address);
    console.log('Contract ABI available:', !!contractInfo.abi);

    if (
      contractInfo.address !== "0x0000000000000000000000000000000000000000"
    ) {
      const ethersProvider = new ethers.BrowserProvider(provider);
      const contract = new ethers.Contract(
        contractInfo.address,
        contractInfo.abi,
        ethersProvider
      );
      
      // First check if contract is active using getGameConfig
      try {
        console.log('Calling getGameConfig() on contract:', contractInfo.address);
        console.log('Contract ABI functions:', contractInfo.abi.map((item: any) => item.name).filter(Boolean));

        const gameConfig = await contract.getGameConfig();
        const isActive = gameConfig[3]; // isActive is the 4th element
        console.log('Contract is active:', isActive);
        
        if (!isActive) {
          console.warn('Contract is not active');
          return "0";
        }
      } catch (activeError) {
        console.warn('Failed to check if contract is active:', activeError);
        console.warn('Contract address being used:', contractInfo.address);
      }
      
      // Try to get jackpot
      const rawJackpot = await contract.getCurrentGameJackpot();
      console.log('Raw jackpot:', rawJackpot.toString());
      return ethers.formatEther(rawJackpot);
    }
    return "0";
  } catch (error) {
    console.error("Failed to fetch jackpot:", error);
    console.error("Error details:", {
      message: error instanceof Error ? error.message : String(error),
      code: (error as any)?.code,
      data: (error as any)?.data
    });
    return "0";
  }
};

// Function to calculate ticket price in wei
export const calculateTicketPriceWei = (ticketPrice: string): string => {
  if (ticketPrice === "0 VERY") return "0";

  // Extract numeric value from "1 VERY" format
  const priceMatch = ticketPrice.match(/(\d+(?:\.\d+)?)/);
  if (priceMatch) {
    const priceInEther = priceMatch[1];
    return ethers.parseEther(priceInEther).toString();
  }
  return "0";
};

// Function to fetch game configuration from contract
export const fetchGameConfig = async (gameType: GameType, provider: any): Promise<{
  ticketPrice: string;
  ticketPriceWei: string;
  ticketPriceEther: string;
  gameDuration: number;
  maxTicketsPerPlayer: number;
}> => {
  try {
    const contractInfo = getGameContractInfo(gameType);

    if (contractInfo.address === "0x0000000000000000000000000000000000000000") {
      throw new Error("Contract address not set");
    }

    const ethersProvider = new ethers.BrowserProvider(provider);
    const contract = new ethers.Contract(
      contractInfo.address,
      contractInfo.abi,
      ethersProvider
    );

    const contractGameConfig = await contract.getGameConfig();
    
    // Contract returns: [ticketPrice, gameDuration, maxTicketsPerPlayer]
    const ticketPriceWei = contractGameConfig[0].toString();
    const gameDuration = Number(contractGameConfig[1]);
    const maxTicketsPerPlayer = Number(contractGameConfig[2]);
    const ticketPriceEther = ethers.formatEther(ticketPriceWei);

    return {
      ticketPrice: ticketPriceWei,
      ticketPriceWei,
      ticketPriceEther,
      gameDuration,
      maxTicketsPerPlayer
    };
  } catch (error) {
    console.error("Failed to get game config from contract:", error);
    // Fallback to default values if contract call fails
    return {
      ticketPrice: "10000000000000000", // 0.01 ETH in wei
      ticketPriceWei: "10000000000000000",
      ticketPriceEther: "0.01",
      gameDuration: 86400, // 24 hours default
      maxTicketsPerPlayer: 100 // Default max tickets
    };
  }
};

// Function to get ticket price from contract (deprecated, use fetchGameConfig instead)
export const getContractTicketPrice = async (gameType: GameType, provider: any): Promise<{
  ticketPrice: string;
  ticketPriceWei: string;
  ticketPriceEther: string;
}> => {
  try {
    const contractInfo = getGameContractInfo(gameType);

    if (contractInfo.address === "0x0000000000000000000000000000000000000000") {
      throw new Error("Contract address not set");
    }

    const ethersProvider = new ethers.BrowserProvider(provider);
    const contract = new ethers.Contract(
      contractInfo.address,
      contractInfo.abi,
      ethersProvider
    );

    const contractGameConfig = await contract.getGameConfig();
    const actualTicketPrice = contractGameConfig[0]; // ticketPrice is the first element
    const ticketPriceWei = actualTicketPrice.toString();
    const ticketPriceEther = ethers.formatEther(actualTicketPrice);

    return {
      ticketPrice: ticketPriceWei,
      ticketPriceWei,
      ticketPriceEther
    };
  } catch (error) {
    console.error("Failed to get ticket price from contract:", error);
    // Fallback to fixed price if contract call fails
    const fallbackPrice = "10000000000000000"; // 0.01 ETH in wei
    return {
      ticketPrice: fallbackPrice,
      ticketPriceWei: fallbackPrice,
      ticketPriceEther: "0.01"
    };
  }
};



// Function to create dynamic game config from contract data
export const createDynamicGameConfig = async (gameType: GameType, provider: any): Promise<GameConfig> => {
  try {
    // Get contract data
    const contractConfig = await fetchGameConfig(gameType, provider);
    
    // Get base config from GAME_CONFIGS
    const baseConfig = GAME_CONFIGS[gameType];
    
    // Create dynamic config with contract data
    const dynamicConfig: GameConfig = {
      ...baseConfig,
      ticketPrice: contractConfig.ticketPriceEther + " VERY",
      maxTicketsPerPlayer: contractConfig.maxTicketsPerPlayer,
      gameDuration: contractConfig.gameDuration,
    };
    
    return dynamicConfig;
  } catch (error) {
    console.error("Failed to create dynamic game config:", error);
    // Fallback to static config
    return GAME_CONFIGS[gameType];
  }
};

// Function to get contract instance
export const getContractInstance = (gameType: GameType, provider: ethers.Provider) => {
  const contractInfo = getGameContractInfo(gameType);
  
  if (contractInfo.address === "0x0000000000000000000000000000000000000000000000000000000000000000") {
    throw new Error("Contract address not set");
  }

  return new ethers.Contract(
    contractInfo.address,
    contractInfo.abi,
    provider
  );
};

// Function to fetch user's ETH balance
export const fetchUserBalance = async (
  account: string,
  provider: any
): Promise<number> => {
  try {
    if (!account || !provider) {
      return 0;
    }

    const ethersProvider = new ethers.BrowserProvider(provider);
    const balance = await ethersProvider.getBalance(account);
    
    // Convert from wei to ether
    const balanceInEther = Number(ethers.formatEther(balance));
    
    console.log("User ETH balance:", {
      account,
      balanceWei: balance.toString(),
      balanceEther: balanceInEther
    });
    
    return balanceInEther;
  } catch (error) {
    console.error("Failed to fetch user balance:", error);
    return 0;
  }
};

// Function to fetch referral stats from CryptolottoReferral contract
export const fetchReferralStats = async (
  account: string,
  provider: any
): Promise<{
  totalReferrals: number;
  totalRewards: number;
  lastRewardTime: number;
}> => {
  try {
    if (!account || !provider) {
      return {
        totalReferrals: 0,
        totalRewards: 0,
        lastRewardTime: 0
      };
    }

    const referralContractAddress = CONTRACT_ADDRESSES.CryptolottoReferral;
    
    if (referralContractAddress === "0x0000000000000000000000000000000000000000") {
      return {
        totalReferrals: 0,
        totalRewards: 0,
        lastRewardTime: 0
      };
    }

    const ethersProvider = new ethers.BrowserProvider(provider);
    const referralContract = new ethers.Contract(
      referralContractAddress,
      CONTRACT_ABIS.CryptolottoReferral,
      ethersProvider
    );

    // Call getReferralStats function
    const referralStats = await referralContract.getReferralStats(account);
    
    // Convert decimal values from wei (18 decimals) to readable format
    const totalRewardsInWei = referralStats[1];
    console.log("Raw totalRewards from contract:", totalRewardsInWei);
    
    // Convert from wei to ether using string manipulation to avoid precision loss
    let totalRewardsInEther = 0;
    if (totalRewardsInWei && totalRewardsInWei > 0) {
      const weiString = totalRewardsInWei.toString();
      console.log("Wei as string:", weiString);
      
      if (weiString.length > 18) {
        // Insert decimal point 18 places from the right
        const beforeDecimal = weiString.slice(0, -18);
        const afterDecimal = weiString.slice(-18);
        const etherString = beforeDecimal + '.' + afterDecimal;
        totalRewardsInEther = parseFloat(etherString);
        console.log("Converted using string manipulation:", totalRewardsInEther);
      } else {
        // Number is smaller than 18 digits, pad with zeros
        const paddedWei = '0.' + '0'.repeat(18 - weiString.length) + weiString;
        totalRewardsInEther = parseFloat(paddedWei);
        console.log("Converted using padding:", totalRewardsInEther);
      }
    }
    
    console.log("Final totalRewards:", totalRewardsInEther);
    
    return {
      totalReferrals: Number(referralStats[0]),
      totalRewards: totalRewardsInEther,
      lastRewardTime: Number(referralStats[2])
    };

  } catch (error) {
    console.error("Failed to fetch referral stats:", error);
    
    // Return default values on error
    return {
      totalReferrals: 0,
      totalRewards: 0,
      lastRewardTime: 0
    };
  }
};

// Function to call buyTicket using provider
export const sendTransactionWithWepin = async (
  userAccount: any,
  gameType: GameType,
  provider: any,
  ticketCount: number = 1,
  referrer: string = "0x0000000000000000000000000000000000000000"
): Promise<{ txId: string }> => {
  try {
    // Get contract instance with provider
    const ethersProvider = new ethers.BrowserProvider(provider);
    const contract = getContractInstance(gameType, ethersProvider);
    
    // Get game config from contract
    const { ticketPriceWei } = await fetchGameConfig(gameType, provider);
    
    // Calculate total value: ticketPrice * ticketCount
    const totalValueWei = (BigInt(ticketPriceWei) * BigInt(ticketCount)).toString();
    const totalValueEther = ethers.formatEther(totalValueWei);

    console.log("Calling buyTicket with provider:", {
      account: userAccount,
      gameType,
      ticketCount,
      pricePerTicket: ticketPriceWei,
      totalValue: totalValueEther,
      referrer,
      network: "Very",
      signing: "Provider"
    });

    // Create a signer from the provider for the write operation
    const signer = await ethersProvider.getSigner();
    const contractWithSigner = contract.connect(signer);
    
    // Call buyTicket with the signer (with type assertion)
    const tx = await (contractWithSigner as any).buyTicket(referrer, ticketCount, {
      value: totalValueWei
    });

    console.log("Transaction sent successfully:", tx);
    return { txId: tx.hash };
  } catch (error) {
    console.error("Error calling buyTicket:", error);
    throw error;
  }
}; 