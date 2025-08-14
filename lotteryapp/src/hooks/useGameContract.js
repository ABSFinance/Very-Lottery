import { useCallback, useMemo } from 'react';
import { ethers } from 'ethers';
import { useMetaMaskAccount } from '../context/AccountContext';
import { getContractAddress } from '../utils/contractAddresses';

const useGameContract = (gameType) => {
  const { connected, connectedAddr } = useMetaMaskAccount();
  
  const contractAddress = getContractAddress(gameType);
  
  // Create provider and signer
  const provider = useMemo(() => {
    if (typeof window !== 'undefined' && window.ethereum) {
      return new ethers.providers.Web3Provider(window.ethereum);
    }
    return new ethers.providers.JsonRpcProvider(process.env.REACT_APP_PROVIDER_URL || 'https://rpc.verylabs.io');
  }, []);

  const signer = useMemo(() => {
    if (provider && typeof window !== 'undefined' && window.ethereum) {
      return provider.getSigner();
    }
    return null;
  }, [provider]);

  const contractInterface = [
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
  ];

  const contract = useMemo(() => {
    if (!contractAddress) return null;
    
    try {
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
    if (!contract) return null;
    
    try {
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
        currentJackpot: ethers.utils.formatEther(jackpot)
      };
    } catch (error) {
      console.error('Error getting game info:', error);
      return null;
    }
  }, [contract]);

  // Get game configuration using actual functions
  const getGameConfiguration = useCallback(async () => {
    if (!contract) return null;
    
    try {
      const gameConfig = await contract.getGameConfig();
      
      return {
        ticketPrice: ethers.utils.formatEther(gameConfig[0]),
        gameDuration: gameConfig[1].toString(),
        maxTicketsPerPlayer: gameConfig[2].toString(),
        isActive: gameConfig[3]
      };
    } catch (error) {
      console.error('Error getting game config:', error);
      return null;
    }
  }, [contract]);

  // Get player info
  const getPlayerInfo = useCallback(async (playerAddress) => {
    if (!contract) return null;
    
    try {
      const playerInfo = await contract.getPlayerInfo(playerAddress);
      return {
        ticketCount: playerInfo[0].toString(),
        lastPurchaseTime: playerInfo[1].toString(),
        totalSpent: ethers.utils.formatEther(playerInfo[2])
      };
    } catch (error) {
      console.error('Error getting player info:', error);
      return null;
    }
  }, [contract]);

  // Buy ticket
  const buyTicket = useCallback(async (referrer, ticketCount, value) => {
    if (!contract) throw new Error('Contract not initialized');
    
    try {
      const tx = await contract.buyTicket(referrer, ticketCount, { value });
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