import React, { useState, useEffect, useMemo } from "react";
import { useSelector } from "react-redux";
import { Box, VStack, Heading, Text, Badge, Button, Spinner } from "@chakra-ui/react";
import { getContractAddress, GAME_TYPES } from '../utils/contractAddresses';
import useGameContract from '../hooks/useGameContract';
import LotteryListing from "./LotteryListing";
import LotteryStats from "./LotteryStats";
import ReferralSystem from "./ReferralSystem";

const LotteryDashBoard = ({ selectedGame }) => {
  const [gameInfo, setGameInfo] = useState(null);
  const [gameConfig, setGameConfig] = useState(null);
  const [loading, setLoading] = useState(true);

  // Get game contract hook
  const gameContract = useGameContract(selectedGame?.gameType);
  
  // Debug logging for contract hook
  console.log('LotteryDashBoard render:', {
    selectedGame: selectedGame?.title,
    gameContract: !!gameContract,
    gameContractContract: !!gameContract?.contract,
    loading
  });

  // Memoize the contract address to prevent unnecessary re-renders
  const contractAddress = useMemo(() => selectedGame?.address, [selectedGame?.address]);
  
  // Memoize the contract instance to prevent recreation
  const stableContract = useMemo(() => gameContract?.contract, [gameContract?.contract]);

  // Re-enable contract data loading with better error handling
  useEffect(() => {
    console.log('🔄 useEffect triggered with:', { contractAddress, stableContract: !!stableContract, gameInfo: !!gameInfo, gameConfig: !!gameConfig, loading });
    
    // Prevent infinite reloading by checking if we already have data
    if (gameInfo && gameConfig && !loading) {
      console.log('🛑 Already have game data, skipping reload');
      return;
    }
    
    // Add a safety timeout to prevent infinite loading
    const safetyTimeout = setTimeout(() => {
      console.warn('Safety timeout reached, forcing loading to false');
      setLoading(false);
    }, 15000); // 15 second safety timeout
    
    // Flag to track if component is still mounted
    let isMounted = true;
    
    const loadGameData = async () => {
      if (!contractAddress) {
        console.log('No game selected, setting loading to false');
        if (isMounted) {
          setLoading(false);
          setGameInfo(null);
          setGameConfig(null);
        }
        clearTimeout(safetyTimeout);
        return;
      }
      
      if (stableContract) {
        console.log('Loading game data...');
        if (isMounted) {
          setLoading(true);
        }
        try {
          console.log('🎯 Calling getCurrentGameInfo...');
          const info = await gameContract.getCurrentGameInfo();
          console.log('✅ getCurrentGameInfo result:', info);
          
          console.log('🎯 Calling getGameConfiguration...');
          const config = await gameContract.getGameConfiguration();
          console.log('✅ getGameConfiguration result:', config);
          
          console.log('Game data loaded successfully:', { info, config });
          
          // Only update state if component is still mounted
          if (isMounted) {
            setGameInfo(info);
            setGameConfig(config);
          }
        } catch (error) {
          console.error('Error loading game data, using defaults:', error);
          // Set default values when contract calls fail (likely no games started)
          const defaultInfo = {
            currentGameNumber: "0",
            ticketPrice: "0.01",
            isActive: false,
            playerCount: "0",
            currentJackpot: "0",
            status: "No games started yet - Buy first ticket to begin!"
          };
          const defaultConfig = {
            ticketPrice: "0.01",
            gameDuration: "86400", // 1 day in seconds
            maxTicketsPerPlayer: "100",
            isActive: false,
            status: "No games started yet - Buy first ticket to begin!"
          };
          
          console.log('Setting default values:', { defaultInfo, defaultConfig });
          if (isMounted) {
            setGameInfo(defaultInfo);
            setGameConfig(defaultConfig);
          }
        } finally {
          if (isMounted) {
            console.log('Setting loading to false');
            setLoading(false);
          }
          clearTimeout(safetyTimeout);
        }
      } else {
        // Contract not available
        console.log('Contract not available, setting defaults');
        if (isMounted) {
          setLoading(false);
          setGameInfo({
            currentGameNumber: "0",
            ticketPrice: "0.01",
            isActive: false,
            playerCount: "0",
            currentJackpot: "0",
            status: "Contract not available - Check network connection"
          });
          setGameConfig({
            ticketPrice: "0.01",
            gameDuration: "86400",
            maxTicketsPerPlayer: "100",
            isActive: false,
            status: "Contract not available - Check network connection"
          });
        }
        clearTimeout(safetyTimeout);
      }
    };

    loadGameData();
    
    // Cleanup function
    return () => {
      isMounted = false;
      clearTimeout(safetyTimeout);
    };
  }, [contractAddress, stableContract]); // Simplified dependencies to prevent loops
  
  // TEMPORARY: Set default values to stop infinite loading
  useEffect(() => {
    if (!gameInfo || !gameConfig) {
      console.log('🛑 Setting default values to stop infinite loading');
      setGameInfo({
        currentGameNumber: "0",
        ticketPrice: "0.01",
        isActive: false,
        playerCount: "0",
        currentJackpot: "0",
        status: "No games started yet - Buy first ticket to begin!"
      });
      setGameConfig({
        ticketPrice: "0.01",
        gameDuration: "86400",
        maxTicketsPerPlayer: "100",
        isActive: false,
        status: "No games started yet - Buy first ticket to begin!"
      });
      setLoading(false);
    }
  }, []); // Only run once on mount

  return (
    <VStack spacing={6} p={4} maxW="1200px" mx="auto">
      {/* Selected Game Info */}
      {selectedGame && (
        <Box 
          bg="white" 
          p={6} 
          borderRadius="15px" 
          boxShadow="0 10px 30px rgba(0,0,0,0.1)"
          w="100%"
        >
          <VStack spacing={4}>
            <Heading size="lg" color="gray.700">
              {selectedGame.title}
            </Heading>
            
            {loading ? (
              <Spinner size="lg" />
            ) : (
              <>
                <Box display="flex" gap={4} flexWrap="wrap">
                  <Badge colorScheme="green" p={2} borderRadius="md">
                    Price: {gameConfig?.ticketPrice || selectedGame.price}
                  </Badge>
                  <Badge colorScheme="blue" p={2} borderRadius="md">
                    Duration: {selectedGame.duration}
                  </Badge>
                  <Badge colorScheme="purple" p={2} borderRadius="md">
                    Game Type: {selectedGame.gameType}
                  </Badge>
                </Box>
                
                {gameInfo && (
                  <Box display="flex" gap={4} flexWrap="wrap">
                    <Badge colorScheme="orange" p={2} borderRadius="md">
                      Current Jackpot: {gameInfo.currentJackpot} VERY
                    </Badge>
                    <Badge colorScheme="teal" p={2} borderRadius="md">
                      Players: {gameInfo.playerCount}
                    </Badge>
                    <Badge colorScheme="cyan" p={2} borderRadius="md">
                      Game #{gameInfo.currentGameNumber}
                    </Badge>
                    <Badge colorScheme={gameInfo.isActive ? "green" : "red"} p={2} borderRadius="md">
                      Status: {gameInfo.isActive ? "Active" : "Inactive"}
                    </Badge>
                    {gameInfo.status && (
                      <Badge colorScheme="blue" p={2} borderRadius="md">
                        {gameInfo.status}
                      </Badge>
                    )}
                  </Box>
                )}
                
                <Text color="gray.600" textAlign="center">
                  {gameInfo?.status === "No games started yet - Buy first ticket to begin!" 
                    ? "🎯 No games started yet! Buy the first ticket to begin the lottery!"
                    : "Ready to play? Buy your ticket and join the game!"
                  }
                </Text>
              </>
            )}
          </VStack>
        </Box>
      )}

      {/* Referral System */}
      <ReferralSystem />

      {/* Lottery Stats */}
      <LotteryStats selectedGame={selectedGame} gameInfo={gameInfo} />

      {/* Lottery Listing */}
              <LotteryListing selectedGame={selectedGame} />
    </VStack>
  );
};

export default LotteryDashBoard;
