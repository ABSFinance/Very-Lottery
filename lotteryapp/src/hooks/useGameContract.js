import { useCallback, useMemo } from 'react';
import { ethers } from 'ethers';
import { useMetaMaskAccount } from '../context/AccountContext';
import { getContractAddress } from '../utils/contractAddresses';

const useGameContract = (gameType) => {
  const { connected, connectedAddr } = useMetaMaskAccount();
  
  const contractAddress = useMemo(() => getContractAddress(gameType), [gameType]);
  
  // Create provider and signer
  const provider = useMemo(() => {
    // Force use of Verychain RPC provider to ensure correct network connection
    return new ethers.providers.JsonRpcProvider(
      process.env.REACT_APP_RPC_URL || 'https://rpc.verylabs.io',
      {
        name: 'Verychain',
        chainId: 4613
      }
    );
  }, []);

  const signer = useMemo(() => {
    // Only use MetaMask signer if connected to Verychain
    if (typeof window !== 'undefined' && window.ethereum) {
      try {
        const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
        // Note: We can't await in useMemo, so we'll check network when needed
        console.log('ℹ️ MetaMask available, will check network when signing');
        return web3Provider.getSigner();
      } catch (error) {
        console.error('Error creating MetaMask signer:', error);
      }
    }
    
    console.log('ℹ️ Using read-only Verychain provider (no signer)');
    return null;
  }, []);

  const contractInterface = useMemo(() => [
    // Game functions
    "function buyTicket(address referrer, uint256 ticketCount) payable",
    "function getCurrentGameNumber() view returns (uint256)",
    "function getCurrentGamePlayerCount() view returns (uint256)",
    "function getCurrentGameJackpot() view returns (uint256)",
    "function getGameConfig() view returns (uint256 ticketPrice, uint256 gameDuration, uint256 maxTicketsPerPlayer, bool isActive)",
    "function getPlayerInfo(address player) view returns (uint256 ticketCount, uint256 lastPurchaseTime, uint256 totalSpent)",

    // Events
    "event TicketPurchased(address indexed player, uint256 indexed gameNumber, uint256 ticketIndex, uint256 timestamp)",
    "event WinnerSelected(address indexed winner, uint256 indexed gameNumber, uint256 jackpot, uint256 playerCount, uint256 timestamp)"
  ], []);

  const contract = useMemo(() => {
    if (!contractAddress) return null;
    
    try {
      console.log('🔧 Creating contract instance:', {
        address: contractAddress,
        hasSigner: !!signer,
        hasProvider: !!provider,
        providerNetwork: provider?.network?.name || 'Unknown'
      });
      
      console.log('📋 Contract interface functions:', contractInterface);
      
      if (signer) {
        return new ethers.Contract(contractAddress, contractInterface, signer);
      } else {
        return new ethers.Contract(contractAddress, contractInterface, provider);
      }
    } catch (error) {
      console.error('Error creating contract instance:', error);
      return null;
    }
  }, [contractAddress, contractInterface, signer, provider]);

  // Get current game info using actual functions
  const getCurrentGameInfo = useCallback(async () => {
    if (!contract) {
      // Return default values when no contract
      return {
        currentGameNumber: "0",
        ticketPrice: "0.01",
        isActive: false,
        playerCount: "0",
        currentJackpot: "0",
        status: "No games started yet - Buy first ticket to begin!"
      };
    }
    
    try {
      // Use the actual functions that exist on the contract
      const [gameNumber, playerCount, jackpot, gameConfig] = await Promise.all([
        contract.getCurrentGameNumber(),
        contract.getCurrentGamePlayerCount(),
        contract.getCurrentGameJackpot(),
        contract.getGameConfig()
      ]);
      
      return {
        currentGameNumber: gameNumber.toString(),
        ticketPrice: ethers.utils.formatEther(gameConfig[0]),
        isActive: gameConfig[3],
        playerCount: playerCount.toString(),
        currentJackpot: ethers.utils.formatEther(jackpot),
        status: gameConfig[3] ? "Game is active" : "Game is not active"
      };
    } catch (error) {
      console.error('Error getting game info, returning defaults:', error);
      // Return default values when contract call fails (likely no games started)
      return {
        currentGameNumber: "0",
        ticketPrice: "0.01",
        isActive: false,
        playerCount: "0",
        currentJackpot: "0",
        status: "No games started yet - Buy first ticket to begin!"
      };
    }
  }, [contract]);

  // Get game configuration using actual functions
  const getGameConfiguration = useCallback(async () => {
    if (!contract) {
      // Return default values when no contract
      return {
        ticketPrice: "0.01",
        gameDuration: "86400", // 1 day in seconds
        maxTicketsPerPlayer: "100",
        isActive: false,
        status: "No games started yet"
      };
    }
    
    try {
      const gameConfig = await contract.getGameConfig();
      
      return {
        ticketPrice: ethers.utils.formatEther(gameConfig[0]),
        gameDuration: gameConfig[1].toString(),
        maxTicketsPerPlayer: gameConfig[2].toString(),
        isActive: gameConfig[3],
        status: "Game configuration loaded"
      };
    } catch (error) {
      console.error('Error getting game config, returning defaults:', error);
      // Return default values when contract call fails (likely no games started)
      return {
        ticketPrice: "0.01",
        gameDuration: "86400", // 1 day in seconds
        maxTicketsPerPlayer: "100",
        isActive: false,
        status: "No games started yet - Buy first ticket to begin!"
      };
    }
  }, [contract]);

  // Get player info
  const getPlayerInfo = useCallback(async (playerAddress) => {
    if (!contract || !playerAddress) {
      // Return default values when no contract or player address
      return {
        ticketCount: "0",
        lastPurchaseTime: "0",
        totalSpent: "0"
      };
    }
    
    try {
      const playerInfo = await contract.getPlayerInfo(playerAddress);
      
      return {
        ticketCount: playerInfo[0].toString(),
        lastPurchaseTime: playerInfo[1].toString(),
        totalSpent: ethers.utils.formatEther(playerInfo[2])
      };
    } catch (error) {
      console.error('Error getting player info, returning defaults:', error);
      // Return default values when contract call fails
      return {
        ticketCount: "0",
        lastPurchaseTime: "0",
        totalSpent: "0"
      };
    }
  }, [contract]);

  // Buy ticket
  const buyTicket = useCallback(async (referrer, ticketCount, value) => {
    if (!contract) throw new Error('Contract not initialized');
    
    try {
      console.log('Buying ticket with:', { referrer, ticketCount, value: value.toString() });
      
      // The contract function signature is: buyTicket(address referrer, uint256 ticketCount)
      // The value is passed as part of the transaction options, not as a function parameter
      const tx = await contract.buyTicket(referrer, ticketCount, { 
        value: value,
        gasLimit: 500000 // Add reasonable gas limit
      });
      
      console.log('Transaction sent:', tx.hash);
      return tx;
    } catch (error) {
      console.error('Error buying ticket:', error);
      throw error;
    }
  }, [contract]);

  return {
    contract,
    contractAddress,
    getCurrentGameInfo,
    getGameConfiguration,
    getPlayerInfo,
    buyTicket,
    gameType
  };
};

export default useGameContract; 