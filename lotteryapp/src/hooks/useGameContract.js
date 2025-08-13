import { useCallback, useMemo } from 'react';
import * as wagmi from 'wagmi';
import { useProvider, useSigner } from 'wagmi';
import { useDispatch } from 'react-redux';
import { ethers } from 'ethers';
import { getContractAddress, GAME_TYPES } from '../utils/contractAddresses';
import { startAction, stopAction, errorAction } from '../redux/reducers/uiActions';

const useGameContract = (gameType) => {
  const dispatch = useDispatch();
  const [signer] = useSigner();
  const provider = useProvider();

  // Get contract address based on game type
  const contractAddress = useMemo(() => {
    return getContractAddress(gameType);
  }, [gameType]);

  // Contract interface for actual contract functions
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

  const contractConfig = useMemo(() => ({
    addressOrName: contractAddress,
    contractInterface: contractInterface,
    signerOrProvider: signer.data || provider
  }), [contractAddress, signer.data, provider]);

  const contract = wagmi.useContract(contractConfig);

  // Get current game info using actual functions
  const getCurrentGameInfo = useCallback(async () => {
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